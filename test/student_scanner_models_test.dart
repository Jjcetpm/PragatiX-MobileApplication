import 'package:flutter_test/flutter_test.dart';
import 'package:pragatix/features/scanner/models/scanned_student_models.dart';

void main() {
  group('Student Scanner Models Unit Tests', () {
    test('ScannedStudentProfileModel parses JSON correctly', () {
      final json = {
        'id': 1,
        'sprNo': '24CS036',
        'regNo': '24CSC101',
        'fullName': 'John Doe',
        'email': 'john@pragatix.in',
        'departmentId': 10,
        'departmentName': 'Computer Science and Engineering',
        'year': '1',
        'academicYear': 'FIRST_YEAR',
        'sectionId': 101,
        'sectionName': 'A',
        'teamId': 5,
        'teamName': 'CyberKnights',
        'teamRole': 'Captain',
        'isCaptain': true,
        'currentStage': 1,
        'stageName': 'Stage 1',
        'currentXp': 300,
        'lifetimeXp': 550,
        'avatar': 'https://example.com/avatar.jpg',
      };

      final model = ScannedStudentProfileModel.fromJson(json);

      expect(model.id, 1);
      expect(model.sprNo, '24CS036');
      expect(model.regNo, '24CSC101');
      expect(model.fullName, 'John Doe');
      expect(model.departmentName, 'Computer Science and Engineering');
      expect(model.teamName, 'CyberKnights');
      expect(model.isCaptain, true);
      expect(model.currentStage, 1);
      expect(model.currentXp, 300);
      expect(model.lifetimeXp, 550);
      expect(model.avatar, 'https://example.com/avatar.jpg');
    });

    test('EligibleActivityModel parses JSON correctly with scopes and variable XP', () {
      final json = {
        'activityId': 11,
        'assignmentId': 101,
        'activityName': 'Resume Writing Workshop',
        'description': 'Prepare corporate resume',
        'scope': 'GLOBAL',
        'scopeLabel': 'Institution-Wide',
        'isVariableXp': false,
        'awardEnabled': true,
        'awardXp': 50,
        'minXp': 10,
        'maxXp': 100,
        'penaltyEnabled': true,
        'penaltyXp': 20,
        'repeatAllowed': false,
        'alreadyCompleted': false,
        'eligibilityStatus': 'ELIGIBLE',
      };

      final model = EligibleActivityModel.fromJson(json);

      expect(model.activityId, 11);
      expect(model.assignmentId, 101);
      expect(model.activityName, 'Resume Writing Workshop');
      expect(model.scope, 'GLOBAL');
      expect(model.scopeLabel, 'Institution-Wide');
      expect(model.isVariableXp, false);
      expect(model.awardXp, 50);
      expect(model.penaltyEnabled, true);
      expect(model.penaltyXp, 20);
      expect(model.alreadyCompleted, false);
      expect(model.eligibilityStatus, 'ELIGIBLE');
    });

    test('ScannerAwardModel converts to JSON with idempotencyKey', () {
      final model = ScannerAwardModel(
        studentId: 1,
        activityId: 11,
        assignmentId: 101,
        xp: 50,
        remarks: 'Great presentation',
        idempotencyKey: 'idemp-award-001',
      );

      final json = model.toJson();

      expect(json['studentId'], 1);
      expect(json['activityId'], 11);
      expect(json['assignmentId'], 101);
      expect(json['xp'], 50);
      expect(json['remarks'], 'Great presentation');
      expect(json['idempotencyKey'], 'idemp-award-001');
    });

    test('ScannerPenaltyModel converts to JSON with mandatory reason', () {
      final model = ScannerPenaltyModel(
        studentId: 1,
        activityId: 12,
        penaltyXp: 20,
        reason: 'Late submission without notice',
        idempotencyKey: 'idemp-penalty-001',
      );

      final json = model.toJson();

      expect(json['studentId'], 1);
      expect(json['activityId'], 12);
      expect(json['penaltyXp'], 20);
      expect(json['reason'], 'Late submission without notice');
      expect(json['idempotencyKey'], 'idemp-penalty-001');
    });

    test('ScannerTransactionResultModel parses JSON correctly', () {
      final json = {
        'success': true,
        'message': 'XP points awarded successfully',
        'transactionId': 9001,
        'transactionType': 'AWARD',
        'xpPoints': 50,
        'studentId': 1,
        'sprNo': '24CS036',
        'studentName': 'John Doe',
        'newCurrentXp': 350,
        'newLifetimeXp': 600,
        'timestamp': '2026-10-30T10:30:00',
      };

      final model = ScannerTransactionResultModel.fromJson(json);

      expect(model.success, true);
      expect(model.transactionId, 9001);
      expect(model.transactionType, 'AWARD');
      expect(model.xpPoints, 50);
      expect(model.newCurrentXp, 350);
      expect(model.newLifetimeXp, 600);
      expect(model.studentName, 'John Doe');
    });
  });
}

