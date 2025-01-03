/****************************************************************************************************
 *
 * @file:    account.dart
 * @author:  Nolan Olhausen
 * @date: 2024-11-15
 *
 * @brief:
 *      Page for displaying and editing user account details.
 * 
 ****************************************************************************************************/

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AccountPage extends StatefulWidget {
  final Map<String, String> userData;

  const AccountPage({super.key, required this.userData});

  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  // text input controllers
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController emailController;
  late TextEditingController phoneNumberController;
  late TextEditingController birthdayController;

  @override
  void initState() {
    super.initState();
    firstNameController =
        TextEditingController(text: widget.userData['firstName'] ?? '');
    lastNameController =
        TextEditingController(text: widget.userData['lastName'] ?? '');
    emailController =
        TextEditingController(text: widget.userData['email'] ?? '');
    phoneNumberController =
        TextEditingController(text: widget.userData['phoneNumber'] ?? '');
    birthdayController =
        TextEditingController(text: widget.userData['birthday'] ?? '');
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneNumberController.dispose();
    birthdayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Account Details',
          style: GoogleFonts.poppins(
            color: const Color.fromARGB(255, 255, 153, 7),
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'First Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Last Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: phoneNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.lock, color: Colors.grey),
                    ),
                    keyboardType: TextInputType.phone,
                    enabled: false,
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: birthdayController,
                    decoration: const InputDecoration(
                      labelText: 'Birthday',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.lock, color: Colors.grey),
                    ),
                    keyboardType: TextInputType.phone,
                    enabled: false,
                  ),
                  const SizedBox(height: 16.0),
                ],
              ),
            ),
          ),
          Container(
            // save button fixed to bottom
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                // TODO: Add save functionality
              },
              child: Text(
                'SAVE',
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
    );
  }
}
