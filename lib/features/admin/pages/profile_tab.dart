import 'package:flutter/material.dart';
import 'package:pragatix/features/admin/repository/admin_repository.dart';
import 'package:pragatix/shared/widgets/profile_header.dart';
import 'package:pragatix/shared/widgets/shared_profile_card.dart';
import 'package:pragatix/shared/widgets/shared_logout_button.dart';
import 'package:pragatix/core/di/service_locator.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool _isLoading = true;
  String _name = 'Administrator';
  String _email = 'admin@pragatix.com';
  String _role = 'ADMIN';

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final d = await getIt<AdminRepository>().getCurrentUser();
      setState(() {
        _name = d['fullName'] ?? d['username'] ?? 'Administrator';
        _email = d['email'] ?? '';
        _role = d['role'] ?? 'ADMIN';
        _isLoading = false;
      });
      return;
    } catch (e) {
      // fallback
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Profile',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              color: const Color(0xFFF1F5F9),
              width: double.infinity,
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  SharedProfileHeader(
                    title: _name,
                    subtitle: _email,
                    icon: Icons.admin_panel_settings_rounded,
                    radius: 60,
                  ),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: SharedProfileCard(
                      children: [
                        SharedProfileRow(
                          label: 'Role',
                          value: _role.replaceAll('ROLE_', ''),
                        ),
                        const Divider(height: 24),
                        const SharedProfileRow(
                          label: 'Access Level',
                          value: 'Full System Access',
                        ),
                        const Divider(height: 24),
                        const SharedProfileRow(
                          label: 'Application',
                          value: 'pragatiX',
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: SharedLogoutButton(
                      backgroundColor: Color(0xFFEA4335),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
