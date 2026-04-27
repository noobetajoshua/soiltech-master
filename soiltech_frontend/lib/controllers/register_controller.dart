// lib/controllers/register_controller.dart
import 'package:flutter/material.dart';
import 'package:soiltech/snackbar/snackmessage.dart';
import 'package:soiltech/services/auth/auth.dart';

class RegisterController {
  static Future<bool> handleRegister({
    required BuildContext context,
    required TextEditingController username,
    required TextEditingController email,
    required TextEditingController password,
    required TextEditingController confirmPassword,
  }) async {
    final usernameText = username.text.trim();
    final emailText = email.text.trim().toLowerCase();
    final passwordText = password.text;
    final confirmText = confirmPassword.text;

    // ── FRONTEND VALIDATION ───────────────────────────────────────────
    if (usernameText.isEmpty &&
        emailText.isEmpty &&
        passwordText.isEmpty &&
        confirmText.isEmpty) {
      showTopMessage(context, 'Please fill in all fields');
      return false;
    }

    if (usernameText.isEmpty) {
      showTopMessage(context, 'Username is required');
      return false;
    }

    if (emailText.isEmpty) {
      showTopMessage(context, 'Email is required');
      return false;
    }

    if (!emailText.contains('@') || !emailText.contains('.')) {
      showTopMessage(context, 'Enter a valid email address');
      return false;
    }

    if (passwordText.isEmpty) {
      showTopMessage(context, 'Password is required');
      return false;
    }

    if (passwordText.length < 6) {
      showTopMessage(context, 'Password must be at least 6 characters');
      return false;
    }

    if (confirmText.isEmpty) {
      showTopMessage(context, 'Please confirm your password');
      return false;
    }

    if (passwordText != confirmText) {
      showTopMessage(context, 'Passwords do not match');
      return false;
    }

    // ── BACKEND ───────────────────────────────────────────────────────
    final result = await AuthService().registerFarmer(
      username: usernameText,
      email: emailText,
      password: passwordText,
    );

    if (!context.mounted) return false;
    showTopMessage(context, result['message'], success: result['success']);
    return result['success'] ?? false;
  }
}
