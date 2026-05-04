import 'package:flutter/material.dart';
import 'package:soiltech/controllers/change_password_controller.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  static const Color bgColor = Color(0xFFFCFDF7);
  static const Color titleColor = Color(0xFF173F2B);
  static const Color subtitleColor = Color(0xFF767A82);
  static const Color lightBorder = Color(0xFFDCE6C0);
  static const Color inputBorder = Color(0xFFD8DEC6);
  static const Color iconGreen = Color(0xFF8CAB59);
  static const Color buttonStart = Color(0xFFC1D95C);
  static const Color buttonEnd = Color(0xFF3F8C3A);

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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: bgColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(color: bgColor),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Image.asset(
                'assets/logo/changepass_bg.png',
                fit: BoxFit.cover,
                height: h * 0.18,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: bottomInset + h * 0.08),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: h * 0.01),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: w * 0.11,
                            height: w * 0.11,
                            alignment: Alignment.centerLeft,
                            child: Icon(
                              Icons.arrow_back_rounded,
                              size: w * 0.09,
                              color: const Color(0xFF7EA445),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(top: h * 0.006),
                            child: Column(
                              children: [
                                Text(
                                  'Change Password',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: w * 0.075,
                                    fontWeight: FontWeight.w900,
                                    color: titleColor,
                                    height: 1.1,
                                  ),
                                ),
                                SizedBox(height: h * 0.018),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: w * 0.03,
                                  ),
                                  child: Text(
                                    'Keep your account secure with a strong password.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: w * 0.042,
                                      color: subtitleColor,
                                      fontWeight: FontWeight.w500,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          width: w * 0.11,
                          child: Icon(
                            Icons.eco_rounded,
                            size: w * 0.085,
                            color: const Color(0xFFD7E6AE),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: h * 0.05),

                  Container(
                    margin: EdgeInsets.symmetric(horizontal: w * 0.06),
                    padding: EdgeInsets.fromLTRB(
                      w * 0.055,
                      h * 0.035,
                      w * 0.055,
                      h * 0.035,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFEFB),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: lightBorder,
                        width: 1.6,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPasswordField(
                          context: context,
                          controller: _currentPass,
                          label: 'Current Password',
                          hint: 'Enter current password',
                          obscure: _obscureCurrent,
                          toggle: () => setState(
                            () => _obscureCurrent = !_obscureCurrent,
                          ),
                        ),

                        SizedBox(height: h * 0.028),

                        _buildPasswordField(
                          context: context,
                          controller: _newPass,
                          label: 'New Password',
                          hint: 'Enter new password',
                          obscure: _obscureNew,
                          toggle: () =>
                              setState(() => _obscureNew = !_obscureNew),
                        ),

                        SizedBox(height: h * 0.028),

                        _buildPasswordField(
                          context: context,
                          controller: _confirmPass,
                          label: 'Confirm New Password',
                          hint: 'Confirm new password',
                          obscure: _obscureConfirm,
                          toggle: () => setState(
                            () => _obscureConfirm = !_obscureConfirm,
                          ),
                        ),

                        SizedBox(height: h * 0.038),

                        GestureDetector(
                          onTap: _isLoading ? null : _handleChangePassword,
                          child: Container(
                            width: double.infinity,
                            height: h * 0.072,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _isLoading
                                    ? [
                                        buttonStart.withOpacity(0.6),
                                        buttonEnd.withOpacity(0.6),
                                      ]
                                    : const [
                                        buttonStart,
                                        buttonEnd,
                                      ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF67913D).withOpacity(0.28),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Center(
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.6,
                                          ),
                                        )
                                      : Text(
                                          'Change Password',
                                          style: TextStyle(
                                            fontSize: w * 0.052,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                                Positioned(
                                  right: w * 0.05,
                                  child: Icon(
                                    Icons.eco_outlined,
                                    color: Colors.white.withOpacity(0.35),
                                    size: w * 0.075,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: h * 0.18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscure,
    required VoidCallback toggle,
  }) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: w * 0.052,
            fontWeight: FontWeight.w800,
            color: titleColor,
          ),
        ),
        SizedBox(height: h * 0.015),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: inputBorder,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.025),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            style: TextStyle(
              fontSize: w * 0.045,
              color: titleColor,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: const Color(0xFF9698A0),
                fontSize: w * 0.045,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Icon(
                  Icons.lock_outline_rounded,
                  color: iconGreen,
                  size: w * 0.07,
                ),
              ),
              prefixIconConstraints: BoxConstraints(
                minWidth: w * 0.14,
                minHeight: h * 0.065,
              ),
              suffixIcon: IconButton(
                onPressed: toggle,
                icon: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: const Color(0xFF7F876A),
                  size: w * 0.072,
                ),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: w * 0.02,
                vertical: h * 0.022,
              ),
            ),
          ),
        ),
      ],
    );
  }
}