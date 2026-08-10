import 'package:flutter/material.dart';
import 'package:pragatix/core/services/navigator_service.dart';
import 'package:pragatix/core/widgets/pragatix_loader.dart';

class LoadingService {
  static OverlayEntry? _overlayEntry;
  static bool _isLoading = false;

  /// Show the global PragatiX loader overlay.
  static void show({String message = 'Loading'}) {
    if (_isLoading) {
      // If already showing, safely remove without causing markNeedsBuild crashes
      _safeRemove();
    }

    _isLoading = true;

    final overlayState = NavigatorService.navigatorKey.currentState?.overlay;
    if (overlayState == null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => PragatiXLoader(
        message: message,
        fullScreen: true,
      ),
    );

    overlayState.insert(_overlayEntry!);
  }

  /// Hide the global PragatiX loader overlay.
  static void hide() {
    _isLoading = false;
    _safeRemove();
  }

  static void _safeRemove() {
    if (_overlayEntry != null && _overlayEntry!.mounted) {
      _overlayEntry!.remove();
    }
    _overlayEntry = null;
  }
}
