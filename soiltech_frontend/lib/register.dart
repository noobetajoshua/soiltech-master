import 'package:flutter/material.dart';
import 'package:soiltech/reusable/custom.dart';
import 'package:soiltech/controllers/register_controller.dart';
import 'package:soiltech/widgets/app_elevated_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _isPasswordHidden = true;
  bool _isConfirmPasswordHidden = true;

  static const Color _backgroundColor = Color(0xFFF7F5EF);
  static const Color _borderColor = Color(0xFF4F6C46);
  static const Color _textColor = Color(0xFF355C30);

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final success = await RegisterController.handleRegister(
      context: context,
      username: _username,
      email: _email,
      password: _password,
      confirmPassword: _confirmPassword,
    );

    if (!mounted) return;

    if (success) {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final horizontalPadding = screenWidth * 0.07;
    final buttonWidth = screenWidth * 0.70;
    final inputWidth = screenWidth - (horizontalPadding * 2);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── HEADER GRADIENT ──────────────────────────────
            Container(
              clipBehavior: Clip.antiAlias,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFDFFFC9),
                    Color(0xFFC5F79D),
                    Color(0xFF99EB6F),
                    Color(0xFF73DD58),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(120),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.05,
                  vertical: screenHeight * 0.02,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: Color(0xFF123F1A),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back,
                          size: 18,
                          color: Color(0xFFA8F07A),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'CREATE ACCOUNT',
                          style: TextStyle(
                            fontSize: screenWidth * 0.07,
                            fontWeight: FontWeight.w700,
                            color: _textColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 34),
                  ],
                ),
              ),
            ),

            // ── BODY CARD ─────────────────────────────────────
            Expanded(
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(
                  color: Color(0xFFF7F5EF),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(120),
                  ),
                ),
                child: Column(
                  children: [
                    // ── SCROLLABLE FIELDS ─────────────────────
                    Expanded(
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          screenHeight * 0.06,
                          horizontalPadding,
                          screenHeight * 0.02,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── USERNAME ──────────────────────
                            Text(
                              'USERNAME',
                              style: TextStyle(
                                fontSize: screenWidth * 0.035,
                                fontWeight: FontWeight.w700,
                                color: _textColor,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.008),
                            CustomInput(
                              controller: _username,
                              hasError: false,
                              width: inputWidth,
                            ),

                            SizedBox(height: screenHeight * 0.025),

                            // ── EMAIL ─────────────────────────
                            Text(
                              'EMAIL',
                              style: TextStyle(
                                fontSize: screenWidth * 0.035,
                                fontWeight: FontWeight.w700,
                                color: _textColor,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.008),
                            CustomInput(
                              controller: _email,
                              hasError: false,
                              width: inputWidth,
                            ),

                            SizedBox(height: screenHeight * 0.025),

                            // ── PASSWORD ──────────────────────
                            Text(
                              'PASSWORD',
                              style: TextStyle(
                                fontSize: screenWidth * 0.035,
                                fontWeight: FontWeight.w700,
                                color: _textColor,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.008),
                            CustomInput(
                              controller: _password,
                              hasError: false,
                              obscureText: _isPasswordHidden,
                              width: inputWidth,
                              suffixIcon: IconButton(
                                onPressed: () => setState(() {
                                  _isPasswordHidden = !_isPasswordHidden;
                                }),
                                icon: Icon(
                                  _isPasswordHidden
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 20,
                                  color: _borderColor,
                                ),
                              ),
                            ),

                            SizedBox(height: screenHeight * 0.025),

                            // ── CONFIRM PASSWORD ──────────────
                            Text(
                              'CONFIRM PASSWORD',
                              style: TextStyle(
                                fontSize: screenWidth * 0.035,
                                fontWeight: FontWeight.w700,
                                color: _textColor,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.008),
                            CustomInput(
                              controller: _confirmPassword,
                              hasError: false,
                              obscureText: _isConfirmPasswordHidden,
                              width: inputWidth,
                              suffixIcon: IconButton(
                                onPressed: () => setState(() {
                                  _isConfirmPasswordHidden =
                                      !_isConfirmPasswordHidden;
                                }),
                                icon: Icon(
                                  _isConfirmPasswordHidden
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 20,
                                  color: _borderColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── SIGN UP BUTTON — pinned to bottom ─────
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        0,
                        0,
                        0,
                        screenHeight * 0.04,
                      ),
                      child: AppElevatedButton(
                        label: 'SIGN UP',
                        onPressed: _handleRegister,
                        width: buttonWidth,
                        fontSize: screenWidth * 0.041,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
