import 'package:pragatix/core/config/api_config.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pragatix/core/utils/api_client.dart' as http;
import 'package:pragatix/core/utils/string_utils.dart';

class XpProvider extends ChangeNotifier {
  Map<String, int> _xpByCategory = {};
  List<dynamic> _history = [];
  List<dynamic> _streaks = [];
  List<dynamic> _activityStreaks = [];
  List<Map<String, dynamic>> _stages = [];
  Map<String, dynamic>? _progression;
  bool _isLoading = false;

  Map<String, int> get xpByCategory => _xpByCategory;
  List<dynamic> get history => _history;
  List<dynamic> get streaks => _streaks;
  List<dynamic> get activityStreaks => _activityStreaks;
  List<Map<String, dynamic>> get stages => _stages;
  Map<String, dynamic>? get progression => _progression;
  bool get isLoading => _isLoading;

  int get totalXp => _xpByCategory['totalXp'] ?? 0;

  Future<void> fetchSummary(String regNo, String token) async {
    if (regNo.isEmpty) {
      debugPrint('Skipping fetchSummary because regNo is empty');
      return;
    }
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/xp/$regNo/summary'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final Map<String, dynamic> rawMap = data['data'];
          _xpByCategory = rawMap.map((key, val) => MapEntry(key, val as int));
        } else {
          _xpByCategory = {};
        }
      } else {
        _xpByCategory = {};
      }
    } catch (e) {
      _xpByCategory = {};
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchHistory(String regNo, String token) async {
    if (regNo.isEmpty) {
      debugPrint('Skipping fetchHistory because regNo is empty');
      return;
    }
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/v1/xp/$regNo/history?page=0&size=50',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          _history = data['data']['content'] ?? [];
        } else {
          _history = [];
        }
      } else {
        _history = [];
      }
    } catch (e) {
      _history = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchStreaks(String regNo, String token) async {
    if (regNo.isEmpty) {
      debugPrint('Skipping fetchStreaks because regNo is empty');
      return;
    }
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/xp/$regNo/streaks'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          _streaks = data['data'] ?? [];
        } else {
          _streaks = [];
        }
      } else {
        _streaks = [];
      }
    } catch (e) {
      _streaks = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchActivityStreaks(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/students/me/activity-streaks'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          _activityStreaks = data['data'] ?? [];
        } else {
          _activityStreaks = [];
        }
      } else {
        _activityStreaks = [];
      }
    } catch (e) {
      _activityStreaks = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> submitXpClaim(
    String regNo,
    String token,
    String category,
    String activityName,
    int xpPoints,
    String evidenceUrl,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/xp/submit'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'category': category,
          'activityName': activityName,
          'xpPoints': xpPoints,
          'evidenceUrl': evidenceUrl,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final bool success = data['success'] == true;
        if (success) {
          await fetchHistory(regNo, token); // Reload history
          await fetchSummary(regNo, token); // Reload summary
        }
        return success;
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  Future<void> fetchStages(String token) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/students/stages'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> fetchedStages = data['data'] ?? [];
          final List<Map<String, dynamic>> mapped = [];

          for (var st in fetchedStages) {
            final List<dynamic> fetchedSubgroups = st['subgroups'] ?? [];
            final List<Map<String, dynamic>> substages = [];

            bool allSubgroupsCompleted = true;
            String? stageCompletedDate;

            for (var sub in fetchedSubgroups) {
              final int threshold = sub['threshold'] ?? 0;
              final List<dynamic> activitiesList = sub['activities'] ?? [];

              int earnedXP = 0;
              int completedCount = 0;

              for (var act in activitiesList) {
                earnedXP += (act['earnedXP'] as num?)?.toInt() ?? 0;

                if (act['status'] == 'COMPLETED') {
                  completedCount++;

                  if (act['completedDate'] != null) {
                    if (stageCompletedDate == null ||
                        (act['completedDate'] as String).compareTo(
                              stageCompletedDate,
                            ) >
                            0) {
                      stageCompletedDate = act['completedDate'];
                    }
                  }
                }
              }

              if (earnedXP < threshold && threshold > 0) {
                allSubgroupsCompleted = false;
              }

              substages.add({
                'name': StringUtils.toTitleCase(sub['name'] ?? ''),
                'threshold': threshold,
                'earnedXP': earnedXP,
                'completedCount': completedCount,
                'totalCount': activitiesList.length,
                'activities': activitiesList,
              });
            }

            if (substages.isEmpty) allSubgroupsCompleted = false;

            mapped.add({
              'id': st['id'],
              'name': st['name'],
              'description': st['description'] ?? '',
              'displayOrder': st['displayOrder'] ?? 0,
              'stageStatus': st['stageStatus'] ?? 'LOCKED_BEFORE_START',
              'startDateTime': st['startDateTime'],
              'isStageCompleted': allSubgroupsCompleted,
              'stageCompletedDate': stageCompletedDate,
              'substages': substages,
            });
          }

          mapped.sort((a, b) {
            final num aOrder =
                num.tryParse(a['displayOrder']?.toString() ?? '0') ?? 0;
            final num bOrder =
                num.tryParse(b['displayOrder']?.toString() ?? '0') ?? 0;
            return aOrder.compareTo(bOrder);
          });

          _stages = mapped;
        } else {
          _stages = [];
        }
      } else {
        _stages = [];
      }
    } catch (e) {
      debugPrint('Error fetching stages: $e');
      _stages = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchProgression(String token) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/student-level/progression'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          _progression = data['data'];
        } else {
          _progression = null;
        }
      } else {
        _progression = null;
      }
    } catch (e) {
      debugPrint('Error fetching progression: $e');
      _progression = null;
    }
    _isLoading = false;
    notifyListeners();
  }
}
