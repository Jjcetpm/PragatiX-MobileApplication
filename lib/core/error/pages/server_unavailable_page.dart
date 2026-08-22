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
      title: 'Server Unavailable',
      message: 'We couldn\'t connect to the server. Please try again later.',
      primaryButtonText: onRetry != null ? 'Retry' : null,
      onPrimaryPressed: onRetry,
      secondaryButtonText: onBack != null ? 'Go Back' : null,
      onSecondaryPressed: onBack,
    );
  }
}
