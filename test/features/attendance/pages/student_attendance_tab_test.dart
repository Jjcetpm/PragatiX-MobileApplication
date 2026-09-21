import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/attendance/models/student_attendance_summary.dart';
import 'package:pragatix/features/attendance/pages/student_attendance_tab.dart';
import 'package:pragatix/features/attendance/providers/attendance_provider.dart';

class MockAttendanceProvider extends Mock implements AttendanceProvider {}

void main() {
  late MockAttendanceProvider mockAttendance;

  setUp(() {
    mockAttendance = MockAttendanceProvider();
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AttendanceProvider>.value(value: mockAttendance),
      ],
      child: const MaterialApp(
        home: StudentAttendanceTab(),
      ),
    );
  }

  group('StudentAttendanceTab Widget Tests', () {
    testWidgets('Renders dark header, overall attendance card, month metric card, and monthly overview calendar', (tester) async {
      final summary = StudentAttendanceSummary(
        attendancePercentage: 75.0,
        monthlyAttendancePercentage: 75.0,
        currentStreak: 3,
        totalPresentDays: 3,
        totalAbsentDays: 1,
      );

      when(() => mockAttendance.isLoading).thenReturn(false);
      when(() => mockAttendance.error).thenReturn(null);
      when(() => mockAttendance.summary).thenReturn(summary);
      when(() => mockAttendance.currentStreak).thenReturn(3);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Top Header
      expect(find.text('Attendance'), findsOneWidget);
      expect(find.text('Track your attendance & stay consistent.'), findsOneWidget);

      // Overall Attendance Card
      expect(find.text('Overall Attendance'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
      expect(find.text('Keep it up!'), findsOneWidget);
      expect(find.text('Present Days'), findsOneWidget);
      expect(find.text('Absent Days'), findsOneWidget);
      expect(find.text('Total Days'), findsOneWidget);

      // Month Metric Card
      expect(find.text('This Month'), findsOneWidget);

      // Monthly Overview Section
      expect(find.text('Monthly Overview'), findsOneWidget);
      expect(find.text('M'), findsOneWidget);
      expect(find.text('T'), findsAtLeastNWidgets(1));
      expect(find.text('W'), findsOneWidget);
      expect(find.text('F'), findsOneWidget);
      expect(find.text('S'), findsAtLeastNWidgets(1));

      // 4 Status Legends
      expect(find.text('Present (P)'), findsOneWidget);
      expect(find.text('Partial (P)'), findsOneWidget);
      expect(find.text('Absent (A)'), findsOneWidget);
      expect(find.text('Holiday (H)'), findsOneWidget);

      // History Header
      expect(find.text('Attendance History'), findsOneWidget);
      expect(find.text('All Dates'), findsOneWidget);
    });

    testWidgets('DayAttendanceSummary classifies full, partial, and full absent correctly', (tester) async {
      // Full Day Present
      final fullPresent = DayAttendanceSummary();
      fullPresent.addRecord('PRESENT');
      fullPresent.addRecord('PRESENT');
      expect(fullPresent.overallStatus, 'P');

      // Partial Day Present (1 absent, 1 present)
      final partial = DayAttendanceSummary();
      partial.addRecord('PRESENT');
      partial.addRecord('ABSENT');
      expect(partial.overallStatus, 'PARTIAL');

      // Full Day Absent
      final fullAbsent = DayAttendanceSummary();
      fullAbsent.addRecord('ABSENT');
      fullAbsent.addRecord('ABSENT');
      expect(fullAbsent.overallStatus, 'A');
    });
  });
}
