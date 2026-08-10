import 'package:flutter/material.dart';
import 'package:pragatix/features/penalty/models/penalty_request.dart';
import 'package:pragatix/features/penalty/services/penalty_service.dart';

class PenaltyProvider with ChangeNotifier {
  final PenaltyService _penaltyService;

  PenaltyProvider(this._penaltyService);

  List<PenaltyRequest> _ccInbox = [];
  List<PenaltyRequest> _myRequests = [];
  int _pendingCount = 0;
  bool _isLoading = false;
  String? _error;

  List<PenaltyRequest> get ccInbox => _ccInbox;
  List<PenaltyRequest> get myRequests => _myRequests;
  int get pendingCount => _pendingCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchPendingCount() async {
    try {
      final count = await _penaltyService.getPendingCount();
      _pendingCount = count;
      notifyListeners();
    } catch (e) {
      // ignore
    }
  }

  void setPendingCount(int count) {
    _pendingCount = count;
    notifyListeners();
  }

  Future<void> loadCcInbox() async {
    _setLoading(true);
    try {
      _ccInbox = await _penaltyService.getCcInbox();
      _pendingCount = _ccInbox
          .where((r) => r.status.toUpperCase() == 'PENDING')
          .length;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadMyRequests() async {
    _setLoading(true);
    try {
      _myRequests = await _penaltyService.getMyRequests();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> approvePenalty(int id) async {
    _setLoading(true);
    try {
      await _penaltyService.approvePenalty(id);
      await loadCcInbox();
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectPenalty(int id, String reason) async {
    _setLoading(true);
    try {
      await _penaltyService.rejectPenalty(id, reason);
      await loadCcInbox();
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
