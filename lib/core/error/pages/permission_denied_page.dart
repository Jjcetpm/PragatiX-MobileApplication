import 'package:flutter/material.dart';
import 'package:pragatix/core/error/widgets/app_error_view.dart';

class PermissionDeniedPage extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onHome;

  const PermissionDeniedPage({
    super.key,
    this.onBack,
    this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    return AppErrorView(
      icon: Icons.gpp_bad_rounded,
      title: 'Access Denied',
      message: 'You do not have permission to perform this action.',
      primaryButtonText: onBack != null ? 'Go Back' : null,
      onPrimaryPressed: onBack,
      secondaryButtonText: onHome != null ? 'Go Home' : null,
      onSecondaryPressed: onHome,
    );
  }
}
