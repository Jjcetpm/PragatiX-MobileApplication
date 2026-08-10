import 'package:get_it/get_it.dart';

// Providers
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/features/xp/providers/xp_provider.dart';
import 'package:pragatix/features/badge/providers/badge_provider.dart';
import 'package:pragatix/features/activity/providers/activity_provider.dart';
import 'package:pragatix/features/activity/providers/activity_completion_provider.dart';
import 'package:pragatix/features/analytics/providers/xp_analytics_provider.dart';
import 'package:pragatix/features/penalty/providers/penalty_provider.dart';

// Services
import 'package:pragatix/features/activity/services/activity_proxy_service.dart';
import 'package:pragatix/features/activity/services/activity_service.dart';
import 'package:pragatix/features/activity/services/cc_activity_service.dart';
import 'package:pragatix/features/activity/services/group_activity_service.dart';
import 'package:pragatix/features/activity/services/activity_completion_service.dart';
import 'package:pragatix/features/admin/services/admin_proxy_service.dart';
import 'package:pragatix/features/admin/services/admin_service.dart';
import 'package:pragatix/features/auth/services/auth_service.dart';
import 'package:pragatix/features/captain/services/captain_proxy_service.dart';
import 'package:pragatix/features/captain/services/captain_service.dart';
import 'package:pragatix/features/penalty/services/penalty_service.dart';
import 'package:pragatix/features/student/services/student_proxy_service.dart';
import 'package:pragatix/features/student/services/student_service.dart';
import 'package:pragatix/features/teacher/services/teacher_proxy_service.dart';
import 'package:pragatix/features/teacher/services/teacher_service.dart';
import 'package:pragatix/features/team/services/team_proxy_service.dart';
import 'package:pragatix/features/leaderboard/services/leaderboard_service.dart';
import 'package:pragatix/features/analytics/services/xp_analytics_service.dart';

// Repositories
import 'package:pragatix/features/activity/repository/activity_repository.dart';
import 'package:pragatix/features/badge/repository/badge_repository.dart';
import 'package:pragatix/features/admin/repository/admin_repository.dart';
import 'package:pragatix/features/auth/repository/auth_repository.dart';
import 'package:pragatix/features/captain/repository/captain_repository.dart';
import 'package:pragatix/features/student/repository/student_repository.dart';
import 'package:pragatix/features/teacher/repository/teacher_repository.dart';

final getIt = GetIt.instance;

void setupLocator() {
  // 1. Providers
  getIt.registerLazySingleton(() => AuthProvider());
  getIt.registerLazySingleton(() => XpProvider());
  getIt.registerLazySingleton(() => BadgeProvider());
  getIt.registerLazySingleton(() => PenaltyProvider(getIt<PenaltyService>()));
  getIt.registerFactory(() => ActivityProvider(getIt<ActivityRepository>()));
  getIt.registerLazySingleton(
    () => ActivityCompletionProvider(getIt<ActivityCompletionService>()),
  );
  getIt.registerLazySingleton(() => XpAnalyticsProvider());

  // 2. Services
  getIt.registerLazySingleton(() => AuthService());
  getIt.registerLazySingleton(() => AdminService(getIt<AuthProvider>()));
  getIt.registerLazySingleton(() => ActivityService(getIt<AuthProvider>()));
  getIt.registerLazySingleton(() => CCActivityService(getIt<AuthProvider>()));
  getIt.registerLazySingleton(
    () => ActivityCompletionService(getIt<AuthProvider>()),
  );
  getIt.registerLazySingleton(() => CaptainService(getIt<AuthProvider>()));
  getIt.registerLazySingleton(() => PenaltyService(getIt<AuthProvider>()));
  getIt.registerLazySingleton(
    () => GroupActivityService(getIt<AuthProvider>()),
  );
  getIt.registerLazySingleton(() => StudentService(getIt<AuthProvider>()));
  getIt.registerLazySingleton(() => TeacherService(getIt<AuthProvider>()));
  getIt.registerLazySingleton(() => LeaderboardService(getIt<AuthProvider>()));
  getIt.registerLazySingleton(() => XpAnalyticsService());

  // Proxy Services
  getIt.registerLazySingleton(() => ActivityProxyService());
  getIt.registerLazySingleton(() => AdminProxyService());
  getIt.registerLazySingleton(() => CaptainProxyService());
  getIt.registerLazySingleton(() => StudentProxyService());
  getIt.registerLazySingleton(() => TeacherProxyService());
  getIt.registerLazySingleton(() => TeamProxyService());

  // 3. Repositories
  getIt.registerLazySingleton(
    () => ActivityRepository(getIt<ActivityService>()),
  );
  getIt.registerLazySingleton(() => AdminRepository(getIt<AdminService>()));
  getIt.registerLazySingleton(() => BadgeRepository());
  getIt.registerLazySingleton(() => AuthRepository(getIt<AuthService>()));
  getIt.registerLazySingleton(() => CaptainRepository(getIt<CaptainService>()));
  getIt.registerLazySingleton(() => StudentRepository(getIt<StudentService>()));
  getIt.registerLazySingleton(() => TeacherRepository(getIt<TeacherService>()));
}
