import 'package:flutter/material.dart';
import 'package:pragatix/core/services/server_status_service.dart';

/// PragatiX Server Maintenance Screen.
/// Displays a clean, dedicated full-screen maintenance message
/// matching the exact design specification:
/// - Amber crossed wrench and hammer circular badge
/// - "Server is currently under maintenance."
/// - "Please try again later."
/// - Direct "Retry" action button with active server health probe
class MaintenancePage extends StatelessWidget {
  final dynamic onRetry;
  final VoidCallback? onHome;
  final String? maintenanceMessage;

  const MaintenancePage({
    super.key,
    this.onRetry,
    this.onHome,
    this.maintenanceMessage,
  });

  Future<void> _handleRetry(BuildContext context) async {
    if (onRetry != null) {
      final res = onRetry!();
      if (res is Future) {
        await res;
      }
      return;
    }

    final isAlive = await ServerStatusService.instance.checkServerHealth();
    if (!isAlive && context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Server is still under maintenance. Please try again later.',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Amber circular icon badge
            Container(
              width: 92,
              height: 92,
              decoration: const BoxDecoration(
                color: Color(0xFFFEF3C7), // Warm pale amber background
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.construction_rounded,
                  size: 46,
                  color: Color(0xFFD97706), // Warm amber-600
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 2. Main Title
            const Text(
              'Server is currently under maintenance.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),

            // 3. Subtitle message
            Text(
              maintenanceMessage ?? ServerStatusService.instance.maintenanceMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14.5,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),

            // 4. Retry Action Button with reactive loading indicator
            ValueListenableBuilder<bool>(
              valueListenable: ServerStatusService.instance.isChecking,
              builder: (context, isChecking, _) {
                return ElevatedButton(
                  onPressed: isChecking ? null : () => _handleRetry(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB), // Vibrant blue
                    disabledBackgroundColor: const Color(0xFF93C5FD),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isChecking)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      else
                        const Icon(
                          Icons.refresh_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                      const SizedBox(width: 8),
                      const Text(
                        'Retry',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
