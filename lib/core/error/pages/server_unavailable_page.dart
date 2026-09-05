import 'package:flutter/material.dart';
import 'package:pragatix/core/error/widgets/app_error_view.dart';

class ServerUnavailablePage extends StatelessWidget {
  final VoidCallback? onRetry;
  final VoidCallback? onBack;

  const ServerUnavailablePage({
    super.key,
    this.onRetry,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return AppErrorView(
      icon: Icons.cloud_off_rounded,
      title: 'Server Under Maintenance',
      message: 'Server is currently under maintenance. Please try again later.\n\n(Daily maintenance window: 11:00 PM – 04:00 AM)',
      primaryButtonText: onRetry != null ? 'Retry' : null,
      onPrimaryPressed: onRetry,
      secondaryButtonText: onBack != null ? 'Go Back' : null,
      onSecondaryPressed: onBack,
    );
  }
}
