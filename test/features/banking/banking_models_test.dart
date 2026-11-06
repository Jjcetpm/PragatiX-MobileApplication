import 'package:flutter_test/flutter_test.dart';
import 'package:pragatix/features/banking/models/banking_models.dart';

void main() {
  group('Banking Models Test Suite', () {
    test('BankModel parses correctly from backend JSON', () {
      final json = {
        'id': 10,
        'bankName': 'Semester 1 Bank',
        'bankCode': 'BANK-S1-2024',
        'description': 'Main Semester 1 Banking Period',
        'startDate': '2024-01-01',
        'endDate': '2024-06-30',
        'applicableDepartments': ['CSE', 'ECE'],
        'applicableAcademicYears': ['2023-2027'],
        'status': 'ACTIVE',
        'executionStatus': 'SUCCESS',
        'lastExecutionAt': '2024-06-30T18:00:00Z',
        'createdByName': 'Super Admin',
      };

      final bank = BankModel.fromJson(json);

      expect(bank.id, 10);
      expect(bank.bankName, 'Semester 1 Bank');
      expect(bank.bankCode, 'BANK-S1-2024');
      expect(bank.status, 'ACTIVE');
      expect(bank.applicableDepartments, contains('CSE'));
      expect(bank.applicableDepartments, contains('ECE'));
      expect(bank.executionStatus, 'SUCCESS');
    });

    test('BankingPreviewModel parses calculations and overlap warnings', () {
      final json = {
        'bankId': 10,
        'bankName': 'Semester 1 Bank',
        'startDate': '2024-01-01',
        'endDate': '2024-06-30',
        'eligibleStudentsCount': 120,
        'totalXpAwards': 15000,
        'totalXpPenalties': 2000,
        'totalXpAdjustments': 500,
        'totalNetXp': 13500,
        'hasOverlappingBanks': true,
        'overlappingBankNames': ['Summer Bank 2024'],
      };

      final preview = BankingPreviewModel.fromJson(json);

      expect(preview.eligibleStudentsCount, 120);
      expect(preview.totalXpAwards, 15000);
      expect(preview.totalXpPenalties, 2000);
      expect(preview.totalNetXp, 13500);
      expect(preview.hasOverlappingBanks, isTrue);
      expect(preview.overlappingBankNames, contains('Summer Bank 2024'));
    });

    test('StudentBankSummaryModel correctly separates current, banked, and lifetime XP', () {
      final json = {
        'bankId': 10,
        'bankName': 'Semester 1 Bank',
        'bankCode': 'BANK-S1',
        'startDate': '2024-01-01',
        'endDate': '2024-06-30',
        'bankStatus': 'ACTIVE',
        'isFinalized': false,
        'currentPeriodAwards': 850,
        'currentPeriodPenalties': 50,
        'currentPeriodAdjustments': 0,
        'netCurrentPeriodXp': 800,
        'bankedXp': 0,
        'lifetimeXp': 4200,
        'stageSummaries': [
          {
            'stageId': 1,
            'stageName': 'Stage 1 - Foundations',
            'stageCode': 'STG-01',
            'xpAwards': 500,
            'xpPenalties': 20,
            'netXp': 480,
          },
          {
            'stageId': 2,
            'stageName': 'Stage 2 - Advanced',
            'stageCode': 'STG-02',
            'xpAwards': 350,
            'xpPenalties': 30,
            'netXp': 320,
          }
        ],
        'recentTransactions': [
          {
            'transactionId': 99,
            'points': 100,
            'type': 'AWARD',
            'activityTitle': 'Hackathon Champion',
            'createdAt': '2024-03-15T10:00:00Z',
          }
        ],
      };

      final summary = StudentBankSummaryModel.fromJson(json);

      // Verify separation of metrics
      expect(summary.netCurrentPeriodXp, 800);
      expect(summary.bankedXp, 0);
      expect(summary.lifetimeXp, 4200);
      expect(summary.stageSummaries.length, 2);
      expect(summary.stageSummaries[0].netXp, 480);
      expect(summary.stageSummaries[1].netXp, 320);
      expect(summary.stageSummaries[0].netXp + summary.stageSummaries[1].netXp, 800);
      expect(summary.recentTransactions.first.activityTitle, 'Hackathon Champion');
    });

    test('ResetHistoryModel parses audit trail accurately', () {
      final json = {
        'id': 7,
        'bankId': 10,
        'scope': 'STAGE',
        'targetId': 1,
        'reason': 'Recalculation due to stage extension approved by Dean',
        'resetByName': 'Super Admin User',
        'affectedStudentCount': 65,
        'resetAt': '2024-06-01T12:00:00Z',
      };

      final reset = ResetHistoryModel.fromJson(json);

      expect(reset.id, 7);
      expect(reset.scope, 'STAGE');
      expect(reset.targetId, 1);
      expect(reset.affectedStudentCount, 65);
      expect(reset.reason, contains('Dean'));
    });
  });
}
