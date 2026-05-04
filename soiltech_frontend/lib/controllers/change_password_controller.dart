import 'package:flutter/material.dart';
import 'package:soiltech/services/auth/auth.dart';
import 'package:soiltech/snackbar/snackmessage.dart';

class ChangePasswordController {
  static final AuthService _authService = AuthService();

  static Future<Map<String, dynamic>> changePassword({
    required BuildContext context,
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
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
    try {
      // Validate empty fields
      if (currentPassword.isEmpty ||
          newPassword.isEmpty ||
          confirmPassword.isEmpty) {
        showTopMessage(
          context,
          'Please fill all fields',
          success: false,
          width: snackbarWidth,
          height: snackbarHeight,
          fontSize: snackbarFontSize,
          padding: snackbarPadding,
          alignment: snackbarAlignment,
        );
        return {'success': false, 'message': 'Please fill all fields'};
      }

      // Validate password match
      if (newPassword != confirmPassword) {
        showTopMessage(
          context,
          'New passwords do not match',
          success: false,
          width: snackbarWidth,
          height: snackbarHeight,
          fontSize: snackbarFontSize,
          padding: snackbarPadding,
          alignment: snackbarAlignment,
        );
        return {'success': false, 'message': 'New passwords do not match'};
      }

      // Call service
      final result = await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

      if (!context.mounted) return result;

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

      return result;
    } catch (e) {
      showTopMessage(
        context,
        'Error: ${e.toString()}',
        success: false,
        width: snackbarWidth,
        height: snackbarHeight,
        fontSize: snackbarFontSize,
        padding: snackbarPadding,
        alignment: snackbarAlignment,
      );
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
}