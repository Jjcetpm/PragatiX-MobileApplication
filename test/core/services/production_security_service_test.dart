import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pragatix/core/services/production_security_service.dart';
import 'package:pragatix/core/widgets/security_gate.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProductionSecurityService & SecurityCheckResult Tests', () {
    test('SecurityCheckResult.safe factory generates correct values', () {
      final safeResult = SecurityCheckResult.safe(isReleaseMode: false);
      expect(safeResult.isDebuggingEnabled, isFalse);
      expect(safeResult.isUsbDebugging, isFalse);
      expect(safeResult.isWirelessDebugging, isFalse);
      expect(safeResult.isReleaseMode, isFalse);
      expect(safeResult.hasError, isFalse);
    });

    test('SecurityCheckResult.blocked factory generates correct values', () {
      final blockedResult = SecurityCheckResult.blocked(
        isUsbDebugging: true,
        isWirelessDebugging: false,
      );
      expect(blockedResult.isDebuggingEnabled, isTrue);
      expect(blockedResult.isUsbDebugging, isTrue);
      expect(blockedResult.isWirelessDebugging, isFalse);
      expect(blockedResult.isReleaseMode, isTrue);
    });

    test('checkDebuggingState skips check in debug/testing mode', () async {
      final service = ProductionSecurityService.instance;
      final result = await service.checkDebuggingState();
      // In flutter_test environment, kReleaseMode is false
      expect(result.isDebuggingEnabled, isFalse);
      expect(result.isReleaseMode, isFalse);
      expect(service.currentStatus?.isDebuggingEnabled, isFalse);
    });
  });

  group('SecurityGate Widget Tests', () {
    testWidgets('SecurityGate renders child normally when debugging is disabled or in debug mode', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SecurityGate(
            child: Scaffold(
              body: Text('Protected Home Screen Content'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Protected Home Screen Content'), findsOneWidget);
      expect(find.text('Security Warning'), findsNothing);
    });
  });
}
