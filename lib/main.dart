/****************************************************************************************************
 *
 * @file:    main.dart
 * @author:  Nolan Olhausen
 * @date: 2024-11-15
 *
 * @brief:
 *      This file is the main entry point for the application. It initializes the app and sets up
 *      the theme manager and the main scaffold. The main scaffold is the main UI for the app and
 *      contains the bottom navigation bar and the main content area. The main content area is
 *      determined by the current index of the bottom navigation bar.
 * 
 ****************************************************************************************************/

import 'package:flutter/material.dart';
import 'package:mobile_app/pages/cart.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:mobile_app/pages/onboard.dart';
import 'package:mobile_app/pages/store_location.dart';
import 'package:mobile_app/pages/rewards.dart';
import 'package:mobile_app/theme/theme_manager.dart';
import 'package:mobile_app/theme/themes.dart';
import 'package:provider/provider.dart';
import 'pages/extra.dart';
import 'pages/menu.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'cards/product_card.dart';
import 'pages/account.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:square_in_app_payments/google_pay_constants.dart'
    as google_pay_constants;
import 'package:square_in_app_payments/in_app_payments.dart';
import 'package:square_in_app_payments/models.dart';
import 'utility/squareAPI.dart';

int scaffoldIndex = 0; // Index for the scaffold navigation

List<String> carouselImages = [
  'assets/images/327x140.png'
]; // List of carousel images

void main() async {
  await dotenv.load(); // Load environment variables
  tz.initializeTimeZones(); // Initialize time zones
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeManager(), // Provide ThemeManager
      child: const MyApp(), // Run the MyApp widget
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isLoading = true; // Loading state
  bool showSplash = true; // Splash screen state
  List<Item> products = []; // List of products
  List<CartItem> cart = []; // List of cart items
  List<RewardProgram> programs = []; // List of reward programs
  LoyaltyAccount? account; // Loyalty account
  bool applePayEnabled = false; // Apple Pay enabled state
  bool googlePayEnabled = false; // Google Pay enabled state
  String errorMessage = ''; // Error message

  @override
  void initState() {
    super.initState();
    _loadResources(); // Load resources
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        showSplash = false; // Hide splash screen after 3 seconds
      });
    });
  }

  Future<void> _loadResources() async {
    try {
      await Future.wait([
        _initSquarePayment(), // Initialize Square payment
        _loadProducts(), // Load products
        _loadLoyaltyProgram(), // Load loyalty program
      ]);
    } catch (e) {
      setState(() {
        errorMessage = "Error loading resources: $e"; // Set error message
      });
    } finally {
      setState(() {
        isLoading = false; // Set loading state to false
      });
    }
  }

  Future<void> _loadProducts() async {
    try {
      final fetchedProducts = await SquareAPI()
          .fetchOnlineAvailabeAndRelated(); // Fetch products from API
      setState(() {
        products = fetchedProducts; // Set products
      });
    } catch (e) {
      setState(() {
        errorMessage = "Failed to load products: $e"; // Set error message
      });
    }
  }

  Future<void> _loadLoyaltyProgram() async {
    try {
      final fetchedPrograms = await SquareAPI()
          .fetchRewardProgram(); // Fetch reward programs from API
      setState(() {
        programs = fetchedPrograms; // Set reward programs
      });
    } catch (e) {
      setState(() {
        errorMessage = "Failed to load programs: $e"; // Set error message
      });
    }
  }

  Future<void> _initSquarePayment() async {
    await InAppPayments.setSquareApplicationId(
        dotenv.env['PROD_APP_ID']!); // Set Square application ID

    var canUseApplePay = false;
    var canUseGooglePay = false;
    if (Platform.isAndroid) {
      await InAppPayments.initializeGooglePay(dotenv.env['PROD_MAIN_LOC_ID']!,
          google_pay_constants.environmentTest); // Initialize Google Pay
      canUseGooglePay = await InAppPayments
          .canUseGooglePay; // Check if Google Pay can be used
    } else if (Platform.isIOS) {
      await _setIOSCardEntryTheme(); // Set iOS card entry theme
      await InAppPayments.initializeApplePay(
          dotenv.env['APPLE_PAY_MERCH_ID']!); // Initialize Apple Pay
      canUseApplePay =
          await InAppPayments.canUseApplePay; // Check if Apple Pay can be used
    }

    setState(() {
      applePayEnabled = canUseApplePay; // Set Apple Pay enabled state
      googlePayEnabled = canUseGooglePay; // Set Google Pay enabled state
    });
  }

  Future _setIOSCardEntryTheme() async {
    var themeConfiguationBuilder =
        IOSThemeBuilder(); // Create iOS theme builder
    themeConfiguationBuilder.saveButtonTitle = 'Pay'; // Set save button title
    themeConfiguationBuilder.errorColor = RGBAColorBuilder()
      ..r = 255
      ..g = 0
      ..b = 0; // Set error color
    themeConfiguationBuilder.tintColor = RGBAColorBuilder()
      ..r = 36
      ..g = 152
      ..b = 141; // Set tint color
    themeConfiguationBuilder.keyboardAppearance =
        KeyboardAppearance.light; // Set keyboard appearance
    themeConfiguationBuilder.messageColor = RGBAColorBuilder()
      ..r = 114
      ..g = 114
      ..b = 114; // Set message color

    await InAppPayments.setIOSCardEntryTheme(
        themeConfiguationBuilder.build()); // Set iOS card entry theme
  }

  @override
  Widget build(BuildContext context) {
    final themeManager =
        Provider.of<ThemeManager>(context); // Get theme manager
    if (showSplash || isLoading) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                    'assets/images/updatedSplash.png'), // Splash screen image
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      );
    }
    return MaterialApp(
      title: 'Eagles Brew',
      theme: lightTheme, // Light theme
      darkTheme: darkTheme, // Dark theme
      themeMode: themeManager.themeMode, // Theme mode
      home: Scaffold(
        body: OnboardingPage(
          products: products, // Pass products to OnboardingPage
          programs: programs, // Pass programs to OnboardingPage
          applePayEnabled:
              applePayEnabled, // Pass Apple Pay enabled state to OnboardingPage
          googlePayEnabled:
              googlePayEnabled, // Pass Google Pay enabled state to OnboardingPage
        ),
      ),
      routes: {
        '/rewards': (context) => MainScaffold(
              title: 'Rewards',
              products: products,
              programs: programs,
              account: account,
              applePayEnabled: applePayEnabled,
              googlePayEnabled: googlePayEnabled,
              cart: cart,
              child: RewardsPage(
                  programs: programs,
                  account: account,
                  cart: cart), // Rewards page route
            ),
        '/menu': (context) => MainScaffold(
              title: 'Menu',
              products: products,
              programs: programs,
              account: account,
              applePayEnabled: applePayEnabled,
              googlePayEnabled: googlePayEnabled,
              cart: cart,
              child: MenuPage(
                account: account,
                products: products,
                cart: cart,
                applePayEnabled: applePayEnabled,
                googlePayEnabled: googlePayEnabled,
              ), // Menu page route
            ),
        '/store': (context) => MainScaffold(
              title: 'Store',
              products: products,
              programs: programs,
              account: account,
              applePayEnabled: applePayEnabled,
              googlePayEnabled: googlePayEnabled,
              cart: cart,
              child: const LocationPage(
                storeLocation: LatLng(37.338360, -94.298150),
                address: '315 N 4th St, Jasper, MO 64755',
              ), // Store page route
            ),
        '/extras': (context) => MainScaffold(
              title: 'Extras',
              products: products,
              programs: programs,
              account: account,
              applePayEnabled: applePayEnabled,
              googlePayEnabled: googlePayEnabled,
              cart: cart,
              child: ExtrasPage(
                products: products,
                programs: programs,
                cart: cart,
                applePayEnabled: applePayEnabled,
                googlePayEnabled: googlePayEnabled,
              ), // Extras page route
            ),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  final List<Item> products; // List of products
  List<CartItem> cart; // List of cart items
  final List<RewardProgram> programs; // List of reward programs
  final LoyaltyAccount? account; // Loyalty account
  MyHomePage(
      {super.key,
      required this.cart,
      required this.products,
      required this.programs,
      required this.account});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 50), // Spacer
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Eagles Brew",
                    style: GoogleFonts.poppins(
                      color: const Color.fromARGB(255, 255, 153, 7),
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  IconButton(
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
                      icon: (SvgPicture.asset('assets/icons/userIcon.svg',
                          height: 36,
                          width: 36,
                          color: const Color.fromARGB(
                              255, 255, 153, 7)))) // User icon button
                ],
              ),
              const SizedBox(height: 25), // Spacer
              CarouselSlider(
                options: CarouselOptions(
                  height: 140.0,
                  autoPlay: true,
                  enableInfiniteScroll: false,
                  autoPlayInterval: const Duration(seconds: 10),
                  enlargeCenterPage: true,
                  enlargeFactor: 0.3,
                ),
                items: [1, 2, 3, 4, 5].map((i) {
                  return Builder(
                    builder: (BuildContext context) {
                      return Container(
                        width: 327,
                        height: 140,
                        clipBehavior: Clip.antiAlias,
                        decoration: ShapeDecoration(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Container(
                          width: 327,
                          height: 140,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage(
                                  carouselImages[0]), // Carousel image
                              fit: BoxFit.fill,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16.0, horizontal: 8.0),
                    child: Text(
                      "FEATURED ITEMS",
                      style: GoogleFonts.poppins(
                        color: const Color.fromARGB(255, 255, 153, 7),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    mainAxisExtent: 300,
                  ),
                  itemCount: widget.products
                      .where((product) => product.categories
                          .any((category) => category.name == 'Seasonal'))
                      .toList()
                      .length, // Count of seasonal products
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    final seasonalProducts = widget.products
                        .where((product) => product.categories
                            .any((category) => category.name == 'Seasonal'))
                        .toList(); // Filter seasonal products

                    final product = seasonalProducts[index];
                    return ProductCard(
                      product: product,
                      cart: widget.cart,
                    ); // Product card
                  },
                ),
              )
            ],
          )),
    );
  }
}

class MainScaffold extends StatefulWidget {
  final Widget child; // Child widget
  final String title; // Title
  final List<Item> products; // List of products
  List<CartItem> cart; // List of cart items
  final List<RewardProgram> programs; // List of reward programs
  final LoyaltyAccount? account; // Loyalty account
  final bool applePayEnabled; // Apple Pay enabled state
  final bool googlePayEnabled; // Google Pay enabled state

  MainScaffold({
    super.key,
    required this.child,
    required this.cart,
    required this.title,
    required this.products,
    required this.programs,
    required this.account,
    required this.applePayEnabled,
    required this.googlePayEnabled,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    switch (scaffoldIndex) {
      case 0:
        child = MyHomePage(
            products: widget.products,
            programs: widget.programs,
            account: widget.account,
            cart: widget.cart); // Home page
        break;
      case 1:
        child = RewardsPage(
          programs: widget.programs,
          account: widget.account,
          cart: widget.cart,
        ); // Rewards page
        break;
      case 2:
        child = MenuPage(
          account: widget.account,
          products: widget.products,
          cart: widget.cart,
          applePayEnabled: widget.applePayEnabled,
          googlePayEnabled: widget.googlePayEnabled,
        ); // Menu page
        break;
      case 3:
        child = const LocationPage(
          storeLocation: LatLng(37.338360, -94.298150),
          address: '315 N 4th St, Jasper, MO 64755',
        ); // Store location page
        break;
      case 4:
        child = ExtrasPage(
          products: widget.products,
          programs: widget.programs,
          cart: widget.cart,
          applePayEnabled: widget.applePayEnabled,
          googlePayEnabled: widget.googlePayEnabled,
        ); // Extras page
        break;
      default:
        child = MyHomePage(
            products: widget.products,
            programs: widget.programs,
            account: widget.account,
            cart: widget.cart); // Default to home page
    }
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: (SvgPicture.asset('assets/icons/home-05.svg',
                height: 26,
                width: 26,
                color: const Color.fromARGB(255, 255, 153, 7))),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: (SvgPicture.asset('assets/icons/gift-01.svg',
                height: 26,
                width: 26,
                color: const Color.fromARGB(255, 255, 153, 7))),
            label: 'Rewards',
          ),
          BottomNavigationBarItem(
            icon: (SvgPicture.asset('assets/icons/coffee.svg',
                height: 26,
                width: 26,
                color: const Color.fromARGB(255, 255, 153, 7))),
            label: 'Order',
          ),
          BottomNavigationBarItem(
            icon: (SvgPicture.asset('assets/icons/marker-02.svg',
                height: 26,
                width: 26,
                color: const Color.fromARGB(255, 255, 153, 7))),
            label: 'Store',
          ),
          BottomNavigationBarItem(
            icon: (SvgPicture.asset('assets/icons/menu-01.svg',
                height: 26,
                width: 26,
                color: const Color.fromARGB(255, 255, 153, 7))),
            label: 'More',
          ),
        ],
        selectedItemColor: const Color.fromARGB(255, 255, 153, 7),
        unselectedItemColor: const Color.fromARGB(255, 255, 153, 7),
        selectedLabelStyle: GoogleFonts.poppins(
          color: const Color.fromARGB(255, 255, 153, 7),
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          color: const Color.fromARGB(255, 255, 153, 7),
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
        onTap: (index) {
          setState(() {
            scaffoldIndex = index; // Update scaffold index on tap
          });
        },
      ),
    );
  }
}
