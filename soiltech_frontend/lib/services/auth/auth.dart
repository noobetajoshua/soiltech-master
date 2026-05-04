// lib/services/auth/auth_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  // ══════════════════════════════════════════════════════════════
  // LOGIN
  // ══════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> loginFarmer({
    required String usernameOrEmail,
    required String password,
  }) async {
    try {
      final isEmail =
          usernameOrEmail.contains('@') && usernameOrEmail.contains('.');
      String email = usernameOrEmail;

      if (isEmail) {
        // EMAIL login — check if email exists in farmer_profile
        final emailCheck = await _client
            .from('farmer_profile')
            .select('email')
            .eq('email', usernameOrEmail)
            .maybeSingle();

        if (emailCheck == null) {
          return _errorResponse('Invalid email');
        }
      } else {
        // USERNAME login — look up email from username
        final result = await _client
            .from('farmer_profile')
            .select('email')
            .eq('username', usernameOrEmail)
            .maybeSingle();

        if (result == null) {
          return _errorResponse('Invalid username');
        }

        email = result['email'];
      }

      // Credential exists — attempt sign in
      final authResponse = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        return _errorResponse('Login failed. Try again.');
      }

      return _successResponse(message: 'Login successful!');
    } on AuthException catch (e) {
      if (e.message.contains('Invalid login credentials')) {
        return _errorResponse('Incorrect password');
      }
      return _errorResponse(e.message);
    } catch (e) {
      return _errorResponse('Something went wrong. Try again.');
    }
  }

  // ══════════════════════════════════════════════════════════════
  // REGISTRATION
  // ══════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> registerFarmer({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      // STEP 1: Check username uniqueness
      if (await _isUsernameTaken(username)) {
        return _errorResponse('Username is already taken');
      }

      // STEP 2: Create Supabase Auth user
      final authResponse = await _client.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        return _errorResponse('Registration failed. Try again.');
      }

      // STEP 3: Insert into farmer_profile
      try {
        await _client.from('farmer_profile').insert({
          'id': authResponse.user!.id,
          'username': username,
          'email': email,
        });
      } on PostgrestException catch (e) {
        // Rollback — delete auth user so they can try again clean
        await _client.auth.admin.deleteUser(authResponse.user!.id);

        if (e.message.contains('duplicate key value') &&
            e.message.contains('username')) {
          return _errorResponse('Username is already taken');
        }
        if (e.message.contains('duplicate key value') &&
            e.message.contains('email')) {
          return _errorResponse('Email is already registered');
        }
        return _errorResponse('Profile setup failed. Try again.');
      }

      return _successResponse(message: 'Registration successful!');
    } on AuthException catch (e) {
      if (e.message.contains('already registered')) {
        return _errorResponse('Email is already registered');
      }
      return _errorResponse(e.message);
    } catch (e) {
      return _errorResponse('Something went wrong. Try again.');
    }
  }


// ══════════════════════════════════════════════════════════════
// CHANGE PASSWORD
// ══════════════════════════════════════════════════════════════

Future<Map<String, dynamic>> changePassword({
  required String currentPassword,
  required String newPassword,
  required String confirmPassword,
}) async {
  try {
    if (newPassword != confirmPassword) {
      return {'success': false, 'message': 'New passwords do not match'};
    }

    if (currentPassword == newPassword) {
      return {'success': false, 'message': 'Please enter a new password'};
    }

    final user = _client.auth.currentUser;
    if (user == null) {
      return {'success': false, 'message': 'User not found'};
    }

    try {
      await _client.auth.signInWithPassword(
        email: user.email!,
        password: currentPassword,
      );
    } catch (e) {
      return {'success': false, 'message': 'Invalid current password'};
    }

    await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );

    return {'success': true, 'message': 'Password changed successfully'};
  } catch (e) {
    return {'success': false, 'message': 'Error: ${e.toString()}'};
  }
}



  // ══════════════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════════════

  Future<bool> _isUsernameTaken(String username) async {
    final result = await _client
        .from('farmer_profile')
        .select('username')
        .eq('username', username)
        .maybeSingle();
    return result != null;
  }

  // ══════════════════════════════════════════════════════════════
  // RESPONSE BUILDERS
  // ══════════════════════════════════════════════════════════════

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
