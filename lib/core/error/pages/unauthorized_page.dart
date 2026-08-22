import 'package:flutter/material.dart';
import 'package:pragatix/core/error/widgets/app_error_view.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/features/auth/pages/login_page.dart';
import 'package:pragatix/core/services/navigator_service.dart';

class UnauthorizedPage extends StatelessWidget {
  const UnauthorizedPage({super.key});

  void _handleLoginAgain(BuildContext context) {
    // Clear stored auth state
    final auth = getIt<AuthProvider>();
    auth.logout();

    // Navigate to login, removing all previous routes
    final nav = NavigatorService.navigatorKey.currentState ?? Navigator.of(context);
    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppErrorView(
      icon: Icons.lock_clock_rounded,
      title: 'Session Expired',
      message: 'Your session has expired. Please login again.',
      primaryButtonText: 'Login Again',
      onPrimaryPressed: () => _handleLoginAgain(context),
    );
  }
}
