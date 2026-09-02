import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:pragatix/features/admin/services/admin_service.dart';
import 'package:pragatix/core/exceptions/api_exception.dart';

class AdminRepository {
  final AdminService _adminService;

  AdminRepository(this._adminService);

  // DEPARTMENTS
  Future<List<dynamic>> getDepartments({bool all = false, String? type}) async {
    String endpoint = '/api/v1/admin/departments';
    if (type != null && type.isNotEmpty) {
      endpoint += '?type=$type';
    } else if (all) {
      endpoint += '?type=ALL';
    }
    final response = await _adminService.get(endpoint);
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

  Future<List<dynamic>> getAssignedYears() async {
    try {
      final years = await getYears();
      final admins = await getYearAdmins();

      final Set<String> assignedYearKeys = {};
      for (var a in admins) {
        if (a is Map) {
          final yId = a['assignedYearId']?.toString().trim();
          final yName = (a['assignedYearName'] ?? '').toString().trim().toLowerCase();
          if (yId != null && yId.isNotEmpty) assignedYearKeys.add(yId);
          if (yName.isNotEmpty && yName != 'null' && yName != 'not assigned') {
            assignedYearKeys.add(yName);
            if (yName.contains('first') || yName.contains('1')) {
              assignedYearKeys.add('1');
              assignedYearKeys.add('first year');
              assignedYearKeys.add('first_year');
            }
            if (yName.contains('second') || yName.contains('2')) {
              assignedYearKeys.add('2');
              assignedYearKeys.add('second year');
              assignedYearKeys.add('second_year');
            }
            if (yName.contains('third') || yName.contains('3')) {
              assignedYearKeys.add('3');
              assignedYearKeys.add('third year');
              assignedYearKeys.add('third_year');
            }
            if (yName.contains('fourth') || yName.contains('4')) {
              assignedYearKeys.add('4');
              assignedYearKeys.add('fourth year');
              assignedYearKeys.add('fourth_year');
            }
          }
        }
      }

      if (assignedYearKeys.isEmpty) {
        return years;
      }

      final filtered = years.where((y) {
        if (y is Map) {
          final idStr = y['id']?.toString().trim();
          final noStr = y['yearNo']?.toString().trim();
          final nameStr = (y['yearName'] ?? '').toString().trim().toLowerCase();
          final enumStr = nameStr.replaceAll(' ', '_');

          return (idStr != null && assignedYearKeys.contains(idStr)) ||
              (noStr != null && assignedYearKeys.contains(noStr)) ||
              (nameStr.isNotEmpty && assignedYearKeys.contains(nameStr)) ||
              (enumStr.isNotEmpty && assignedYearKeys.contains(enumStr));
        }
        return false;
      }).toList();

      return filtered.isNotEmpty ? filtered : years;
    } catch (_) {
      return getYears();
    }
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

  Future<Map<String, dynamic>> addDepartment(
    String name,
    String code,
    bool supportsSections, {
    String departmentType = 'MAIN',
  }) async {
    final response = await _adminService.post('/api/v1/admin/departments', {
      'name': name,
      'code': code,
      'departmentType': departmentType,
      'supportsSections': departmentType == 'SUB' ? false : supportsSections,
    });
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> editDepartment(
    int id,
    String name,
    String code,
    bool supportsSections, {
    String departmentType = 'MAIN',
  }) async {
    final response = await _adminService.put('/api/v1/admin/departments/$id', {
      'name': name,
      'code': code,
      'departmentType': departmentType,
      'supportsSections': departmentType == 'SUB' ? false : supportsSections,
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

  Future<List<dynamic>> getFilterDepartmentsByYear(String year) async {
    final response = await _adminService.get('/api/v1/students/filters/departments?year=${Uri.encodeComponent(year)}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['data'] ?? [];
      }
    }
    throw Exception('Failed to load filtered departments');
  }

  Future<List<dynamic>> getFilterSections({String? year, int? departmentId}) async {
    String url = '/api/v1/students/filters/sections?';
    if (year != null && year.trim().isNotEmpty) {
      url += 'year=${Uri.encodeComponent(year.trim())}&';
    }
    if (departmentId != null) {
      url += 'departmentId=$departmentId';
    }
    final response = await _adminService.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['data'] ?? [];
      }
    }
    throw Exception('Failed to load filtered sections');
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

  // GET ALL TEACHERS / USERS
  Future<List<dynamic>> getTeachers({int? departmentId, String? keyword}) async {
    String url = '/api/v1/admin/users';
    final List<String> queryParams = [];
    if (departmentId != null) {
      queryParams.add('departmentId=$departmentId');
    }
    if (keyword != null && keyword.trim().isNotEmpty) {
      queryParams.add('keyword=${Uri.encodeComponent(keyword.trim())}');
    }
    if (queryParams.isNotEmpty) {
      url += '?${queryParams.join('&')}';
    }
    final response = await _adminService.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['data'] ?? [];
      }
    }
    throw Exception('Failed to load teachers');
  }

  // GET TEACHER PROFILE & POINTS AWARDED HISTORY
  Future<Map<String, dynamic>> getTeacherPointsHistory(dynamic teacherId) async {
    final response = await _adminService.get('/api/v1/admin/users/$teacherId/points-history');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return Map<String, dynamic>.from(data['data']);
      }
    }
    throw Exception('Failed to load teacher points history');
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
    String? keyword,
    String? year,
    int? departmentId,
    int? sectionId,
  }) async {
    String url = '/api/v1/students?page=$page&size=$size&sortBy=$sortBy';
    if (keyword != null && keyword.trim().isNotEmpty) {
      url += '&keyword=${Uri.encodeComponent(keyword.trim())}';
    }
    if (year != null && year.trim().isNotEmpty) {
      url += '&year=${Uri.encodeComponent(year.trim())}';
    }
    if (departmentId != null) {
      url += '&departmentId=$departmentId';
    }
    if (sectionId != null) {
      url += '&sectionId=$sectionId';
    }

    final response = await _adminService.get(url);
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
    String? keyword,
    String? year,
    int? departmentId,
    int? sectionId,
  }) async {
    final res = await getStudentsPaginated(
      page: page,
      size: size,
      sortBy: sortBy,
      keyword: keyword,
      year: year,
      departmentId: departmentId,
      sectionId: sectionId,
    );
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

  Future<Map<String, dynamic>> batchUpdateStudents({
    required List<int> studentIds,
    int? departmentId,
    int? yearId,
    String? year,
    int? semesterId,
    String? semester,
    int? sectionId,
  }) async {
    final response = await _adminService.put(
      '/api/v1/students/batch-update',
      {
        'studentIds': studentIds,
        if (departmentId != null) 'departmentId': departmentId,
        if (yearId != null) 'yearId': yearId,
        if (year != null) 'year': year,
        if (semesterId != null) 'semesterId': semesterId,
        if (semester != null) 'semester': semester,
        if (sectionId != null) 'sectionId': sectionId,
      },
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

  // LEVELS MANAGEMENT
  Future<List<dynamic>> getLevels({String? academicYear}) async {
    String endpoint = '/api/admin/levels';
    if (academicYear != null && academicYear.isNotEmpty) {
      endpoint += '?academicYear=$academicYear';
    }
    final response = await _adminService.get(endpoint);
    final data = _handleResponse(response);
    return data['data'] ?? [];
  }

  Future<dynamic> createLevel(Map<String, dynamic> body) async {
    final response = await _adminService.post('/api/admin/levels', body);
    final data = _handleResponse(response);
    return data['data'];
  }

  Future<dynamic> updateLevel(int id, Map<String, dynamic> body) async {
    final response = await _adminService.put('/api/admin/levels/$id', body);
    final data = _handleResponse(response);
    return data['data'];
  }

  Future<void> deleteLevel(int id) async {
    final response = await _adminService.delete('/api/admin/levels/$id');
    _handleResponse(response);
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
