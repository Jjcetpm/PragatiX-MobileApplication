import 'package:flutter/material.dart';
import 'package:pragatix/core/error/widgets/app_error_view.dart';

class MaintenancePage extends StatelessWidget {
  final VoidCallback? onRetry;
  final VoidCallback? onHome;
  final String? maintenanceMessage;

  const MaintenancePage({
    super.key,
    this.onRetry,
    this.onHome,
    this.maintenanceMessage,
  });

  @override
  Widget build(BuildContext context) {
    return AppErrorView(
      icon: Icons.construction_rounded,
      title: 'Under Maintenance',
      message: maintenanceMessage ?? 'We\'re currently performing maintenance. Please try again later.',
      primaryButtonText: onRetry != null ? 'Try Again' : null,
      onPrimaryPressed: onRetry,
      secondaryButtonText: onHome != null ? 'Go Home' : null,
      onSecondaryPressed: onHome,
    );
  }
}
