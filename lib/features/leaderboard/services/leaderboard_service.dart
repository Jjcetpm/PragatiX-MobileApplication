import 'dart:convert';
import 'package:pragatix/core/utils/api_client.dart' as http;
import 'package:pragatix/core/config/api_config.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';

class LeaderboardService {
  final AuthProvider authProvider;

  LeaderboardService(this.authProvider);

  String get token => authProvider.token ?? '';

  Future<List<Map<String, dynamic>>> getLeaderboard({
    String? yearId,
    String? departmentId,
    String? sectionId,
  }) async {
    final Map<String, String> queryParams = {};
    if (yearId != null && yearId.isNotEmpty && yearId != 'All') {
      queryParams['yearId'] = yearId;
    }
    if (departmentId != null &&
        departmentId.isNotEmpty &&
        departmentId != 'All') {
      queryParams['departmentId'] = departmentId;
    }
    if (sectionId != null && sectionId.isNotEmpty && sectionId != 'All') {
      queryParams['sectionId'] = sectionId;
    }

    final Map<String, Map<String, dynamic>> mergedMap = {};

    // 1. Fetch from /api/v1/students?page=0&size=1000&sortBy=score to ensure ALL active students are loaded
    try {
      final Map<String, String> studentParams = {
        'page': '0',
        'size': '1000',
        'sortBy': 'score',
      };
      if (departmentId != null && departmentId.isNotEmpty && departmentId != 'All') {
        studentParams['departmentId'] = departmentId;
      }
      if (sectionId != null && sectionId.isNotEmpty && sectionId != 'All') {
        studentParams['sectionId'] = sectionId;
      }
      final sUri = Uri.parse('${ApiConfig.baseUrl}/api/v1/students').replace(queryParameters: studentParams);
      final sRes = await http.get(
        sUri,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (sRes.statusCode == 200) {
        final sData = jsonDecode(sRes.body);
        List<dynamic>? sList;
        if (sData is List) {
          sList = sData;
        } else if (sData is Map) {
          if (sData['data'] is List) {
            sList = sData['data'];
          } else if (sData['content'] is List) {
            sList = sData['content'];
          } else if (sData['data'] is Map && sData['data']['content'] is List) {
            sList = sData['data']['content'];
          }
        }
        if (sList != null && sList.isNotEmpty) {
          for (var st in sList) {
            if (st is Map) {
              final regNo = (st['regNo'] ?? st['registerNumber'] ?? st['username'] ?? st['id'] ?? '').toString().trim();
              final fullName = (st['fullName'] ?? st['name'] ?? 'Student').toString().trim();
              final key = regNo.toLowerCase().isNotEmpty ? regNo.toLowerCase() : fullName.toLowerCase();
              final int xp = (st['totalXp'] is num) ? (st['totalXp'] as num).toInt() : (int.tryParse(st['totalXp']?.toString() ?? '0') ?? (int.tryParse(st['score']?.toString() ?? '0') ?? 0));

              mergedMap[key] = {
                'id': st['id'],
                'regNo': regNo,
                'fullName': fullName,
                'departmentName': st['departmentName'] ?? st['department']?['name'] ?? (st['department'] is String ? st['department'] : ''),
                'sectionName': st['sectionName'] ?? st['section']?['sectionName'] ?? (st['section'] is String ? st['section'] : ''),
                'year': st['year'] ?? st['academicYear'] ?? '',
                'totalXp': xp,
                'score': xp,
                'teamRole': st['teamRole'],
              };
            }
          }
        }
      }
    } catch (_) {}

    // 2. Fetch from /api/v1/leaderboard and overlay
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/leaderboard',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic>? list;
        if (data is List) {
          list = data;
        } else if (data is Map) {
          if (data['data'] is List) {
            list = data['data'];
          } else if (data['content'] is List) {
            list = data['content'];
          } else if (data['data'] is Map && data['data']['content'] is List) {
            list = data['data']['content'];
          }
        }
        if (list != null && list.isNotEmpty) {
          for (var item in list) {
            if (item is Map) {
              final regNo = (item['registerNumber'] ?? item['regNo'] ?? item['studentRegNo'] ?? item['username'] ?? item['id'] ?? '').toString().trim();
              final fullName = (item['studentName'] ?? item['fullName'] ?? item['name'] ?? 'Student').toString().trim();
              final key = regNo.toLowerCase().isNotEmpty ? regNo.toLowerCase() : fullName.toLowerCase();
              final int xp = (item['totalXp'] is num) ? (item['totalXp'] as num).toInt() : (int.tryParse(item['totalXp']?.toString() ?? '0') ?? (int.tryParse(item['score']?.toString() ?? '0') ?? 0));

              if (mergedMap.containsKey(key)) {
                final existing = mergedMap[key]!;
                final int currentXp = (existing['totalXp'] is num) ? (existing['totalXp'] as num).toInt() : (int.tryParse(existing['totalXp']?.toString() ?? '0') ?? 0);
                if (xp > currentXp) {
                  existing['totalXp'] = xp;
                  existing['score'] = xp;
                }
                if ((existing['departmentName'] == null || existing['departmentName'].toString().isEmpty) && item['departmentName'] != null) {
                  existing['departmentName'] = item['departmentName'];
                }
                if ((existing['sectionName'] == null || existing['sectionName'].toString().isEmpty) && item['sectionName'] != null) {
                  existing['sectionName'] = item['sectionName'];
                }
              } else {
                mergedMap[key] = {
                  'id': item['id'],
                  'regNo': regNo,
                  'fullName': fullName,
                  'departmentName': item['departmentName'] ?? item['department']?['name'] ?? '',
                  'sectionName': item['sectionName'] ?? item['section']?['sectionName'] ?? '',
                  'year': item['year'] ?? item['academicYear'] ?? '',
                  'totalXp': xp,
                  'score': xp,
                  'teamRole': item['teamRole'],
                };
              }
            }
          }
        }
      }
    } catch (_) {}

    final List<Map<String, dynamic>> results = mergedMap.values.toList();
    results.sort((a, b) {
      final aXp = (a['totalXp'] is num) ? (a['totalXp'] as num).toInt() : (int.tryParse(a['totalXp']?.toString() ?? '0') ?? 0);
      final bXp = (b['totalXp'] is num) ? (b['totalXp'] as num).toInt() : (int.tryParse(b['totalXp']?.toString() ?? '0') ?? 0);
      return bXp.compareTo(aXp);
    });

    return results;
  }

  Future<Map<String, dynamic>> getFilters({
    String? yearId,
    String? departmentId,
  }) async {
    final Map<String, String> queryParams = {};
    if (yearId != null && yearId.isNotEmpty && yearId != 'All') {
      queryParams['yearId'] = yearId;
    }
    if (departmentId != null &&
        departmentId.isNotEmpty &&
        departmentId != 'All') {
      queryParams['departmentId'] = departmentId;
    }

    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/leaderboard/filters',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data['success'] == true && data['data'] is Map) {
          return Map<String, dynamic>.from(data['data']);
        }
      }
    } catch (_) {}

    // Fallback: Fetch departments and years from admin endpoints
    try {
      final dRes = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/admin/departments?all=true'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final yRes = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/admin/years'),
        headers: {'Authorization': 'Bearer $token'},
      );
      List<dynamic> depts = [];
      List<dynamic> years = [];
      if (dRes.statusCode == 200) {
        final d = jsonDecode(dRes.body);
        depts = d['data'] is List ? d['data'] : (d is List ? d : []);
      }
      if (yRes.statusCode == 200) {
        final y = jsonDecode(yRes.body);
        years = y['data'] is List ? y['data'] : (y is List ? y : []);
      }
      return {
        'years': years,
        'departments': depts,
        'sections': [],
      };
    } catch (_) {}

    return {'years': [], 'departments': [], 'sections': []};
  }
}
