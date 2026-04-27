import 'package:flutter/material.dart';

class CustomInput extends StatelessWidget {
  final TextEditingController controller;
  final bool hasError;
  final bool obscureText;
  final Widget? suffixIcon;
  final double width;
  final double height; // added

  const CustomInput({
    super.key,
    required this.controller,
    required this.hasError,
    this.obscureText = false,
    this.suffixIcon,
    required this.width,
    this.height = 40, // default height
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: hasError ? Colors.red : const Color.fromARGB(255, 234, 231, 231),
          width: hasError ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 3,
            spreadRadius: -3,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(
          fontSize: 19,
          color: Colors.black,
        ),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}
