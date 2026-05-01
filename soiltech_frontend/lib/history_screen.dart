// lib/widgets/history_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'history_scan_details_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // ── Constants ──────────────────────────────────────────────
  static const bgColor     = Color(0xFFF1EFEA);
  static const darkGreen   = Color.fromARGB(255, 114, 168, 127);
  static const borderColor = Color(0xFF7D9C74);
  static const textDark    = Color(0xFF0A2418);

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
        _scans     = List<Map<String, dynamic>>.from(rows);
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
      case 'high'    : return Colors.green.shade600;
      case 'moderate': return Colors.orange.shade600;
      case 'low'     : return Colors.red.shade400;
      default        : return darkGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title          : const Text('Scan History'),
        backgroundColor: bgColor,
        elevation      : 0,
        foregroundColor: textDark,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: darkGreen),
            )
          : _scans.isEmpty
              ? Center(
                  child: Text(
                    'No scans yet.\nDo your first soil scan!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  color    : darkGreen,
                  child    : ListView.builder(
                    padding   : EdgeInsets.symmetric(
                      horizontal: w * 0.04,
                      vertical  : h * 0.015,
                    ),
                    itemCount  : _scans.length,
                    itemBuilder: (context, index) {
                      final scan = _scans[index];
                      return _HistoryCard(
                        scan      : scan,
                        chipColor : _chipColor(scan['om_level']),
                        onTap     : () {
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

  static const darkGreen   = Color.fromARGB(255, 114, 168, 127);
  static const borderColor = Color(0xFF7D9C74);
  static const textDark    = Color(0xFF0A2418);

  const _HistoryCard({
    required this.scan,
    required this.chipColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w         = MediaQuery.of(context).size.width;
    final h         = MediaQuery.of(context).size.height;
    final imageUrl  = scan['image_url'] as String?;
    final soilType  = scan['soil_type']  ?? '—';
    final omLevel   = scan['om_level']   ?? '—';
    final confidence = scan['confidence'] ?? '—';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin     : EdgeInsets.only(bottom: h * 0.015),
        decoration : BoxDecoration(
          color       : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border      : Border.all(color: borderColor, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Photo ────────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft : Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width    : double.infinity,
                      height   : h * 0.2,
                      fit      : BoxFit.cover,
                      errorBuilder: (_, __, ___) => _photoPlaceholder(w, h),
                    )
                  : _photoPlaceholder(w, h),
            ),

            // ── Soil info ─────────────────────────────────
            Padding(
              padding: EdgeInsets.all(w * 0.04),
              child  : Column(
                children: [
                  _resultRow(
                    w,
                    Icons.layers,
                    'Soil Type',
                    soilType,
                    darkGreen,
                  ),
                  const SizedBox(height: 10),
                  _resultRow(
                    w,
                    Icons.eco,
                    'Organic Matter',
                    omLevel,
                    chipColor,
                  ),
                  const SizedBox(height: 10),
                  _resultRow(
                    w,
                    Icons.bar_chart,
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
      width : double.infinity,
      height: h * 0.2,
      color : Colors.grey.shade100,
      child : Icon(
        Icons.image_outlined,
        size : w * 0.12,
        color: Colors.grey.shade300,
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: w * 0.045, color: Colors.grey.shade400),
            SizedBox(width: w * 0.025),
            Text(
              label,
              style: TextStyle(
                fontSize: w * 0.035,
                color   : Colors.grey.shade500,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color       : chipColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            value[0].toUpperCase() + value.substring(1),
            style: TextStyle(
              fontSize  : w * 0.032,
              fontWeight: FontWeight.w700,
              color     : chipColor,
            ),
          ),
        ),
      ],
    );
  }
}