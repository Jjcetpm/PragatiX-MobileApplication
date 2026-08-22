import 'package:flutter/material.dart';
import 'package:pragatix/core/error/error_type.dart';
import 'package:pragatix/core/error/error_mapper.dart';
import 'package:pragatix/core/theme/app_colors.dart';

class ErrorDebugPage extends StatelessWidget {
  const ErrorDebugPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error Pages Debug'),
        backgroundColor: AppColors.darkSlate,
        foregroundColor: Colors.white,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: AppErrorType.values.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final type = AppErrorType.values[index];
          return ListTile(
            title: Text(type.name),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(
                      title: Text(type.name),
                      backgroundColor: AppColors.darkSlate,
                      foregroundColor: Colors.white,
                    ),
                    body: AppErrorMapper.getErrorPage(
                      type,
                      onRetry: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Retry clicked')),
                      ),
                      onBack: () => Navigator.of(context).pop(),
                      onHome: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Go Home clicked')),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
