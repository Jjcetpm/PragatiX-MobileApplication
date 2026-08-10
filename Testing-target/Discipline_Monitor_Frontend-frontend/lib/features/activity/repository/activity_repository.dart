import 'package:pragatix/features/activity/models/activity_model.dart';
import 'package:pragatix/features/activity/models/my_activity_model.dart';
import 'package:pragatix/features/activity/models/grouped_activity_model.dart';
import 'package:pragatix/features/activity/services/activity_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Activity module – repository.
// Maps raw API data → domain models. UI never touches ActivityService directly.
// ─────────────────────────────────────────────────────────────────────────────

class ActivityRepository {
  final ActivityService _service;

  ActivityRepository(ActivityService service) : _service = service;

  String? _mapSubgroupNameForApi(String? name) {
    if (name == null) return null;
    final lower = name.toLowerCase().trim();
    if (lower == 'must' || lower == 'must (individual)') return 'Must';
    if (lower == 'individual') return 'Individual';
    if (lower == 'group' || lower == 'groups') return 'Group';
    return name;
  }

  String get token => _service.token;

  Future<List<MyActivityModel>> getMyActivities() async {
    final raw = await _service.fetchMyActivities();
    return raw
        .map((e) => MyActivityModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ActivityModel>> getActivities({
    int? stageId,
    String? subgroupName,
    String? academicYear,
  }) async {
    final raw = await _service.fetchActivities(
      stageId: stageId,
      subgroupName: _mapSubgroupNameForApi(subgroupName),
      academicYear: academicYear,
    );
    return raw
        .map((e) => ActivityModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<GroupedActivityModel>> getGroupedActivities({
    int? stageId,
    String? subgroupName,
    String? academicYear,
  }) async {
    final raw = await _service.fetchGroupedActivities(
      stageId: stageId,
      subgroupName: _mapSubgroupNameForApi(subgroupName),
      academicYear: academicYear,
    );
    return raw
        .map((e) => GroupedActivityModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<dynamic>> getDepartments() async {
    return _service.fetchDepartments();
  }

  Future<List<dynamic>> getTeachers() async {
    final users = await _service.fetchUsers();
    return users.where((u) {
      final roles = u['roles'] as List<dynamic>? ?? [];
      return roles.any((r) {
        if (r is String) return r == 'ROLE_TEACHER';
        if (r is Map) return r['name'] == 'ROLE_TEACHER';
        return false;
      });
    }).toList();
  }

  Future<List<dynamic>> getClassCoordinators() async {
    return _service.fetchClassCoordinators();
  }

  Future<List<dynamic>> getCustomFrequencies() async {
    return _service.fetchCustomFrequencies();
  }

  Future<Map<String, dynamic>> createCustomFrequency(
    Map<String, dynamic> body,
  ) async {
    return _service.createCustomFrequency(body);
  }

  Future<ActivityModel> create(
    Map<String, dynamic> body, {
    int? stageId,
    String? subgroupName,
  }) async {
    final result = await _service.createActivity(body);
    final actData = result['data'] as Map<String, dynamic>? ?? result;
    return ActivityModel.fromJson(actData);
  }

  Future<ActivityModel> update(
    int activityId,
    Map<String, dynamic> body,
  ) async {
    final result = await _service.updateActivity(activityId, body);
    final actData = result['data'] as Map<String, dynamic>? ?? result;
    return ActivityModel.fromJson(actData);
  }

  Future<void> mapActivityToStage(
    int stageId,
    int activityId,
    String subgroup,
  ) async {
    await _service.mapActivityToStage(stageId, activityId, _mapSubgroupNameForApi(subgroup) ?? subgroup);
  }

  Future<void> unmapActivityFromStage(int stageId, int activityId) async {
    await _service.unmapActivityFromStage(stageId, activityId);
  }

  Future<void> delete(int activityId, {bool force = false}) async {
    await _service.deleteActivity(activityId, force: force);
  }

  Future<List<dynamic>> getSections() async {
    return _service.fetchSections();
  }

  Future<List<dynamic>> getAssignments(int activityId, [int? stageId]) async {
    return _service.fetchAssignments(activityId, stageId);
  }

  Future<Map<String, dynamic>> addAssignment(
    int activityId,
    int departmentId,
    String year,
    int? sectionId,
    int? teacherId,
    String scope, [
    int? stageId,
  ]) async {
    return _service.addAssignment(
      activityId,
      departmentId,
      year,
      sectionId,
      teacherId,
      scope,
      stageId,
    );
  }

  Future<void> removeAssignment(int assignmentId) async {
    await _service.removeAssignment(assignmentId);
  }

  Future<void> clearAllAssignments(int activityId, [int? stageId]) async {
    await _service.clearAllAssignments(activityId, stageId);
  }

  Future<void> assignActivity(
    int activityId,
    bool ccEnabled,
    bool globalEnabled, [
    List<Map<String, dynamic>>? assignments,
    int? stageId,
  ]) async {
    await _service.assignActivity(
      activityId,
      ccEnabled,
      globalEnabled,
      assignments,
      stageId,
    );
  }
}
