// widgets/app_text_button.dart
import 'package:flutter/material.dart';

// General reusable text + tappable label row.
// Used for "Don't have an account? SIGN UP" and similar patterns.
class AppTextButton extends StatelessWidget {
  final String prefixText;
  final String actionText;
  final Widget destination;
  final double screenWidth;

  const AppTextButton({
    super.key,
    required this.prefixText,
    required this.actionText,
    required this.destination,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        children: [
          Text(
            prefixText,
            style: TextStyle(
              fontSize: screenWidth * 0.032,
              color: const Color(0xFF707070),
              fontWeight: FontWeight.w500,
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => destination),
              );
            },
            child: Text(
              actionText,
              style: TextStyle(
                fontSize: screenWidth * 0.032,
                color: const Color(0xFF355C30),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
