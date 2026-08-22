import 'package:flutter/material.dart';
import 'package:pragatix/core/error/widgets/app_error_view.dart';

class RequestTimeoutPage extends StatelessWidget {
  final VoidCallback? onRetry;
  final VoidCallback? onBack;

  const RequestTimeoutPage({
    super.key,
    this.onRetry,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return AppErrorView(
      icon: Icons.timer_off_rounded,
      title: 'Request Timed Out',
      message: 'The server took too long to respond. Please try again.',
      primaryButtonText: onRetry != null ? 'Retry' : null,
      onPrimaryPressed: onRetry,
      secondaryButtonText: onBack != null ? 'Go Back' : null,
      onSecondaryPressed: onBack,
    );
  }
}
