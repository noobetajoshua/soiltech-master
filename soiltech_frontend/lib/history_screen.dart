// lib/widgets/history_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'history_scan_details_screen.dart';
import 'menu.dart';
import 'scan_screen.dart';
import 'profile.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const bgColor = Color(0xFFF5F8D6);
  static const primaryGreen = Color(0xFFC1D95C);
  static const secondaryGreen = Color(0xFF80B155);
  static const darkGreen = Color(0xFF2F5E1A);
  static const borderColor = Color(0xFF80B155);
  static const textDark = Color(0xFF0A2418);
  static const cream = Color(0xFFF8F3D9);

  static const String historyBgAsset = 'assets/logo/history_bg.png';

  List<Map<String, dynamic>> _scans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

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

      if (!mounted) return;

      setState(() {
        _scans = List<Map<String, dynamic>>.from(rows);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Load error: $e')));
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

  void _goProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  void _goScanDetails(Map<String, dynamic> scan) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ScanDetailScreen(scan: scan)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: bgColor,
      extendBody: true,
      appBar: AppBar(
        title: const Text(
          'Scan History',
          style: TextStyle(fontWeight: FontWeight.w900, color: textDark),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textDark,
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: _goHome,
          icon: const Icon(Icons.arrow_back_rounded, color: darkGreen),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: w * 0.04),
            child: GestureDetector(
              onTap: _goProfile,
              child: Container(
                width: w * 0.105,
                height: w * 0.105,
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
                  size: w * 0.062,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              historyBgAsset,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: bgColor),
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.white.withOpacity(0.08)),
          ),
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: darkGreen))
              : _scans.isEmpty
              ? _buildEmptyState(w, h)
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  color: darkGreen,
                  child: ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      w * 0.04,
                      h * 0.015,
                      w * 0.04,
                      h * 0.16,
                    ),
                    itemCount: _scans.length,
                    itemBuilder: (context, index) {
                      final scan = _scans[index];
                      return _HistoryCard(
                        scan: scan,
                        chipColor: _chipColor(scan['om_level']),
                        onTap: () => _goScanDetails(scan),
                      );
                    },
                  ),
                ),
        ],
      ),
      bottomNavigationBar: SoilTechBottomNav(
        selectedIndex: 2,
        onHomeTap: _goHome,
        onScanTap: _goScan,
        onHistoryTap: () {},
      ),
    );
  }

  Widget _buildEmptyState(double w, double h) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: w * 0.08),
        child: Container(
          padding: EdgeInsets.all(w * 0.07),
          decoration: BoxDecoration(
            color: cream.withOpacity(0.82),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: borderColor.withOpacity(0.35)),
            boxShadow: [
              BoxShadow(
                color: darkGreen.withOpacity(0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
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
          border: Border.all(color: borderColor.withOpacity(0.45), width: 1),
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
              child: Icon(icon, size: w * 0.045, color: darkGreen),
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
