import 'package:flutter/material.dart';

OverlayEntry? _currentEntry;
AnimationController? _currentController;

/// Shows a custom toast with fade-in/out animation.
/// Dismisses any existing toast before showing the new one.
void showCustomToast(
  BuildContext context, {
  required String message,
  bool isError = false,
  Duration duration = const Duration(seconds: 2),
}) {
  // Dismiss previous toast immediately
  if (_currentEntry != null && _currentEntry!.mounted) {
    _currentEntry!.remove();
    _currentController?.dispose();
    _currentEntry = null;
    _currentController = null;
  }

  final overlay = Overlay.of(context);

  final controller = AnimationController(
    vsync: overlay,
    duration: const Duration(milliseconds: 300),
    reverseDuration: const Duration(milliseconds: 250),
  );

  final animation = CurvedAnimation(
    parent: controller,
    curve: Curves.easeOut,
    reverseCurve: Curves.easeIn,
  );

  final entry = OverlayEntry(
    builder: (context) {
      return _ToastOverlay(
        message: message,
        isError: isError,
        animation: animation,
      );
    },
  );

  _currentEntry = entry;
  _currentController = controller;

  overlay.insert(entry);
  controller.forward();

  Future.delayed(duration, () {
    // Only dismiss if this is still the active toast
    if (_currentEntry == entry && entry.mounted) {
      controller.reverse().then((_) {
        if (entry.mounted) entry.remove();
        controller.dispose();
        if (_currentEntry == entry) {
          _currentEntry = null;
          _currentController = null;
        }
      });
    }
  });
}

class _ToastOverlay extends StatelessWidget {
  const _ToastOverlay({
    required this.message,
    required this.isError,
    required this.animation,
  });

  final String message;
  final bool isError;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Positioned(
      left: 24,
      right: 24,
      bottom: bottomPadding + 32,
      child: FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(animation),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: isError
                    ? const Color(0xE6DC2626)
                    : const Color(0xCC333333),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
