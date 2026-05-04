import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

/// Profile Service for Managing Farmer Profiles
/// Handles fetching, uploading, removing farmer profile images, and updating profile
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
  // UPDATE PROFILE
  // ══════════════════════════════════════════════════════════════

  /// Updates farmer profile (username, email)
  /// Checks uniqueness excluding the current user before updating
  Future<Map<String, dynamic>> updateFarmerProfile({
    required String username,
    required String email,
  }) async {
    try {
      final authUserId = _client.auth.currentUser?.id;
      if (authUserId == null) {
        return _errorResponse('User not authenticated');
      }

      // STEP 1: Get current profile for comparison
      final currentProfile = await _fetchFarmerProfile(authUserId);
      if (currentProfile == null) {
        return _errorResponse('Profile not found');
      }

      // STEP 2: Check username uniqueness (only if changed)
      if (username != currentProfile['username']) {
        if (await _isUsernameTaken(username, excludeId: authUserId)) {
          return _errorResponse('Username is already taken');
        }
      }

      // STEP 3: Check email uniqueness (only if changed)
      if (email != currentProfile['email']) {
        if (await _isEmailTaken(email, excludeId: authUserId)) {
          return _errorResponse('Email is already registered');
        }
      }

      // STEP 4: Update record
      final updatedProfile = await _client
          .from('farmer_profile')
          .update({
            'username': username,
            'email': email,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', authUserId)
          .select()
          .maybeSingle();

      if (updatedProfile == null) {
        return _errorResponse('Failed to update profile');
      }

      return _successResponse(
        message: 'Profile updated successfully',
        data: updatedProfile,
      );
    } on PostgrestException catch (e) {
      if (e.message.contains('duplicate key value')) {
        if (e.message.contains('username')) {
          return _errorResponse('Username is already taken');
        }
        if (e.message.contains('email')) {
          return _errorResponse('Email is already registered');
        }
      }
      return _errorResponse('Database error: ${e.message}');
    } catch (e) {
      return _errorResponse('Unexpected error: ${e.toString()}');
    }
  }

  // ══════════════════════════════════════════════════════════════
  // UPLOAD PROFILE PHOTO
  // ══════════════════════════════════════════════════════════════

  /// Upload profile photo to bucket and update farmer record
  Future<bool> uploadProfilePhoto(String authUserId, File imageFile) async {
    try {
      final fileName =
          '${authUserId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'farmer_profiles/$fileName';

      final bytes = await imageFile.readAsBytes();
      await _client.storage
          .from(_bucketName)
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final publicUrl = _client.storage
          .from(_bucketName)
          .getPublicUrl(filePath);

      final currentProfile = await getFarmerProfile();
      final oldImageUrl = currentProfile?['photo_url'];

      await _client
          .from('farmer_profile')
          .update({'photo_url': publicUrl})
          .eq('id', authUserId);

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
  Future<bool> removeProfilePhoto(String authUserId) async {
    try {
      final currentProfile = await getFarmerProfile();
      final imageUrl = currentProfile?['photo_url'];

      if (imageUrl == null || imageUrl.isEmpty) {
        print('No profile photo to remove');
        return false;
      }

      await _deleteOldProfilePhoto(imageUrl);

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
  // HELPER METHODS
  // ══════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>?> _fetchFarmerProfile(String authUserId) async {
    return await _client
        .from('farmer_profile')
        .select()
        .eq('id', authUserId)
        .maybeSingle();
  }

  Future<bool> _isUsernameTaken(
    String username, {
    required String excludeId,
  }) async {
    final result = await _client
        .from('farmer_profile')
        .select('username')
        .eq('username', username)
        .neq('id', excludeId)
        .maybeSingle();
    return result != null;
  }

  Future<bool> _isEmailTaken(String email, {required String excludeId}) async {
    final result = await _client
        .from('farmer_profile')
        .select('email')
        .eq('email', email)
        .neq('id', excludeId)
        .maybeSingle();
    return result != null;
  }

  Future<void> _deleteOldProfilePhoto(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;

      final bucketIndex = pathSegments.indexOf(_bucketName);
      if (bucketIndex == -1) return;

      final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
      await _client.storage.from(_bucketName).remove([filePath]);
    } catch (e) {
      print('Error deleting old photo: ${e.toString()}');
    }
  }

  Map<String, dynamic> _successResponse({
    required String message,
    dynamic data,
  }) {
    return {'success': true, 'message': message, 'data': data};
  }

  Map<String, dynamic> _errorResponse(String message) {
    return {'success': false, 'message': message};
  }
}
