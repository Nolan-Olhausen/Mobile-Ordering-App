/****************************************************************************************************
 *
 * @file:    onboard.dart
 * @author:  Nolan Olhausen
 * @date: 2024-11-15
 *
 * @brief:
 *      Page for onboarding users to the app. Allows users to log in, sign up, or continue as a guest.
 * 
 ****************************************************************************************************/

import 'package:flutter/material.dart';
import '../main.dart';
import 'login.dart';
import 'signup.dart';
import '../utility/squareAPI.dart';

class OnboardingPage extends StatelessWidget {
  final List<Item> products;
  final List<RewardProgram> programs;
  final bool applePayEnabled;
  final bool googlePayEnabled;

  const OnboardingPage(
      {super.key,
      required this.programs,
      required this.products,
      required this.applePayEnabled,
      required this.googlePayEnabled});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/updatedSplash.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LoginPage(
                            programs: programs,
                            products: products,
                            applePayEnabled: applePayEnabled,
                            googlePayEnabled: googlePayEnabled,
                          ),
                        ),
                      );
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
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SignupPage(
                            programs: programs,
                            products: products,
                            applePayEnabled: applePayEnabled,
                            googlePayEnabled: googlePayEnabled,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[900],
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
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MainScaffold(
                          title: 'Home',
                          products: products,
                          programs: programs,
                          account: null,
                          cart: [],
                          applePayEnabled: applePayEnabled,
                          googlePayEnabled: googlePayEnabled,
                          child: MyHomePage(
                            products: products,
                            programs: programs,
                            account: null,
                            cart: [],
                          ),
                        ),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Continue as Guest',
                    style: TextStyle(fontSize: 18, color: Colors.orange),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
