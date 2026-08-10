import 'package:flutter/material.dart';
import 'package:pragatix/features/badge/repository/badge_repository.dart';

class BadgeProvider extends ChangeNotifier {
  final BadgeRepository _repository = BadgeRepository();

  List<dynamic> _earnedBadges = [];
  List<dynamic> _pendingBadges = [];
  List<dynamic> _availableBadges = [];
  List<dynamic> _teacherPendingClaims = [];

  // NEW WORKFLOW
  List<dynamic> _myBadgeRequests = [];
  List<dynamic> _adminCCBadgeRequests = [];

  bool _isLoading = false;

  List<dynamic> get earnedBadges => _earnedBadges;
  List<dynamic> get pendingBadges => _pendingBadges;
  List<dynamic> get availableBadges => _availableBadges;
  List<dynamic> get teacherPendingClaims => _teacherPendingClaims;
  List<dynamic> get myBadgeRequests => _myBadgeRequests;
  List<dynamic> get adminCCBadgeRequests => _adminCCBadgeRequests;
  bool get isLoading => _isLoading;

  Future<void> fetchMyBadges(String token) async {
    _isLoading = true;
    notifyListeners();

    final response = await _repository.fetchMyBadges(token);
    if (response['success'] == true) {
      final List<dynamic> list = response['data'];
      _earnedBadges = list.where((b) => b['status'] == 'APPROVED').toList();
      _pendingBadges = list.where((b) => b['status'] == 'PENDING').toList();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchAllBadges(String token) async {
    final response = await _repository.fetchAllBadges(token);
    if (response['success'] == true) {
      _availableBadges = response['data'];
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> submitBadgeClaim(
    String token,
    String badgeName,
    String evidenceUrl,
  ) async {
    debugPrint('BadgeProvider: Calling repository submitBadgeClaim...');
    final response = await _repository.submitBadgeClaim(
      token,
      badgeName,
      evidenceUrl,
    );
    debugPrint('BadgeProvider: Response received: $response');
    if (response['success'] == true) {
      debugPrint(
        'BadgeProvider: Submission successful. Refreshing my badges...',
      );
      await fetchMyBadges(token);
    }
    return response;
  }

  Future<void> fetchTeacherPendingClaims(String token) async {
    _isLoading = true;
    notifyListeners();

    final response = await _repository.fetchTeacherPendingClaims(token);
    if (response['success'] == true) {
      _teacherPendingClaims = response['data'];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> approveClaim(String token, int claimId) async {
    final response = await _repository.approveClaim(token, claimId);
    if (response['success'] == true) {
      _teacherPendingClaims.removeWhere((c) => c['id'] == claimId);
      notifyListeners();
    }
    return response;
  }

  Future<Map<String, dynamic>> rejectClaim(String token, int claimId) async {
    final response = await _repository.rejectClaim(token, claimId);
    if (response['success'] == true) {
      _teacherPendingClaims.removeWhere((c) => c['id'] == claimId);
      notifyListeners();
    }
    return response;
  }

  // --- NEW WORKFLOW ---

  Future<void> fetchMyBadgeRequests(String token) async {
    _isLoading = true;
    notifyListeners();

    final response = await _repository.getMyRequests(token);
    if (response['success'] == true) {
      _myBadgeRequests = response['data'];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> requestBadgeWorkflow(
    String token,
    int badgeId,
    String proofLink,
  ) async {
    final response = await _repository.requestBadge(token, badgeId, proofLink);
    if (response['success'] == true) {
      await fetchMyBadgeRequests(token);
      await fetchMyBadges(token); // To update claim button status if needed
    }
    return response;
  }

  Future<void> fetchAdminCCBadgeRequests(String token, String role) async {
    _isLoading = true;
    notifyListeners();

    final response = role == 'ADMIN'
        ? await _repository.getAdminRequests(token)
        : await _repository.getCCRequests(token);

    if (response['success'] == true) {
      _adminCCBadgeRequests = response['data'];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> approveBadgeWorkflow(
    String token,
    int requestId,
    String role,
  ) async {
    final response = await _repository.approveWorkflowRequest(
      token,
      requestId,
      role,
    );
    if (response['success'] == true) {
      await fetchAdminCCBadgeRequests(token, role);
    }
    return response;
  }

  Future<Map<String, dynamic>> rejectBadgeWorkflow(
    String token,
    int requestId,
    String role, {
    String? remarks,
  }) async {
    final response = await _repository.rejectWorkflowRequest(
      token,
      requestId,
      role,
      remarks: remarks,
    );
    if (response['success'] == true) {
      await fetchAdminCCBadgeRequests(token, role);
    }
    return response;
  }
}
