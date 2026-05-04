// lib/widgets/history_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'history_scan_details_screen.dart';
import 'menu.dart';
import 'scan_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // ── Constants ──────────────────────────────────────────────
  static const bgColor = Color(0xFFF5F8D6);
  static const primaryGreen = Color(0xFFC1D95C);
  static const darkGreen = Color(0xFF2F5E1A);
  static const borderColor = Color(0xFF80B155);
  static const textDark = Color(0xFF0A2418);
  static const cream = Color(0xFFF8F3D9);

  List<Map<String, dynamic>> _scans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final rows = await Supabase.instance.client
          .from('scan_history')
          .select(
            'id, soil_type, om_level, confidence, crop_name, '
            'compatibility, issues, amendments, explanation, '
            'image_url, scanned_at',
          )
          .eq('user_id', user.id)
          .order('scanned_at', ascending: false);

      setState(() {
        _scans = List<Map<String, dynamic>>.from(rows);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Load error: $e')),
        );
      }
    }
  }

  Color _chipColor(String? value) {
    switch (value?.toLowerCase()) {
      case 'high':
        return Colors.green.shade600;
      case 'moderate':
        return Colors.orange.shade600;
      case 'low':
        return Colors.red.shade400;
      default:
        return darkGreen;
    }
  }

  void _goHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MenuScreen()),
    );
  }

  void _goScan() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScanScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          'Scan History',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: textDark,
          ),
        ),
        centerTitle: true,
        backgroundColor: bgColor,
        elevation: 0,
        foregroundColor: textDark,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: darkGreen),
            )
          : _scans.isEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: w * 0.08),
                    child: Container(
                      padding: EdgeInsets.all(w * 0.07),
                      decoration: BoxDecoration(
                        color: cream.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: borderColor.withOpacity(0.35),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.history_rounded,
                            size: w * 0.16,
                            color: darkGreen.withOpacity(0.65),
                          ),
                          SizedBox(height: h * 0.018),
                          Text(
                            'No scans yet',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: textDark,
                              fontSize: w * 0.052,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: h * 0.008),
                          Text(
                            'Do your first soil scan to see your results here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: textDark.withOpacity(0.55),
                              fontSize: w * 0.035,
                              height: 1.35,
                            ),
                          ),
                          SizedBox(height: h * 0.022),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              foregroundColor: darkGreen,
                              elevation: 0,
                              padding: EdgeInsets.symmetric(
                                horizontal: w * 0.06,
                                vertical: h * 0.015,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: _goScan,
                            icon: const Icon(Icons.document_scanner_rounded),
                            label: const Text(
                              'Scan Now',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  color: darkGreen,
                  child: ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      w * 0.04,
                      h * 0.015,
                      w * 0.04,
                      h * 0.13,
                    ),
                    itemCount: _scans.length,
                    itemBuilder: (context, index) {
                      final scan = _scans[index];
                      return _HistoryCard(
                        scan: scan,
                        chipColor: _chipColor(scan['om_level']),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ScanDetailScreen(scan: scan),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
      bottomNavigationBar: SoilTechBottomNav(
        selectedIndex: 2,
        onHomeTap: _goHome,
        onScanTap: _goScan,
        onHistoryTap: () {},
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// History Card
// ─────────────────────────────────────────────────────────────
class _HistoryCard extends StatelessWidget {
  final Map<String, dynamic> scan;
  final Color chipColor;
  final VoidCallback onTap;

  static const darkGreen = Color(0xFF2F5E1A);
  static const primaryGreen = Color(0xFFC1D95C);
  static const borderColor = Color(0xFF80B155);
  static const textDark = Color(0xFF0A2418);
  static const cream = Color(0xFFF8F3D9);

  const _HistoryCard({
    required this.scan,
    required this.chipColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final imageUrl = scan['image_url'] as String?;
    final soilType = scan['soil_type']?.toString() ?? '—';
    final omLevel = scan['om_level']?.toString() ?? '—';
    final confidence = scan['confidence']?.toString() ?? '—';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: h * 0.018),
        decoration: BoxDecoration(
          color: cream.withOpacity(0.9),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: borderColor.withOpacity(0.45),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: darkGreen.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Photo ────────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
              ),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: double.infinity,
                      height: h * 0.2,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _photoPlaceholder(w, h),
                    )
                  : _photoPlaceholder(w, h),
            ),

            // ── Soil info ─────────────────────────────────
            Padding(
              padding: EdgeInsets.all(w * 0.045),
              child: Column(
                children: [
                  _resultRow(
                    w,
                    Icons.layers_rounded,
                    'Soil Type',
                    soilType,
                    darkGreen,
                  ),
                  const SizedBox(height: 12),
                  _resultRow(
                    w,
                    Icons.eco_rounded,
                    'Organic Matter',
                    omLevel,
                    chipColor,
                  ),
                  const SizedBox(height: 12),
                  _resultRow(
                    w,
                    Icons.bar_chart_rounded,
                    'Confidence',
                    confidence,
                    darkGreen,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoPlaceholder(double w, double h) {
    return Container(
      width: double.infinity,
      height: h * 0.2,
      color: const Color(0xFFF0E7C4).withOpacity(0.75),
      child: Icon(
        Icons.image_outlined,
        size: w * 0.12,
        color: darkGreen.withOpacity(0.25),
      ),
    );
  }

  Widget _resultRow(
    double w,
    IconData icon,
    String label,
    String value,
    Color chipColor,
  ) {
    final safeValue = value.isEmpty ? '—' : value;
    final displayValue = safeValue == '—'
        ? safeValue
        : safeValue[0].toUpperCase() + safeValue.substring(1);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(w * 0.018),
              decoration: BoxDecoration(
                color: primaryGreen.withOpacity(0.35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: w * 0.045,
                color: darkGreen,
              ),
            ),
            SizedBox(width: w * 0.025),
            Text(
              label,
              style: TextStyle(
                fontSize: w * 0.035,
                fontWeight: FontWeight.w600,
                color: textDark.withOpacity(0.62),
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: chipColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            displayValue,
            style: TextStyle(
              fontSize: w * 0.032,
              fontWeight: FontWeight.w800,
              color: chipColor,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Bottom Navigation
// ─────────────────────────────────────────────────────────────
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