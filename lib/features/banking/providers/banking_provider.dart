import 'package:flutter/foundation.dart';
import 'package:pragatix/features/banking/models/banking_models.dart';
import 'package:pragatix/features/banking/services/banking_service.dart';

class BankingProvider extends ChangeNotifier {
  // --- Student State ---
  List<StudentBankSummaryModel> _applicableBanks = [];
  StudentBankSummaryModel? _studentSummary;
  List<StudentBankingTransactionModel> _studentTransactions = [];
  int? _selectedBankId;
  bool _loadingStudent = false;
  bool _loadingTransactions = false;
  String? _studentError;

  List<StudentBankSummaryModel> get applicableBanks => _applicableBanks;
  StudentBankSummaryModel? get studentSummary => _studentSummary;
  List<StudentBankingTransactionModel> get studentTransactions => _studentTransactions;
  int? get selectedBankId => _selectedBankId;
  bool get loadingStudent => _loadingStudent;
  bool get loadingTransactions => _loadingTransactions;
  String? get studentError => _studentError;

  // --- Admin State ---
  List<BankModel> _banks = [];
  BankDashboardStatsModel _stats = BankDashboardStatsModel();
  bool _loadingAdmin = false;
  String? _adminError;

  List<BankModel> get banks => _banks;
  BankDashboardStatsModel get stats => _stats;
  bool get loadingAdmin => _loadingAdmin;
  String? get adminError => _adminError;

  // --- Preview State ---
  BankingPreviewModel? _preview;
  bool _loadingPreview = false;
  String? _previewError;

  BankingPreviewModel? get preview => _preview;
  bool get loadingPreview => _loadingPreview;
  String? get previewError => _previewError;

  // --- Action Loading State ---
  bool _executingAction = false;
  bool get executingAction => _executingAction;

  // ================= STUDENT METHODS =================

  Future<void> loadStudentBanks(String token, {int? preferredBankId}) async {
    _loadingStudent = true;
    _studentError = null;
    notifyListeners();

    try {
      final service = BankingService(token: token);
      final banks = await service.getMyBanks();
      _applicableBanks = banks;

      if (banks.isNotEmpty) {
        int targetId = preferredBankId ?? _selectedBankId ?? banks.first.bankId ?? 0;
        final matching = banks.any((b) => b.bankId == targetId);
        if (!matching) {
          targetId = banks.first.bankId ?? 0;
        }
        _selectedBankId = targetId;
        _studentSummary = banks.firstWhere((b) => b.bankId == targetId, orElse: () => banks.first);

        if (targetId != 0) {
          await loadStudentTransactions(token, targetId);
        }
      } else {
        _selectedBankId = null;
        _studentSummary = null;
        _studentTransactions = [];
      }
    } catch (e) {
      _studentError = e.toString().replaceAll('Exception: ', '');
    } finally {
      _loadingStudent = false;
      notifyListeners();
    }
  }

  Future<void> selectStudentBank(String token, int bankId) async {
    _selectedBankId = bankId;
    if (_applicableBanks.isNotEmpty) {
      final found = _applicableBanks.where((b) => b.bankId == bankId);
      if (found.isNotEmpty) {
        _studentSummary = found.first;
      }
    }
    notifyListeners();
    await loadStudentTransactions(token, bankId);
  }

  Future<void> loadStudentTransactions(String token, int bankId, {String? search, String? type}) async {
    _loadingTransactions = true;
    notifyListeners();

    try {
      final service = BankingService(token: token);
      _studentTransactions = await service.getMyBankTransactions(
        bankId: bankId,
        search: search,
        type: type,
        page: 0,
        size: 5000,
      );
    } catch (e) {
      _studentTransactions = [];
    } finally {
      _loadingTransactions = false;
      notifyListeners();
    }
  }

  Future<void> loadStudentSummary(String token) async {
    await loadStudentBanks(token);
  }

  // ================= ADMIN METHODS =================

  Future<void> loadAdminDashboard(String token, {String? status}) async {
    _loadingAdmin = true;
    _adminError = null;
    notifyListeners();

    try {
      final service = BankingService(token: token);
      final results = await Future.wait([
        service.getBanks(status: status),
        service.getDashboardStats(),
      ]);
      _banks = results[0] as List<BankModel>;
      _stats = results[1] as BankDashboardStatsModel;
    } catch (e) {
      _adminError = e.toString().replaceAll('Exception: ', '');
    } finally {
      _loadingAdmin = false;
      notifyListeners();
    }
  }

  Future<void> loadPreview(String token, int bankId) async {
    _loadingPreview = true;
    _previewError = null;
    _preview = null;
    notifyListeners();

    try {
      final service = BankingService(token: token);
      _preview = await service.getPreview(bankId);
    } catch (e) {
      _previewError = e.toString().replaceAll('Exception: ', '');
    } finally {
      _loadingPreview = false;
      notifyListeners();
    }
  }

  Future<bool> executeBanking(String token, int bankId, {String? notes}) async {
    _executingAction = true;
    notifyListeners();

    try {
      final service = BankingService(token: token);
      await service.executeBanking(bankId, notes: notes);
      await loadAdminDashboard(token);
      return true;
    } catch (e) {
      _adminError = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _executingAction = false;
      notifyListeners();
    }
  }

  Future<bool> executeReset({
    required String token,
    required int bankId,
    required String scope,
    int? targetId,
    required String reason,
  }) async {
    _executingAction = true;
    notifyListeners();

    try {
      final service = BankingService(token: token);
      await service.executeReset(
        bankId: bankId,
        scope: scope,
        targetId: targetId,
        reason: reason,
      );
      await loadAdminDashboard(token);
      return true;
    } catch (e) {
      _adminError = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _executingAction = false;
      notifyListeners();
    }
  }

  Future<bool> deleteBank(String token, int bankId) async {
    try {
      final service = BankingService(token: token);
      await service.deleteBank(bankId);
      _banks.removeWhere((b) => b.id == bankId);
      await loadAdminDashboard(token);
      return true;
    } catch (e) {
      _adminError = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
