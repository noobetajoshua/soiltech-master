import 'package:flutter/material.dart';

/// Shows a top message overlay with custom container styling.
void showTopMessage(
  BuildContext context,
  String message, {
  bool success = false,
  Duration duration = const Duration(seconds: 2),
  Alignment alignment = const Alignment(0, -0.78),
}) {
  final overlay = Overlay.of(context);
  

  final overlayEntry = OverlayEntry(
    builder: (context) => Align(
      alignment: alignment,
      child: Material(
        color: Colors.transparent,
        child: Container(
          height: 45,
          width: 250,
          decoration: BoxDecoration(
            color: success ? const Color(0xFF4CAF50) : const Color(0xFFCD4545),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: success ? const Color(0xFF4CAF50) : const Color(0xFFCD4545),
              width: 0,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(overlayEntry);

  Future.delayed(duration, () {
    overlayEntry.remove();
  });
}
