import 'package:flutter/material.dart';
import 'package:pragatix/core/error/widgets/app_error_view.dart';

class EmptyDataPage extends StatelessWidget {
  final String? title;
  final String? message;
  final IconData? icon;
  final String? primaryButtonText;
  final VoidCallback? onPrimaryPressed;

  const EmptyDataPage({
    super.key,
    this.title,
    this.message,
    this.icon,
    this.primaryButtonText,
    this.onPrimaryPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppErrorView(
      icon: icon ?? Icons.inbox_rounded,
      title: title ?? 'No Data Available',
      message: message ?? 'There is nothing to display here yet.',
      primaryButtonText: primaryButtonText,
      onPrimaryPressed: onPrimaryPressed,
    );
  }
}
