import 'package:flutter/material.dart';
import 'profile.dart';
import 'scan_screen.dart';
import 'login.dart';
import 'history_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  static const Color bgColor = Color(0xFFF5F8D6);
  static const Color primaryGreen = Color(0xFFC1D95C);
  static const Color secondaryGreen = Color(0xFF80B155);
  static const Color darkGreen = Color(0xFF2F5E1A);
  static const Color brown = Color(0xFF9A6B36);
  static const Color cream = Color(0xFFF8F3D9);

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: darkGreen),
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
              icon: Icon(Icons.person, size: w * 0.07, color: darkGreen),
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
              color: darkGreen,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: darkGreen.withOpacity(0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(w * 0.025),
                      decoration: BoxDecoration(
                        color: primaryGreen,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.document_scanner,
                        color: darkGreen,
                        size: w * 0.065,
                      ),
                    ),
                    SizedBox(width: w * 0.03),
                    Text(
                      'Start Soil Scan',
                      style: TextStyle(
                        fontSize: w * 0.052,
                        fontWeight: FontWeight.w800,
                        color: cream,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: h * 0.014),

                Text(
                  'Take a photo of your soil to identify soil type, organic matter, and get field recommendations.',
                  style: TextStyle(
                    fontSize: w * 0.034,
                    height: 1.35,
                    color: cream.withOpacity(0.82),
                  ),
                ),

                SizedBox(height: h * 0.024),

                Wrap(
                  spacing: w * 0.02,
                  runSpacing: h * 0.01,
                  children: [
                    _tag(Icons.layers, 'Soil Type', w),
                    _tag(Icons.grass, 'Organic Matter', w),
                    _tag(Icons.water_drop, 'Drainage', w),
                  ],
                ),

                SizedBox(height: h * 0.026),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: darkGreen,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: h * 0.018),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
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
                        fontSize: w * 0.042,
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

      bottomNavigationBar: SoilTechBottomNav(
        selectedIndex: 0,
        onHomeTap: () {},
        onScanTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ScanScreen()),
          );
        },
        onHistoryTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HistoryScreen()),
          );
        },
      ),
    );
  }

  Widget _tag(IconData icon, String label, double w) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: w * 0.027,
        vertical: w * 0.017,
      ),
      decoration: BoxDecoration(
        color: cream.withOpacity(0.10),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cream.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: w * 0.038, color: primaryGreen),
          SizedBox(width: w * 0.012),
          Text(
            label,
            style: TextStyle(
              fontSize: w * 0.029,
              fontWeight: FontWeight.w500,
              color: cream.withOpacity(0.82),
            ),
          ),
        ],
      ),
    );
  }
}

class SoilTechBottomNav extends StatelessWidget {
  final int selectedIndex;
  final VoidCallback onHomeTap;
  final VoidCallback onScanTap;
  final VoidCallback onHistoryTap;

  const SoilTechBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onHomeTap,
    required this.onScanTap,
    required this.onHistoryTap,
  });

  static const Color bgColor = Color(0xFFF5F8D6);
  static const Color primaryGreen = Color(0xFFC1D95C);
  static const Color darkGreen = Color(0xFF2F5E1A);
  static const Color cream = Color(0xFFF8F3D9);

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          w * 0.075,
          0,
          w * 0.075,
          h * 0.018,
        ),
        child: SizedBox(
          height: h * 0.105,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                height: h * 0.072,
                decoration: BoxDecoration(
                  color: darkGreen,
                  borderRadius: BorderRadius.circular(34),
                  boxShadow: [
                    BoxShadow(
                      color: darkGreen.withOpacity(0.22),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavItem(
                      icon: Icons.home_rounded,
                      isSelected: selectedIndex == 0,
                      onTap: onHomeTap,
                    ),
                    _NavItem(
                      icon: Icons.document_scanner_rounded,
                      isSelected: selectedIndex == 1,
                      onTap: onScanTap,
                    ),
                    _NavItem(
                      icon: Icons.history_rounded,
                      isSelected: selectedIndex == 2,
                      onTap: onHistoryTap,
                    ),
                  ],
                ),
              ),

              Positioned(
                top: 0,
                left: _activeBubbleLeft(context, selectedIndex),
                child: GestureDetector(
                  onTap: selectedIndex == 0
                      ? onHomeTap
                      : selectedIndex == 1
                          ? onScanTap
                          : onHistoryTap,
                  child: Container(
                    width: h * 0.072,
                    height: h * 0.072,
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: darkGreen.withOpacity(0.16),
                          blurRadius: 14,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: h * 0.055,
                        height: h * 0.055,
                        decoration: const BoxDecoration(
                          color: darkGreen,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _selectedIcon(selectedIndex),
                          color: primaryGreen,
                          size: w * 0.066,
                        ),
                      ),
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

  double _activeBubbleLeft(BuildContext context, int index) {
    final screenWidth = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    final horizontalPadding = screenWidth * 0.075;
    final navWidth = screenWidth - (horizontalPadding * 2);
    final bubbleSize = h * 0.072;

    final itemWidth = navWidth / 3;
    final centerX = itemWidth * index + itemWidth / 2;

    return centerX - bubbleSize / 2;
  }

  IconData _selectedIcon(int index) {
    switch (index) {
      case 1:
        return Icons.document_scanner_rounded;
      case 2:
        return Icons.history_rounded;
      default:
        return Icons.home_rounded;
    }
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  static const Color primaryGreen = Color(0xFFC1D95C);
  static const Color cream = Color(0xFFF8F3D9);

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Expanded(
      child: IconButton(
        onPressed: onTap,
        icon: Icon(
          icon,
          size: w * 0.075,
          color: isSelected ? Colors.transparent : cream,
        ),
      ),
    );
  }
}