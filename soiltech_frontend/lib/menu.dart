import 'package:flutter/material.dart';
import 'profile.dart';
import 'scan_screen.dart';
import 'login.dart';
import 'history_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    const bgColor = Color(0xFFF1EFEA);
    const navColor = Color(0xFFB8F57C);
    const iconColor = Color(0xFF0A2418);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: iconColor),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          },
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: w * 0.03),
            child: IconButton(
              icon: Icon(Icons.person, size: w * 0.07, color: iconColor),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: w * 0.05),
          child: Container(
            padding: EdgeInsets.all(w * 0.05),
            decoration: BoxDecoration(
              color: const Color(0xFF1B4332),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(w * 0.02),
                      decoration: BoxDecoration(
                        color: navColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.document_scanner,
                        color: iconColor,
                        size: w * 0.06,
                      ),
                    ),
                    SizedBox(width: w * 0.03),
                    Text(
                      'Start Soil Scan',
                      style: TextStyle(
                        fontSize: w * 0.05,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: h * 0.012),
                Text(
                  'Take a photo of your soil to identify soil type, organic matter, and get field recommendations.',
                  style: TextStyle(fontSize: w * 0.033, color: Colors.white70),
                ),
                SizedBox(height: h * 0.02),
                Row(
                  children: [
                    _tag(Icons.layers, 'Soil Type', w),
                    SizedBox(width: w * 0.02),
                    _tag(Icons.grass, 'Organic Matter', w),
                    SizedBox(width: w * 0.02),
                    _tag(Icons.water_drop, 'Drainage', w),
                  ],
                ),
                SizedBox(height: h * 0.02),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: navColor,
                      foregroundColor: iconColor,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: h * 0.018),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ScanScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Scan Now',
                      style: TextStyle(
                        fontSize: w * 0.04,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        height: h * 0.08,
        width: h * 0.08,
        child: FloatingActionButton(
          elevation: 0,
          backgroundColor: navColor,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ScanScreen()),
            );
          },
          child: Icon(Icons.document_scanner, size: w * 0.07, color: iconColor),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(w * 0.01, 0, w * 0.01, h * 0.01),
        child: Container(
          height: h * 0.07,
          decoration: BoxDecoration(
            color: navColor,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Home — left of FAB
              Padding(
                padding: EdgeInsets.only(left: w * 0.03),
                child: IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.home, size: w * 0.09, color: iconColor),
                ),
              ),

              // FAB gap
              SizedBox(width: w * 0.13),

              // History — right of FAB
              Padding(
                padding: EdgeInsets.only(right: w * 0.03),
                child: IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HistoryScreen(),
                      ),
                    );
                  },
                  icon: Icon(Icons.history, size: w * 0.09, color: iconColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tag(IconData icon, String label, double w) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.025, vertical: w * 0.015),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: w * 0.035, color: Colors.white70),
          SizedBox(width: w * 0.01),
          Text(
            label,
            style: TextStyle(fontSize: w * 0.028, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
