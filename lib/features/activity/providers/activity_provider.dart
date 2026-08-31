import 'package:flutter/foundation.dart';
import 'package:pragatix/features/activity/models/activity_category_item.dart';
import 'package:pragatix/features/activity/models/activity_evidence_item.dart';
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
  List<ActivityCategoryItem> activityCategories = [];
  List<String> xpCategories = [
    'Academic',
    'Skill',
    'Communication',
    'Leadership',
    'Discipline',
    'Placement',
    'Innovation',
    'Community',
    'Sports',
    'Cultural',
  ];
  List<ActivityEvidenceItem> activityEvidences = [];
  List<String> evidenceOptions = [
    'Handwritten',
    'Soft Copy',
    'Diary / Notebook',
    'Weekly Log',
    'Direct Observation',
    'Attendance Register',
    'ERP Attendance',
  ];

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

  // ── Active filter state ───────────────────────────────────────────────────
  int? currentStageId;
  String? currentSubgroupName;
  String? currentAcademicYear;

  // ── Load activities ───────────────────────────────────────────────────────
  Future<void> loadActivities({
    int? stageId,
    String? subgroupName,
    String? academicYear,
  }) async {
    currentStageId = stageId;
    currentSubgroupName = subgroupName;
    currentAcademicYear = academicYear;
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
    try {
      await loadCategories();
      await loadEvidenceTypes();
    } catch (_) {}
    isLoadingDependencies = false;
    _safeNotify();
  }

  // ── Category Management ───────────────────────────────────────────────────
  Future<void> loadCategories() async {
    try {
      final raw = await _repository.getCategories();
      activityCategories = raw
          .map((json) => ActivityCategoryItem.fromJson(json as Map<String, dynamic>))
          .toList();
      if (activityCategories.isNotEmpty) {
        xpCategories = activityCategories.map((c) => c.name).toList();
      }
      _safeNotify();
    } catch (e) {
      debugPrint('Provider failed to load categories: $e');
    }
  }

  Future<ActivityCategoryItem?> createCategory(
    String name, {
    String? description,
    String? icon,
    int? displayOrder,
  }) async {
    error = null;
    _safeNotify();
    try {
      final res = await _repository.createCategory({
        'name': name.trim(),
        'description': description?.trim(),
        'icon': icon?.trim(),
        'displayOrder': displayOrder ?? 0,
      });
      final newItem = ActivityCategoryItem.fromJson(res);
      activityCategories.add(newItem);
      if (!xpCategories.any((c) => c.toLowerCase() == newItem.name.toLowerCase())) {
        xpCategories.add(newItem.name);
      }
      _safeNotify();
      return newItem;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      _safeNotify();
      return null;
    }
  }

  Future<ActivityCategoryItem?> updateCategory(
    int id,
    String name, {
    String? description,
    String? icon,
    int? displayOrder,
  }) async {
    error = null;
    _safeNotify();
    try {
      final res = await _repository.updateCategory(id, {
        'name': name.trim(),
        'description': description?.trim(),
        'icon': icon?.trim(),
        'displayOrder': displayOrder ?? 0,
      });
      final updatedItem = ActivityCategoryItem.fromJson(res);
      final idx = activityCategories.indexWhere((c) => c.id == id);
      if (idx != -1) {
        activityCategories[idx] = updatedItem;
      }
      xpCategories = activityCategories.map((c) => c.name).toList();
      _safeNotify();
      return updatedItem;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      _safeNotify();
      return null;
    }
  }

  Future<bool> deleteCategory(int id) async {
    error = null;
    _safeNotify();
    try {
      await _repository.deleteCategory(id);
      activityCategories.removeWhere((c) => c.id == id);
      xpCategories = activityCategories.map((c) => c.name).toList();
      _safeNotify();
      return true;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      _safeNotify();
      return false;
    }
  }

  // ── Evidence Management ───────────────────────────────────────────────────
  Future<void> loadEvidenceTypes() async {
    try {
      final raw = await _repository.getEvidenceTypes();
      activityEvidences = raw
          .map((json) => ActivityEvidenceItem.fromJson(json as Map<String, dynamic>))
          .toList();
      if (activityEvidences.isNotEmpty) {
        evidenceOptions = activityEvidences.map((e) => e.name).toList();
      }
      _safeNotify();
    } catch (e) {
      debugPrint('Provider failed to load evidence types: $e');
    }
  }

  Future<ActivityEvidenceItem?> createEvidenceType(
    String name, {
    String? description,
    int? displayOrder,
  }) async {
    error = null;
    _safeNotify();
    try {
      final res = await _repository.createEvidenceType({
        'name': name.trim(),
        'description': description?.trim(),
        'displayOrder': displayOrder ?? 0,
      });
      final newItem = ActivityEvidenceItem.fromJson(res);
      activityEvidences.add(newItem);
      if (!evidenceOptions.any((e) => e.toLowerCase() == newItem.name.toLowerCase())) {
        evidenceOptions.add(newItem.name);
      }
      _safeNotify();
      return newItem;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      _safeNotify();
      return null;
    }
  }

  Future<ActivityEvidenceItem?> updateEvidenceType(
    int id,
    String name, {
    String? description,
    int? displayOrder,
  }) async {
    error = null;
    _safeNotify();
    try {
      final res = await _repository.updateEvidenceType(id, {
        'name': name.trim(),
        'description': description?.trim(),
        'displayOrder': displayOrder ?? 0,
      });
      final updatedItem = ActivityEvidenceItem.fromJson(res);
      final idx = activityEvidences.indexWhere((e) => e.id == id);
      if (idx != -1) {
        activityEvidences[idx] = updatedItem;
      }
      evidenceOptions = activityEvidences.map((e) => e.name).toList();
      _safeNotify();
      return updatedItem;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      _safeNotify();
      return null;
    }
  }

  Future<bool> deleteEvidenceType(int id) async {
    error = null;
    _safeNotify();
    try {
      await _repository.deleteEvidenceType(id);
      activityEvidences.removeWhere((e) => e.id == id);
      evidenceOptions = activityEvidences.map((e) => e.name).toList();
      _safeNotify();
      return true;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      _safeNotify();
      return false;
    }
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

  Future<void> deleteActivity(
    int activityId, {
    bool force = false,
    int? stageId,
    String? subgroupName,
    String? academicYear,
  }) async {
    try {
      await _repository.delete(activityId, force: force);
      final effStageId = stageId ?? currentStageId;
      final effSubgroup = subgroupName ?? currentSubgroupName;
      final effYear = academicYear ?? currentAcademicYear;
      await loadActivities(
        stageId: effStageId,
        subgroupName: effSubgroup,
        academicYear: effYear,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> unmapActivityFromStage(
    int stageId,
    int activityId, {
    String? subgroupName,
    String? academicYear,
  }) async {
    try {
      await _repository.unmapActivityFromStage(stageId, activityId);
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      rethrow;
    } finally {
      final effSubgroup = subgroupName ?? currentSubgroupName;
      final effYear = academicYear ?? currentAcademicYear;
      await loadActivities(
        stageId: stageId,
        subgroupName: effSubgroup,
        academicYear: effYear,
      );
    }
  }

  Future<List<dynamic>> getAssignments(int activityId, {int? stageId}) async {
    debugPrint('========================');
    debugPrint('FRONTEND LOG: PROVIDER getAssignments()');
    debugPrint('Assignment count before update: ${currentAssignments.length}');
    
    final list = await _repository.getAssignments(activityId, stageId);
    currentAssignments = list;
    
    debugPrint('Assignment count after update: ${currentAssignments.length}');
    debugPrint('notifyListeners() called from Provider');
    debugPrint('========================');
    
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
