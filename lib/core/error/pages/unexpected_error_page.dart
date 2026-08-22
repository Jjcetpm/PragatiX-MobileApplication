import 'package:flutter/material.dart';
import 'package:pragatix/core/error/widgets/app_error_view.dart';

class UnexpectedErrorPage extends StatelessWidget {
  final VoidCallback? onRetry;
  final VoidCallback? onHome;

  const UnexpectedErrorPage({
    super.key,
    this.onRetry,
    this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    return AppErrorView(
      icon: Icons.warning_amber_rounded,
      title: 'Unexpected Error',
      message: 'Something unexpected happened. Please try again.',
      primaryButtonText: onRetry != null ? 'Retry' : null,
      onPrimaryPressed: onRetry,
      secondaryButtonText: onHome != null ? 'Go Home' : null,
      onSecondaryPressed: onHome,
    );
  }
}
