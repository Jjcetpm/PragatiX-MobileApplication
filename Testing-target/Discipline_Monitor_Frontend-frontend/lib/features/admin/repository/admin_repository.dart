import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:pragatix/features/admin/services/admin_service.dart';
import 'package:pragatix/core/exceptions/api_exception.dart';

class AdminRepository {
  final AdminService _adminService;

  AdminRepository(this._adminService);

  // DEPARTMENTS
  Future<List<dynamic>> getDepartments() async {
    final response = await _adminService.get('/api/v1/admin/departments');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['data'] ?? [];
      }
    }
    throw Exception('Failed to load departments');
  }

  Future<List<dynamic>> getAcademicYears() async {
    final response = await _adminService.get('/api/v1/admin/academic-years');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) return data['data'] ?? [];
    }
    throw Exception('Failed to load academic years');
  }

  Future<List<dynamic>> getYears() async {
    final response = await _adminService.get('/api/v1/admin/years');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) return data['data'] ?? [];
    }
    throw Exception('Failed to load years');
  }

  Future<List<dynamic>> getSemesters() async {
    final response = await _adminService.get('/api/v1/admin/semesters');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) return data['data'] ?? [];
    }
    throw Exception('Failed to load semesters');
  }

  Future<List<dynamic>> getGenders() async {
    final response = await _adminService.get('/api/v1/admin/genders');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) return data['data'] ?? [];
    }
    throw Exception('Failed to load genders');
  }

  Future<List<dynamic>> getTeams() async {
    final response = await _adminService.get('/api/v1/teams');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) return data['data'] ?? [];
    }
    throw Exception('Failed to load teams');
  }

  Future<Map<String, dynamic>> addDepartment(String name, String code) async {
    final response = await _adminService.post('/api/v1/admin/departments', {
      'name': name,
      'code': code,
    });
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> editDepartment(
    int id,
    String name,
    String code,
  ) async {
    final response = await _adminService.put('/api/v1/admin/departments/$id', {
      'name': name,
      'code': code,
    });
    return _handleResponse(response);
  }

  Future<void> deleteDepartment(int id) async {
    final response = await _adminService.delete(
      '/api/v1/admin/departments/$id',
    );
    _handleResponse(response);
  }

  Future<List<dynamic>> getDepartmentSections(int deptId) async {
    final response = await _adminService.get(
      '/api/v1/admin/departments/$deptId/sections',
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['data'] ?? [];
      }
    }
    throw Exception('Failed to load sections');
  }

  Future<Map<String, dynamic>> addDepartmentSection(
    int deptId,
    String sectionName,
  ) async {
    final response = await _adminService.post(
      '/api/v1/admin/departments/$deptId/sections',
      {'sectionName': sectionName},
    );
    return _handleResponse(response);
  }

  Future<void> deleteDepartmentSection(int sectionId) async {
    final response = await _adminService.delete(
      '/api/v1/admin/sections/$sectionId',
    );
    _handleResponse(response);
  }

  // ROLES
  Future<List<dynamic>> getRoles() async {
    final response = await _adminService.get('/api/v1/admin/roles');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['data'] ?? [];
      }
    }
    throw Exception('Failed to load roles');
  }

  // SECTIONS (All)
  Future<List<dynamic>> getSections() async {
    final response = await _adminService.get('/api/v1/admin/sections');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['data'] ?? [];
      }
    }
    throw Exception('Failed to load sections');
  }

  // SUBJECTS
  Future<List<dynamic>> getSubjects() async {
    final response = await _adminService.get('/api/v1/admin/subjects');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['data'] ?? [];
      }
    }
    throw Exception('Failed to load subjects');
  }

  Future<Map<String, dynamic>> addSubject(String name) async {
    final response = await _adminService.post('/api/v1/admin/subjects', {
      'name': name,
    });
    return _handleResponse(response);
  }

  Future<void> deleteSubject(int id) async {
    final response = await _adminService.delete('/api/v1/admin/subjects/$id');
    _handleResponse(response);
  }

  // USERS
  Future<List<dynamic>> getUsers() async {
    final response = await _adminService.get('/api/v1/admin/users');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['data'] ?? [];
      }
    }
    throw Exception('Failed to load users');
  }

  Future<Map<String, dynamic>> addUser(Map<String, dynamic> userData) async {
    final response = await _adminService.post('/api/v1/admin/users', userData);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateUser(
    int id,
    Map<String, dynamic> userData,
  ) async {
    final response = await _adminService.put(
      '/api/v1/admin/users/$id',
      userData,
    );
    return _handleResponse(response);
  }

  Future<void> deleteUser(int id) async {
    final response = await _adminService.delete('/api/v1/admin/users/$id');
    _handleResponse(response);
  }

  // STUDENTS
  Future<Map<String, dynamic>> getStudentsPaginated({
    int page = 0,
    int size = 1000,
    String sortBy = 'fullName',
  }) async {
    final response = await _adminService.get(
      '/api/v1/students?page=$page&size=$size&sortBy=$sortBy',
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        final content = data['data'];
        if (content is Map<String, dynamic>) {
          final List<dynamic> list = content['content'] as List<dynamic>? ?? [];
          final int totalElements = content['totalElements'] ?? list.length;
          final int totalPages = content['totalPages'] ?? 1;
          final bool last = content['last'] ?? true;
          final int number = content['number'] ?? page;
          debugPrint(
            'AdminRepository: Loaded ${list.length} students (Page $number of $totalPages, Total in DB: $totalElements)',
          );
          return {
            'content': list,
            'totalPages': totalPages,
            'totalElements': totalElements,
            'last': last,
            'number': number,
          };
        } else if (content is List) {
          debugPrint('AdminRepository: Loaded ${content.length} students');
          return {
            'content': content,
            'totalPages': 1,
            'totalElements': content.length,
            'last': true,
            'number': 0,
          };
        }
      }
    }
    throw Exception('Failed to load students');
  }

  Future<List<dynamic>> getStudents({
    int page = 0,
    int size = 1000,
    String sortBy = 'fullName',
  }) async {
    final res = await getStudentsPaginated(page: page, size: size, sortBy: sortBy);
    return res['content'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> searchStudents(
    String keyword, {
    int page = 0,
    int size = 1000,
  }) async {
    final response = await _adminService.get(
      '/api/v1/students/search?keyword=${Uri.encodeComponent(keyword)}&page=$page&size=$size',
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        final content = data['data'];
        if (content is Map<String, dynamic>) {
          final List<dynamic> list = content['content'] as List<dynamic>? ?? [];
          final int totalElements = content['totalElements'] ?? list.length;
          final int totalPages = content['totalPages'] ?? 1;
          final bool last = content['last'] ?? true;
          final int number = content['number'] ?? page;
          return {
            'content': list,
            'totalPages': totalPages,
            'totalElements': totalElements,
            'last': last,
            'number': number,
          };
        } else if (content is List) {
          return {
            'content': content,
            'totalPages': 1,
            'totalElements': content.length,
            'last': true,
            'number': 0,
          };
        }
      }
    }
    throw Exception('Failed to search students');
  }

  Future<Map<String, dynamic>> addStudent(
    Map<String, dynamic> studentData,
  ) async {
    final response = await _adminService.post('/api/v1/students', studentData);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateStudent(
    int id,
    Map<String, dynamic> studentData,
  ) async {
    final response = await _adminService.put(
      '/api/v1/students/$id',
      studentData,
    );
    return _handleResponse(response);
  }

  Future<void> deleteStudent(int id) async {
    final response = await _adminService.delete('/api/v1/students/$id');
    _handleResponse(response);
  }

  // STAGES
  Future<Map<String, dynamic>> getStats() async {
    final response = await _adminService.get('/api/v1/admin/stats');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['data'] ?? {};
      }
    }
    throw Exception('Failed to load stats');
  }

  Future<List<dynamic>> getStages({String? academicYear}) async {
    final url = academicYear != null && academicYear.isNotEmpty
        ? '/api/v1/admin/stages?academicYear=$academicYear'
        : '/api/v1/admin/stages';
    final response = await _adminService.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['data'] ?? [];
      }
    }
    throw Exception('Failed to load stages');
  }

  Future<Map<String, dynamic>> addStage(Map<String, dynamic> stageData) async {
    final response = await _adminService.post(
      '/api/v1/admin/stages',
      stageData,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateStage(
    int id,
    Map<String, dynamic> stageData,
  ) async {
    final response = await _adminService.put(
      '/api/v1/admin/stages/$id',
      stageData,
    );
    return _handleResponse(response);
  }

  Future<void> deleteStage(int id) async {
    final response = await _adminService.delete('/api/v1/admin/stages/$id');
    _handleResponse(response);
  }

  // PROFILE
  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await _adminService.get('/api/v1/auth/me');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['data'] ?? {};
      }
    }
    throw Exception('Failed to load profile');
  }

  // SUPER ADMIN (Year Admins)
  Future<List<dynamic>> getYearAdmins() async {
    final response = await _adminService.get('/api/v1/superadmin/year-admins');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['data'] ?? [];
      }
    }
    throw Exception('Failed to load year admins');
  }

  Future<Map<String, dynamic>> addYearAdmin(
    Map<String, dynamic> adminData,
  ) async {
    final response = await _adminService.post(
      '/api/v1/superadmin/year-admins',
      adminData,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateYearAdmin(
    int id,
    Map<String, dynamic> adminData,
  ) async {
    final response = await _adminService.put(
      '/api/v1/superadmin/year-admins/$id',
      adminData,
    );
    return _handleResponse(response);
  }

  Future<void> deleteYearAdmin(int id) async {
    final response = await _adminService.delete(
      '/api/v1/superadmin/year-admins/$id',
    );
    _handleResponse(response);
  }

  // CAPTAIN REWARD SETTINGS
  Future<Map<String, dynamic>> getCaptainRewardSettings(String academicYear) async {
    final response = await _adminService.get('/api/v1/admin/captain-reward/settings/$academicYear');
    final data = _handleResponse(response);
    return data['data'] ?? {};
  }

  Future<Map<String, dynamic>> updateCaptainRewardSettings(String academicYear, Map<String, dynamic> settings) async {
    final response = await _adminService.put(
      '/api/v1/admin/captain-reward/settings/$academicYear',
      settings,
    );
    final data = _handleResponse(response);
    return data['data'] ?? {};
  }

  // Generic handler for JSON response mapping
  Map<String, dynamic> _handleResponse(dynamic response) {
    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }
    throw ApiException(
      response.statusCode,
      data['message'] ?? 'An error occurred',
    );
  }
}
