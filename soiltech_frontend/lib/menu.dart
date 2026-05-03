import 'package:flutter/material.dart';
import 'profile.dart';
import 'scan_screen.dart';
import 'history_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  static const Color bgColor = Colors.white;
  static const Color primaryGreen = Color(0xFFC1D95C);
  static const Color secondaryGreen = Color(0xFF80B155);
  static const Color darkGreen = Color(0xFF2F5E1A);
  static const Color brown = Color(0xFF9A6B36);
  static const Color cream = Color(0xFFF8F3D9);
  static const Color textDark = Color(0xFF0A2418);

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: h * 0.13),
          child: Column(
            children: [
              _HeroSection(w: w, h: h),

              Transform.translate(
                offset: Offset(0, -h * 0.065),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: w * 0.045),
                  child: Column(
                    children: [
                      _ScanCard(w: w, h: h),
                      SizedBox(height: h * 0.024),
                      _InsightsSection(w: w, h: h),
                      SizedBox(height: h * 0.024),
                      _RecentScansCard(w: w, h: h),
                    ],
                  ),
                ),
              ),
            ],
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
}

class _HeroSection extends StatelessWidget {
  final double w;
  final double h;

  const _HeroSection({
    required this.w,
    required this.h,
  });

  static const Color darkGreen = Color(0xFF2F5E1A);
  static const Color cream = Color(0xFFF8F3D9);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: h * 0.43,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/logo/bg_menu.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),

          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    cream.withOpacity(0.12),
                    Colors.transparent,
                    darkGreen.withOpacity(0.10),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            top: h * 0.025,
            left: w * 0.045,
            child: IconButton(
              icon: Icon(
                Icons.menu_rounded,
                color: darkGreen,
                size: w * 0.08,
              ),
              onPressed: () {},
            ),
          ),

          Positioned(
            top: h * 0.027,
            right: w * 0.05,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
              child: Container(
                width: w * 0.115,
                height: w * 0.115,
                decoration: BoxDecoration(
                  color: cream.withOpacity(0.95),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: darkGreen.withOpacity(0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: darkGreen,
                  size: w * 0.07,
                ),
              ),
            ),
          ),

          Positioned(
            left: w * 0.075,
            top: h * 0.12,
            right: w * 0.08,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Better Soil,\nBetter Harvest.',
                  style: TextStyle(
                    fontSize: w * 0.087,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    color: darkGreen,
                    letterSpacing: -0.7,
                    shadows: [
                      Shadow(
                        color: Colors.white.withOpacity(0.55),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: h * 0.014),
                Text(
                  'Start scanning and take\nthe first step today.',
                  style: TextStyle(
                    fontSize: w * 0.04,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                    color: darkGreen.withOpacity(0.82),
                    shadows: [
                      Shadow(
                        color: Colors.white.withOpacity(0.55),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanCard extends StatelessWidget {
  final double w;
  final double h;

  const _ScanCard({
    required this.w,
    required this.h,
  });

  static const Color primaryGreen = Color(0xFFC1D95C);
  static const Color secondaryGreen = Color(0xFF80B155);
  static const Color darkGreen = Color(0xFF2F5E1A);
  static const Color cream = Color(0xFFF8F3D9);
  static const Color textDark = Color(0xFF0A2418);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.052),
      decoration: BoxDecoration(
        color: cream.withOpacity(0.97),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.9)),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withOpacity(0.16),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Start Soil Scan',
                  style: TextStyle(
                    fontSize: w * 0.058,
                    fontWeight: FontWeight.w900,
                    color: darkGreen,
                  ),
                ),
                SizedBox(height: h * 0.01),
                Text(
                  'Take a photo of your soil\nand get smart insights.',
                  style: TextStyle(
                    fontSize: w * 0.038,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                    color: textDark.withOpacity(0.72),
                  ),
                ),
                SizedBox(height: h * 0.022),
                SizedBox(
                  height: h * 0.055,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: darkGreen,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(horizontal: w * 0.07),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Scan Now',
                          style: TextStyle(
                            fontSize: w * 0.043,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(width: w * 0.025),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: w * 0.06,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: w * 0.025),

          Container(
            width: w * 0.22,
            height: w * 0.22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFC1D95C),
                  Color(0xFF80B155),
                  Color(0xFF2F5E1A),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: darkGreen.withOpacity(0.22),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: w * 0.165,
                height: w * 0.165,
                decoration: BoxDecoration(
                  color: darkGreen.withOpacity(0.92),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.camera_alt_rounded,
                  color: cream,
                  size: w * 0.09,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightsSection extends StatelessWidget {
  final double w;
  final double h;

  const _InsightsSection({
    required this.w,
    required this.h,
  });

  static const Color primaryGreen = Color(0xFFC1D95C);
  static const Color darkGreen = Color(0xFF2F5E1A);
  static const Color textDark = Color(0xFF0A2418);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'We get insights',
          style: TextStyle(
            fontSize: w * 0.049,
            fontWeight: FontWeight.w900,
            color: darkGreen,
          ),
        ),
        SizedBox(height: h * 0.018),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _InsightItem(
              w: w,
              icon: Icons.science_rounded,
              label: 'Analyze\nSoil',
            ),
            _VerticalDivider(h: h),
            _InsightItem(
              w: w,
              icon: Icons.compost_rounded,
              label: 'Soil\nAmendments',
            ),
            _VerticalDivider(h: h),
            _InsightItem(
              w: w,
              icon: Icons.eco_rounded,
              label: 'Perfect\nCrop',
            ),
          ],
        ),
      ],
    );
  }
}

class _InsightItem extends StatelessWidget {
  final double w;
  final IconData icon;
  final String label;

  const _InsightItem({
    required this.w,
    required this.icon,
    required this.label,
  });

  static const Color primaryGreen = Color(0xFFC1D95C);
  static const Color darkGreen = Color(0xFF2F5E1A);
  static const Color textDark = Color(0xFF0A2418);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: w * 0.22,
      child: Column(
        children: [
          Container(
            width: w * 0.15,
            height: w * 0.15,
            decoration: BoxDecoration(
              color: primaryGreen.withOpacity(0.26),
              shape: BoxShape.circle,
              border: Border.all(
                color: primaryGreen.withOpacity(0.55),
              ),
            ),
            child: Icon(
              icon,
              color: darkGreen,
              size: w * 0.075,
            ),
          ),
          SizedBox(height: w * 0.022),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: w * 0.031,
              height: 1.18,
              fontWeight: FontWeight.w700,
              color: textDark.withOpacity(0.82),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  final double h;

  const _VerticalDivider({
    required this.h,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: h * 0.07,
      color: const Color(0xFF80B155).withOpacity(0.18),
    );
  }
}

class _RecentScansCard extends StatelessWidget {
  final double w;
  final double h;

  const _RecentScansCard({
    required this.w,
    required this.h,
  });

  static const Color primaryGreen = Color(0xFFC1D95C);
  static const Color secondaryGreen = Color(0xFF80B155);
  static const Color darkGreen = Color(0xFF2F5E1A);
  static const Color brown = Color(0xFF9A6B36);
  static const Color cream = Color(0xFFF8F3D9);
  static const Color textDark = Color(0xFF0A2418);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.045),
      decoration: BoxDecoration(
        color: cream.withOpacity(0.92),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Recent Scans',
                style: TextStyle(
                  fontSize: w * 0.05,
                  fontWeight: FontWeight.w900,
                  color: darkGreen,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HistoryScreen(),
                    ),
                  );
                },
                child: Text(
                  'View all',
                  style: TextStyle(
                    fontSize: w * 0.032,
                    fontWeight: FontWeight.w700,
                    color: secondaryGreen,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: h * 0.018),
          Row(
            children: [
              Container(
                width: w * 0.18,
                height: w * 0.18,
                decoration: BoxDecoration(
                  color: brown.withOpacity(0.20),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.terrain_rounded,
                  color: brown,
                  size: w * 0.09,
                ),
              ),
              SizedBox(width: w * 0.035),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Loamy Soil',
                      style: TextStyle(
                        fontSize: w * 0.043,
                        fontWeight: FontWeight.w900,
                        color: darkGreen,
                      ),
                    ),
                    SizedBox(height: h * 0.004),
                    Text(
                      'High Organic Matter',
                      style: TextStyle(
                        fontSize: w * 0.033,
                        fontWeight: FontWeight.w500,
                        color: textDark.withOpacity(0.60),
                      ),
                    ),
                    SizedBox(height: h * 0.006),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_month_rounded,
                          size: w * 0.043,
                          color: secondaryGreen,
                        ),
                        SizedBox(width: w * 0.015),
                        Text(
                          'May 10, 2025',
                          style: TextStyle(
                            fontSize: w * 0.032,
                            color: textDark.withOpacity(0.55),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: w * 0.04,
                  vertical: h * 0.008,
                ),
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.28),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: primaryGreen),
                ),
                child: Text(
                  'High',
                  style: TextStyle(
                    fontSize: w * 0.034,
                    fontWeight: FontWeight.w900,
                    color: darkGreen,
                  ),
                ),
              ),
            ],
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

  static const Color primaryGreen = Color(0xFFC1D95C);
  static const Color secondaryGreen = Color(0xFF80B155);
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
                  color: primaryGreen,
                  borderRadius: BorderRadius.circular(34),
                  boxShadow: [
                    BoxShadow(
                      color: darkGreen.withOpacity(0.16),
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
                    width: h * 0.074,
                    height: h * 0.074,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          cream,
                          primaryGreen,
                          secondaryGreen,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: darkGreen.withOpacity(0.18),
                          blurRadius: 14,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: h * 0.056,
                        height: h * 0.056,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              secondaryGreen,
                              darkGreen,
                            ],
                          ),
                        ),
                        child: Icon(
                          _selectedIcon(selectedIndex),
                          color: cream,
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
    final bubbleSize = h * 0.074;

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

  static const Color darkGreen = Color(0xFF2F5E1A);

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Expanded(
      child: IconButton(
        onPressed: onTap,
        icon: Icon(
          icon,
          size: w * 0.075,
          color: isSelected ? Colors.transparent : darkGreen,
        ),
      ),
    );
  }
}