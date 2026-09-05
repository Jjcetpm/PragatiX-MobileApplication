import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pragatix/core/exceptions/api_exception.dart';
import 'package:pragatix/core/utils/error_handler.dart';
import 'package:pragatix/core/error/error_type.dart';
import 'package:pragatix/core/error/error_mapper.dart';
import 'package:pragatix/core/services/server_status_service.dart';
import 'package:pragatix/core/widgets/server_maintenance_gate.dart';

void main() {
  group('Centralized Error Classification Tests', () {
    // 1. No Internet -> NO_INTERNET
    test('1. No Internet -> NO_INTERNET', () {
      final e1 = NoInternetException();
      final c1 = ErrorHandler.classify(e1);
      expect(c1.category, NetworkErrorCategory.noInternet);
      expect(c1.title, 'No Internet Connection');
      expect(c1.message, 'Please check your internet connection and try again.');
      expect(AppErrorMapper.fromException(e1), AppErrorType.noInternet);

      final e2 = const SocketException('Network is unreachable');
      final c2 = ErrorHandler.classify(e2);
      expect(c2.category, NetworkErrorCategory.noInternet);
      expect(c2.title, 'No Internet Connection');
      expect(c2.message, 'Please check your internet connection and try again.');

      final e3 = const SocketException('Network is down');
      final c3 = ErrorHandler.classify(e3);
      expect(c3.category, NetworkErrorCategory.noInternet);
      expect(c3.title, 'No Internet Connection');
      expect(c3.message, 'Please check your internet connection and try again.');
    });

    // 2. Internet available + connection refused -> SERVER_UNAVAILABLE
    test('2. Internet available + connection refused -> SERVER_UNAVAILABLE', () {
      final e = const SocketException('Connection refused, errno = 111');
      final c = ErrorHandler.classify(e);
      expect(c.category, NetworkErrorCategory.serverUnavailable);
      expect(c.title, 'Server is currently under maintenance.');
      expect(c.message, 'Please try again later.');
      expect(AppErrorMapper.fromException(e), AppErrorType.maintenance);
    });

    // 3. Internet available + timeout -> SERVER_UNAVAILABLE
    test('3. Internet available + timeout -> SERVER_UNAVAILABLE', () {
      final e1 = TimeoutException('Request timed out after 25s');
      final c1 = ErrorHandler.classify(e1);
      expect(c1.category, NetworkErrorCategory.serverUnavailable);
      expect(c1.title, 'Server is currently under maintenance.');
      expect(c1.message, 'Please try again later.');
      expect(AppErrorMapper.fromException(e1), AppErrorType.maintenance);

      final e2 = const SocketException('Connection timed out');
      final c2 = ErrorHandler.classify(e2);
      expect(c2.category, NetworkErrorCategory.serverUnavailable);
      expect(c2.title, 'Server is currently under maintenance.');
      expect(c2.message, 'Please try again later.');
    });

    // 4. HTTP 503 -> SERVER_ERROR / maintenance
    test('4. HTTP 503 -> SERVER_ERROR / maintenance', () {
      final e = ApiException(503, 'Service Unavailable');
      final c = ErrorHandler.classify(e);
      expect(c.category, NetworkErrorCategory.serverUnavailable);
      expect(c.title, 'Server is currently under maintenance.');
      expect(c.message, 'Please try again later.');
      expect(AppErrorMapper.fromException(e), AppErrorType.maintenance);
    });

    // 5. HTTP 500 -> SERVER_ERROR (shows Server Error with actual backend message, NOT maintenance)
    test('5. HTTP 500 -> SERVER_ERROR', () {
      final e = ApiException(500, 'Internal Server Error');
      final c = ErrorHandler.classify(e);
      expect(c.category, NetworkErrorCategory.serverError);
      expect(c.title, 'Server Error');
      expect(c.message, 'Internal Server Error');
      expect(AppErrorMapper.fromException(e), AppErrorType.serverError);
    });

    // 6. HTTP 401 -> CLIENT/AUTH ERROR (preserve auth)
    test('6. HTTP 401 -> CLIENT/AUTH ERROR', () {
      final e = ApiException(401, 'Session expired. Please login again.');
      final c = ErrorHandler.classify(e);
      expect(c.category, NetworkErrorCategory.clientError);
      expect(c.title, 'Session Expired');
      expect(c.message, 'Session expired. Please login again.');
      expect(AppErrorMapper.fromException(e), AppErrorType.unauthorized);
    });

    // 7. HTTP 403 -> CLIENT/AUTH ERROR (preserve permissions)
    test('7. HTTP 403 -> CLIENT/AUTH ERROR', () {
      final e = ApiException(403, 'Forbidden');
      final c = ErrorHandler.classify(e);
      expect(c.category, NetworkErrorCategory.clientError);
      expect(c.title, 'Permission Denied');
      expect(c.message, 'You do not have permission to perform this action.');
      expect(AppErrorMapper.fromException(e), AppErrorType.permissionDenied);
    });

    // 8. Successful response -> SUCCESS
    test('8. Successful response -> SUCCESS', () {
      final c = ErrorHandler.classify(null);
      expect(c.category, NetworkErrorCategory.success);
      expect(c.title, 'Success');
      expect(c.message, '');
    });

    // 9. ServerStatusService manages maintenance mode reactively
    test('9. ServerStatusService manages maintenance mode reactively', () {
      final service = ServerStatusService.instance;
      service.setMaintenanceMode(false);
      expect(service.isMaintenanceMode.value, isFalse);

      service.setMaintenanceMode(true, message: 'Custom maintenance message');
      expect(service.isMaintenanceMode.value, isTrue);
      expect(service.maintenanceMessage, 'Custom maintenance message');

      service.setMaintenanceMode(false, message: 'Please try again later.');
      expect(service.isMaintenanceMode.value, isFalse);
      expect(service.maintenanceMessage, 'Please try again later.');
    });

    // 10. ServerMaintenanceGate completely blocks page navigation when maintenance is active
    testWidgets('10. ServerMaintenanceGate completely blocks page navigation when maintenance is active', (tester) async {
      final service = ServerStatusService.instance;
      service.setAllOnline();

      await tester.pumpWidget(
        MaterialApp(
          home: ServerMaintenanceGate(
            enableAutoProbe: false,
            child: const Scaffold(
              body: Center(child: Text('Normal Dashboard Content')),
            ),
          ),
        ),
      );

      // When maintenance is off, normal content is visible
      expect(find.text('Normal Dashboard Content'), findsOneWidget);
      expect(find.text('Server is currently under maintenance.'), findsNothing);

      // Trigger maintenance mode
      service.setMaintenanceMode(true);
      await tester.pumpAndSettle();

      // Normal content is completely hidden
      expect(find.text('Normal Dashboard Content'), findsNothing);

      // Maintenance page takes over completely
      expect(find.text('Server is currently under maintenance.'), findsOneWidget);
      expect(find.text('Please try again later.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byIcon(Icons.construction_rounded), findsOneWidget);

      // Reset back to normal
      service.setAllOnline();
      await tester.pumpAndSettle();
      expect(find.text('Normal Dashboard Content'), findsOneWidget);
    });

    // 11. ServerMaintenanceGate displays NoInternetPage when device network is OFF
    testWidgets('11. ServerMaintenanceGate displays NoInternetPage when device network is OFF', (tester) async {
      final service = ServerStatusService.instance;
      service.setAllOnline();

      await tester.pumpWidget(
        MaterialApp(
          home: ServerMaintenanceGate(
            enableAutoProbe: false,
            child: const Scaffold(
              body: Center(child: Text('Normal Dashboard Content')),
            ),
          ),
        ),
      );

      // Trigger No Internet Mode (Device network is OFF)
      service.setNoInternetMode(true);
      await tester.pumpAndSettle();

      // Normal content is completely hidden
      expect(find.text('Normal Dashboard Content'), findsNothing);

      // Must display No Internet Page, NOT maintenance page!
      expect(find.text('No Internet Connection'), findsOneWidget);
      expect(find.text('Please check your internet connection and try again.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
      expect(find.text('Server is currently under maintenance.'), findsNothing);

      // Reset back to normal
      service.setAllOnline();
      await tester.pumpAndSettle();
      expect(find.text('Normal Dashboard Content'), findsOneWidget);
      expect(find.text('No Internet Connection'), findsNothing);
    });
  });
}
