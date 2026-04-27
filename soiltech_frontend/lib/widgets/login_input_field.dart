import 'package:flutter/material.dart';

// Reusable bordered input field with floating label.
// Extracted from _border_label_field — now usable on any screen.
class LoginInputField extends StatelessWidget {
  final String labelText;
  final TextEditingController controller;
  final double screenWidth;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final bool isPassword;
  final bool isPasswordHidden;
  final VoidCallback? onToggleVisibility;

  const LoginInputField({
    super.key,
    required this.labelText,
    required this.controller,
    required this.screenWidth,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    this.isPassword = false,
    this.isPasswordHidden = false,
    this.onToggleVisibility,
  });


  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Input container with border
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword ? isPasswordHidden : false,
            style: TextStyle(
              fontSize: screenWidth * 0.034,
              color: textColor,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.03,
                vertical: 11,
              ),
              suffixIcon: isPassword
                  ? IconButton(
                      onPressed: onToggleVisibility,
                      icon: Icon(
                        isPasswordHidden
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: borderColor,
                      ),
                    )
                  : null,
            ),
          ),
        ),

        // Floating label positioned above the border
        Positioned(
          left: 12,
          top: -9,
          child: Container(
            color: backgroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              labelText,
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}