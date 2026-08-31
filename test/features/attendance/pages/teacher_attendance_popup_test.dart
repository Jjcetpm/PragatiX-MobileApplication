import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:pragatix/features/attendance/models/student_attendance_list_item.dart';
import 'package:pragatix/features/attendance/pages/teacher_attendance_tab.dart';
import '../../../helpers/mocks.dart';
import '../../../helpers/test_wrapper.dart';

void main() {
  group('Mark Attendance Popup & Search Tests', () {
    late List<StudentAttendanceListItem> mockStudents;

    setUp(() {
      setupTestGetIt();
      mockStudents = [
        StudentAttendanceListItem(
          studentId: 101,
          studentName: 'Abhishek Gupta',
          registerNumber: '24CSC282',
          status: 'PRESENT',
        ),
        StudentAttendanceListItem(
          studentId: 102,
          studentName: 'Abhishek Kapoor',
          registerNumber: '24CSC120',
          status: 'PRESENT',
        ),
        StudentAttendanceListItem(
          studentId: 103,
          studentName: 'Anil Mehta',
          registerNumber: '24AID817',
          status: 'PRESENT',
        ),
        StudentAttendanceListItem(
          studentId: 104,
          studentName: 'Deepa Roy',
          registerNumber: '24CYS647',
          status: 'ABSENT',
        ),
      ];
    });

    testWidgets('Renders all loaded students initially and displays count', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          TestWrapper(
            child: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => Dialog(
                          insetPadding: EdgeInsets.zero,
                          child: AttendancePopupContent(
                            initialStudents: mockStudents,
                            onSave: (_) {},
                          ),
                        ),
                      );
                    },
                    child: const Text('Open'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(find.text('Mark Attendance'), findsOneWidget);
        expect(find.text('4 Students'), findsOneWidget);
        expect(find.text('Abhishek Gupta'), findsOneWidget);
        expect(find.text('Abhishek Kapoor'), findsOneWidget);
        expect(find.text('Anil Mehta'), findsOneWidget);
        expect(find.text('Deepa Roy'), findsOneWidget);
      });
    });

    testWidgets('Filters students by name in real-time', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          TestWrapper(
            child: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => Dialog(
                          insetPadding: EdgeInsets.zero,
                          child: AttendancePopupContent(
                            initialStudents: mockStudents,
                            onSave: (_) {},
                          ),
                        ),
                      );
                    },
                    child: const Text('Open'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        // Type 'Deepa' into search bar
        await tester.enterText(find.byType(TextField), 'Deepa');
        await tester.pumpAndSettle();

        expect(find.text('1 / 4 Students'), findsOneWidget);
        expect(find.text('Deepa Roy'), findsOneWidget);
        expect(find.text('Abhishek Gupta'), findsNothing);
        expect(find.text('Anil Mehta'), findsNothing);
      });
    });

    testWidgets('Filters students by register/roll number in real-time', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          TestWrapper(
            child: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => Dialog(
                          insetPadding: EdgeInsets.zero,
                          child: AttendancePopupContent(
                            initialStudents: mockStudents,
                            onSave: (_) {},
                          ),
                        ),
                      );
                    },
                    child: const Text('Open'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        // Search by roll no '24AID817'
        await tester.enterText(find.byType(TextField), '24AID817');
        await tester.pumpAndSettle();

        expect(find.text('1 / 4 Students'), findsOneWidget);
        expect(find.text('Anil Mehta'), findsOneWidget);
        expect(find.text('Abhishek Gupta'), findsNothing);
      });
    });

    testWidgets('Displays empty state when no students match search query', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          TestWrapper(
            child: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => Dialog(
                          insetPadding: EdgeInsets.zero,
                          child: AttendancePopupContent(
                            initialStudents: mockStudents,
                            onSave: (_) {},
                          ),
                        ),
                      );
                    },
                    child: const Text('Open'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'NonExistentStudent');
        await tester.pumpAndSettle();

        expect(find.text('No students found matching "NonExistentStudent"'), findsOneWidget);
        expect(find.text('0 / 4 Students'), findsOneWidget);
      });
    });

    testWidgets('Toggles student status and saves updated list', (tester) async {
      List<StudentAttendanceListItem>? savedResult;

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          TestWrapper(
            child: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => Dialog(
                          insetPadding: EdgeInsets.zero,
                          child: AttendancePopupContent(
                            initialStudents: mockStudents,
                            onSave: (list) {
                              savedResult = list;
                            },
                          ),
                        ),
                      );
                    },
                    child: const Text('Open'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        // Search for Anil Mehta and toggle to ABSENT
        await tester.enterText(find.byType(TextField), 'Anil');
        await tester.pumpAndSettle();

        expect(find.text('Anil Mehta'), findsOneWidget);
        // Find segment 'A' for Anil
        await tester.tap(find.text('A'));
        await tester.pumpAndSettle();

        // Clear search
        await tester.tap(find.byIcon(Icons.cancel_rounded));
        await tester.pumpAndSettle();

        expect(find.text('4 Students'), findsOneWidget);

        // Click Save Attendance
        await tester.tap(find.text('Save Attendance'));
        await tester.pumpAndSettle();

        expect(savedResult, isNotNull);
        expect(savedResult!.length, 4);
        final anil = savedResult!.firstWhere((s) => s.studentId == 103);
        expect(anil.status, 'ABSENT');
      });
    });
  });
}
