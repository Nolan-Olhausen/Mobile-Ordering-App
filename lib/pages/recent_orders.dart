/****************************************************************************************************
 *
 * @file:    recent_orders.dart
 * @author:  Nolan Olhausen
 * @date: 2024-11-15
 *
 * @brief:
 *      Page for displaying recent orders.
 * 
 ****************************************************************************************************/

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RecentOrdersPage extends StatelessWidget {
  final List<Map<String, dynamic>> recentOrders;

  const RecentOrdersPage({super.key, required this.recentOrders});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Recent Orders',
          style: GoogleFonts.poppins(
            color: const Color.fromARGB(255, 255, 153, 7),
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: recentOrders.length,
                itemBuilder: (context, index) {
                  final order = recentOrders[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #: ${order['orderId']}',
                            style: GoogleFonts.poppins(
                              color: const Color.fromARGB(255, 255, 153, 7),
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Column(
                            children: order['items']
                                .asMap()
                                .entries
                                .map<Widget>((entry) {
                              int itemIndex = entry.key;
                              var item = entry.value;

                              return Padding(
                                padding: EdgeInsets.only(
                                    bottom:
                                        itemIndex < order['items'].length - 1
                                            ? 8.0
                                            : 0),
                                child: InkWell(
                                  onTap: () {
                                    // TODO
                                  },
                                  child: Row(
                                    children: [
                                      Image.asset(
                                        item['imagePath'],
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          item['name'],
                                          style: const TextStyle(fontSize: 18),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
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
