/****************************************************************************************************
 *
 * @file:    extra.dart
 * @author:  Nolan Olhausen
 * @date: 2024-11-15
 *
 * @brief:
 *      This file contains the ExtrasPage widget, which is a stateless widget that displays
 *      a list of buttons that navigate to various pages in the app. The SettingsModal and
 *      ContactModal widgets are also defined in this file, which are stateful widgets that
 *      display modal sheets with contact information and settings options, respectively.
 * 
 ****************************************************************************************************/

import 'package:flutter/material.dart';
import 'package:mobile_app/pages/onboard.dart';
import 'package:mobile_app/pages/recent_orders.dart';
import 'package:mobile_app/theme/theme_manager.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'account.dart';
import 'cart.dart';
import '../utility/squareAPI.dart';

void _launchUrl(String url) async {
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}

class ExtrasPage extends StatelessWidget {
  final List<Item> products;
  List<CartItem> cart;
  final bool applePayEnabled;
  final bool googlePayEnabled;
  final List<RewardProgram> programs;
  ExtrasPage(
      {super.key,
      required this.programs,
      required this.cart,
      required this.products,
      required this.applePayEnabled,
      required this.googlePayEnabled});
  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 75),
              Image.asset(
                'assets/images/1.png',
                height: 125,
                fit: BoxFit.cover,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AccountPage(
                        userData: {
                          'firstName': 'John',
                          'lastName': 'Doe',
                          'email': 'john.doe@example.com',
                          'phoneNumber': '123-456-7890',
                          'birthday': 'August 16',
                        },
                      ),
                    ),
                  );
                },
                child: Text(
                  "ACCOUNT",
                  style: GoogleFonts.poppins(
                    color: const Color.fromARGB(255, 255, 153, 7),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const RecentOrdersPage(recentOrders: [
                        {
                          'orderId': 1,
                          'items': [
                            {
                              'imagePath': 'assets/images/60x60.png',
                              'name': 'Espresso'
                            },
                            {
                              'imagePath': 'assets/images/60x60.png',
                              'name': 'Latte'
                            },
                          ],
                        },
                        {
                          'orderId': 2,
                          'items': [
                            {
                              'imagePath': 'assets/images/60x60.png',
                              'name': 'Cappuccino'
                            },
                          ],
                        },
                        {
                          'orderId': 3,
                          'items': [
                            {
                              'imagePath': 'assets/images/60x60.png',
                              'name': 'Cold Brew'
                            },
                            {
                              'imagePath': 'assets/images/60x60.png',
                              'name': 'Mocha'
                            },
                            {
                              'imagePath': 'assets/images/60x60.png',
                              'name': 'Caramel Macchiato'
                            },
                          ],
                        },
                      ]),
                    ),
                  );
                },
                child: Text(
                  "RECENT ORDERS",
                  style: GoogleFonts.poppins(
                    color: const Color.fromARGB(255, 255, 153, 7),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO
                },
                child: Text(
                  "GIFT CARDS",
                  style: GoogleFonts.poppins(
                    color: const Color.fromARGB(255, 255, 153, 7),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  _showSettingsModal(context);
                },
                child: Text(
                  "SETTINGS",
                  style: GoogleFonts.poppins(
                    color: const Color.fromARGB(255, 255, 153, 7),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  _showContactModal(context);
                },
                child: Text(
                  "CONTACT US",
                  style: GoogleFonts.poppins(
                    color: const Color.fromARGB(255, 255, 153, 7),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Scaffold(
                        body: OnboardingPage(
                          products: products,
                          programs: programs,
                          applePayEnabled: applePayEnabled,
                          googlePayEnabled: googlePayEnabled,
                        ),
                      ),
                    ),
                  );
                },
                child: Text(
                  "LOG OUT",
                  style: GoogleFonts.poppins(
                    color: const Color.fromARGB(255, 255, 153, 7),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: SvgPicture.asset(
                        themeManager.getSVGIconPath('instagram', context),
                        height: 36,
                        width: 36,
                      ),
                      onPressed: () {
                        _launchUrl(
                            'https://www.instagram.com/eaglesbrewcoffeeshop?utm_source=ig_web_button_share_sheet&igsh=ZDNlZDc0MzIxNw==');
                      },
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: SvgPicture.asset(
                        themeManager.getSVGIconPath('facebook', context),
                        height: 36,
                        width: 36,
                      ),
                      onPressed: () {
                        _launchUrl('https://www.facebook.com/eaglesbrewcoffee');
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Version: X.X.X",
                style: GoogleFonts.poppins(
                  color: const Color.fromARGB(255, 255, 153, 7),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettingsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (BuildContext context) {
        return const SettingsModal();
      },
    );
  }

  void _showContactModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (BuildContext context) {
        return const ContactModal();
      },
    );
  }
}

class SettingsModal extends StatefulWidget {
  const SettingsModal({super.key});

  @override
  _SettingsModalState createState() => _SettingsModalState();
}

class ContactModal extends StatefulWidget {
  const ContactModal({super.key});

  @override
  _ContactModalState createState() => _ContactModalState();
}

class _SettingsModalState extends State<SettingsModal> {
  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Settings",
            style: GoogleFonts.poppins(
              color: const Color.fromARGB(255, 255, 153, 7),
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  color: const Color.fromARGB(
                      255, 255, 153, 7), // Color of the left divider
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 16.0, horizontal: 8.0), // Space around the text
                child: Text(
                  "Theme Settings",
                  style: GoogleFonts.poppins(
                    color: const Color.fromARGB(255, 255, 153, 7),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  color: const Color.fromARGB(
                      255, 255, 153, 7), // Color of the right divider
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Use System Theme",
                style: GoogleFonts.poppins(
                  color: const Color.fromARGB(255, 255, 153, 7),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Switch(
                value: themeManager.useSystemTheme,
                activeTrackColor: const Color.fromARGB(255, 255, 153, 7),
                onChanged: (value) {
                  setState(() {
                    themeManager.toggleSystemTheme(value);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Dark Theme",
                style: GoogleFonts.poppins(
                  color: const Color.fromARGB(255, 255, 153, 7),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Opacity(
                opacity: themeManager.useSystemTheme ? 0.5 : 1.0,
                child: Switch(
                  value: themeManager.themeMode == ThemeMode.dark,
                  activeTrackColor: const Color.fromARGB(255, 255, 153, 7),
                  onChanged: themeManager.useSystemTheme
                      ? null
                      : (value) {
                          themeManager.toggleTheme(value);
                        },
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  color: const Color.fromARGB(
                      255, 255, 153, 7), // Color of the left divider
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 16.0, horizontal: 8.0), // Space around the text
                child: Text(
                  "Notification Settings",
                  style: GoogleFonts.poppins(
                    color: const Color.fromARGB(255, 255, 153, 7),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  color: const Color.fromARGB(
                      255, 255, 153, 7), // Color of the right divider
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Push Notifications",
                style: GoogleFonts.poppins(
                  color: const Color.fromARGB(255, 255, 153, 7),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Switch(
                value: false,
                activeTrackColor: const Color.fromARGB(255, 255, 153, 7),
                onChanged: (value) {},
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _ContactModalState extends State<ContactModal> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Contact Us",
            style: GoogleFonts.poppins(
              color: const Color.fromARGB(255, 255, 153, 7),
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  color: const Color.fromARGB(255, 255, 153, 7),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                child: Text(
                  "Email",
                  style: GoogleFonts.poppins(
                    color: const Color.fromARGB(255, 255, 153, 7),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  color: const Color.fromARGB(255, 255, 153, 7),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Eaglesbrew22@gmail.com",
                style: GoogleFonts.poppins(
                  color: const Color.fromARGB(255, 255, 153, 7),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              IconButton(
                icon: SvgPicture.asset(
                  'assets/icons/email.svg',
                  height: 24,
                  width: 24,
                  color: const Color.fromARGB(255, 255, 153, 7),
                ),
                onPressed: () {
                  final Uri emailUri = Uri(
                    scheme: 'mailto',
                    path: 'Eaglesbrew22@gmail.com',
                  );

                  _launchUrl(emailUri.toString());
                },
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  color: const Color.fromARGB(
                      255, 255, 153, 7), // Color of the left divider
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 16.0, horizontal: 8.0), // Space around the text
                child: Text(
                  "Phone",
                  style: GoogleFonts.poppins(
                    color: const Color.fromARGB(255, 255, 153, 7),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  color: const Color.fromARGB(
                      255, 255, 153, 7), // Color of the right divider
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "+1 (417) 262-2101",
                style: GoogleFonts.poppins(
                  color: const Color.fromARGB(255, 255, 153, 7),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              IconButton(
                icon: SvgPicture.asset(
                  'assets/icons/phone-call-01.svg',
                  height: 24,
                  width: 24,
                  color: const Color.fromARGB(255, 255, 153, 7),
                ),
                onPressed: () {
                  _launchUrl('tel:+14172622101');
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
