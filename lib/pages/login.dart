/****************************************************************************************************
 *
 * @file:    login.dart
 * @author:  Nolan Olhausen
 * @date: 2024-11-15
 *
 * @brief:
 *      Page for logging in to the app.
 * 
 ****************************************************************************************************/

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utility/squareAPI.dart';
import 'signup.dart';
import '../main.dart';

class LoginPage extends StatefulWidget {
  final List<RewardProgram> programs;
  final List<Item> products;
  final bool applePayEnabled;
  final bool googlePayEnabled;
  const LoginPage(
      {super.key,
      required this.programs,
      required this.products,
      required this.applePayEnabled,
      required this.googlePayEnabled});
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Log In',
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
                  return null;
                },
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      String phoneNumber = '+1${_phoneController.text}';
                      List<LoyaltyAccount> users =
                          await SquareAPI().searchLoyaltyAccount(phoneNumber);
                      LoyaltyAccount user = users.first;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MainScaffold(
                            title: 'Home',
                            products: widget.products,
                            programs: widget.programs,
                            account: user,
                            applePayEnabled: widget.applePayEnabled,
                            googlePayEnabled: widget.googlePayEnabled,
                            cart: [],
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
                    'Log In',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SignupPage(
                        programs: widget.programs,
                        products: widget.products,
                        applePayEnabled: widget.applePayEnabled,
                        googlePayEnabled: widget.googlePayEnabled,
                      ), // Your signup page
                    ),
                  );
                },
                child: const Text(
                  'Don’t have an account? Sign Up',
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
