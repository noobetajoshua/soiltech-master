// lib/widgets/scan_saved_screen.dart

import 'package:flutter/material.dart';
import 'scan_screen.dart';

class ScanSavedScreen extends StatelessWidget {
  const ScanSavedScreen({super.key});

  static const bgColor    = Color(0xFFF1EFEA);
  static const greenColor = Color(0xFFA8EA7A);
  static const darkGreen  = Color.fromARGB(255, 114, 168, 127);
  static const borderColor = Color(0xFF7D9C74);
  static const textDark   = Color(0xFF0A2418);

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: w * 0.1),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Check icon ──────────────────────────────
                Container(
                  width: w * 0.22,
                  height: w * 0.22,
                  decoration: BoxDecoration(
                    color: greenColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: w * 0.12,
                  ),
                ),

                SizedBox(height: h * 0.03),

                Text(
                  'Scan Saved!',
                  style: TextStyle(
                    fontSize: w * 0.065,
                    fontWeight: FontWeight.w800,
                    color: textDark,
                  ),
                ),

                SizedBox(height: h * 0.01),

                Text(
                  'Your result has been saved to your history.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: w * 0.038,
                    color: Colors.grey.shade600,
                  ),
                ),

                SizedBox(height: h * 0.05),

                // ── View History ────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to history screen
                      // Replace with your history screen navigation
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: EdgeInsets.symmetric(vertical: h * 0.02),
                      elevation: 0,
                    ),
                    child: const Text(
                      'View History',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: h * 0.015),

                // ── Scan Again ──────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ScanScreen(),
                        ),
                        (route) => route.isFirst,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: EdgeInsets.symmetric(vertical: h * 0.02),
                    ),
                    child: const Text(
                      'Scan Again',
                      style: TextStyle(
                        color: darkGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}