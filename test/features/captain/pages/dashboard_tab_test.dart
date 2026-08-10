import 'package:flutter_test/flutter_test.dart';
import 'package:pragatix/features/captain/pages/dashboard_tab.dart';
import '../../../helpers/test_wrapper.dart';

void main() {
  group('Captain DashboardTab Widget Tests', () {
    testWidgets('renders dashboard text correctly', (tester) async {
      await tester.pumpWidget(
        const TestWrapper(
          child: DashboardTab(),
        ),
      );

      expect(find.text('Dashboard Tab'), findsOneWidget);
    });
  });
}
