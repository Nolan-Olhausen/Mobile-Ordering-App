/****************************************************************************************************
 *
 * @file:    rewards.dart
 * @author:  Nolan Olhausen
 * @date: 2024-11-15
 *
 * @brief:
 *      Page for displaying rewards and loyalty points.
 * 
 ****************************************************************************************************/

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app/pages/cart.dart';
import '../utility/squareAPI.dart';

class RewardsPage extends StatelessWidget {
  final List<RewardProgram> programs; // List of reward programs
  List<CartItem> cart; // List of cart items
  final LoyaltyAccount? account; // Loyalty account

  RewardsPage(
      {super.key,
      required this.programs,
      required this.cart,
      required this.account});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 50), // Spacer
            Text(
              'Rewards',
              style: GoogleFonts.poppins(
                color: const Color.fromARGB(255, 255, 153, 7),
                fontSize: 36,
                fontWeight: FontWeight.w900,
              ),
            ),
            // Display account balance or guest if no account
            if (account == null)
              Text(
                'GUEST',
                style: GoogleFonts.poppins(
                  color: const Color.fromARGB(255, 255, 153, 7),
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                ),
              )
            else if (account!.balance == 1)
              Text(
                '${account!.balance} ${programs.first.singular}',
                style: GoogleFonts.poppins(
                  color: const Color.fromARGB(255, 255, 153, 7),
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                ),
              )
            else
              Text(
                '${account!.balance} ${programs.first.plural}',
                style: GoogleFonts.poppins(
                  color: const Color.fromARGB(255, 255, 153, 7),
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 16.0, horizontal: 8.0),
                  child: Text(
                    "Redeemable At Checkout",
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
            // List of reward tiers
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: programs.first.rewardTiers.length,
                itemBuilder: (context, index) {
                  final reward = programs.first.rewardTiers[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          const SizedBox(width: 16), // Spacer
                          Expanded(
                            child: Text(
                              reward.name,
                            ),
                          ),
                          Text(
                            '${reward.points}',
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
