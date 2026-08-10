import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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

  Future<void> fetchStudents(String token) async {
    if (_allStudents.isNotEmpty) return; // Cache the students
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/v1/students?page=0&size=1000&sortBy=fullName',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true &&
            data['data'] != null &&
            data['data']['content'] != null) {
          final List<dynamic> list = List.from(data['data']['content']);
          list.sort((a, b) {
            final nameA = (a['fullName'] ?? '').toString().trim().toLowerCase();
            final nameB = (b['fullName'] ?? '').toString().trim().toLowerCase();
            final comp = nameA.compareTo(nameB);
            if (comp != 0) return comp;
            final regA = (a['regNo'] ?? '').toString().trim().toLowerCase();
            final regB = (b['regNo'] ?? '').toString().trim().toLowerCase();
            return regA.compareTo(regB);
          });
          _allStudents = list;
          _filteredStudents = _allStudents;
        } else {
          _error = 'Failed to load students format';
        }
      } else {
        _error = 'Failed to load students: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Error loading students: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void searchStudents(String query) {
    _searchQuery = query.toLowerCase();

    if (_searchQuery.isEmpty) {
      _filteredStudents = _allStudents;
    } else {
      _filteredStudents = _allStudents.where((student) {
        final name = (student['fullName'] ?? '').toString().toLowerCase();
        final regNo = (student['regNo'] ?? '').toString().toLowerCase();
        final sprNo = (student['sprNo'] ?? '').toString().toLowerCase();
        final email = (student['email'] ?? '').toString().toLowerCase();

        return name.contains(_searchQuery) ||
            regNo.contains(_searchQuery) ||
            sprNo.contains(_searchQuery) ||
            email.contains(_searchQuery);
      }).toList();
    }

    _filteredStudents.sort((a, b) {
      final nameA = (a['fullName'] ?? '').toString().trim().toLowerCase();
      final nameB = (b['fullName'] ?? '').toString().trim().toLowerCase();
      final comp = nameA.compareTo(nameB);
      if (comp != 0) return comp;
      final regA = (a['regNo'] ?? '').toString().trim().toLowerCase();
      final regB = (b['regNo'] ?? '').toString().trim().toLowerCase();
      return regA.compareTo(regB);
    });

    notifyListeners();
  }
}
