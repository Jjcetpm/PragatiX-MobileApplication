import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/core/config/api_config.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pragatix/features/student/services/student_proxy_service.dart';
import 'package:pragatix/shared/widgets/profile_header.dart';
import 'package:pragatix/shared/widgets/shared_profile_card.dart';
import 'package:pragatix/shared/widgets/shared_logout_button.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/attendance/providers/attendance_provider.dart';
import 'package:pragatix/features/attendance/widgets/fire_streak_icon.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool isLoading = true;
  String studentName = 'Sharugesh';
  String regNo = '24CS036';
  String email = 'sharugesh@college.edu';
  String department = 'Computer Science';
  String section = 'A';
  String year = 'III';
  String sprNo = 'SPR-2024-089';
  String semester = 'VI Semester';
  String phone = '+91 98765 43210';
  int score = 95;
  int streak = 12;
  String teamRole = 'STUDENT';
  String teamName = 'No Team';
  int rank = 0;
  String currentLevel = '1';

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    if (context.read<AuthProvider>().token! == 'debug_token') {
      setState(() {
        isLoading = false;
      });
      return;
    }
    try {
      final response = await getIt<StudentProxyService>().get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/me'),
        headers: {
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final resData = data['data'];
          setState(() {
            studentName = resData['fullName'] ?? 'Sharugesh';
            regNo = resData['username'] ?? '24CS036';
            email = resData['email'] ?? 'sharugesh@college.edu';
            section = resData['section'] ?? 'A';
            year = resData['year'] ?? 'III';
            sprNo = resData['sprNo'] ?? 'SPR-2024-089';
            semester = resData['semester'] ?? 'VI Semester';
            phone = resData['phone'] ?? '+91 98765 43210';
            department = resData['department'] ?? 'Computer Science';
            teamRole =
                resData['userType']?.toString().replaceAll('_', ' ') ??
                'STUDENT';
            teamName = resData['teamName'] ?? 'No Team';
            if (teamName.isEmpty) teamName = 'No Team';
            rank = resData['rank'] ?? 0;
            currentLevel = resData['currentLevel']?.toString() ?? '1';
            isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      // Keep mock values
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          Consumer<AttendanceProvider>(
            builder: (context, provider, child) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: FireStreakIcon(streakCount: provider.currentStreak),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 36),
              SharedProfileHeader(
                title: studentName,
                subtitle: 'Register ID: $regNo',
                icon: Icons.person_outline_rounded,
                radius: 54,
                isCaptain: teamRole == 'CAPTAIN',
                isViceCaptain: teamRole == 'VICE CAPTAIN',
              ),
              const SizedBox(height: 24),

              // Details Card
              SharedProfileCard(
                children: [
                  SharedProfileRow(label: 'Role', value: teamRole),
                  const Divider(height: 20, thickness: 0.8),
                  SharedProfileRow(label: 'Team Name', value: teamName),
                  const Divider(height: 20, thickness: 0.8),
                  SharedProfileRow(label: 'Level', value: currentLevel),
                  const Divider(height: 20, thickness: 0.8),
                  SharedProfileRow(label: 'Rank', value: '#$rank'),
                  const Divider(height: 20, thickness: 0.8),
                  SharedProfileRow(label: 'Full Name', value: studentName),
                  const Divider(height: 20, thickness: 0.8),
                  SharedProfileRow(label: 'Register No.', value: regNo),
                  const Divider(height: 20, thickness: 0.8),
                  SharedProfileRow(label: 'SPR No.', value: sprNo),
                  const Divider(height: 20, thickness: 0.8),
                  SharedProfileRow(
                    label: 'Academic Year',
                    value: '$year Year - Sec $section',
                  ),
                  const Divider(height: 20, thickness: 0.8),
                  SharedProfileRow(label: 'Semester', value: semester),
                  const Divider(height: 20, thickness: 0.8),
                  SharedProfileRow(label: 'Department', value: department),
                  const Divider(height: 20, thickness: 0.8),
                  SharedProfileRow(label: 'Email Address', value: email),
                  const Divider(height: 20, thickness: 0.8),
                  SharedProfileRow(label: 'Phone No.', value: phone),
                ],
              ),

              const SizedBox(height: 40),

              const SharedLogoutButton(backgroundColor: Color(0xFF4F46E5)),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
