import 'package:flutter/material.dart';
import 'package:pragatix/core/error/widgets/app_error_view.dart';

class UploadErrorPage extends StatelessWidget {
  final VoidCallback? onRetry;
  final VoidCallback? onChooseAnother;
  final String? detailedReason;

  const UploadErrorPage({
    super.key,
    this.onRetry,
    this.onChooseAnother,
    this.detailedReason,
  });

  @override
  Widget build(BuildContext context) {
    return AppErrorView(
      icon: Icons.upload_file_rounded,
      title: 'Upload Failed',
      message: detailedReason ?? 'We couldn\'t upload your file. Please check the file and try again.',
      primaryButtonText: onRetry != null ? 'Try Again' : null,
      onPrimaryPressed: onRetry,
      secondaryButtonText: onChooseAnother != null ? 'Choose Another File' : null,
      onSecondaryPressed: onChooseAnother,
    );
  }
}
