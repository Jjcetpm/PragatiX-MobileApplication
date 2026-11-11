import 'dart:convert';
import 'package:pragatix/core/config/api_config.dart';
import 'package:pragatix/core/utils/api_client.dart' as http;
import 'package:pragatix/features/banking/models/banking_models.dart';

class BankingService {
  final String token;
  static const String baseUrl = ApiConfig.baseUrl;

  BankingService({required this.token});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // --- Student Banking ---
  Future<List<StudentBankSummaryModel>> getMyBanks() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/banking/my-banks'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final list = (decoded is List) ? decoded : (decoded is Map && decoded.containsKey('data') && decoded['data'] is List ? decoded['data'] as List : []);
      return list.map((e) => StudentBankSummaryModel.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      return [];
    }
  }

  Future<StudentBankSummaryModel> getMyBankSummary({int? bankId}) async {
    final uri = bankId != null
        ? Uri.parse('$baseUrl/api/v1/banking/my-bank?bankId=$bankId')
        : Uri.parse('$baseUrl/api/v1/banking/my-bank');

    final response = await http.get(
      uri,
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final data = (json is Map && json.containsKey('data') && json['data'] is Map)
          ? json['data'] as Map<String, dynamic>
          : json as Map<String, dynamic>;
      return StudentBankSummaryModel.fromJson(data);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to load banking summary');
    }
  }

  Future<List<StudentBankingTransactionModel>> getMyBankTransactions({
    required int bankId,
    String? search,
    String? type,
    int page = 0,
    int size = 5000,
  }) async {
    final queryParams = <String, String>{
      'bankId': bankId.toString(),
      'page': page.toString(),
      'size': size.toString(),
    };
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (type != null && type.isNotEmpty && type != 'ALL') queryParams['type'] = type;

    final uri = Uri.parse('$baseUrl/api/v1/banking/my-bank/transactions').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final payload = (json is Map && json.containsKey('data')) ? json['data'] : json;
      final List<dynamic> content = (payload is Map && payload.containsKey('content'))
          ? payload['content'] as List<dynamic>
          : (payload is List ? payload : []);
      return content.map((e) => StudentBankingTransactionModel.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      return [];
    }
  }

  // --- Admin Bank Dashboard Stats ---
  Future<BankDashboardStatsModel> getDashboardStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/banking/dashboard/stats'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return BankDashboardStatsModel.fromJson(json as Map<String, dynamic>);
    } else {
      return BankDashboardStatsModel();
    }
  }

  // --- List Banks ---
  Future<List<BankModel>> getBanks({String? status}) async {
    final uri = status != null && status.isNotEmpty
        ? Uri.parse('$baseUrl/api/v1/banking?status=$status')
        : Uri.parse('$baseUrl/api/v1/banking');

    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => BankModel.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load banks');
    }
  }

  // --- Bank Details ---
  Future<BankModel> getBankById(int bankId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/banking/$bankId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return BankModel.fromJson(json as Map<String, dynamic>);
    } else {
      throw Exception('Failed to load bank details');
    }
  }

  // --- Delete Bank ---
  Future<void> deleteBank(int bankId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/v1/banking/$bankId'),
      headers: _headers,
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to delete bank');
    }
  }

  // --- Stages ---
  Future<List<BankStageModel>> getStages(int bankId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/banking/$bankId/stages'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => BankStageModel.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load stages');
    }
  }

  // --- Subgroups ---
  Future<List<BankSubgroupModel>> getSubgroups(int bankId, int stageId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/banking/$bankId/stages/$stageId/subgroups'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => BankSubgroupModel.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load subgroups');
    }
  }

  // --- Banking Preview ---
  Future<BankingPreviewModel> getPreview(int bankId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/banking/$bankId/preview'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return BankingPreviewModel.fromJson(json as Map<String, dynamic>);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to calculate banking preview');
    }
  }

  // --- Execute Banking ---
  Future<Map<String, dynamic>> executeBanking(int bankId, {String? notes}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/banking/$bankId/execute'),
      headers: _headers,
      body: jsonEncode({
        'idempotencyKey': 'mob_${DateTime.now().millisecondsSinceEpoch}',
        'notes': notes ?? 'Executed via mobile app',
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Banking execution failed');
    }
  }

  // --- Reset Balances ---
  Future<ResetHistoryModel> executeReset({
    required int bankId,
    required String scope,
    int? targetId,
    required String reason,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/banking/reset'),
      headers: _headers,
      body: jsonEncode({
        'bankId': bankId,
        'scope': scope,
        'targetId': targetId,
        'reason': reason,
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return ResetHistoryModel.fromJson(json as Map<String, dynamic>);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Reset failed');
    }
  }

  Future<List<ResetHistoryModel>> getResetHistory(int bankId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/banking/$bankId/reset-history'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final list = (json is List)
          ? json
          : (json is Map && json.containsKey('data') && json['data'] is List
              ? json['data'] as List
              : (json is Map && json.containsKey('content') && json['content'] is List
                  ? json['content'] as List
                  : []));
      return list.map((e) => ResetHistoryModel.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      return [];
    }
  }

  // --- Finalized Student Banking Records ---
  Future<List<StudentBankingRecordModel>> getStudentRecords(
    int bankId, {
    int page = 0,
    int size = 5000,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/banking/$bankId/records?page=$page&size=$size'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List<dynamic> content = json['content'] as List<dynamic>? ?? [];
      return content.map((e) => StudentBankingRecordModel.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      return [];
    }
  }

  // --- Staff Student Bank Summary & Transactions ---
  Future<StudentBankSummaryModel> getStudentBankSummary(int bankId, int studentId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/banking/$bankId/students/$studentId/summary'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final data = (json is Map && json.containsKey('data') && json['data'] is Map)
          ? json['data'] as Map<String, dynamic>
          : json as Map<String, dynamic>;
      return StudentBankSummaryModel.fromJson(data);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to load student banking summary');
    }
  }

  Future<List<StudentBankingTransactionModel>> getStudentBankTransactions(
    int bankId,
    int studentId, {
    String? search,
    String? type,
    int page = 0,
    int size = 5000,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
    };
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (type != null && type.isNotEmpty && type != 'ALL') queryParams['type'] = type;

    final uri = Uri.parse('$baseUrl/api/v1/banking/$bankId/students/$studentId/transactions')
        .replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final payload = (json is Map && json.containsKey('data')) ? json['data'] : json;
      final List<dynamic> content = (payload is Map && payload.containsKey('content'))
          ? payload['content'] as List<dynamic>
          : (payload is List ? payload : []);
      return content.map((e) => StudentBankingTransactionModel.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      return [];
    }
  }

  // --- Bank Settings ---
  Future<BankSettingsModel> getBankSettings(int bankId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/banking/$bankId/settings'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final data = (json is Map && json.containsKey('data')) ? json['data'] : json;
      return BankSettingsModel.fromJson(data as Map<String, dynamic>);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to load bank settings');
    }
  }

  // --- Reset Preview ---
  Future<ResetPreviewModel> previewReset({
    required int bankId,
    required String scope,
    int? targetId,
    String? studentRegNo,
  }) async {
    final queryParams = <String, String>{
      'scope': scope,
    };
    if (targetId != null) queryParams['targetId'] = targetId.toString();
    if (studentRegNo != null && studentRegNo.isNotEmpty) {
      queryParams['studentRegNo'] = studentRegNo;
    }

    final uri = Uri.parse('$baseUrl/api/v1/banking/$bankId/reset/preview')
        .replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final data = (json is Map && json.containsKey('data')) ? json['data'] : json;
      return ResetPreviewModel.fromJson(data as Map<String, dynamic>);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to load reset preview');
    }
  }

  // --- Restore Preview ---
  Future<RestorePreviewModel> previewRestore({
    required int bankId,
    required String scope,
    int? targetStageId,
    int? targetSubgroupId,
    int? targetStudentId,
    String? targetStudentRegNo,
  }) async {
    final queryParams = <String, String>{
      'restoreScope': scope,
    };
    if (targetStageId != null) queryParams['targetStageId'] = targetStageId.toString();
    if (targetSubgroupId != null) queryParams['targetSubgroupId'] = targetSubgroupId.toString();
    if (targetStudentId != null) queryParams['targetStudentId'] = targetStudentId.toString();
    if (targetStudentRegNo != null && targetStudentRegNo.isNotEmpty) {
      queryParams['targetStudentRegNo'] = targetStudentRegNo;
    }

    final uri = Uri.parse('$baseUrl/api/v1/banking/$bankId/restore/preview')
        .replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final data = (json is Map && json.containsKey('data')) ? json['data'] : json;
      return RestorePreviewModel.fromJson(data as Map<String, dynamic>);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to load restore preview');
    }
  }

  // --- Execute Restore ---
  Future<RestoreHistoryModel> executeRestore({
    required int bankId,
    required String scope,
    int? targetStageId,
    int? targetSubgroupId,
    int? targetStudentId,
    String? targetStudentRegNo,
    required String reason,
    String? idempotencyKey,
  }) async {
    final body = <String, dynamic>{
      'bankId': bankId,
      'scope': scope,
      'targetStageId': targetStageId,
      'targetSubgroupId': targetSubgroupId,
      'targetStudentId': targetStudentId,
      'targetStudentRegNo': targetStudentRegNo,
      'reason': reason,
      'idempotencyKey': idempotencyKey,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/banking/$bankId/restore'),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final data = (json is Map && json.containsKey('data')) ? json['data'] : json;
      return RestoreHistoryModel.fromJson(data as Map<String, dynamic>);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Restore execution failed');
    }
  }

  // --- Restore History ---
  Future<List<RestoreHistoryModel>> getRestoreHistory(
    int bankId, {
    int page = 0,
    int size = 5000,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/banking/$bankId/restore-history?page=$page&size=$size'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final payload = (json is Map && json.containsKey('data')) ? json['data'] : json;
      final List<dynamic> content = (payload is Map && payload.containsKey('content'))
          ? payload['content'] as List<dynamic>
          : (payload is List ? payload : []);
      return content.map((e) => RestoreHistoryModel.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      return [];
    }
  }
}
