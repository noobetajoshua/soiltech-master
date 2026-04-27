import 'package:flutter/material.dart';
import 'package:soiltech/controllers/login_controller.dart';
import 'package:soiltech/widgets/login_input_field.dart';
import 'package:soiltech/widgets/login_text_button.dart';
import 'package:soiltech/menu.dart';
import 'package:soiltech/register.dart';
import 'package:soiltech/widgets/app_elevated_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _identifier = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _isPasswordHidden = true;

  static const Color _backgroundColor = Color(0xFFF7F5EF);
  static const Color _borderColor = Color(0xFF4F6C46);
  static const Color _textColor = Color(0xFF355C30);



  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final result = await LoginController.handleLogin(
      context: context,
      identifier: _identifier,
      password: _password,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MenuScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final headerHeight = screenHeight * 0.40;
    final bodyTopPosition = screenHeight * 0.33;
    final horizontalPadding = screenWidth * 0.10;
    final buttonWidth = screenWidth * 0.58;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          // ── KEY FIX: removed LayoutBuilder + ConstrainedBox + fixed SizedBox height
          // Stack now sizes to its children naturally, scroll handles the rest
          child: SizedBox(
            width: double.infinity,
            height: screenHeight,
            child: Stack(
              children: [
                // ── HEADER GRADIENT ──────────────────────────────
                Container(
                  width: double.infinity,
                  height: headerHeight,
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
                      bottomRight: Radius.circular(200),
                    ),
                  ),
                ),

                // ── BODY CARD ─────────────────────────────────────
                Positioned(
                  top: bodyTopPosition,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _backgroundColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(88),
                      ),
                    ),
                    child: SingleChildScrollView(
                      // ── SECOND ScrollView wraps only the form content
                      // This one scrolls when keyboard pushes content up
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        screenHeight * 0.075,
                        horizontalPadding,
                        screenHeight * 0.035,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── EMAIL FIELD ───────────────────────
                          LoginInputField(
                            labelText: 'EMAIL',
                            controller: _identifier,
                            screenWidth: screenWidth,
                            backgroundColor: _backgroundColor,
                            borderColor: _borderColor,
                            textColor: _textColor,
                          ),

                          SizedBox(height: screenHeight * 0.03),

                          // ── PASSWORD FIELD ────────────────────
                          LoginInputField(
                            labelText: 'PASSWORD',
                            controller: _password,
                            screenWidth: screenWidth,
                            backgroundColor: _backgroundColor,
                            borderColor: _borderColor,
                            textColor: _textColor,
                            isPassword: true,
                            isPasswordHidden: _isPasswordHidden,
                            onToggleVisibility: () {
                              setState(() {
                                _isPasswordHidden = !_isPasswordHidden;
                              });
                            },
                          ),

                          SizedBox(height: screenHeight * 0.018),

                          // ── FORGOT PASSWORD ───────────────────
                      

                          SizedBox(height: screenHeight * 0.045),

                          // ── LOGIN BUTTON ──────────────────────
                          AppElevatedButton(
                            label: 'LOGIN',
                            onPressed: _handleLogin,
                            width: buttonWidth,
                            fontSize: screenWidth * 0.041,
                          ),

                          SizedBox(height: screenHeight * 0.04),

                          // ── SIGN UP ROW ───────────────────────
                          AppTextButton(
                            prefixText: "Don't have an account? ",
                            actionText: 'SIGN UP',
                            destination: const RegisterScreen(),
                            screenWidth: screenWidth,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
