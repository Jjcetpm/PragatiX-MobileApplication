import 'package:flutter/material.dart';
import 'package:pragatix/core/error/widgets/app_error_view.dart';

class DownloadErrorPage extends StatelessWidget {
  final VoidCallback? onRetry;
  final VoidCallback? onBack;

  const DownloadErrorPage({
    super.key,
    this.onRetry,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return AppErrorView(
      icon: Icons.file_download_off_rounded,
      title: 'Download Failed',
      message: 'We couldn\'t download the file. Please try again.',
      primaryButtonText: onRetry != null ? 'Retry Download' : null,
      onPrimaryPressed: onRetry,
      secondaryButtonText: onBack != null ? 'Go Back' : null,
      onSecondaryPressed: onBack,
    );
  }
}
