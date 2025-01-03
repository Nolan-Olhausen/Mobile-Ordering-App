/****************************************************************************************************
 *
 * @file:    signup.dart
 * @author:  Nolan Olhausen
 * @date: 2024-11-15
 *
 * @brief:
 *      Page for signing up for a loyalty account.
 * 
 ****************************************************************************************************/

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utility/squareAPI.dart';
import 'login.dart';
import '../main.dart';

// Function to show a timed error dialog
void showTimedErrorDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      // Dialog content
      return AlertDialog(
        title: const Text("Error"),
        content: Text(message),
      );
    },
  );

  // Close the dialog after 3 seconds
  Timer(const Duration(seconds: 3), () {
    Navigator.of(context, rootNavigator: true).pop();
  });
}

// SignupPage widget
class SignupPage extends StatefulWidget {
  final List<Item> products; // List of products
  final List<RewardProgram> programs; // List of reward programs
  final bool applePayEnabled; // Apple Pay enabled state
  final bool googlePayEnabled; // Google Pay enabled state

  const SignupPage(
      {super.key,
      required this.programs,
      required this.products,
      required this.applePayEnabled,
      required this.googlePayEnabled});

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>(); // Form key for validation
  final TextEditingController _phoneController = TextEditingController(); // Controller for phone number input

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sign Up',
          style: GoogleFonts.poppins(
            color: const Color.fromARGB(255, 255, 153, 7),
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Phone number input field
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  prefixText: '+1 ',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  final phoneRegex = RegExp(r'^\d{10}$');
                  if (!phoneRegex.hasMatch(value)) {
                    return 'Please enter a valid phone number (10 digits)';
                  }
                  return null;
                },
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              // Sign up button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      String phoneNumber = '+1${_phoneController.text}';
                      LoyaltyAccount user = await SquareAPI()
                          .createLoyaltyAccount(
                              widget.programs.first.id, phoneNumber);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MainScaffold(
                            title: 'Home',
                            products: widget.products,
                            programs: widget.programs,
                            account: user,
                            cart: [],
                            applePayEnabled: widget.applePayEnabled,
                            googlePayEnabled: widget.googlePayEnabled,
                            child: MyHomePage(
                              products: widget.products,
                              programs: widget.programs,
                              account: user,
                              cart: [],
                            ),
                          ),
                        ),
                      );
                    } else {
                      showTimedErrorDialog(
                          context, "Error signing up. Please try again.");
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 255, 153, 7),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Navigate to login page
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoginPage(
                        programs: widget.programs,
                        products: widget.products,
                        applePayEnabled: widget.applePayEnabled,
                        googlePayEnabled: widget.googlePayEnabled,
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Already have an account? Log In',
                  style: TextStyle(color: Color.fromARGB(255, 255, 153, 7)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
