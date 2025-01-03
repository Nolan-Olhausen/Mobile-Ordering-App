/****************************************************************************************************
 *
 * @file:    squareAPI.dart
 * @author:  Nolan Olhausen
 * @date: 2024-11-15
 *
 * @brief:
 *      Dart file that contains the SquareAPI class and several classes that are used to parse the
 *      JSON data returned from the Square API. This file is used to interact with the Square API
 *      to fetch items, create orders, and charge cards.
 * 
 ****************************************************************************************************/

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';
import '../pages/cart.dart';

// item class, very fragile. Several linked classes that also have similar work done, just less complex
class Item {
  final String id;
  final String name;
  final String? description;
  final List<Category> categories;
  final List<ModifierList> modifierLists;
  final List<ItemVariation> itemVariations;
  final List<ItemOption> itemOptions;
  final ItemImage? itemImage;

  Item(
      {required this.id,
      required this.name,
      required this.description,
      required this.categories,
      required this.modifierLists,
      required this.itemVariations,
      required this.itemOptions,
      required this.itemImage});

  factory Item.fromJson(
      Map<String, dynamic> json, Map<String, Map<String, dynamic>> lookup) {
    // resolve categories
    final categoriesJson =
        json['item_data']['categories'] as List<dynamic>? ?? [];

    // extract the 'id' values from the categories
    final categoryIds = categoriesJson.map((category) {
      return category['id'] as String; // Cast to String
    }).toList();
    final categories = categoryIds
        .map<Category?>((id) {
          final categoryJson = lookup['CATEGORY']?[id];
          return categoryJson != null ? Category.fromJson(categoryJson) : null;
        })
        .whereType<Category>()
        .toList();
    // resolve modifier lists
    final modifierListsJson =
        json['item_data']['modifier_list_info'] as List<dynamic>? ?? [];
    final modifierListIds = modifierListsJson.map((modifierList) {
      return modifierList['modifier_list_id'] as String;
    }).toList();
    final modifierLists = modifierListIds
        .map<ModifierList?>((id) {
          final modifierJson = lookup['MODIFIER_LIST']?[id];
          return modifierJson != null
              ? ModifierList.fromJson(modifierJson)
              : null;
        })
        .whereType<ModifierList>()
        .toList();
    // resolve item options
    final optionsJson =
        json['item_data']['item_options'] as List<dynamic>? ?? [];
    final optionIds = optionsJson.map((option) {
      return option['item_option_id'];
    }).toList();
    final itemOptions = optionIds
        .map<ItemOption?>((id) {
          final optionJson = lookup['ITEM_OPTION']?[id];
          return optionJson != null ? ItemOption.fromJson(optionJson) : null;
        })
        .whereType<ItemOption>()
        .toList();
    final Map<String, ItemOption> itemOptionsMap = {
      for (var itemOption in itemOptions) itemOption.id: itemOption,
    };
    // resolve item variations
    final variationsJson = json['item_data']['variations'] as List<dynamic>;
    final itemVariations = variationsJson.map<ItemVariation>((variationJson) {
      return ItemVariation.fromJson(variationJson, itemOptionsMap);
    }).toList();
    // resolve image
    final imageId = json['item_data']['image_ids']?.first;
    final itemImage = imageId != null
        ? ItemImage.fromJson(lookup['IMAGE']?[imageId] ?? {})
        : ItemImage(
            id: 'None',
            url:
                'https://items-images-production.s3.us-west-2.amazonaws.com/files/5453a9c49c551df8930415d2de8e61a2c7fcd555/original.png');
    return Item(
      id: json['id'],
      name: json['item_data']['name'],
      description: json['item_data']['description'],
      categories: categories,
      modifierLists: modifierLists,
      itemVariations: itemVariations,
      itemOptions: itemOptions,
      itemImage: itemImage,
    );
  }
}

// item image class
class ItemImage {
  final String id;
  final String url;

  ItemImage({required this.id, required this.url});

  factory ItemImage.fromJson(Map<String, dynamic> json) {
    return ItemImage(
      id: json['id'],
      url: json['image_data']['url'],
    );
  }
}

// item variation class
class ItemVariation {
  final String id;
  final String name;
  final String itemId;
  final int price;
  final List<ItemOptionVal> itemOptionValues;

  ItemVariation(
      {required this.id,
      required this.name,
      required this.itemId,
      required this.price,
      required this.itemOptionValues});

  factory ItemVariation.fromJson(
    Map<String, dynamic> json,
    Map<String, ItemOption> itemOptionsMap,
  ) {
    final List<ItemOptionVal> resolvedOptions =
        (json['item_variation_data']['item_option_values'] as List<dynamic>)
            .map((optionValueJson) {
      final optionId = optionValueJson['item_option_id'];
      final valueId = optionValueJson['item_option_value_id'];
      final itemOption = itemOptionsMap[optionId];
      final itemOptionValue = itemOption?.itemOptionVals.firstWhere(
        (value) => value.id == valueId,
        orElse: () => throw Exception("Option Value not found"),
      );
      return ItemOptionVal(
        id: itemOptionValue!.id,
        itemOptionId: itemOptionValue.itemOptionId,
        name: itemOptionValue.name,
      );
    }).toList();

    return ItemVariation(
      id: json['id'],
      name: json['item_variation_data']['name'],
      itemId: json['item_variation_data']['item_id'],
      price: json['item_variation_data']['price_money']['amount'],
      itemOptionValues: resolvedOptions,
    );
  }
}

// item option
class ItemOption {
  final String id;
  final String name;
  final bool showColors;
  final List<ItemOptionVal> itemOptionVals;

  ItemOption(
      {required this.id,
      required this.name,
      required this.showColors,
      required this.itemOptionVals});

  factory ItemOption.fromJson(Map<String, dynamic> json) {
    return ItemOption(
      id: json['id'],
      name: json['item_option_data']['name'],
      showColors: json['item_option_data']['show_colors'],
      itemOptionVals: (json['item_option_data']['values'] as List<dynamic>)
          .map((itemOptionJson) => ItemOptionVal.fromJson(itemOptionJson))
          .toList(),
    );
  }
}

// item option values
class ItemOptionVal {
  final String id;
  final String itemOptionId;
  final String name;

  ItemOptionVal(
      {required this.id, required this.itemOptionId, required this.name});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ItemOptionVal && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  factory ItemOptionVal.fromJson(Map<String, dynamic> json) {
    return ItemOptionVal(
      id: json['id'],
      name: json['item_option_value_data']['name'],
      itemOptionId: json['item_option_value_data']['item_option_id'],
    );
  }
}

// modifier sets
class ModifierList {
  final String id;
  final String name;
  final List<Modifier> modifiers;
  final String selectionType;

  ModifierList(
      {required this.id,
      required this.name,
      required this.modifiers,
      required this.selectionType});

  factory ModifierList.fromJson(Map<String, dynamic> json) {
    return ModifierList(
      id: json['id'],
      name: json['modifier_list_data']['name'],
      selectionType: json['modifier_list_data']['selection_type'],
      modifiers: (json['modifier_list_data']['modifiers'] as List<dynamic>)
          .map((modifierJson) => Modifier.fromJson(modifierJson))
          .toList(),
    );
  }
}

// individual modifier values
class Modifier {
  final String id;
  final String name;
  final int price;
  final String modifierListId;

  Modifier(
      {required this.id,
      required this.name,
      required this.price,
      required this.modifierListId});

  factory Modifier.fromJson(Map<String, dynamic> json) {
    return Modifier(
      id: json['id'],
      name: json['modifier_data']['name'],
      price: json['modifier_data']['price_money']['amount'],
      modifierListId: json['modifier_data']['modifier_list_id'],
    );
  }
}

// categories
class Category {
  final String id;
  final String name;
  final String? parentId;

  Category({required this.id, required this.name, required this.parentId});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['category_data']['name'],
      parentId: json['category_data']['parent_category']['id'],
    );
  }
}

// loyalty program
class RewardProgram {
  final String id;
  final List<RewardTier> rewardTiers;
  final List<AccrualRule> accrualRules;
  final String singular;
  final String plural;

  RewardProgram(
      {required this.singular,
      required this.plural,
      required this.id,
      required this.rewardTiers,
      required this.accrualRules});

  factory RewardProgram.fromJson(Map<String, dynamic> json) {
    return RewardProgram(
      id: json['id'],
      singular: json['terminology']['one'],
      plural: json['terminology']['other'],
      rewardTiers: (json['reward_tiers'] as List)
          .map((tier) => RewardTier.fromJson(tier))
          .toList(),
      accrualRules: (json['accrual_rules'] as List)
          .map((rule) => AccrualRule.fromJson(rule))
          .toList(),
    );
  }
}

// rewards in loyalty program
class RewardTier {
  final String id;
  final int points;
  final String name;
  final String discountType;
  final int? fixedDiscountMoney; // For FIXED_AMOUNT
  final String? percentageDiscount; // For FIXED_PERCENTAGE
  final List<String>? categoryObjectIds; // For FIXED_PERCENTAGE
  final int? maxDiscountMoney; // For FIXED_PERCENTAGE

  RewardTier({
    required this.id,
    required this.points,
    required this.name,
    required this.discountType,
    this.fixedDiscountMoney,
    this.percentageDiscount,
    this.categoryObjectIds,
    this.maxDiscountMoney,
  });

  factory RewardTier.fromJson(Map<String, dynamic> json) {
    final definition = json['definition'];
    final discountType = definition['discount_type'];

    int? fixedDiscountMoney;
    String? percentageDiscount;
    List<String>? categoryObjectIds;
    int? maxDiscountMoney;

    if (discountType == 'FIXED_AMOUNT') {
      fixedDiscountMoney = definition['fixed_discount_money']?['amount'];
    } else if (discountType == 'FIXED_PERCENTAGE') {
      percentageDiscount = definition['percentage_discount'];
      categoryObjectIds = (definition['catalog_object_ids'] as List?)
          ?.map((id) => id as String)
          .toList();
      maxDiscountMoney = definition['max_discount_money']?['amount'];
    }

    return RewardTier(
      id: json['id'],
      points: json['points'],
      name: json['name'],
      discountType: discountType,
      fixedDiscountMoney: fixedDiscountMoney,
      percentageDiscount: percentageDiscount,
      categoryObjectIds: categoryObjectIds,
      maxDiscountMoney: maxDiscountMoney,
    );
  }
}

// how points are accrued
class AccrualRule {
  final String accrualType;
  final int points;
  final double spend;

  AccrualRule(
      {required this.accrualType, required this.points, required this.spend});

  factory AccrualRule.fromJson(Map<String, dynamic> json) {
    return AccrualRule(
      accrualType: json['accrual_type'],
      points: json['points'],
      spend: (json['spend_data']['amount_money']['amount'] as int).toDouble() /
          100,
    );
  }
}

// customer accounts
class LoyaltyAccount {
  final String id;
  final String mapId;
  final String phone;
  final String program;
  final int balance;
  final String customerId;

  LoyaltyAccount({
    required this.mapId,
    required this.id,
    required this.phone,
    required this.program,
    required this.balance,
    required this.customerId,
  });

  factory LoyaltyAccount.fromJson(Map<String, dynamic> json) {
    return LoyaltyAccount(
      id: json['id'],
      mapId: json['mapping']['id'],
      phone: json['mapping']['phone_number'],
      program: json['program_id'],
      balance: json['balance'],
      customerId: json['customer_id'],
    );
  }
}

//  methods for API calls needed
class SquareAPI {
  static const String _url = "https://connect.squareup.com/v2/";
  static String? get accessToken => dotenv.env['PROD_ACCESS_TOKEN'];
  static String? get onlineChannel => dotenv.env['ONLINE_CHANNEL'];
  static String? get taxId => dotenv.env['TAX_ID'];

  //==============================================================================
  // CATALOG
  //==============================================================================

  // lookup table required before parsing into above objects
  Map<String, Map<String, dynamic>> buildCatalogLookup(
      List<Map<String, dynamic>> entities) {
    final Map<String, Map<String, dynamic>> lookup = {};

    // helper function to group entities by type
    void addEntitiesToLookup(
        String entityType, List<Map<String, dynamic>> entityList) {
      if (!lookup.containsKey(entityType)) {
        lookup[entityType] = {};
      }
      for (var entity in entityList) {
        final id = entity['id'];
        if (id != null) {
          lookup[entityType]![id] = entity;
        }
      }
    }

    // group entities by their type
    for (var entity in entities) {
      final entityType = entity['type'];
      if (entityType != null) {
        addEntitiesToLookup(entityType, [entity]);
      }
    }

    return lookup;
  }

  // fetch the catalog items and related modifiers, options, categories from Square API
  Future<List<Item>> fetchOnlineAvailabeAndRelated() async {
    // check if the authorization token is loaded
    final token = accessToken;
    if (token == null) {
      throw Exception(
          "(fetchOnlineAvailabeAndRelated) Authorization token is missing");
    }

    List<Map<String, dynamic>> allObjects = [];
    String? cursor;

    do {
      // build the URL with the cursor if available, this request can have a large response
      final url = Uri.parse(
          '${_url}catalog/list?types=item%2Citem_option%2Cmodifier_list%2Ccategory%2Cimage${cursor != null ? "&cursor=$cursor" : ""}');

      // make the HTTP GET request
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      // check if the response is successful
      if (response.statusCode == 200) {
        // parse the JSON response
        var data = jsonDecode(response.body);

        // add the objects from the current page to the accumulated list
        final objects = (data['objects'] as List)
            .map((item) => item as Map<String, dynamic>)
            .toList();
        allObjects.addAll(objects);

        // update the cursor for the next request
        cursor = data['cursor'];
      } else {
        throw Exception(
            '(fetchOnlineAvailabeAndRelated) Failed to load catalog items ${response.statusCode}');
      }
    } while (cursor != null);

    // build the lookup table using all retrieved objects
    final lookup = buildCatalogLookup(allObjects);

    // filter out the archived items and parse the remaining ones
    final items = allObjects
        .where((obj) => obj['type'] == 'ITEM' && obj['is_archived'] != true);

    return items.map<Item>((json) => Item.fromJson(json, lookup)).toList();
  }

  //==============================================================================
  // LOYALTY
  //==============================================================================

  // fetch loyalty program from API
  Future<List<RewardProgram>> fetchRewardProgram() async {
    final token = accessToken;
    if (token == null) {
      throw Exception("(fetchRewardProgram) Authorization token is missing");
    }

    final response = await http.get(
      Uri.parse('${_url}loyalty/programs'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      final objects = (data['programs'] as List)
          .map((program) => program as Map<String, dynamic>)
          .toList();

      return objects
          .map<RewardProgram>((json) => RewardProgram.fromJson(json))
          .toList();
    } else {
      throw Exception(
          '(fetchRewardProgram) Failed to load loyalty program ${response.statusCode}');
    }
  }

  // fetch loyalty account from API
  Future<List<LoyaltyAccount>> searchLoyaltyAccount(String phone) async {
    final token = accessToken;
    if (token == null) {
      throw Exception("(searchLoyaltyAccount) Authorization token is missing");
    }

    final Map<String, dynamic> body = {
      'query': {
        'mappings': [
          {'phone_number': phone}
        ]
      }
    };

    final response = await http.post(
      Uri.parse('${_url}loyalty/accounts/search'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      final objects = (data['loyalty_accounts'] as List)
          .map((account) => account as Map<String, dynamic>)
          .toList();

      return objects
          .map<LoyaltyAccount>((json) => LoyaltyAccount.fromJson(json))
          .toList();
    } else {
      throw Exception(
          '(searchLoyaltyAccount) Failed to load loyalty accounts ${response.statusCode}');
    }
  }

  // create loyalty account through API
  Future<LoyaltyAccount> createLoyaltyAccount(
      String programId, String phone) async {
    final token = accessToken;
    if (token == null) {
      throw Exception("(createLoyaltyAccount) Authorization token is missing");
    }

    var uuid = const Uuid();
    String idempotencyKey = uuid.v4();

    final body = {
      "idempotency_key": idempotencyKey,
      "loyalty_account": {
        "program_id": programId,
        "mapping": {"phone_number": phone},
      },
    };

    final response = await http.post(
      Uri.parse('${_url}loyalty/accounts'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      final loyaltyAccountData = data['loyalty_account'];

      return LoyaltyAccount.fromJson(loyaltyAccountData);
    } else {
      throw Exception(
          '(createLoyaltyAccount) Failed to create loyalty account ${response.statusCode}');
    }
  }

  //==============================================================================
  // ORDERS
  //==============================================================================

  // fetch price of one item (used on product page when modifying)
  Future<double> fetchItemPrice({
    required String variationId,
    List<String>? modifierIds,
  }) async {
    final token = accessToken;
    if (token == null) {
      throw Exception("(fetchItemPrice) Authorization token is missing");
    }

    Map<String, dynamic> lineItem = {
      'quantity': '1',
      'item_type': 'ITEM',
      'catalog_object_id': variationId,
    };

    if (modifierIds != null && modifierIds.isNotEmpty) {
      lineItem['modifiers'] = modifierIds.map((modifierId) {
        return {'catalog_object_id': modifierId};
      }).toList();
    }

    Map<String, dynamic> requestBody = {
      'order': {
        'location_id': dotenv.env['PROD_MAIN_LOC_ID'],
        'line_items': [lineItem],
      },
    };

    final response = await http.post(
      Uri.parse('${_url}orders/calculate'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(requestBody),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      double totalAmount = 0.0;
      if (responseData['order'] != null &&
          responseData['order']['total_money'] != null) {
        totalAmount = responseData['order']['total_money']['amount'] / 100.0;
      }
      return totalAmount;
    } else {
      throw Exception(
          '(fetchItemPrice) Failed to calculate item price ${response.statusCode}');
    }
  }

  // fetch price of all items (used for cart)
  Future<Map<String, double>> fetchCartPrice({
    required List<CartItem> cart,
  }) async {
    final token = accessToken;
    if (token == null) {
      throw Exception("(fetchCartPrice) Authorization token is missing");
    }

    List<Map<String, dynamic>> lineItems = [];

    // iterate over each CartItem in the cart
    for (CartItem cartItem in cart) {
      // create a line item for the CartItem
      Map<String, dynamic> lineItem = {
        'quantity':
            cartItem.quantity.toString(), // use the quantity from the CartItem
        'item_type': 'ITEM',
        'catalog_object_id':
            cartItem.variationId, // variation ID of the product
      };

      // add modifiers if they exist
      if (cartItem.modifierIds.isNotEmpty) {
        lineItem['modifiers'] = cartItem.modifierIds.map((modifierId) {
          return {'catalog_object_id': modifierId};
        }).toList();
      }

      // add the created line item to the list
      lineItems.add(lineItem);
    }

    Map<String, dynamic> tax = {
      'catalog_object_id': '$taxId',
      'scope': 'ORDER',
    };

    Map<String, dynamic> requestBody = {
      'order': {
        'location_id': dotenv.env['PROD_MAIN_LOC_ID'],
        'line_items': lineItems,
        'taxes': [tax],
      },
    };

    final response = await http.post(
      Uri.parse('${_url}orders/calculate'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(requestBody),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      double totalAmount = 0.0;
      double taxAmount = 0.0;

      if (responseData['order'] != null) {
        if (responseData['order']['total_money'] != null) {
          totalAmount = responseData['order']['total_money']['amount'] / 100.0;
        }
        if (responseData['order']['total_tax_money'] != null) {
          taxAmount =
              responseData['order']['total_tax_money']['amount'] / 100.0;
        }
      }

      // return both total and tax amounts (i wanted to display them seperately)
      return {
        'totalAmount': totalAmount,
        'taxAmount': taxAmount,
      };
    } else {
      throw Exception(
          '(fetchCartPrice) Failed to calculate cart price ${response.statusCode}');
    }
  }

  // charge care from transaction.dart adjusted to curl command
  Future<void> chargeCard(
      String nonce, double orderAmount, double tipAmount, String uuid) async {
    const String chargeUrl = '${_url}payments';

    final Map<String, dynamic> requestBody = {
      "idempotency_key": uuid,
      "amount_money": {
        "amount": (orderAmount * 100).toInt(),
        "currency": "USD",
      },
      "source_id": nonce,
      "tip_money": {
        "amount": (tipAmount * 100).toInt(),
        "currency": "USD",
      },
    };

    try {
      final http.Response response = await http.post(
        Uri.parse(chargeUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
          "Accept": "application/json",
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
      } else {
        final responseBody = jsonDecode(response.body);
        throw Exception(
            'Payment failed: ${responseBody['errors'] ?? 'Unknown error'}');
      }
    } on SocketException catch (ex) {
      throw Exception('Network error: ${ex.message}');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // create order, mostly similar code to fetchCartPrice
  Future<Map<String, String>> createOrder({
    required List<CartItem> cart,
    required String pickupTime,
    String? customerId,
    String? name,
  }) async {
    final token = accessToken;
    if (token == null) {
      throw Exception("(createOrder) Authorization token is missing");
    }

    List<Map<String, dynamic>> lineItems = [];

    for (CartItem cartItem in cart) {
      Map<String, dynamic> lineItem = {
        'quantity': cartItem.quantity.toString(),
        'item_type': 'ITEM',
        'catalog_object_id': cartItem.variationId,
      };

      if (cartItem.modifierIds.isNotEmpty) {
        lineItem['modifiers'] = cartItem.modifierIds.map((modifierId) {
          return {'catalog_object_id': modifierId};
        }).toList();
      }

      lineItems.add(lineItem);
    }

    Map<String, dynamic> tax = {
      'catalog_object_id': '$taxId',
      'scope': 'ORDER',
    };

    Map<String, dynamic> recipient = {};
    if (customerId != null) {
      recipient = {
        "customer_id": customerId,
      };
    } else if (name != null) {
      recipient = {
        "display_name": name,
      };
    }

    Map<String, dynamic> fulfillment = {
      "pickup_details": {
        "schedule_type": "SCHEDULED",
        "pickup_at": pickupTime,
        "recipient": recipient,
      },
      "type": "PICKUP",
    };
    var uuid = const Uuid().v4();
    Map<String, dynamic> requestBody = {
      'idempotency_key': uuid,
      'order': {
        'location_id': dotenv.env['PROD_MAIN_LOC_ID'],
        'fulfillments': [fulfillment],
        'line_items': lineItems,
        'taxes': [tax],
      },
    };

    final response = await http.post(
      Uri.parse('${_url}orders'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(requestBody),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      return {
        'orderId': responseData['order']['id'],
        'fulfillmentUid': responseData['order']['fulfillments'][0]['uid'],
      };
    } else {
      throw Exception(
          '(createOrder) Failed to create order ${response.statusCode}');
    }
  }

  // cancel order (used when user exits payment entry)
  Future<void> cancelOrder(
      {required String orderId, required String fulfillmentId}) async {
    final token = accessToken;
    if (token == null) {
      throw Exception("(cancelOrder) Authorization token is missing");
    }

    Map<String, dynamic> fulfillment = {
      'state': 'CANCELED',
      'uid': fulfillmentId
    };

    final requestBody = {
      'order': {
        'state': 'CANCELED',
        'location_id': dotenv.env['PROD_MAIN_LOC_ID'],
        'fulfillments': [fulfillment],
        'version': 1,
      },
    };

    final response = await http.put(
      Uri.parse('${_url}orders/$orderId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(requestBody),
    );

    if (response.statusCode == 200) {
    } else {
      throw Exception(
          '(cancelOrder) Failed to cancel order ${response.statusCode}');
    }
  }
}
