import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/core/theme/app_colors.dart';
import 'package:pragatix/features/auth/pages/login_page.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';

class SharedLogoutButton extends StatelessWidget {
  final Color backgroundColor;

  const SharedLogoutButton({
    super.key,
    this.backgroundColor = AppColors.adminPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Sign Out'),
              content: const Text('Are you sure you want to sign out?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    ).logout();
                    if (!context.mounted) return;
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/',
                      (route) => false,
                    );
                  },
                  child: const Text(
                    'Sign Out',
                    style: TextStyle(color: AppColors.danger),
                  ),
                ),
              ],
            ),
          );
        },
        icon: const Icon(Icons.logout_rounded, color: Colors.white),
        label: const Text(
          'Sign Out',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
