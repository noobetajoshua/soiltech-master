// lib/services/profile/profile_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  // ══════════════════════════════════════════════════════════════
  // GET CURRENT FARMER PROFILE
  // ══════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>?> getFarmerProfile() async {
    final user = _client.auth.currentUser;

    if (user == null) return null;

    final response = await _client
        .from('farmer_profile')
        .select('username, email, photo_url')
        .eq('id', user.id)
        .single();

    return response;
  }

  // ══════════════════════════════════════════════════════════════
  // UPDATE PHOTO URL (for future photo upload)
  // ══════════════════════════════════════════════════════════════

  Future<void> updatePhotoUrl(String photoUrl) async {
    final user = _client.auth.currentUser;

    if (user == null) return;

    await _client
        .from('farmer_profile')
        .update({
          'photo_url': photoUrl,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', user.id);
  }

  // ══════════════════════════════════════════════════════════════
  // SIGN OUT
  // ══════════════════════════════════════════════════════════════

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
