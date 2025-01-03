/****************************************************************************************************
 *
 * @file:    checkout.dart
 * @author:  Nolan Olhausen
 * @date: 2024-11-15
 *
 * @brief:
 *      Page for handling the checkout process for the user. Allows user to select a pickup date
 *      and time, as well as a payment method. The user can then complete the order and pay for it.
 * 
 ****************************************************************************************************/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'cart.dart';
import 'package:square_in_app_payments/in_app_payments.dart';
import 'package:square_in_app_payments/models.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:square_in_app_payments/google_pay_constants.dart'
    as google_pay_constants;
import '../utility/squareAPI.dart';
import 'package:timezone/standalone.dart' as tz;
import '../utility/transaction.dart';
import 'package:built_collection/built_collection.dart';

enum ApplePayStatus { success, fail, unknown }

class CheckoutPage extends StatefulWidget {
  List<CartItem> cart;
  final double orderAmount;
  final double tipAmount;
  final bool applePayEnabled;
  final bool googlePayEnabled;
  final LoyaltyAccount? account;
  static final GlobalKey<ScaffoldState> scaffoldKey =
      GlobalKey<ScaffoldState>();

  CheckoutPage(
      {super.key,
      required this.cart,
      required this.applePayEnabled,
      required this.googlePayEnabled,
      required this.orderAmount,
      required this.tipAmount,
      required this.account});

  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String? selectedPaymentMethod;
  bool isDateTimeSelected = false;
  final List<Map<String, dynamic>> paymentMethods = [
    {
      'name': 'Credit/Debit Card',
      'type': 'text',
      'icon': null
    }, // No icon for card
    {
      'name': 'Apple Pay',
      'type': 'icon',
      'icon': 'assets/images/applePayBlack.png'
    },
    {
      'name': 'Google Pay',
      'type': 'icon',
      'icon': 'assets/images/googlePayBlack.png'
    },
  ];

  bool get _chargeServerHostReplaced => chargeServerHost != "REPLACE_ME";
  ApplePayStatus _applePayStatus = ApplePayStatus.unknown;

  Map<String, String> orderIds = {
    'orderId': '',
    'fulfillmentUid': '',
  };
  String userInputAccount = '';

  final Map<String, List<String>> storePickupHours = {
    // Square has no api call to fetch hours, so needed manually
    'Monday': [],
    'Tuesday': ['06:10AM', '11:55AM'],
    'Wednesday': ['06:10AM', '11:55AM'],
    'Thursday': ['06:10AM', '11:55AM'],
    'Friday': ['06:10AM', '11:55AM'],
    'Saturday': ['09:10AM', '12:55PM'],
    'Sunday': [],
  }.map((day, times) {
    return MapEntry(
      day,
      times.map<String>((time) {
        return time
            .replaceAll(RegExp(r'\s+'), '')
            .replaceAll(RegExp(r'[^\x00-\x7F]+'), '')
            .trim();
      }).toList(),
    );
  });

  DateTime selectedDate = DateTime.now();
  String? selectedTimeSlot;
  List<DateTime> availableDates = [];
  List<String> timeSlots = [];
  String? selectedDayLabel;

  @override
  void initState() {
    super.initState();
    _initializeAvailableDates();
    _updateTimeSlotsForDate(selectedDate);
  }

  void _onDateTimeSelectionChanged() {
    setState(() {
      isDateTimeSelected = selectedTimeSlot != null;
    });
  }

  // Square requires specific time format when sending order fulfillments
  Future<String> formatToRFC3339(DateTime date, String timeSlot) async {
    try {
      // extract the period (AM/PM)
      final period = timeSlot.substring(timeSlot.length - 2).toUpperCase();

      // extract the hour and minute part from the time string
      final hourMinute =
          timeSlot.substring(0, timeSlot.length - 6); // Extracts the hour part
      final minute = int.parse(
          timeSlot.substring(timeSlot.length - 5, timeSlot.length - 3));

      // handle both single and double digit hours
      final hour = int.tryParse(hourMinute) ?? 0;

      // adjust the hour based on AM/PM
      int correctedHour = hour;
      if (period == 'PM' && hour != 12) {
        correctedHour += 12; // Add 12 hours for PM (except for 12 PM)
      } else if (period == 'AM' && hour == 12) {
        correctedHour = 0; // 12 AM is midnight, so set hour to 0
      }

      // combine to create date
      final combinedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        correctedHour,
        minute,
      );

      // get central time (shops location)
      final centralTimeZone = tz.getLocation('America/Chicago');

      // create a TZDateTime for central (used because times displayed in app represent central time, but flutter
      // DateTime uses device local time zone, extra precaution to avoid time miscalculations)
      final centralTime = tz.TZDateTime(
          centralTimeZone,
          combinedDateTime.year,
          combinedDateTime.month,
          combinedDateTime.day,
          combinedDateTime.hour,
          combinedDateTime.minute);

      // convert cental to UTC
      final utcTime = centralTime.toUtc();

      // convert to Iso8601 first as theres no RFC conversion method, manually regEx
      final rfc3339String = utcTime.toIso8601String().replaceFirstMapped(
            RegExp(r'(\.\d+)?Z?$'),
            (match) =>
                'Z', // regex for Iso to RFC, generally identical, but extra precaution
          );
      return rfc3339String;
    } catch (e) {
      print('Error parsing time slot: $e');
      return ''; // Return empty string in case of error
    }
  }

  // get dates available to place order
  void _initializeAvailableDates() {
    for (int i = 0; i < 7; i++) {
      availableDates.add(DateTime.now().add(Duration(days: i)));
    }
  }

  // get time slots for available days
  void _updateTimeSlotsForDate(DateTime date) {
    final dayOfWeek = DateFormat.EEEE().format(date);
    if (storePickupHours[dayOfWeek]!.isEmpty) {
      timeSlots = [];
    } else {
      final openTime = storePickupHours[dayOfWeek]![0];
      final closeTime = storePickupHours[dayOfWeek]![1];
      timeSlots = generateTimeSlots(openTime, closeTime);
    }
    setState(() {});
  }

  // TODO
  // supposed to remove slots that already have a certain amount of orders in a certain span
  // to avoid overloading shop, currently putting on hold for later
  // jm also doesnt work for how i have times setup anyway, so gonna need whole refactor
  Future<List<String>> getUnavailableSlots(DateTime date) async {
    final activeOrders = await fetchActiveOrders(date);
    final unavailableSlots = <String>[];

    for (var order in activeOrders) {
      final pickupTime = DateFormat.jm().parse(order.pickupTime);
      final timeSlotStart = pickupTime.subtract(const Duration(minutes: 5));
      final timeSlotEnd = pickupTime.add(const Duration(minutes: 15));

      for (var slot in timeSlots) {
        final slotTime = DateFormat.jm().parse(slot);
        if (slotTime.isAfter(timeSlotStart) && slotTime.isBefore(timeSlotEnd)) {
          unavailableSlots.add(slot);
        }
      }
    }

    return unavailableSlots;
  }

  // generate the time slots for the days
  List<String> generateTimeSlots(String openTime, String closeTime,
      {int intervalMinutes = 5}) {
    List<String> slots = [];
    try {
      openTime = openTime.replaceAll(RegExp(r'[\u202F\u00A0\s]+'), ' ').trim();
      closeTime =
          closeTime.replaceAll(RegExp(r'[\u202F\u00A0\s]+'), ' ').trim();

      DateTime? startTime = _parseTime(openTime);
      DateTime? endTime = _parseTime(closeTime);

      if (startTime == null || endTime == null) {
        return [];
      }

      while (startTime!.isBefore(endTime)) {
        slots.add(_formatTime(startTime));
        startTime = startTime.add(Duration(minutes: intervalMinutes));
      }
    } catch (e) {
      print('Error parsing time: $e');
    }
    return slots;
  }

  // manually parse time because jm dont work for this
  DateTime? _parseTime(String time) {
    try {
      final period = time.substring(time.length - 2);
      final hour = int.parse(time.substring(0, 2));
      final minute = int.parse(time.substring(3, 5));

      int correctedHour = hour;
      if (period == 'PM' && hour != 12) {
        correctedHour += 12;
      } else if (period == 'AM' && hour == 12) {
        correctedHour = 0;
      }

      return DateTime(2000, 1, 1, correctedHour, minute);
    } catch (e) {
      print('Error parsing individual time: $e');
      return null;
    }
  }

  // manually format time because jm dont work for this
  String _formatTime(DateTime time) {
    final hour = time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '${hour == 0 ? 12 : hour}:$minute $period';
  }

  // TODO
  // need to create an api request to get active orders for the shop to be used in
  // other todo above to not overload shop
  Future<List<Order>> fetchActiveOrders(DateTime date) async {
    return [
      Order(pickupTime: '10:15 AM'),
      Order(pickupTime: '10:20 AM'),
      Order(pickupTime: '10:25 AM'),
    ];
  }

  // TODO make theme of alert dialog match app, currently uses flutter default colors/look
  // show alerts if needed (Square uses something like this in example but doesnt provide code for it
  // but example code references it a lot)
  void showAlertDialog(
      {required BuildContext context,
      required String title,
      required String description,
      required bool status}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(description),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // handle payments
  void _handlePayment() async {
    if (!isDateTimeSelected &&
        (widget.account != null || userInputAccount != '')) {
      // if date or time is not selected, show an alert
      showAlertDialog(
        context: CheckoutPage.scaffoldKey.currentContext!,
        title: "Date and Time Required",
        description: "Please select a pickup date and time before proceeding.",
        status: false,
      );
      return;
    }

    final pickupDateTimeRFC =
        await formatToRFC3339(selectedDate, selectedTimeSlot!);

    if (widget.account == null) {
      // if guest logged in
      orderIds = await SquareAPI().createOrder(
          cart: widget.cart,
          pickupTime: pickupDateTimeRFC,
          name: userInputAccount);
    } else {
      // customer is logged in
      orderIds = await SquareAPI().createOrder(
          cart: widget.cart,
          pickupTime: pickupDateTimeRFC,
          customerId: widget.account!.customerId);
    }

    if (selectedPaymentMethod == 'Credit/Debit Card') {
      await _onStartCardEntryFlow();
    } else if (selectedPaymentMethod == 'Apple Pay' && widget.applePayEnabled) {
      _onStartApplePay();
    } else if (selectedPaymentMethod == 'Google Pay' &&
        widget.googlePayEnabled) {
      _onStartGooglePay();
    }
  }

  // MOST CODE BELOW UNTIL BUILD IS SQUARE PROVIDED CODE FOR PAYMENT PROCESSING, HARDLY CHANGED
  // ONLY NOTICIBLE CHANGE IS CHARGECARD UTILIZES CURL AND NOT THIRD PARTY SERVICE HOSTING
  void _onCardEntryComplete() {
    if (_chargeServerHostReplaced) {
      showAlertDialog(
          context: CheckoutPage.scaffoldKey.currentContext!,
          title: "Congratulation,Your order was successful",
          description:
              "Go to your Square dashboard to see this order reflected in the sales tab.",
          status: true);
    }
  }

  void _onCardEntryCardNonceRequestSuccess(CardDetails result) async {
    try {
      var uuid = const Uuid().v4();
      await SquareAPI()
          .chargeCard(result.nonce, widget.orderAmount, widget.tipAmount, uuid);
      InAppPayments.completeCardEntry(
          onCardEntryComplete: _onCardEntryComplete);
    } on ChargeException catch (ex) {
      InAppPayments.showCardNonceProcessingError(ex.errorMessage);
    }
  }

  Future<void> _onStartCardEntryFlow() async {
    await InAppPayments.startCardEntryFlow(
        onCardNonceRequestSuccess: _onCardEntryCardNonceRequestSuccess,
        onCardEntryCancel: _onCancelCardEntryFlow,
        collectPostalCode: true);
  }

  Future<void> _onStartGiftCardEntryFlow() async {
    await InAppPayments.startGiftCardEntryFlow(
        onCardNonceRequestSuccess: _onCardEntryCardNonceRequestSuccess,
        onCardEntryCancel: _onCancelCardEntryFlow);
  }

  Future<void> _onStartCardEntryFlowWithBuyerVerification() async {
    var money = Money((b) => b
      ..amount = 100
      ..currencyCode = 'USD');

    var contact = Contact((b) => b
      ..givenName = "John"
      ..familyName = "Doe"
      ..addressLines =
          BuiltList<String>(["London Eye", "Riverside Walk"]).toBuilder()
      ..city = "London"
      ..countryCode = "GB"
      ..email = "johndoe@example.com"
      ..phone = "8001234567"
      ..postalCode = "SE1 7");

    await InAppPayments.startCardEntryFlowWithBuyerVerification(
        onBuyerVerificationSuccess: _onBuyerVerificationSuccess,
        onBuyerVerificationFailure: _onBuyerVerificationFailure,
        onCardEntryCancel: _onCancelCardEntryFlow,
        buyerAction: "Charge",
        money: money,
        squareLocationId: dotenv.env['PROD_MAIN_LOC_ID']!,
        contact: contact,
        collectPostalCode: true);
  }

  Future<void> _onStartBuyerVerificationFlow() async {
    var money = Money((b) => b
      ..amount = 100
      ..currencyCode = 'USD');

    var contact = Contact((b) => b
      ..givenName = "John"
      ..familyName = "Doe"
      ..addressLines =
          BuiltList<String>(["London Eye", "Riverside Walk"]).toBuilder()
      ..city = "London"
      ..countryCode = "GB"
      ..email = "johndoe@example.com"
      ..phone = "8001234567"
      ..postalCode = "SE1 7");

    await InAppPayments.startBuyerVerificationFlow(
        onBuyerVerificationSuccess: _onBuyerVerificationSuccess,
        onBuyerVerificationFailure: _onBuyerVerificationFailure,
        buyerAction: "Charge",
        money: money,
        squareLocationId: dotenv.env['PROD_MAIN_LOC_ID']!,
        contact: contact,
        paymentSourceId: "REPLACE_WITH_PAYMENT_SOURCE_ID");
  }

  Future<void> _onCancelCardEntryFlow() async {
    await SquareAPI().cancelOrder(
        orderId: orderIds['orderId']!,
        fulfillmentId: orderIds['fulfillmentUid']!);
  }

  void _onStartGooglePay() async {
    try {
      await InAppPayments.requestGooglePayNonce(
          priceStatus: google_pay_constants.totalPriceStatusFinal,
          price: (widget.orderAmount + widget.tipAmount).toStringAsFixed(2),
          currencyCode: 'USD',
          onGooglePayNonceRequestSuccess: _onGooglePayNonceRequestSuccess,
          onGooglePayNonceRequestFailure: _onGooglePayNonceRequestFailure,
          onGooglePayCanceled: onGooglePayEntryCanceled);
    } on PlatformException catch (ex) {
      showAlertDialog(
          context: CheckoutPage.scaffoldKey.currentContext!,
          title: "Failed to start GooglePay",
          description: ex.toString(),
          status: false);
    }
  }

  void _onGooglePayNonceRequestSuccess(CardDetails result) async {
    try {
      var uuid = const Uuid().v4();
      await SquareAPI()
          .chargeCard(result.nonce, widget.orderAmount, widget.tipAmount, uuid);
      showAlertDialog(
          context: CheckoutPage.scaffoldKey.currentContext!,
          title: "Congratulation,Your order was successful",
          description: "Go to your recent orders to see order ID.",
          status: true);
    } on ChargeException catch (ex) {
      showAlertDialog(
          context: CheckoutPage.scaffoldKey.currentContext!,
          title: "Error processing GooglePay payment",
          description: ex.errorMessage,
          status: false);
    }
  }

  Future<void> _onGooglePayNonceRequestFailure(ErrorInfo errorInfo) async {
    await SquareAPI().cancelOrder(
        orderId: orderIds['orderId']!,
        fulfillmentId: orderIds['fulfillmentUid']!);
    showAlertDialog(
        context: CheckoutPage.scaffoldKey.currentContext!,
        title: "Failed to request GooglePay nonce",
        description: errorInfo.toString(),
        status: false);
  }

  Future<void> onGooglePayEntryCanceled() async {
    await SquareAPI().cancelOrder(
        orderId: orderIds['orderId']!,
        fulfillmentId: orderIds['fulfillmentUid']!);
  }

  void _onStartApplePay() async {
    try {
      await InAppPayments.requestApplePayNonce(
          price: (widget.orderAmount + widget.tipAmount).toStringAsFixed(2),
          summaryLabel: 'Eagles Brew',
          countryCode: 'US',
          currencyCode: 'USD',
          paymentType: ApplePayPaymentType.finalPayment,
          onApplePayNonceRequestSuccess: _onApplePayNonceRequestSuccess,
          onApplePayNonceRequestFailure: _onApplePayNonceRequestFailure,
          onApplePayComplete: _onApplePayEntryComplete);
    } on PlatformException catch (ex) {
      showAlertDialog(
          context: CheckoutPage.scaffoldKey.currentContext!,
          title: "Failed to start ApplePay",
          description: ex.toString(),
          status: false);
    }
  }

  void _onBuyerVerificationSuccess(BuyerVerificationDetails result) async {
    try {
      await chargeCardAfterBuyerVerification(result.nonce, result.token);
    } on ChargeException catch (ex) {
      await SquareAPI().cancelOrder(
          orderId: orderIds['orderId']!,
          fulfillmentId: orderIds['fulfillmentUid']!);
      showAlertDialog(
          context: CheckoutPage.scaffoldKey.currentContext!,
          title: "Error processing card payment",
          description: ex.errorMessage,
          status: false);
    }
  }

  void _onApplePayNonceRequestSuccess(CardDetails result) async {
    try {
      var uuid = const Uuid().v4();
      await SquareAPI()
          .chargeCard(result.nonce, widget.orderAmount, widget.tipAmount, uuid);
      _applePayStatus = ApplePayStatus.success;
      showAlertDialog(
          context: CheckoutPage.scaffoldKey.currentContext!,
          title: "Congratulation,Your order was successful",
          description: "Go to your recent orders to see order ID.",
          status: true);
      await InAppPayments.completeApplePayAuthorization(isSuccess: true);
    } on ChargeException catch (ex) {
      await InAppPayments.completeApplePayAuthorization(
          isSuccess: false, errorMessage: ex.errorMessage);
      showAlertDialog(
          context: CheckoutPage.scaffoldKey.currentContext!,
          title: "Error processing ApplePay payment",
          description: ex.errorMessage,
          status: false);
      _applePayStatus = ApplePayStatus.fail;
    }
  }

  void _onApplePayNonceRequestFailure(ErrorInfo errorInfo) async {
    _applePayStatus = ApplePayStatus.fail;
    await SquareAPI().cancelOrder(
        orderId: orderIds['orderId']!,
        fulfillmentId: orderIds['fulfillmentUid']!);
    await InAppPayments.completeApplePayAuthorization(
        isSuccess: false, errorMessage: errorInfo.message);
    showAlertDialog(
        context: CheckoutPage.scaffoldKey.currentContext!,
        title: "Error request ApplePay nonce",
        description: errorInfo.toString(),
        status: false);
  }

  Future<void> _onApplePayEntryComplete() async {
    if (_applePayStatus == ApplePayStatus.unknown) {
      // the apple pay is canceled
      await SquareAPI().cancelOrder(
          orderId: orderIds['orderId']!,
          fulfillmentId: orderIds['fulfillmentUid']!);
    }
  }

  void _onBuyerVerificationFailure(ErrorInfo errorInfo) async {
    await SquareAPI().cancelOrder(
        orderId: orderIds['orderId']!,
        fulfillmentId: orderIds['fulfillmentId']!);
    showAlertDialog(
        context: CheckoutPage.scaffoldKey.currentContext!,
        title: "Error verifying buyer",
        description: errorInfo.toString(),
        status: false);
  }

  // Future<void> _onStartSecureRemoteCommerceFlow() async {
  //   await InAppPayments.startSecureRemoteCommerce(
  //       amount: 100,
  //       onMaterCardNonceRequestSuccess: _onMaterCardNonceRequestSuccess,
  //       onMasterCardNonceRequestFailure: _onMasterCardNonceRequestFailure);
  // }

  void _onMaterCardNonceRequestSuccess(CardDetails result) async {
    try {
      var uuid = const Uuid().v4();
      await SquareAPI()
          .chargeCard(result.nonce, widget.orderAmount, widget.tipAmount, uuid);
    } on ChargeException catch (ex) {
      showAlertDialog(
          context: CheckoutPage.scaffoldKey.currentContext!,
          title: "Error processing payment",
          description: ex.errorMessage,
          status: false);
    }
  }

  void _onMasterCardNonceRequestFailure(ErrorInfo errorInfo) async {
    showAlertDialog(
        context: CheckoutPage.scaffoldKey.currentContext!,
        title: "Error processing payment",
        description: errorInfo.toString(),
        status: false);
  }
  // END SQUARE CODE

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: CheckoutPage.scaffoldKey,
      appBar: AppBar(title: const Text('Checkout')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            if (widget.account == null) ...[
              // if guest logged in, need a name as recipient details for order is required by square
              const Text(
                'Enter Pickup Name',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter your account name',
                ),
                onChanged: (value) {
                  setState(() {
                    userInputAccount = value;
                  });
                },
              ),
              const SizedBox(height: 16),
            ],
            const Text('Select Pickup Date', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: availableDates.map((date) {
                  String label = DateFormat('EEE MMM d').format(date);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: selectedDayLabel == label,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            selectedDate = date;
                            selectedDayLabel = label;
                            selectedTimeSlot = null;
                            _updateTimeSlotsForDate(date);
                            _onDateTimeSelectionChanged();
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Select Pickup Time', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            timeSlots.isNotEmpty
                ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: timeSlots.map((slot) {
                        return ChoiceChip(
                          label: Text(slot),
                          selected: selectedTimeSlot == slot,
                          onSelected: (selected) {
                            setState(() {
                              selectedTimeSlot = selected ? slot : null;
                              _onDateTimeSelectionChanged();
                            });
                          },
                        );
                      }).toList(),
                    ),
                  )
                : const Text('No available time slots for the selected day.'),
            const SizedBox(height: 16),
            const Text('Select Payment Method', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Column(
              children: paymentMethods.map((method) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: method['type'] == 'icon'
                        ? ElevatedButton(
                            onPressed: () {
                              setState(() {
                                selectedPaymentMethod = method['name'];
                                _handlePayment();
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 0.0),
                            ),
                            child: Container(
                              width: double.infinity,
                              height: 50,
                              child: Image.asset(
                                method['icon'],
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        : TextButton(
                            onPressed: () {
                              setState(() {
                                selectedPaymentMethod = method['name'];
                                _handlePayment();
                              });
                            },
                            style: TextButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              backgroundColor:
                                  const Color.fromARGB(255, 255, 153, 7),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16.0), // Button height
                            ),
                            child: Text(
                              method['name'],
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                  ),
                );
              }).toList(),
            ),
            const Spacer(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Add functionality (if needed, wont know until i send actual payments, might just automatically navigate back to home after payment)
                },
                child: Text(
                  'COMPLETE ORDER',
                  style: GoogleFonts.poppins(
                    color: const Color.fromARGB(255, 255, 153, 7),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Order {
  // wont be needed once i setup api call for active orders for methods at beginning
  final String pickupTime;

  Order({required this.pickupTime});
}
