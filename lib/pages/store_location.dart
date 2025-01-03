/****************************************************************************************************
 *
 * @file:    store_location.dart
 * @author:  Nolan Olhausen
 * @date: 2024-11-15
 *
 * @brief:
 *      This file contains the LocationPage widget, which displays the store location on a Google
 *      Map and provides the user with options to open the location in Google Maps or copy the
 *      address to the clipboard.
 * 
 ****************************************************************************************************/

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class LocationPage extends StatelessWidget {
  final LatLng storeLocation;
  final String address;

  const LocationPage(
      {super.key, required this.storeLocation, required this.address});

  Future<void> _launchUrl() async {
    // construct the Google Maps URL with the address
    final url =
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> _copyToClipboard(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: address));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Address copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 50),
            Text(
              'Store Location',
              style: GoogleFonts.poppins(
                color: const Color.fromARGB(255, 255, 153, 7),
                fontSize: 36,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8.0),
            Container(
              height: MediaQuery.of(context).size.height * 0.5,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: storeLocation,
                  zoom: 17.0,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('storeMarker'),
                    position: storeLocation,
                    infoWindow: const InfoWindow(
                      title: 'Eagles Brew',
                    ),
                  ),
                },
              ),
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 16.0, horizontal: 8.0),
                  child: Text(
                    "Address",
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      address,
                      style: GoogleFonts.poppins(
                        color: const Color.fromARGB(255, 255, 153, 7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.directions),
                        color: const Color.fromARGB(255, 255, 153, 7),
                        onPressed: _launchUrl,
                      ),
                      const SizedBox(width: 8.0),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        color: const Color.fromARGB(255, 255, 153, 7),
                        onPressed: () => _copyToClipboard(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
