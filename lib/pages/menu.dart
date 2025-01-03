/****************************************************************************************************
 *
 * @file:    menu.dart
 * @author:  Nolan Olhausen
 * @date: 2024-11-15
 *
 * @brief:
 *      This file contains the MenuPage class, which is a StatefulWidget that displays the menu
 *      of products available for purchase. The menu can be filtered by category and subcategory,
 *      and searched by name or description. The user can add products to their cart by clicking
 *      on the product card. The user can also navigate to the cart page by clicking on the cart icon.
 * 
 ****************************************************************************************************/

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../cards/product_card.dart';
import 'cart.dart';
import '../utility/squareAPI.dart';

class MenuPage extends StatefulWidget {
  final List<Item> products;
  List<CartItem> cart;
  final bool applePayEnabled;
  final bool googlePayEnabled;
  final LoyaltyAccount? account;

  MenuPage(
      {super.key,
      required this.cart,
      required this.products,
      required this.applePayEnabled,
      required this.googlePayEnabled,
      required this.account});
  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  String selectedMainFilter = 'All';
  String selectedSubFilter = '';
  String searchQuery = '';

  // main category filters
  final List<String> mainFilters = [
    'All',
    'Seasonal',
    'Coffee',
    'Blended',
    'Other Drinks',
    'Food'
  ];

  // sub category filters
  Map<String, List<String>> subFilters = {
    'Seasonal': [
      'All',
      'Latte',
      'Mocha',
      'Chai',
      'Coffee Frappe',
      'Cream Frappe'
    ],
    'Coffee': [
      'All',
      'Latte',
      'Mocha',
      'Macchiato',
      'Cappuccino',
      'Americano',
      'Cold Brew',
      'Espresso',
      'Drip Coffee'
    ],
    'Blended': ['All', 'Coffee Frappe', 'Cream Frappe', 'Smoothie'],
    'Other Drinks': ['All', 'Chai', 'Italian Soda', 'Energy Drink', 'Kids'],
    'Food': ['All', 'Sweet', 'Muffin', 'Pastry', 'Soup'],
  };

  @override
  Widget build(BuildContext context) {
    final filteredProducts = widget.products.where((product) {
      // check if the product categories contain the selectedMainFilter
      final matchesMainFilter = (selectedMainFilter == 'All') ||
          product.categories
              .any((category) => category.name == selectedMainFilter);

      // check if the product categories contain the selectedSubFilter
      final matchesSubFilter = (selectedMainFilter == 'All') ||
          product.categories
              .any((category) => category.name == selectedSubFilter) ||
          (product.categories
                  .any((category) => category.name == selectedMainFilter) &&
              selectedSubFilter == 'All');

      // check if the product matches the search query
      final matchesSearchQuery = product.description!
              .toLowerCase()
              .contains(searchQuery.toLowerCase()) ||
          product.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          product.categories.any((category) =>
              category.name.toLowerCase().contains(searchQuery.toLowerCase()));

      return matchesMainFilter && matchesSubFilter && matchesSearchQuery;
    }).toList();
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 50),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Menu",
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
                          builder: (context) => CartPage(
                            account: widget.account,
                            products: widget.cart,
                            applePayEnabled: widget.applePayEnabled,
                            googlePayEnabled: widget.googlePayEnabled,
                          ),
                        ),
                      );
                    },
                    icon: (SvgPicture.asset('assets/icons/cart.svg',
                        height: 36,
                        width: 36,
                        color: const Color.fromARGB(255, 255, 153, 7))))
              ],
            ),
            TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 8),
            Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: mainFilters.map((filter) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ChoiceChip(
                        label: Text(filter),
                        selected: selectedMainFilter == filter,
                        onSelected: (selected) {
                          setState(() {
                            selectedMainFilter = filter;
                            if (filter == 'All') {
                              selectedSubFilter = '';
                            } else {
                              selectedSubFilter = subFilters[filter]!.first;
                            }
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            if (selectedMainFilter != 'All')
              Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: subFilters[selectedMainFilter]!.map((subFilter) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: ChoiceChip(
                          label: Text(subFilter),
                          selected: selectedSubFilter == subFilter,
                          onSelected: (selected) {
                            setState(() {
                              selectedSubFilter = subFilter;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
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
                itemCount: filteredProducts.length,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  final product = filteredProducts[index];
                  return ProductCard(
                    product: product,
                    cart: widget.cart,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
