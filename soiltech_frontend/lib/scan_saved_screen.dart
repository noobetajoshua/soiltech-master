// lib/widgets/scan_saved_screen.dart

import 'package:flutter/material.dart';
import 'history_screen.dart'; // adjust if path differs
import 'scan_screen.dart'; // adjust if path differs

class ScanSavedScreen extends StatelessWidget {
  const ScanSavedScreen({super.key});

  static const Color bgColor = Colors.white;
  static const Color darkGreen = Color(0xFF2F5E1A);
  static const Color mediumGreen = Color(0xFF5B922F);
  static const Color secondaryGreen = Color(0xFF80B155);
  static const Color borderColor = Color(0xFF5B922F);
  static const Color textDark = Color(0xFF0A2418);
  static const Color subtitleColor = Color(0xFF777C82);

  static const String scanSaveImageAsset = 'assets/logo/scan_save_image.png';

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    final double h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: w * 0.065),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              Image.asset(
                scanSaveImageAsset,
                width: w * 0.58,
                height: w * 0.58,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  width: w * 0.48,
                  height: w * 0.48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F8D6),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: darkGreen.withOpacity(0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: mediumGreen,
                    size: 110,
                  ),
                ),
              ),

              SizedBox(height: h * 0.035),

              Text(
                'Scan Saved!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: w * 0.083,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  color: textDark,
                  letterSpacing: -0.8,
                ),
              ),

              SizedBox(height: h * 0.02),

              Text(
                'Your soil scan has been saved to your history.\nYou can review it anytime.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: w * 0.041,
                  height: 1.55,
                  color: subtitleColor,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const Spacer(flex: 2),

              SizedBox(
                width: double.infinity,
                height: h * 0.078,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil(
                      (route) => route.settings.name == '/' || route.isFirst,
                    );
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HistoryScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mediumGreen,
                    foregroundColor: Colors.white,
                    elevation: 10,
                    shadowColor: darkGreen.withOpacity(0.22),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF5B922F),
                          Color(0xFF2F5E1A),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      padding: EdgeInsets.symmetric(horizontal: w * 0.055),
                      child: Row(
                        children: [
                          Container(
                            width: w * 0.085,
                            height: w * 0.085,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white,
                                width: 2.4,
                              ),
                            ),
                            child: Icon(
                              Icons.bar_chart_rounded,
                              color: Colors.white,
                              size: w * 0.058,
                            ),
                          ),
                          SizedBox(width: w * 0.04),
                          Expanded(
                            child: Text(
                              'View History',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: w * 0.047,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white,
                            size: w * 0.075,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: h * 0.025),

              SizedBox(
                width: double.infinity,
                height: h * 0.078,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ScanScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(
                      color: borderColor,
                      width: 1.8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: w * 0.055),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.refresh_rounded,
                        color: mediumGreen,
                        size: w * 0.078,
                      ),
                      SizedBox(width: w * 0.04),
                      Expanded(
                        child: Text(
                          'Scan Again',
                          style: TextStyle(
                            color: mediumGreen,
                            fontWeight: FontWeight.w900,
                            fontSize: w * 0.047,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: mediumGreen,
                        size: w * 0.075,
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}