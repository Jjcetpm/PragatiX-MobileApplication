import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/core/theme/app_theme.dart';
import 'package:pragatix/core/services/navigator_service.dart';
import 'package:pragatix/core/services/loading_service.dart';
import 'package:pragatix/features/xp/providers/xp_provider.dart';
import 'package:pragatix/features/badge/providers/badge_provider.dart';
import 'package:pragatix/features/activity/providers/activity_completion_provider.dart';
import 'package:pragatix/features/student/pages/student_dashboard_page.dart';
import 'package:pragatix/features/teacher/pages/teacher_dashboard.dart';
import 'package:pragatix/features/admin/pages/admin_dashboard.dart';
import 'package:pragatix/features/captain/pages/captain_dashboard_page.dart';
import 'package:pragatix/features/auth/pages/login_page.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/shared/providers/student_search_provider.dart';
import 'package:pragatix/features/attendance/providers/attendance_provider.dart';
import 'package:pragatix/features/analytics/providers/xp_analytics_provider.dart';
import 'package:pragatix/features/penalty/providers/penalty_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupLocator();

  final authProvider = getIt<AuthProvider>();
  
  // Show loader during initial auth check if possible
  // Since runApp hasn't been called yet, the overlay is not available.
  // The login page itself can handle the loading state if needed.
  await authProvider.checkAuthStatus();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => authProvider),
        ChangeNotifierProvider(create: (_) => getIt<XpProvider>()),
        ChangeNotifierProvider(create: (_) => getIt<BadgeProvider>()),
        ChangeNotifierProvider(create: (_) => getIt<PenaltyProvider>()),
        ChangeNotifierProvider(create: (_) => StudentSearchProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(
          create: (_) => getIt<ActivityCompletionProvider>(),
        ),
        ChangeNotifierProvider(create: (_) => getIt<XpAnalyticsProvider>()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NavigatorService.navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'pragatiX – Track. Learn. Grow.',
      theme: AppTheme.light(),
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isAuthenticated) {
            final role = auth.role ?? '';
            final userType = auth.currentUser?['userType'] ?? '';
            final isCaptain =
                auth.currentUser?['teamRole'] == 'CAPTAIN' ||
                auth.currentUser?['teamRole'] == 'VICE_CAPTAIN';

            if (role == 'ROLE_ADMIN') {
              return const AdminDashboard();
            } else if (userType == 'TEACHER' ||
                role == 'ROLE_TEACHER' ||
                role == 'ROLE_DISCIPLINE_COMMITTEE') {
              return const TeacherDashboard();
            } else if (userType == 'CAPTAIN' || isCaptain) {
              return const CaptainDashboardPage();
            } else if (role == 'ROLE_STUDENT' ||
                userType == 'STUDENT' ||
                role == 'STUDENT') {
              return const StudentDashboardPage();
            } else {
              // Unknown role or missing data
              return const LoginPage();
            }
          }
          return const LoginPage();
        },
      ),
    );
  }
}
