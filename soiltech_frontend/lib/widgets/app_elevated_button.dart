import 'package:flutter/material.dart';

class AppElevatedButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final double width;
  final double fontSize;

  static const Color _buttonColor = Color(0xFFA8F07A);
  static const Color _buttonTextColor = Color(0xFF2F4F29);

  const AppElevatedButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.width,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: width,
        height: 46,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: _buttonColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: _buttonTextColor,
            ),
          ),
        ),
      ),
    );
  }
}
