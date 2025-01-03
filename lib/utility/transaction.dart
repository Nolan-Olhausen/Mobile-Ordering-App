import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:square_in_app_payments/models.dart';

// MOST OF THIS IS SQUARE PROVIDED CODE
// ONLY DIFFERENCE IS CHARGECARD ADJUSTED TO CURL COMMAND RATHER THAN THIRD PARTY HOST

String chargeServerHost = "REPLACE_ME";
Uri chargeUrl = Uri.parse("$chargeServerHost/chargeForCookie");

class ChargeException implements Exception {
  String errorMessage;
  ChargeException(this.errorMessage);
}

Future<void> chargeCard(CardDetails result) async {
  var body = jsonEncode({"nonce": result.nonce});
  http.Response response;
  try {
    response = await http.post(chargeUrl, body: body, headers: {
      "Accept": "application/json",
      "content-type": "application/json"
    });
  } on SocketException catch (ex) {
    throw ChargeException(ex.message);
  }

  var responseBody = json.decode(response.body);
  if (response.statusCode == 200) {
    return;
  } else {
    throw ChargeException(responseBody["errorMessage"]);
  }
}

Future<void> chargeCardAfterBuyerVerification(
    String nonce, String token) async {
  var body = jsonEncode({"nonce": nonce, "token": token});
  http.Response response;
  try {
    response = await http.post(chargeUrl, body: body, headers: {
      "Accept": "application/json",
      "content-type": "application/json"
    });
  } on SocketException catch (ex) {
    throw ChargeException(ex.message);
  }

  var responseBody = json.decode(response.body);
  if (response.statusCode == 200) {
    return;
  } else {
    throw ChargeException(responseBody["errorMessage"]);
  }
}
