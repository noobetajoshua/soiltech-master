import 'package:flutter/material.dart';

/// Private variable to track the currently visible overlay
OverlayEntry? _activeOverlay;

/// Removes any currently active overlay immediately
void removeActiveOverlay() {
  _activeOverlay?.remove();
  _activeOverlay = null;
}

/// Shows a top message overlay with custom container styling
void showTopMessage(
  BuildContext context,
  String message, {
  bool isSuccess = false,
  Duration duration = const Duration(seconds: 2),
  Alignment alignment = const Alignment(0, -0.45),
  double width = 250,
  double height = 50,
  double fontSize = 16,
}) {
  final overlay = Overlay.of(context);

  // Remove previous overlay immediately
  _activeOverlay?.remove();

  final overlayEntry = OverlayEntry(
    builder: (context) => Align(
      alignment: alignment,
      child: Material(
        color: Colors.transparent,
        child: Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: isSuccess ? const Color(0xFF4CAF50) : const Color(0xFFCD4545),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSuccess ? const Color(0xFF4CAF50) : const Color(0xFFCD4545),
              width: 0,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(overlayEntry);
  _activeOverlay = overlayEntry;

  Future.delayed(duration, () {
    // Safe removal: check if overlay is still active
    if (_activeOverlay == overlayEntry) {
      overlayEntry.remove();
      _activeOverlay = null;
    }
  });
}