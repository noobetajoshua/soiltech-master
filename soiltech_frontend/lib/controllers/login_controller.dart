// lib/controllers/login_controller.dart
import 'package:flutter/material.dart';
import 'package:soiltech/snackbar/snackmessage.dart';
import 'package:soiltech/services/auth/auth.dart';

class LoginController {
  static Future<Map<String, dynamic>> handleLogin({
    required BuildContext context,
    required TextEditingController identifier,
    required TextEditingController password,
  }) async {
    final usernameOrEmail = identifier.text.trim();
    final passwordText = password.text.trim();

    // ── FRONTEND VALIDATION ───────────────────────────────────────────
    if (usernameOrEmail.isEmpty && passwordText.isEmpty) {
      showTopMessage(context, 'Please fill in all fields');
      return {'success': false};
    }

    if (usernameOrEmail.isEmpty) {
      showTopMessage(context, 'Username or Email is required');
      return {'success': false};
    }

    if (passwordText.isEmpty) {
      showTopMessage(context, 'Password is required');
      return {'success': false};
    }

    // ── BACKEND ───────────────────────────────────────────────────────
    final result = await AuthService().loginFarmer(
      usernameOrEmail: usernameOrEmail,
      password: passwordText,
    );

    if (!context.mounted) return {'success': false};

    showTopMessage(context, result['message'], success: result['success']);
    return result;
  }
}
