// lib/history_screen.dart
// STEP 12 — History screen: list of past scan cards from scan_history
// STEP 13 — Each card opens results_screen with that scan's chat thread

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'results_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
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
            'compatibility, issues, amendments, explanation, scanned_at',
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Load error: $e')));
      }
    }
  }

  String _formatDate(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
          '${dt.day.toString().padLeft(2, '0')}  '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }

  String _compatibilityLabel(String? v) {
    switch (v) {
      case 'suitable':
        return '✅ Suitable';
      case 'fair':
        return '⚠️ Fair';
      case 'not_suitable':
        return '❌ Not Suitable';
      default:
        return v ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan History'),
        backgroundColor: const Color(0xFFF1EFEA),
        elevation: 0,
        foregroundColor: const Color(0xFF0A2418),
      ),
      backgroundColor: const Color(0xFFF1EFEA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _scans.isEmpty
          ? const Center(
              child: Text(
                'No scans yet.\nDo your first soil scan!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadHistory,
              child: ListView.builder(
                padding: EdgeInsets.symmetric(
                  horizontal: w * 0.04,
                  vertical: 12,
                ),
                itemCount: _scans.length,
                itemBuilder: (context, index) {
                  final scan = _scans[index];
                  return _ScanCard(
                    scan: scan,
                    compatibilityLabel: _compatibilityLabel(
                      scan['compatibility'],
                    ),
                    dateLabel: _formatDate(scan['scanned_at']),
                    onTap: () {
                      // STEP 13 — Open results screen with this scan's data
                      // Pass scanId so the chat thread loads from Supabase
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ResultsScreen(
                            // predictResult carries the soil/om/confidence data
                            predictResult: {
                              'soil_type': scan['soil_type'] ?? '',
                              'om_level': scan['om_level'] ?? '',
                              'confidence': scan['confidence'] ?? '',
                              'crop_name': scan['crop_name'] ?? '',
                            },
                            // History view has no image file — use placeholder
                            imageFile: File(''),
                            scanId: scan['id'] as String,
                          ),
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
// Scan card widget
// ─────────────────────────────────────────────────────────────
class _ScanCard extends StatelessWidget {
  final Map<String, dynamic> scan;
  final String compatibilityLabel;
  final String dateLabel;
  final VoidCallback onTap;

  const _ScanCard({
    required this.scan,
    required this.compatibilityLabel,
    required this.dateLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date
              Text(
                dateLabel,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 6),

              // Soil type + crop
              Text(
                '${scan['soil_type']?.toString().toUpperCase() ?? '—'} soil',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                'Crop: ${scan['crop_name'] ?? '—'}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 4),

              // Organic matter + confidence
              Text('Organic Matter: ${scan['om_level'] ?? '—'}'),
              Text('Confidence: ${scan['confidence'] ?? '—'}'),
              const SizedBox(height: 6),

              // Compatibility badge
              Text(compatibilityLabel, style: const TextStyle(fontSize: 13)),

              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Tap to view details & chat →',
                  style: TextStyle(fontSize: 11, color: Colors.blueGrey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
