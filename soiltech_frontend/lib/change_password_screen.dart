import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:soiltech/controllers/change_password_controller.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  static const darkGreen = Color.fromARGB(255, 114, 168, 127);
  static const greenColor = Color(0xFFA8EA7A);

  final TextEditingController _currentPass = TextEditingController();
  final TextEditingController _newPass = TextEditingController();
  final TextEditingController _confirmPass = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPass.dispose();
    _newPass.dispose();
    _confirmPass.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    setState(() => _isLoading = true);

    final result = await ChangePasswordController.changePassword(
      context: context,
      currentPassword: _currentPass.text,
      newPassword: _newPass.text,
      confirmPassword: _confirmPass.text,
      snackbarAlignment: const Alignment(0, -0.75),
      snackbarFontSize: 13,
      snackbarWidth: 320,
      snackbarHeight: 60,
      snackbarPadding: const EdgeInsets.only(left: 48, top: 12, bottom: 12),
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      _currentPass.clear();
      _newPass.clear();
      _confirmPass.clear();

      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ── Gradient background ──────────────────────────────
          Container(
            height: h,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [darkGreen, greenColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // ── Scroll area ──────────────────────────────────────
          SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: h * 0.20),

                // ── Glass card ──────────────────────────────────
                Container(
                  margin: EdgeInsets.symmetric(horizontal: w * 0.06),
                  padding: EdgeInsets.all(w * 0.004),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [darkGreen, greenColor],
                    ),
                    borderRadius: BorderRadius.circular(w * 0.05),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(w * 0.05),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        padding: EdgeInsets.all(w * 0.06),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.72),
                          borderRadius: BorderRadius.circular(w * 0.05),
                        ),
                        child: Column(
                          children: [
                            _passwordField(
                              controller: _currentPass,
                              label: 'Current Password',
                              obscure: _obscureCurrent,
                              toggle: () => setState(
                                () => _obscureCurrent = !_obscureCurrent,
                              ),
                              w: w,
                            ),
                            SizedBox(height: h * 0.025),

                            _passwordField(
                              controller: _newPass,
                              label: 'New Password',
                              obscure: _obscureNew,
                              toggle: () =>
                                  setState(() => _obscureNew = !_obscureNew),
                              w: w,
                            ),
                            SizedBox(height: h * 0.025),

                            _passwordField(
                              controller: _confirmPass,
                              label: 'Confirm New Password',
                              obscure: _obscureConfirm,
                              toggle: () => setState(
                                () => _obscureConfirm = !_obscureConfirm,
                              ),
                              w: w,
                            ),
                            SizedBox(height: h * 0.04),

                            // ── Change Password button ──────────
                            GestureDetector(
                              onTap: _isLoading ? null : _handleChangePassword,
                              child: Container(
                                height: h * 0.065,
                                width: w * 0.55,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: _isLoading
                                        ? [
                                            darkGreen.withOpacity(0.5),
                                            greenColor.withOpacity(0.5),
                                          ]
                                        : [darkGreen, const Color(0xFF5FA87A)],
                                  ),
                                  borderRadius: BorderRadius.circular(w * 0.04),
                                ),
                                child: Center(
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : Text(
                                          'Change Password',
                                          style: TextStyle(
                                            fontSize: w * 0.045,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                            ),

                            SizedBox(height: h * 0.02),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: h * 0.1),
              ],
            ),
          ),

          // ── Title ────────────────────────────────────────────
          Positioned(
            top: h * 0.055,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Change Password',
                style: TextStyle(
                  fontSize: w * 0.07,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // ── Back button ──────────────────────────────────────
          Positioned(
            top: h * 0.055,
            left: w * 0.04,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
                size: w * 0.065,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback toggle,
    required double w,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: w * 0.043,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: w * 0.02),
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(w * 0.03),
              borderSide: BorderSide.none,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscure ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey[700],
              ),
              onPressed: toggle,
            ),
          ),
        ),
      ],
    );
  }
}
