/****************************************************************************************************
 *
 * @file:    product_card.dart
 * @author:  Nolan Olhausen
 * @date: 2024-11-15
 *
 * @brief:
 *      Card for displaying product details.
 * 
 ****************************************************************************************************/

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app/pages/cart.dart';
import '../pages/product.dart';
import '../utility/squareAPI.dart';
import 'package:intl/intl.dart';

class ProductCard extends StatelessWidget {
  final Item product; // product to display
  List<CartItem> cart; // cart for passing between pages

  // constructor
  ProductCard({
    super.key,
    required this.product,
    required this.cart,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // on tap go to product page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductPage(
              product: product,
              cart: cart,
            ),
          ),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect( // product image
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(10),
                  ),
                  child: Image.network(
                    product.itemImage!.url,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 150,
                  ),
                ),
                Expanded( // other product details
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: const Color.fromARGB(255, 255, 153, 7),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          product.categories
                              .where((category) =>
                                  category.parentId != null &&
                                  category.parentId !=
                                      "2NE57KUAQOBL7RGPZE5UZVK2") // status category, avoid displaying
                              .map((category) => category.name)
                              .join(
                                  ', '), // combine category names with a comma
                          style: GoogleFonts.poppins(
                            color: const Color.fromARGB(255, 124, 75, 7),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          product.description!,
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(), // pushes `cost` to the bottom of this column
                        Text(
                          NumberFormat.currency(symbol: '\$', decimalDigits: 2)
                              .format(product.itemVariations.first.price / 100),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (product.categories.any((category) =>
                ['Seasonal', 'New', 'Sale', 'Popular'].contains(category.name))) // status banners on cards
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(255, 255, 153, 7),
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(10),
                      ),
                    ),
                    child: Text(
                      product.categories
                          .firstWhere((category) => [
                                'Seasonal',
                                'New',
                                'Sale',
                                'Popular'
                              ].contains(category.name))
                          .name,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
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
