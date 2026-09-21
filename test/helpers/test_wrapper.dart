import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/features/auth/repository/auth_repository.dart';
import 'package:pragatix/features/admin/repository/admin_repository.dart';
import 'package:pragatix/features/activity/repository/activity_repository.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'mocks.dart';

/// A wrapper to provide necessary context and providers for widget tests.
class TestWrapper extends StatelessWidget {
  final Widget child;
  final AuthProvider? mockAuthProvider;

  const TestWrapper({
    super.key,
    required this.child,
    this.mockAuthProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(
          value: mockAuthProvider ?? MockAuthProvider(),
        ),
      ],
      child: MaterialApp(
        home: child,
        // Add any necessary theme or routing setup here
      ),
    );
  }
}

/// Reset and setup getIt for a fresh test environment
void setupTestGetIt({
  MockAdminRepository? adminRepo,
  MockActivityRepository? activityRepo,
  MockAuthRepository? authRepo,
  AuthProvider? authProvider,
}) {
  if (getIt.isRegistered<AuthProvider>()) {
    getIt.unregister<AuthProvider>();
  }
  if (authProvider != null) {
    getIt.registerSingleton<AuthProvider>(authProvider);
  }

  if (getIt.isRegistered<AdminRepository>()) {
    getIt.unregister<AdminRepository>();
  }
  if (adminRepo != null) {
    getIt.registerSingleton<AdminRepository>(adminRepo);
  }

  if (getIt.isRegistered<ActivityRepository>()) {
    getIt.unregister<ActivityRepository>();
  }
  if (activityRepo != null) {
    getIt.registerSingleton<ActivityRepository>(activityRepo);
  }

  if (getIt.isRegistered<AuthRepository>()) {
    getIt.unregister<AuthRepository>();
  }
  if (authRepo != null) {
    getIt.registerSingleton<AuthRepository>(authRepo);
  }

  // Register fallback values for mocktail
  registerFallbackValues();
}
