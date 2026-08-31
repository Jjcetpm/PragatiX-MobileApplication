import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pragatix/core/utils/api_client.dart' as http;
import 'package:pragatix/core/config/api_config.dart';

class StudentSearchProvider extends ChangeNotifier {
  List<dynamic> _allStudents = [];
  List<dynamic> _filteredStudents = [];
  bool _isLoading = false;
  String _error = '';
  String _searchQuery = '';

  List<dynamic> get filteredStudents => _filteredStudents;
  bool get isLoading => _isLoading;
  String get error => _error;

  static String? normalizeYear(dynamic year) {
    if (year == null) return null;
    final clean = year.toString().trim().toUpperCase();
    if (clean.isEmpty || clean == 'ALL' || clean == 'NULL') return null;

    // Check 4th year / IV / 4
    if (clean.contains('FOURTH') ||
        clean.contains('4TH') ||
        clean.contains('IV') ||
        RegExp(r'(^|\D)4(\D|$)').hasMatch(clean)) {
      return '4';
    }
    // Check 3rd year / III / 3
    if (clean.contains('THIRD') ||
        clean.contains('3RD') ||
        clean.contains('III') ||
        RegExp(r'(^|\D)3(\D|$)').hasMatch(clean)) {
      return '3';
    }
    // Check 2nd year / II / 2
    if (clean.contains('SECOND') ||
        clean.contains('2ND') ||
        clean.contains('II') ||
        RegExp(r'(^|\D)2(\D|$)').hasMatch(clean)) {
      return '2';
    }
    // Check 1st year / I / 1
    if (clean.contains('FIRST') ||
        clean.contains('1ST') ||
        RegExp(r'(^|\D)I(\D|$)').hasMatch(clean) ||
        RegExp(r'(^|\D)1(\D|$)').hasMatch(clean)) {
      return '1';
    }
    return clean;
  }

  static bool isYearMatching(String? filterYear, dynamic student) {
    if (filterYear == null ||
        filterYear.trim().isEmpty ||
        filterYear.trim().toLowerCase() == 'all') {
      return true;
    }
    final targetNorm = normalizeYear(filterYear);
    if (targetNorm == null) return true;

    final sYear = student['year'];
    final sYearNo = student['yearNo'];
    final sYearRef = student['yearRef'] is Map
        ? (student['yearRef']['yearNo'] ?? student['yearRef']['name'] ?? student['yearRef']['yearName'])
        : null;
    final sAcadYear = student['academicYear'];

    final sYearNorm = normalizeYear(sYear);
    final sYearNoNorm = normalizeYear(sYearNo);
    final sYearRefNorm = normalizeYear(sYearRef);
    final sAcadYearNorm = normalizeYear(sAcadYear);

    return targetNorm == sYearNorm ||
        targetNorm == sYearNoNorm ||
        targetNorm == sYearRefNorm ||
        targetNorm == sAcadYearNorm;
  }

  static bool isDeptMatching(dynamic filterDeptId, dynamic student) {
    if (filterDeptId == null ||
        filterDeptId.toString().isEmpty ||
        filterDeptId.toString() == '0' ||
        filterDeptId.toString().toLowerCase() == 'all') {
      return true;
    }
    final targetDeptStr = filterDeptId.toString().trim().toLowerCase();

    final sDeptId = student['departmentId'];
    if (sDeptId != null && sDeptId.toString().trim().toLowerCase() == targetDeptStr) {
      return true;
    }

    if (student['department'] is Map) {
      final mapId = student['department']['id'];
      if (mapId != null && mapId.toString().trim().toLowerCase() == targetDeptStr) {
        return true;
      }
      final mapName = student['department']['name'] ?? student['department']['deptName'];
      if (mapName != null && mapName.toString().trim().toLowerCase() == targetDeptStr) {
        return true;
      }
    }

    final sDeptName = student['departmentName'] ??
        (student['department'] is String ? student['department'] : null);
    if (sDeptName != null && sDeptName.toString().trim().toLowerCase() == targetDeptStr) {
      return true;
    }

    return false;
  }

  static bool isSectionMatching(dynamic filterSectionId, dynamic student) {
    if (filterSectionId == null ||
        filterSectionId.toString().isEmpty ||
        filterSectionId.toString() == '0' ||
        filterSectionId.toString().toLowerCase() == 'all') {
      return true;
    }
    final targetSecStr = filterSectionId.toString().trim().toLowerCase();

    final sSecId = student['sectionId'];
    if (sSecId != null && sSecId.toString().trim().toLowerCase() == targetSecStr) {
      return true;
    }

    if (student['section'] is Map) {
      final mapId = student['section']['id'];
      if (mapId != null && mapId.toString().trim().toLowerCase() == targetSecStr) {
        return true;
      }
      final mapName = student['section']['sectionName'] ?? student['section']['name'];
      if (mapName != null && mapName.toString().trim().toLowerCase() == targetSecStr) {
        return true;
      }
    }

    final sSecName = student['sectionName'] ??
        (student['section'] is String ? student['section'] : null);
    if (sSecName != null && sSecName.toString().trim().toLowerCase() == targetSecStr) {
      return true;
    }

    return false;
  }

  Future<void> fetchStudents(
    String token, {
    bool forceRefresh = false,
    String? year,
    dynamic departmentId,
    dynamic sectionId,
    bool unassignedOnly = false,
  }) async {
    _isLoading = true;
    _error = '';
    _filteredStudents = [];
    notifyListeners();

    try {
      final queryParams = <String, String>{
        'page': '0',
        'size': '1000',
        'sortBy': 'fullName',
      };

      final normYear = normalizeYear(year);
      if (normYear != null && normYear.isNotEmpty) {
        queryParams['year'] = normYear;
      }
      if (departmentId != null && departmentId.toString().isNotEmpty && departmentId.toString() != '0') {
        queryParams['departmentId'] = departmentId.toString();
      }
      if (sectionId != null && sectionId.toString().isNotEmpty && sectionId.toString() != '0') {
        queryParams['sectionId'] = sectionId.toString();
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/students').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true &&
            data['data'] != null &&
            data['data']['content'] != null) {
          final List<dynamic> list = List.from(data['data']['content']);
          _allStudents = list;
          
          // Apply strict in-memory filtering immediately before notifying listeners
          _applyFilters(
            query: _searchQuery,
            unassignedOnly: unassignedOnly,
            year: year,
            departmentId: departmentId,
            sectionId: sectionId,
          );
        } else {
          _error = 'Failed to load students format';
          _filteredStudents = [];
        }
      } else {
        _error = 'Failed to load students: ${response.statusCode}';
        _filteredStudents = [];
      }
    } catch (e) {
      _error = 'Error loading students: $e';
      _filteredStudents = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _applyFilters({
    required String query,
    bool unassignedOnly = false,
    String? year,
    dynamic departmentId,
    dynamic sectionId,
  }) {
    _searchQuery = query.toLowerCase().trim();

    _filteredStudents = _allStudents.where((student) {
      if (unassignedOnly && student['teamId'] != null) {
        return false;
      }
      if (!isYearMatching(year, student)) {
        return false;
      }
      if (!isDeptMatching(departmentId, student)) {
        return false;
      }
      if (!isSectionMatching(sectionId, student)) {
        return false;
      }

      if (_searchQuery.isNotEmpty) {
        final name = (student['fullName'] ?? '').toString().toLowerCase();
        final regNo = (student['regNo'] ?? '').toString().toLowerCase();
        final sprNo = (student['sprNo'] ?? '').toString().toLowerCase();
        final email = (student['email'] ?? '').toString().toLowerCase();

        return name.contains(_searchQuery) ||
            regNo.contains(_searchQuery) ||
            sprNo.contains(_searchQuery) ||
            email.contains(_searchQuery);
      }
      return true;
    }).toList();

    _filteredStudents.sort((a, b) {
      final nameA = (a['fullName'] ?? '').toString().trim().toLowerCase();
      final nameB = (b['fullName'] ?? '').toString().trim().toLowerCase();
      final comp = nameA.compareTo(nameB);
      if (comp != 0) return comp;
      final regA = (a['regNo'] ?? '').toString().trim().toLowerCase();
      final regB = (b['regNo'] ?? '').toString().trim().toLowerCase();
      return regA.compareTo(regB);
    });
  }

  void searchStudents(
    String query, {
    bool unassignedOnly = false,
    String? year,
    dynamic departmentId,
    dynamic sectionId,
  }) {
    _applyFilters(
      query: query,
      unassignedOnly: unassignedOnly,
      year: year,
      departmentId: departmentId,
      sectionId: sectionId,
    );
    notifyListeners();
  }
}
