import 'package:flutter/material.dart';
import 'package:pragatix/core/error/widgets/app_error_view.dart';

class ServerErrorPage extends StatelessWidget {
  final VoidCallback? onRetry;
  final VoidCallback? onBack;

  const ServerErrorPage({
    super.key,
    this.onRetry,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return AppErrorView(
      icon: Icons.error_outline_rounded,
      title: 'Something Went Wrong',
      message: 'The server encountered an unexpected error. Please try again later.',
      primaryButtonText: onRetry != null ? 'Retry' : null,
      onPrimaryPressed: onRetry,
      secondaryButtonText: onBack != null ? 'Go Back' : null,
      onSecondaryPressed: onBack,
    );
  }
}
