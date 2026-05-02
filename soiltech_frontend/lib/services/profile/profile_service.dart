import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

/// Profile Service for Managing Farmer Profiles
/// Handles fetching, uploading, and removing farmer profile images
class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  final SupabaseClient _client = Supabase.instance.client;
  static const String _bucketName = 'profile_pics';

  // ══════════════════════════════════════════════════════════════
  // FETCH PROFILE
  // ══════════════════════════════════════════════════════════════

  /// Fetch complete farmer profile by id (FK → auth.users.id)
  /// Includes photo_url column
  Future<Map<String, dynamic>?> getFarmerProfile() async {
    try {
      final authUserId = _client.auth.currentUser?.id;
      if (authUserId == null) return null;

      final profile = await _client
          .from('farmer_profile')
          .select('username, email, photo_url')
          .eq('id', authUserId)
          .maybeSingle();

      if (profile == null) return null;

      return {
        'username': profile['username'],
        'email': profile['email'],
        'photo_url': profile['photo_url'],
      };
    } on PostgrestException catch (e) {
      print('Database error: ${e.message}');
      return null;
    } catch (e) {
      print('Unexpected error: ${e.toString()}');
      return null;
    }
  }

  // ══════════════════════════════════════════════════════════════
  // UPLOAD PROFILE PHOTO
  // ══════════════════════════════════════════════════════════════

  /// Upload profile photo to bucket and update farmer record
  ///
  /// Steps:
  /// 1. Upload file to Supabase bucket
  /// 2. Get public URL
  /// 3. Update farmers.photo_url with the URL
  /// 4. Delete old photo if exists (cleanup)
  ///
  /// Returns: true if successful, false otherwise
  Future<bool> uploadProfilePhoto(String authUserId, File imageFile) async {
    try {
      // Step 1: Generate unique filename
      final fileName =
          '${authUserId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'farmer_profiles/$fileName';

      // Step 2: Upload file to bucket
      final bytes = await imageFile.readAsBytes();
      await _client.storage
          .from(_bucketName)
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      // Step 3: Get public URL of uploaded file
      final publicUrl = _client.storage
          .from(_bucketName)
          .getPublicUrl(filePath);

      // Step 4: Get current profile to check if old image exists
      final currentProfile = await getFarmerProfile();
      final oldImageUrl = currentProfile?['photo_url'];

      // Step 5: Update database with new image URL
      await _client
          .from('farmer_profile')
          .update({'photo_url': publicUrl})
          .eq('id', authUserId);

      // Step 6: Delete old image from bucket (cleanup old file)
      if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
        await _deleteOldProfilePhoto(oldImageUrl);
      }

      print('Profile photo uploaded successfully: $publicUrl');
      return true;
    } on StorageException catch (e) {
      print('Storage error: ${e.message}');
      return false;
    } on PostgrestException catch (e) {
      print('Database error: ${e.message}');
      return false;
    } catch (e) {
      print('Unexpected error: ${e.toString()}');
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════════
  // REMOVE PROFILE PHOTO
  // ══════════════════════════════════════════════════════════════

  /// Remove profile photo from bucket and clear farmer record
  ///
  /// Steps:
  /// 1. Get current profile to find old image URL
  /// 2. Delete image from bucket
  /// 3. Set photo_url to NULL in database
  ///
  /// Returns: true if successful, false otherwise
  Future<bool> removeProfilePhoto(String authUserId) async {
    try {
      // Step 1: Get current profile to find image URL
      final currentProfile = await getFarmerProfile();
      final imageUrl = currentProfile?['photo_url'];

      if (imageUrl == null || imageUrl.isEmpty) {
        print('No profile photo to remove');
        return false;
      }

      // Step 2: Delete image from bucket
      await _deleteOldProfilePhoto(imageUrl);

      // Step 3: Clear photo_url column in database
      await _client
          .from('farmer_profile')
          .update({'photo_url': null})
          .eq('id', authUserId);

      print('Profile photo removed successfully');
      return true;
    } on PostgrestException catch (e) {
      print('Database error: ${e.message}');
      return false;
    } catch (e) {
      print('Unexpected error: ${e.toString()}');
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════════
  // SIGN OUT
  // ══════════════════════════════════════════════════════════════

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ══════════════════════════════════════════════════════════════
  // HELPER: DELETE OLD PHOTO
  // ══════════════════════════════════════════════════════════════

  /// Delete old profile photo from bucket
  /// Extracts file path from public URL and deletes it
  Future<void> _deleteOldProfilePhoto(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;

      final bucketIndex = pathSegments.indexOf(_bucketName);
      if (bucketIndex == -1) return;

      final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
      await _client.storage.from(_bucketName).remove([filePath]);
    } catch (e) {
      // Don't throw — cleanup should not break the main flow
      print('Error deleting old photo: ${e.toString()}');
    }
  }
}
