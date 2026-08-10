import 'package:flutter/foundation.dart';
import 'package:pragatix/features/activity/models/activity_model.dart';
import 'package:pragatix/features/activity/models/my_activity_model.dart';
import 'package:pragatix/features/activity/repository/activity_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Activity module – state management (ChangeNotifier).
// The UI NEVER calls HTTP directly. Everything goes through this provider.
// ─────────────────────────────────────────────────────────────────────────────

class ActivityProvider extends ChangeNotifier {
  final ActivityRepository _repository;

  ActivityProvider(this._repository);

  String get token => _repository.token;

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _safeNotify() {
    if (!_isDisposed && hasListeners) {
      notifyListeners();
    }
  }

  // ── List state ────────────────────────────────────────────────────────────
  List<ActivityModel> activities = [];
  List<MyActivityModel> myActivities = [];
  List<dynamic> departments = [];
  List<dynamic> allTeachers = [];
  List<dynamic> sections = [];
  List<dynamic> classCoordinators = [];
  List<dynamic> customFrequencies = [];

  bool isLoadingActivities = false;
  bool isLoadingDependencies = false;
  bool isSaving = false;
  String? error;

  // ── Assignment state ──────────────────────────────────────────────────────
  List<dynamic> currentAssignments = [];
  
  // ── Load my activities ────────────────────────────────────────────────────
  Future<void> loadMyActivities() async {
    isLoadingActivities = true;
    error = null;
    _safeNotify();
    try {
      myActivities = await _repository.getMyActivities();
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      myActivities = [];
    } finally {
      isLoadingActivities = false;
      _safeNotify();
    }
  }

  // ── Load activities ───────────────────────────────────────────────────────
  Future<void> loadActivities({
    int? stageId,
    String? subgroupName,
    String? academicYear,
  }) async {
    isLoadingActivities = true;
    error = null;
    activities = [];
    _safeNotify();
    try {
      activities = await _repository.getActivities(
        stageId: stageId,
        subgroupName: subgroupName,
        academicYear: academicYear,
      );
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      activities = [];
    } finally {
      isLoadingActivities = false;
      _safeNotify();
    }
  }

  // ── Load form dependencies (departments + teachers + sections) ───────────
  Future<void> loadDependencies() async {
    isLoadingDependencies = true;
    _safeNotify();
    try {
      departments = await _repository.getDepartments();
    } catch (_) {
      departments = [];
    }
    try {
      allTeachers = await _repository.getTeachers();
    } catch (_) {
      allTeachers = [];
    }
    try {
      sections = await _repository.getSections();
      debugPrint(
        'DEBUG_LOG: Provider loaded sections count: ${sections.length}, data: $sections',
      );
    } catch (e) {
      debugPrint('DEBUG_LOG: Provider failed to load sections: $e');
      sections = [];
    }
    try {
      classCoordinators = await _repository.getClassCoordinators();
      debugPrint(
        'DEBUG_LOG: Provider loaded class coordinators count: ${classCoordinators.length}',
      );
    } catch (e) {
      debugPrint('DEBUG_LOG: Provider failed to load class coordinators: $e');
      classCoordinators = [];
    }
    try {
      customFrequencies = await _repository.getCustomFrequencies();
    } catch (e) {
      customFrequencies = [];
    }
    isLoadingDependencies = false;
    _safeNotify();
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────
  Future<bool> createActivity(
    Map<String, dynamic> body, {
    int? stageId,
    String? subgroupName,
    String? academicYear,
  }) async {
    isSaving = true;
    error = null;
    _safeNotify();
    try {
      await _repository.create(
        body,
        stageId: stageId,
        subgroupName: subgroupName,
      );
      
      // Full refresh
      await loadActivities(stageId: stageId, subgroupName: subgroupName, academicYear: academicYear);
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isSaving = false;
      _safeNotify();
    }
  }

  Future<Map<String, dynamic>?> createCustomFrequency(
    Map<String, dynamic> body,
  ) async {
    error = null;
    _safeNotify();
    try {
      final newFreq = await _repository.createCustomFrequency(body);
      customFrequencies = [...customFrequencies, newFreq];
      _safeNotify();
      return newFreq;
    } catch (e) {
      error = e.toString();
      _safeNotify();
      return null;
    }
  }

  Future<bool> updateActivity(int activityId, Map<String, dynamic> body, {
    int? stageId,
    String? subgroupName,
    String? academicYear,
  }) async {
    isSaving = true;
    error = null;
    _safeNotify();
    try {
      await _repository.update(activityId, body);
      // Full refresh
      await loadActivities(stageId: stageId, subgroupName: subgroupName, academicYear: academicYear);
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isSaving = false;
      _safeNotify();
    }
  }

  Future<bool> mapExistingActivityToStage(
    int stageId,
    ActivityModel activity,
    String subgroupName,
  ) async {
    isSaving = true;
    error = null;
    _safeNotify();
    try {
      await _repository.mapActivityToStage(stageId, activity.id, subgroupName);

      // Refresh list directly from backend to ensure all properties (like subgroup ids) are updated
      await loadActivities(stageId: stageId, subgroupName: subgroupName);
      return true;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      isSaving = false;
      _safeNotify();
    }
  }

  Future<void> deleteActivity(int activityId, {bool force = false}) async {
    try {
      await _repository.delete(activityId, force: force);
      await loadActivities(); // Full refresh
    } catch (e) {
      rethrow;
    }
  }

  Future<void> unmapActivityFromStage(int stageId, int activityId, {String? subgroupName}) async {
    try {
      await _repository.unmapActivityFromStage(stageId, activityId);
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      rethrow;
    } finally {
      await loadActivities(stageId: stageId, subgroupName: subgroupName); // Full refresh with subgroupName
    }
  }

  Future<List<dynamic>> getAssignments(int activityId, {int? stageId}) async {
    print('========================');
    print('FRONTEND LOG: PROVIDER getAssignments()');
    print('Assignment count before update: ${currentAssignments.length}');
    
    final list = await _repository.getAssignments(activityId, stageId);
    currentAssignments = list;
    
    print('Assignment count after update: ${currentAssignments.length}');
    print('notifyListeners() called from Provider');
    print('========================');
    
    _safeNotify();
    return list;
  }

  Future<void> addAssignment(
    int activityId,
    int departmentId,
    String year,
    int? sectionId,
    int? teacherId,
    String scope, {
    int? stageId,
  }) async {
    isSaving = true;
    error = null;
    _safeNotify();
    try {
      await _repository.addAssignment(
        activityId,
        departmentId,
        year,
        sectionId,
        teacherId,
        scope,
        stageId,
      );
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isSaving = false;
      _safeNotify();
    }
  }

  Future<void> removeAssignment(int assignmentId) async {
    isSaving = true;
    error = null;
    _safeNotify();
    try {
      await _repository.removeAssignment(assignmentId);
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isSaving = false;
      _safeNotify();
    }
  }

  Future<void> clearAllAssignments(int activityId, {int? stageId}) async {
    isSaving = true;
    error = null;
    _safeNotify();
    try {
      await _repository.clearAllAssignments(activityId, stageId);
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isSaving = false;
      _safeNotify();
    }
  }

  Future<void> assignActivity(
    int activityId,
    bool ccEnabled,
    bool globalEnabled, [
    List<Map<String, dynamic>>? assignments,
    int? stageId,
  ]) async {
    isSaving = true;
    error = null;
    _safeNotify();
    try {
      await _repository.assignActivity(
        activityId,
        ccEnabled,
        globalEnabled,
        assignments,
        stageId,
      );
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isSaving = false;
      _safeNotify();
    }
  }
}
