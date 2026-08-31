import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pragatix/core/services/production_security_service.dart';
import 'package:pragatix/core/theme/app_colors.dart';

/// Root security gate widget that protects the entire application in production builds.
///
/// Automatically monitors app lifecycle (`resumed` state when returning from Android Settings)
/// and displays a non-dismissible, brand-styled security shield whenever USB or Wireless
/// debugging is active in Release mode (`kReleaseMode == true`).
class SecurityGate extends StatefulWidget {
  final Widget child;

  const SecurityGate({
    super.key,
    required this.child,
  });

  @override
  State<SecurityGate> createState() => _SecurityGateState();
}

class _SecurityGateState extends State<SecurityGate> with WidgetsBindingObserver {
  final ProductionSecurityService _securityService = ProductionSecurityService.instance;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initial check when the widget mounts
    _performSecurityCheck();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When returning from Android Settings or bringing the app back to foreground,
    // re-run the security check automatically.
    if (state == AppLifecycleState.resumed) {
      debugPrint('[Security] App resumed from background. Re-evaluating debugging status...');
      _performSecurityCheck();
    }
  }

  Future<void> _performSecurityCheck() async {
    if (!kReleaseMode) return;
    if (_isChecking) return;

    setState(() {
      _isChecking = true;
    });

    try {
      await _securityService.checkDebuggingState();
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // If not in release mode (development/testing build), always bypass with zero interference.
    if (!kReleaseMode) {
      return widget.child;
    }

    return ValueListenableBuilder<SecurityCheckResult?>(
      valueListenable: _securityService.statusNotifier,
      builder: (context, status, _) {
        // If debugging is enabled in production, show the non-dismissible security warning shield.
        if (status != null && status.isDebuggingEnabled) {
          return PopScope(
            canPop: false,
            child: _SecurityWarningShield(
              status: status,
              isChecking: _isChecking,
              onOpenSettings: () async {
                await _securityService.openSettings();
              },
              onCheckAgain: _performSecurityCheck,
            ),
          );
        }

        // Otherwise, allow normal application access.
        return widget.child;
      },
    );
  }
}

/// PragatiX-branded non-dismissible security blocking screen.
class _SecurityWarningShield extends StatelessWidget {
  final SecurityCheckResult status;
  final bool isChecking;
  final VoidCallback onOpenSettings;
  final VoidCallback onCheckAgain;

  const _SecurityWarningShield({
    required this.status,
    required this.isChecking,
    required this.onOpenSettings,
    required this.onCheckAgain,
  });

  @override
  Widget build(BuildContext context) {
    final bool isUsb = status.isUsbDebugging;
    final bool isWireless = status.isWirelessDebugging;

    String debugTypeDesc = 'USB/Wireless Debugging';
    if (isUsb && !isWireless) {
      debugTypeDesc = 'USB Debugging';
    } else if (!isUsb && isWireless) {
      debugTypeDesc = 'Wireless Debugging';
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A), // Deep Slate Navy
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 1. Security Shield Icon Container
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.gpp_bad_rounded,
                      size: 52,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 2. Security Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shield_outlined, size: 14, color: Color(0xFFFCA5A5)),
                        SizedBox(width: 6),
                        Text(
                          'SECURITY ENFORCEMENT',
                          style: TextStyle(
                            color: Color(0xFFFCA5A5),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Title
                  const Text(
                    'Security Warning',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // 4. Message Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF334155)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.adb_rounded, color: Color(0xFFF59E0B), size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '$debugTypeDesc is enabled on this device.',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'For security reasons, please disable USB/Wireless Debugging before using PragatiX.',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 13.5,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Please disable debugging in Developer Options and return to the app or tap "Check Again".',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12.5,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // 5. Open Settings Button (Primary Action)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.adminPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                      ),
                      onPressed: onOpenSettings,
                      icon: const Icon(Icons.settings_rounded, size: 20),
                      label: const Text(
                        'Open Settings',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 6. Check Again Button (Secondary Action)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF475569)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: isChecking ? null : onCheckAgain,
                      icon: isChecking
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.refresh_rounded, size: 20),
                      label: Text(
                        isChecking ? 'Checking status...' : 'Check Again',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
