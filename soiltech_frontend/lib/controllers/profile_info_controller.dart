import 'package:flutter/material.dart';
import 'package:soiltech/services/profile/profile_service.dart';
import 'package:soiltech/snackbar/snackmessage.dart';

class ProfileController {
  /// Validates profile fields (username, email)
  static bool validateProfileFields({
    required String username,
    required String email,
  }) {
    if (username.trim().isEmpty) return false;
    if (email.trim().isEmpty) return false;
    return true;
  }

  /// Handles profile update
  ///
  /// PROCESS:
  /// 1. Validate fields
  /// 2. Call ProfileService to update (username, email)
  /// 3. Show result snackbar
  /// 4. Return result for UI handling
  static Future<Map<String, dynamic>> handleSaveProfile({
    required BuildContext context,
    required TextEditingController username,
    required TextEditingController email,
    // Snackbar customization
    double snackbarWidth = 280,
    double snackbarHeight = 60,
    double snackbarFontSize = 13,
    EdgeInsets snackbarPadding = const EdgeInsets.only(
      left: 48,
      top: 12,
      bottom: 12,
    ),
    Alignment snackbarAlignment = const Alignment(0, -0.45),
  }) async {
    final usernameText = username.text.trim();
    final emailText = email.text.trim();

    // STEP 1: Validate
    if (!validateProfileFields(username: usernameText, email: emailText)) {
      showTopMessage(
        context,
        'Please fill out all fields',
        success: false,
        width: snackbarWidth,
        height: snackbarHeight,
        fontSize: snackbarFontSize,
        padding: snackbarPadding,
        alignment: snackbarAlignment,
      );
      return {'success': false, 'message': 'Please fill out all fields'};
    }

    // STEP 2: Call service
    final result = await ProfileService().updateFarmerProfile(
      username: usernameText,
      email: emailText,
    );

    if (!context.mounted) return result;

    // STEP 3: Show snackbar
    showTopMessage(
      context,
      result['message'],
      success: result['success'],
      width: snackbarWidth,
      height: snackbarHeight,
      fontSize: snackbarFontSize,
      padding: snackbarPadding,
      alignment: snackbarAlignment,
    );

    // STEP 4: Return result
    return result;
  }
}
