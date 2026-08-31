import 'package:flutter_test/flutter_test.dart';
import 'package:pragatix/shared/providers/student_search_provider.dart';

void main() {
  group('StudentSearchProvider Normalization & Filtering Tests', () {
    test('normalizeYear handles various formats properly', () {
      expect(StudentSearchProvider.normalizeYear('1'), '1');
      expect(StudentSearchProvider.normalizeYear('Year 1'), '1');
      expect(StudentSearchProvider.normalizeYear('1st Year'), '1');
      expect(StudentSearchProvider.normalizeYear('First Year'), '1');
      expect(StudentSearchProvider.normalizeYear('I'), '1');

      expect(StudentSearchProvider.normalizeYear('2'), '2');
      expect(StudentSearchProvider.normalizeYear('Year 2'), '2');
      expect(StudentSearchProvider.normalizeYear('2nd Year'), '2');
      expect(StudentSearchProvider.normalizeYear('Second Year'), '2');
      expect(StudentSearchProvider.normalizeYear('II'), '2');

      expect(StudentSearchProvider.normalizeYear('3'), '3');
      expect(StudentSearchProvider.normalizeYear('Year 3'), '3');
      expect(StudentSearchProvider.normalizeYear('3rd Year'), '3');
      expect(StudentSearchProvider.normalizeYear('Third Year'), '3');
      expect(StudentSearchProvider.normalizeYear('III'), '3');

      expect(StudentSearchProvider.normalizeYear('4'), '4');
      expect(StudentSearchProvider.normalizeYear('Year 4'), '4');
      expect(StudentSearchProvider.normalizeYear('4th Year'), '4');
      expect(StudentSearchProvider.normalizeYear('Fourth Year'), '4');
      expect(StudentSearchProvider.normalizeYear('IV'), '4');

      expect(StudentSearchProvider.normalizeYear(null), isNull);
      expect(StudentSearchProvider.normalizeYear(''), isNull);
      expect(StudentSearchProvider.normalizeYear('ALL'), isNull);
    });

    test('isYearMatching correctly filters students by year', () {
      final sYear1 = {'fullName': 'Aditya 1', 'year': '1'};
      final sYear2 = {'fullName': 'Aditya 2', 'year': '2'};
      final sYear3 = {'fullName': 'Aditya 3', 'year': '3'};

      expect(StudentSearchProvider.isYearMatching('Year 1', sYear1), isTrue);
      expect(StudentSearchProvider.isYearMatching('Year 1', sYear2), isFalse);
      expect(StudentSearchProvider.isYearMatching('Year 2', sYear2), isTrue);
      expect(StudentSearchProvider.isYearMatching('3rd Year', sYear3), isTrue);
      expect(StudentSearchProvider.isYearMatching('ALL', sYear1), isTrue);
      expect(StudentSearchProvider.isYearMatching(null, sYear1), isTrue);
    });

    test('isDeptMatching correctly filters students by departmentId and departmentName', () {
      final sDept1 = {'fullName': 'Aditya 1', 'departmentId': 1, 'departmentName': 'Civil Engineering'};
      final sDept2 = {'fullName': 'Aditya 2', 'departmentId': 2, 'departmentName': 'ECE'};

      expect(StudentSearchProvider.isDeptMatching(1, sDept1), isTrue);
      expect(StudentSearchProvider.isDeptMatching(1, sDept2), isFalse);
      expect(StudentSearchProvider.isDeptMatching('2', sDept2), isTrue);
      expect(StudentSearchProvider.isDeptMatching(null, sDept1), isTrue);
    });

    test('isSectionMatching correctly filters students by sectionId and sectionName', () {
      final sSec1 = {'fullName': 'Aditya 1', 'sectionId': 10, 'sectionName': 'A'};
      final sSec2 = {'fullName': 'Aditya 2', 'sectionId': 20, 'sectionName': 'B'};

      expect(StudentSearchProvider.isSectionMatching(10, sSec1), isTrue);
      expect(StudentSearchProvider.isSectionMatching(10, sSec2), isFalse);
      expect(StudentSearchProvider.isSectionMatching(null, sSec1), isTrue);
    });
  });
}
