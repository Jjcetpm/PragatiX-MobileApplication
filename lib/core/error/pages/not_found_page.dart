import 'package:flutter/material.dart';
import 'package:pragatix/core/error/widgets/app_error_view.dart';

class NotFoundPage extends StatelessWidget {
  final VoidCallback? onHome;
  final VoidCallback? onBack;

  const NotFoundPage({
    super.key,
    this.onHome,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return AppErrorView(
      icon: Icons.search_off_rounded,
      title: 'Page Not Found',
      message: 'The page or resource you\'re looking for could not be found.',
      primaryButtonText: onHome != null ? 'Go Home' : null,
      onPrimaryPressed: onHome,
      secondaryButtonText: onBack != null ? 'Go Back' : null,
      onSecondaryPressed: onBack,
    );
  }
}
