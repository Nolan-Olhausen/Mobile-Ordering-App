/****************************************************************************************************
 *
 * @file:    product.dart
 * @author:  Nolan Olhausen
 * @date: 2024-11-15
 *
 * @brief:
 *      Page for viewing and customizing a product.
 * 
 ****************************************************************************************************/

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'cart.dart';
import '../utility/squareAPI.dart';

class ProductPage extends StatefulWidget {
  final Item product;
  List<CartItem> cart;

  ProductPage({required this.cart, required this.product, super.key});

  @override
  _ProductPageState createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  // track selected item options and modifiers
  Map<String, String> selectedOptions = {};
  Map<String, String> selectedSingleModifiers = {};
  Map<String, List<String>> selectedMultipleModifiers = {};
  Map<String, List<ItemOptionVal>> validValues =
      {}; // tracks valid values for each dropdown

  @override
  void initState() {
    super.initState();
    _initializeOptions();
    _initializeSingleModifiers();
  }

  // initialize single selection modifiers
  void _initializeSingleModifiers() {
    for (var modifierList in widget.product.modifierLists) {
      if (modifierList.selectionType == 'SINGLE') {
        // check if the modifier list has any modifiers
        if (modifierList.modifiers.isNotEmpty) {
          setState(() {
            // initialize selectedSingleModifiers to the first modifier's id
            selectedSingleModifiers[modifierList.id] =
                modifierList.modifiers.first.id;
          });
        }
      }
    }
  }

  // initialize options (option combinations make item variations)
  void _initializeOptions() {
    for (var option in widget.product.itemOptions) {
      validValues[option.id] = _getValidOptionVals(option.id);

      // default to the first valid value for each option, if available
      if (validValues[option.id]!.isNotEmpty) {
        selectedOptions[option.id] = validValues[option.id]!.first.id;
      }
    }
  }

  // get valid option values (based on previous selections, some get removed when not compatible)
  List<ItemOptionVal> _getValidOptionVals(String itemOptionId) {
    // find the index of the current option
    final currentOptionIndex = widget.product.itemOptions
        .indexWhere((option) => option.id == itemOptionId);

    // gather selected values for all prior options
    final previousSelections = widget.product.itemOptions
        .take(currentOptionIndex)
        .map((option) => selectedOptions[option.id])
        .toList();

    // filter item variations to match previous selections
    final matchingVariations = widget.product.itemVariations.where((variation) {
      return previousSelections.every((selectedValue) {
        if (selectedValue == null) return true;
        return variation.itemOptionValues.any((val) => val.id == selectedValue);
      });
    }).toList();

    // collect valid values for the current option from matching variations
    final validValues = matchingVariations
        .expand((variation) => variation.itemOptionValues)
        .where((val) => val.itemOptionId == itemOptionId)
        .toSet() // precaution for duplicates
        .toList();

    return validValues;
  }

  // update when select option
  void _onOptionSelected(String itemOptionId, String? value) {
    setState(() {
      // update the selected option with the new value
      selectedOptions[itemOptionId] = value!;

      // recalculate valid values for all subsequent options
      for (var i = 0; i < widget.product.itemOptions.length; i++) {
        var option = widget.product.itemOptions[i];

        // recalculate valid values for each option
        validValues[option.id] = _getValidOptionVals(option.id);

        // if the option is one of the following ones (after the selected one),
        // reset its value to the first valid value from the recalculated list
        if (i >
            widget.product.itemOptions
                .indexWhere((opt) => opt.id == itemOptionId)) {
          if (validValues[option.id]!.isNotEmpty) {
            selectedOptions[option.id] = validValues[option.id]!.first.id;
          } else {
            selectedOptions
                .remove(option.id); // in case no valid values are available
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.product;

    String? findMatchingVariationId() {
      return widget.product.itemVariations.firstWhere(
        (variation) {
          return selectedOptions.entries.every((entry) {
            return variation.itemOptionValues.any(
              (v) => v.itemOptionId == entry.key && v.id == entry.value,
            );
          });
        },
      ).id;
    }

    // collect all selected modifier IDs
    List<String> getSelectedModifierIds() {
      final modifierIds = <String>[];
      modifierIds.addAll(selectedSingleModifiers.values);

      for (var modifiers in selectedMultipleModifiers.values) {
        modifierIds.addAll(modifiers);
      }

      return modifierIds;
    }

    String variationId = findMatchingVariationId() ?? '';
    List<String> modifierIds = getSelectedModifierIds();

    return Scaffold(
        appBar: AppBar(
          title: Text(
            item.name,
            style: GoogleFonts.poppins(
              color: const Color.fromARGB(255, 255, 153, 7),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  if (item.itemImage != null)
                    Image.network(
                      item.itemImage!.url,
                      width: 300,
                      height: 300,
                      fit: BoxFit.cover,
                    ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: item.categories
                        .map((category) => Chip(label: Text(category.name)))
                        .toList(),
                  ),
                  const SizedBox(height: 16),

                  if (item.description != null)
                    Text(
                      item.description!,
                      style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  const SizedBox(height: 24),

                  Text(
                    "Customize",
                    style: GoogleFonts.poppins(
                      color: const Color.fromARGB(255, 255, 153, 7),
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 24),
                  Text(
                    "Select Options",
                    style: GoogleFonts.poppins(
                      color: const Color.fromARGB(255, 255, 153, 7),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  // dynamically display options
                  ...item.itemOptions.map((option) {
                    final options = validValues[option.id] ?? [];
                    // check selected value is valid
                    if (selectedOptions[option.id] != null) {
                      assert(
                        options.any((optionVal) =>
                            optionVal.id == selectedOptions[option.id]),
                        'Selected value ${selectedOptions[option.id]} does not match any valid options for ${option.id}',
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: option.name,
                            border: const OutlineInputBorder(),
                          ),
                          value: selectedOptions[option.id],
                          items: options
                              .map((optionVal) => DropdownMenuItem(
                                    value: optionVal.id,
                                    child: Text(optionVal.name),
                                  ))
                              .toList(),
                          onChanged: (value) =>
                              _onOptionSelected(option.id, value),
                        ),
                      ],
                    );
                  }),
                  if (item.modifierLists.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Text(
                          "Modify",
                          style: GoogleFonts.poppins(
                            color: const Color.fromARGB(255, 255, 153, 7),
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        ...item.modifierLists.map((modifierList) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              if (modifierList.selectionType == 'SINGLE') ...[
                                DropdownButtonFormField<String>(
                                  decoration: InputDecoration(
                                    labelText: modifierList.name,
                                    border: const OutlineInputBorder(),
                                  ),
                                  value:
                                      selectedSingleModifiers[modifierList.id],
                                  onChanged: (selectedValue) {
                                    setState(() {
                                      selectedSingleModifiers[modifierList.id] =
                                          selectedValue!;
                                    });
                                  },
                                  items: modifierList.modifiers.map((modifier) {
                                    return DropdownMenuItem<String>(
                                      value: modifier.id,
                                      child: Text(
                                          '${modifier.name} (\$${(modifier.price / 100).toStringAsFixed(2)})'),
                                    );
                                  }).toList(),
                                ),
                              ],
                              if (modifierList.selectionType == 'MULTIPLE') ...[
                                DropdownButtonFormField<String>(
                                  decoration: InputDecoration(
                                    labelText: modifierList.name,
                                    border: const OutlineInputBorder(),
                                  ),
                                  onChanged: (selectedValue) {
                                    setState(() {
                                      if (selectedMultipleModifiers[
                                              modifierList.id] ==
                                          null) {
                                        selectedMultipleModifiers[
                                            modifierList.id] = [];
                                      }

                                      if (!(selectedMultipleModifiers[
                                                  modifierList.id]
                                              ?.contains(selectedValue) ??
                                          false)) {
                                        selectedMultipleModifiers[
                                                modifierList.id]
                                            ?.add(selectedValue!);
                                      }
                                    });
                                  },
                                  items: modifierList.modifiers.map((modifier) {
                                    return DropdownMenuItem<String>(
                                      value: modifier.id,
                                      child: Text(
                                          '${modifier.name} (\$${(modifier.price / 100).toStringAsFixed(2)})'),
                                    );
                                  }).toList(),
                                ),
                                if (selectedMultipleModifiers[
                                        modifierList.id] !=
                                    null)
                                  Wrap(
                                    spacing: 8,
                                    children: selectedMultipleModifiers[
                                            modifierList.id]!
                                        .map((selectedId) {
                                      final selectedModifier = modifierList
                                          .modifiers
                                          .firstWhere((modifier) =>
                                              modifier.id == selectedId);
                                      return Chip(
                                        label: Text(
                                            '${selectedModifier.name} (\$${(selectedModifier.price / 100).toStringAsFixed(2)})'),
                                        deleteIcon: const Icon(Icons.cancel),
                                        onDeleted: () {
                                          setState(() {
                                            selectedMultipleModifiers[
                                                    modifierList.id]
                                                ?.remove(selectedId);
                                          });
                                        },
                                      );
                                    }).toList(),
                                  ),
                              ],
                            ],
                          );
                        }),
                        const SizedBox(height: 16),
                      ],
                    ),
                ],
              ),
            ),
            FutureBuilder<double>(
              future: SquareAPI().fetchItemPrice(
                  variationId: variationId, modifierIds: modifierIds),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (snapshot.hasData) {
                  double totalAmount = snapshot.data!;
                  return Text(
                    'Total: \$${totalAmount.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      color: const Color.fromARGB(255, 255, 153, 7),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  );
                } else {
                  return const Text('No data available');
                }
              },
            ),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.only(right: 16.0, left: 16.0, bottom: 16.0),
              child: ElevatedButton(
                onPressed: () async {
                  final variationIdAdd = findMatchingVariationId();
                  final modifierIdsAdd = getSelectedModifierIds();
                  double itemTotal = await SquareAPI().fetchItemPrice(
                      variationId: variationId, modifierIds: modifierIds);

                  if (variationIdAdd != null) {
                    final cartItem = CartItem(
                      variationId: variationIdAdd,
                      modifierIds: modifierIdsAdd,
                      product: widget.product,
                      itemTotal: itemTotal,
                    );

                    setState(() {
                      widget.cart.add(cartItem);
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('${widget.product.name} added to cart!')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please select a valid variation!')),
                    );
                  }
                },
                child: Text(
                  'ADD TO CART',
                  style: GoogleFonts.poppins(
                    color: const Color.fromARGB(255, 255, 153, 7),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ));
  }
}
