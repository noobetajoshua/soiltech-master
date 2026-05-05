import 'package:flutter/material.dart';
import 'package:soiltech/controllers/login_controller.dart';
import 'package:soiltech/menu.dart';
import 'package:soiltech/register.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _identifier = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _isPasswordHidden = true;
  bool _rememberMe = false;

  static const Color _backgroundColor = Color(0xFFF7F5EF);
  static const Color _borderColor = Color(0xFF4F6C46);
  static const Color _textColor = Color(0xFF355C30);

  static const String _logoAsset = 'assets/logo/soiltech_logo.png';
  static const String _bgAsset = 'assets/logo/login_bg.png';

  static const Color _primaryGreen = Color(0xFFC1D95C);
  static const Color _backgroundSoft = Color(0xFFF5F8D6);
  static const Color _secondaryGreen = Color(0xFF80B155);
  static const Color _darkAccent = Color(0xFF2F5E1A);
  static const Color _hintColor = Color(0xFF8A8F99);
  static const Color _borderGreen = Color(0xFFD5E4B5);
  static const Color _cardColor = Color(0xFFFFFEFB);

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
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: _backgroundSoft,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double screenWidth = constraints.maxWidth;
          final double screenHeight = constraints.maxHeight;

          return Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  _bgAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: _backgroundSoft,
                  ),
                ),
              ),

              SafeArea(
                child: Stack(
                  children: [
                    Positioned(
                      top: screenHeight * 0.055,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: _buildTopLogo(screenWidth),
                      ),
                    ),

                    Positioned(
                      top: screenHeight * 0.36,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _buildLoginCard(screenWidth, screenHeight),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopLogo(double screenWidth) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: screenWidth * 0.62,
          height: screenWidth * 0.62,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.16),
            border: Border.all(
              color: Colors.white.withOpacity(0.60),
              width: 1.5,
            ),
          ),
        ),
        Container(
          width: screenWidth * 0.34,
          height: screenWidth * 0.34,
          padding: EdgeInsets.all(screenWidth * 0.032),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEF).withOpacity(0.96),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white,
              width: 2.6,
            ),
            boxShadow: [
              BoxShadow(
                color: _secondaryGreen.withOpacity(0.16),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Image.asset(
            _logoAsset,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.eco_rounded,
              color: _secondaryGreen,
              size: screenWidth * 0.17,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard(double screenWidth, double screenHeight) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        screenWidth * 0.075,
        screenHeight * 0.03,
        screenWidth * 0.075,
        screenHeight * 0.025,
      ),
      decoration: BoxDecoration(
        color: _cardColor.withOpacity(0.98),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(42),
          topRight: Radius.circular(42),
        ),
        boxShadow: [
          BoxShadow(
            color: _darkAccent.withOpacity(0.08),
            blurRadius: 28,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Text(
            'Log In',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: screenWidth * 0.085,
              fontWeight: FontWeight.w900,
              color: _darkAccent,
              letterSpacing: -0.5,
            ),
          ),

          SizedBox(height: screenHeight * 0.022),

          _buildLabel('Email', screenWidth),
          SizedBox(height: screenHeight * 0.010),
          _buildInputField(
            screenWidth: screenWidth,
            screenHeight: screenHeight,
            controller: _identifier,
            hint: 'Enter your email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),

          SizedBox(height: screenHeight * 0.020),

          _buildLabel('Password', screenWidth),
          SizedBox(height: screenHeight * 0.010),
          _buildInputField(
            screenWidth: screenWidth,
            screenHeight: screenHeight,
            controller: _password,
            hint: 'Enter your password',
            icon: Icons.lock_outline_rounded,
            obscureText: _isPasswordHidden,
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _isPasswordHidden = !_isPasswordHidden;
                });
              },
              icon: Icon(
                _isPasswordHidden
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: _secondaryGreen,
                size: screenWidth * 0.064,
              ),
            ),
          ),

          SizedBox(height: screenHeight * 0.015),

          Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _rememberMe = !_rememberMe;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: screenWidth * 0.045,
                  height: screenWidth * 0.045,
                  decoration: BoxDecoration(
                    color: _rememberMe ? _secondaryGreen : Colors.transparent,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: _secondaryGreen,
                      width: 1.7,
                    ),
                  ),
                  child: _rememberMe
                      ? Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: screenWidth * 0.035,
                        )
                      : null,
                ),
              ),
              SizedBox(width: screenWidth * 0.025),
              Text(
                'Remember me',
                style: TextStyle(
                  fontSize: screenWidth * 0.037,
                  fontWeight: FontWeight.w600,
                  color: _darkAccent,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  // Add forgot password navigation here if needed.
                },
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(
                    fontSize: screenWidth * 0.037,
                    fontWeight: FontWeight.w800,
                    color: _secondaryGreen,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: screenHeight * 0.024),

          SizedBox(
            width: double.infinity,
            height: screenHeight * 0.068,
            child: _buildLoginButton(screenWidth),
          ),

          SizedBox(height: screenHeight * 0.022),

          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegisterScreen()),
              );
            },
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: "Don’t have an account? ",
                    style: TextStyle(
                      fontSize: screenWidth * 0.039,
                      color: const Color(0xFF29313A),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(
                    text: 'Sign Up',
                    style: TextStyle(
                      fontSize: screenWidth * 0.039,
                      color: _secondaryGreen,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, double screenWidth) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontSize: screenWidth * 0.043,
          color: _darkAccent,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildInputField({
    required double screenWidth,
    required double screenHeight,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      height: screenHeight * 0.065,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(27),
        border: Border.all(
          color: _borderGreen,
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: TextStyle(
          fontSize: screenWidth * 0.04,
          fontWeight: FontWeight.w600,
          color: _darkAccent,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(
            color: _hintColor,
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Padding(
            padding: EdgeInsets.only(
              left: screenWidth * 0.035,
              right: screenWidth * 0.015,
            ),
            child: Icon(
              icon,
              color: _secondaryGreen,
              size: screenWidth * 0.06,
            ),
          ),
          prefixIconConstraints: BoxConstraints(
            minWidth: screenWidth * 0.13,
          ),
          suffixIcon: suffixIcon,
          contentPadding: EdgeInsets.symmetric(
            vertical: screenHeight * 0.016,
            horizontal: screenWidth * 0.02,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(double screenWidth) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: _handleLogin,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [
                Color(0xFFC1D95C),
                Color(0xFF80B155),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: _secondaryGreen.withOpacity(0.22),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                'Log In',
                style: TextStyle(
                  fontSize: screenWidth * 0.048,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              Positioned(
                right: screenWidth * 0.06,
                child: Icon(
                  Icons.eco_outlined,
                  color: Colors.white.withOpacity(0.82),
                  size: screenWidth * 0.065,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}