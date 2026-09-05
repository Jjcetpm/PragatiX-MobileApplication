import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/core/theme/app_theme.dart';
import 'package:pragatix/core/services/navigator_service.dart';
import 'package:pragatix/features/xp/providers/xp_provider.dart';
import 'package:pragatix/features/badge/providers/badge_provider.dart';
import 'package:pragatix/features/activity/providers/activity_completion_provider.dart';
import 'package:pragatix/features/student/pages/student_dashboard_page.dart';
import 'package:pragatix/features/teacher/pages/teacher_dashboard.dart';
import 'package:pragatix/features/admin/pages/admin_dashboard.dart';
import 'package:pragatix/features/admin/pages/super_admin_dashboard.dart';
import 'package:pragatix/features/captain/pages/captain_dashboard_page.dart';
import 'package:pragatix/features/auth/pages/login_page.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/shared/providers/student_search_provider.dart';
import 'package:pragatix/features/attendance/providers/attendance_provider.dart';
import 'package:pragatix/features/analytics/providers/xp_analytics_provider.dart';
import 'package:pragatix/features/penalty/providers/penalty_provider.dart';
import 'package:pragatix/features/admin/providers/department_provider.dart';
import 'package:pragatix/core/widgets/security_gate.dart';
import 'package:pragatix/core/widgets/server_maintenance_gate.dart';
import 'package:pragatix/core/services/server_status_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupLocator();

  // Check server health probe on startup
  ServerStatusService.instance.checkServerHealth();

  final authProvider = getIt<AuthProvider>();
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
        ChangeNotifierProvider(create: (_) => DepartmentProvider()),
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
      builder: (context, child) => SecurityGate(
        child: ServerMaintenanceGate(
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isAuthenticated) {
            final userType = auth.currentUser?['userType'] ?? '';
            final isCaptain =
                auth.currentUser?['teamRole'] == 'CAPTAIN' ||
                auth.currentUser?['teamRole'] == 'VICE_CAPTAIN';

            // Extract roles list from the stored user JSON.
            // This matches the routing logic in login_page.dart and correctly
            // handles Admin/Super Admin whose userType may be null/empty.
            final dynamic rawRoles = auth.currentUser?['roles'];
            final List<dynamic> storedRoles =
                rawRoles is List ? rawRoles : [];

            bool hasRole(String roleName) {
              for (var r in storedRoles) {
                if (r is String && r == roleName) return true;
                if (r is Map) {
                  final name = r['name'] ?? r['authority'] ?? '';
                  if (name == roleName) return true;
                }
              }
              return false;
            }

            // Super Admin â€” checked BEFORE Admin to avoid downgrade
            if (hasRole('ROLE_SUPER_ADMIN') || hasRole('ROLE_SUPERADMIN')) {
              return const SuperAdminDashboard();
            }

            // Admin
            if (hasRole('ROLE_ADMIN')) {
              return const AdminDashboard();
            }

            // Teacher / CC / HOD / Discipline Committee
            if (userType == 'TEACHER' ||
                hasRole('ROLE_TEACHER') ||
                hasRole('ROLE_DISCIPLINE_COMMITTEE')) {
              return const TeacherDashboard();
            }

            // Captain / Vice Captain (student leadership)
            if (userType == 'CAPTAIN' || isCaptain) {
              return const CaptainDashboardPage();
            }

            // Student
            if (userType == 'STUDENT' ||
                hasRole('ROLE_STUDENT') ||
                auth.role == 'STUDENT') {
              return const StudentDashboardPage();
            }

            // Unknown/corrupted role â€” force re-login
            return const LoginPage();
          }
          return const LoginPage();
        },
      ),
    );
  }
}