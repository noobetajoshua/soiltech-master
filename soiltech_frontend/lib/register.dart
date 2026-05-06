import 'package:flutter/material.dart';
import 'package:soiltech/controllers/register_controller.dart';

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

  static const String _regisBgAsset = 'assets/logo/regis_bg.png';

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
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: _backgroundColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              _regisBgAsset,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: _backgroundColor,
              ),
            ),
          ),

          SafeArea(
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      screenWidth * 0.06,
                      screenHeight * 0.018,
                      screenWidth * 0.06,
                      0,
                    ),
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: _textColor,
                          size: 28,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.032),

                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.118,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: screenWidth * 0.069,
                            fontWeight: FontWeight.w900,
                            color: _textColor,
                            letterSpacing: -0.6,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.008),
                        Text(
                          'Join us and start your farming journey',
                          style: TextStyle(
                            fontSize: screenWidth * 0.036,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF8B8F8A),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.048),

                  Center(
                    child: Container(
                      width: double.infinity,
                      height: screenHeight * 0.565,
                      margin: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                      ),
                      padding: EdgeInsets.fromLTRB(
                        screenWidth * 0.065,
                        screenHeight * 0.026,
                        screenWidth * 0.065,
                        screenHeight * 0.006,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.94),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(42),
                          topRight: Radius.circular(42),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _textColor.withOpacity(0.12),
                            blurRadius: 30,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _RegisterInputField(
                            label: 'Username',
                            hint: 'Enter your username',
                            controller: _username,
                            icon: Icons.person_outline_rounded,
                            screenWidth: screenWidth,
                          ),

                          SizedBox(height: screenHeight * 0.014),

                          _RegisterInputField(
                            label: 'Email',
                            hint: 'Enter your email',
                            controller: _email,
                            icon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            screenWidth: screenWidth,
                          ),

                          SizedBox(height: screenHeight * 0.014),

                          _RegisterInputField(
                            label: 'Password',
                            hint: 'Enter your password',
                            controller: _password,
                            icon: Icons.lock_outline_rounded,
                            obscureText: _isPasswordHidden,
                            screenWidth: screenWidth,
                            suffixIcon: IconButton(
                              onPressed: () => setState(() {
                                _isPasswordHidden = !_isPasswordHidden;
                              }),
                              icon: Icon(
                                _isPasswordHidden
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: _borderColor,
                                size: screenWidth * 0.055,
                              ),
                            ),
                          ),

                          SizedBox(height: screenHeight * 0.014),

                          _RegisterInputField(
                            label: 'Confirm Password',
                            hint: 'Confirm your password',
                            controller: _confirmPassword,
                            icon: Icons.lock_outline_rounded,
                            obscureText: _isConfirmPasswordHidden,
                            screenWidth: screenWidth,
                            suffixIcon: IconButton(
                              onPressed: () => setState(() {
                                _isConfirmPasswordHidden =
                                    !_isConfirmPasswordHidden;
                              }),
                              icon: Icon(
                                _isConfirmPasswordHidden
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: _borderColor,
                                size: screenWidth * 0.055,
                              ),
                            ),
                          ),

                          const Spacer(),

                          _SignUpButton(
                            screenWidth: screenWidth,
                            onPressed: _handleRegister,
                          ),

                          SizedBox(height: screenHeight * 0.008),

                          Center(
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Already have an account? ',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.035,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF767A78),
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Log In',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.035,
                                        fontWeight: FontWeight.w800,
                                        color: _textColor,
                                      ),
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

                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RegisterInputField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData icon;
  final double screenWidth;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType keyboardType;

  const _RegisterInputField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    required this.screenWidth,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
  });

  static const Color _textColor = Color(0xFF355C30);
  static const Color _borderColor = Color(0xFFDCECBD);
  static const Color _lightGreen = Color(0xFFF0F6DF);
  static const Color _hintColor = Color(0xFF9BA0A8);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: screenWidth * 0.036,
            fontWeight: FontWeight.w800,
            color: _textColor,
          ),
        ),

        SizedBox(height: screenWidth * 0.016),

        Container(
          height: screenWidth * 0.112,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: _borderColor,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _textColor.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: TextStyle(
              fontSize: screenWidth * 0.036,
              fontWeight: FontWeight.w500,
              color: _textColor,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint,
              hintStyle: TextStyle(
                color: _hintColor,
                fontSize: screenWidth * 0.036,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: Padding(
                padding: EdgeInsets.only(
                  left: screenWidth * 0.026,
                  right: screenWidth * 0.016,
                ),
                child: Container(
                  width: screenWidth * 0.064,
                  height: screenWidth * 0.064,
                  decoration: const BoxDecoration(
                    color: _lightGreen,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: _textColor,
                    size: screenWidth * 0.039,
                  ),
                ),
              ),
              prefixIconConstraints: BoxConstraints(
                minWidth: screenWidth * 0.12,
              ),
              suffixIcon: suffixIcon ??
                  Padding(
                    padding: EdgeInsets.only(right: screenWidth * 0.03),
                    child: Icon(
                      Icons.eco_rounded,
                      color: const Color(0xFFB9CF8D),
                      size: screenWidth * 0.044,
                    ),
                  ),
              contentPadding: EdgeInsets.symmetric(
                vertical: screenWidth * 0.029,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SignUpButton extends StatelessWidget {
  final double screenWidth;
  final VoidCallback onPressed;

  const _SignUpButton({
    required this.screenWidth,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: screenWidth * 0.118,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFFD7DE32),
              Color(0xFF5D9D38),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF355C30).withOpacity(0.22),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            padding: EdgeInsets.zero,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: Text(
                  'Sign Up',
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),

              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.only(right: screenWidth * 0.055),
                  child: Icon(
                    Icons.spa_rounded,
                    color: Colors.white.withOpacity(0.55),
                    size: screenWidth * 0.062,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}