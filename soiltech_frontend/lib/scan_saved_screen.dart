// lib/widgets/scan_saved_screen.dart

import 'package:flutter/material.dart';
import 'history_screen.dart'; // adjust import to your actual path

class ScanSavedScreen extends StatelessWidget {
  const ScanSavedScreen({super.key});

  static const bgColor = Color(0xFFF1EFEA);
  static const darkGreen = Color.fromARGB(255, 114, 168, 127);
  static const borderColor = Color(0xFF7D9C74);
  static const textDark = Color(0xFF0A2418);

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: w * 0.08),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Check circle ───────────────────────────
              Container(
                width: w * 0.28,
                height: w * 0.28,
                decoration: const BoxDecoration(
                  color: darkGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 56),
              ),

              SizedBox(height: h * 0.035),

              // ── Title ──────────────────────────────────
              Text(
                'Scan Saved!',
                style: TextStyle(
                  fontSize: w * 0.07,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                ),
              ),

              SizedBox(height: h * 0.012),

              // ── Subtitle ───────────────────────────────
              Text(
                'Your soil scan has been saved to your history.\nYou can review it anytime.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: w * 0.038,
                  color: Colors.grey.shade500,
                  height: 1.5,
                ),
              ),

              SizedBox(height: h * 0.06),

              // ── View History ───────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Pop everything back to root, then push HistoryScreen.
                    // This lands the farmer on History with a clean back stack.
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HistoryScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: EdgeInsets.symmetric(vertical: h * 0.02),
                    elevation: 0,
                  ),
                  child: Text(
                    'View History',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: w * 0.042,
                    ),
                  ),
                ),
              ),

              SizedBox(height: h * 0.015),

              // ── Scan Again ─────────────────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    // Pop all the way back to Step 1 (ScanScreen).
                    // ScanScreen is the root of this navigation stack,
                    // so popUntil(isFirst) drops us right back there.
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: borderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: EdgeInsets.symmetric(vertical: h * 0.02),
                  ),
                  child: Text(
                    'Scan Again',
                    style: TextStyle(
                      color: darkGreen,
                      fontWeight: FontWeight.w700,
                      fontSize: w * 0.042,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
