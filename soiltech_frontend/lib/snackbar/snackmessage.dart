import 'package:flutter/material.dart';

/// Private variable to track the currently visible SnackBar
OverlayEntry? _activeOverlay;

/// Removes any currently active SnackBar immediately
void removeActiveSnackBar() {
  _activeOverlay?.remove();
  _activeOverlay = null;
}

/// Shows a top message overlay with white container and icon indicator
void showTopMessage(
  BuildContext context,
  String message, {
  bool success = false,
  Duration duration = const Duration(seconds: 2),
  Alignment alignment = const Alignment(0, -0.45),
  double width = 280,
  double height = 60,
  double fontSize = 13,
  EdgeInsets padding = const EdgeInsets.only(left: 48, top: 12, bottom: 12),
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
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with circular colored background
              Container(
                width: 25,
                height: 25,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: success
                      ? const Color(0xFF4CAF50) // Green circle
                      : const Color(0xFFCD4545), // Red circle
                ),
                alignment: Alignment.center,
                child: Icon(
                  success ? Icons.check : Icons.close,
                  color: Colors.white,
                  size: 20,
                  weight: 800,
                ),
              ),
              const SizedBox(width: 14),
              // Message text
              Expanded(
                child: Text(
                  message,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  overlay.insert(overlayEntry);
  _activeOverlay = overlayEntry;

  Future.delayed(duration, () {
    // ✅ Safe removal: check if overlay is still active
    if (_activeOverlay == overlayEntry) {
      overlayEntry.remove();
      _activeOverlay = null;
    }
  });
}
