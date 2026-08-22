import 'package:flutter/material.dart';
import 'package:pragatix/core/error/widgets/app_error_view.dart';

class NoInternetPage extends StatelessWidget {
  final VoidCallback? onRetry;
  final VoidCallback? onBack;

  const NoInternetPage({
    super.key,
    this.onRetry,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return AppErrorView(
      icon: Icons.wifi_off_rounded,
      title: 'No Internet Connection',
      message: 'Please check your internet connection and try again.',
      primaryButtonText: onRetry != null ? 'Retry' : null,
      onPrimaryPressed: onRetry,
      secondaryButtonText: onBack != null ? 'Go Back' : null,
      onSecondaryPressed: onBack,
    );
  }
}
