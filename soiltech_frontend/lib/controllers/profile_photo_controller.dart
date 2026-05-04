import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:soiltech/services/profile/profile_service.dart';
import 'package:soiltech/snackbar/snackmessage.dart';

/// Dedicated controller for farmer profile photo operations
/// Handles image picking, upload/remove logic, and snackbar feedback
class ProfilePhotoController {
  final ProfileService profileService = ProfileService(); // ← public
  final ImagePicker _imagePicker = ImagePicker();

  // ══════════════════════════════════════════════════════════════
  // UPLOAD PHOTO
  // ══════════════════════════════════════════════════════════════

  Future<void> uploadProfilePhoto({
    required BuildContext context,
    required String authUserId,
    required VoidCallback onSuccess,
  }) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedFile == null) return;

      final imageFile = File(pickedFile.path);

      final success = await profileService.uploadProfilePhoto(
        authUserId,
        imageFile,
      );

      if (!context.mounted) return;

      if (success) {
        onSuccess();
        showTopMessage(context, 'Photo uploaded successfully', success: true);
      } else {
        showTopMessage(context, 'Failed to upload photo', success: false);
      }
    } catch (e) {
      if (!context.mounted) return;
      showTopMessage(
        context,
        'Error uploading photo: ${e.toString()}',
        success: false,
      );
    }
  }

  // ══════════════════════════════════════════════════════════════
  // REMOVE PHOTO
  // ══════════════════════════════════════════════════════════════

  Future<void> removeProfilePhoto({
    required BuildContext context,
    required String authUserId,
    required VoidCallback onSuccess,
  }) async {
    try {
      final success = await profileService.removeProfilePhoto(authUserId);

      if (!context.mounted) return;

      if (success) {
        onSuccess();
        showTopMessage(context, 'Photo removed successfully', success: true);
      } else {
        showTopMessage(context, 'Failed to remove photo', success: false);
      }
    } catch (e) {
      if (!context.mounted) return;
      showTopMessage(
        context,
        'Error removing photo: ${e.toString()}',
        success: false,
      );
    }
  }
}
