import 'package:flutter/material.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/features/admin/repository/admin_repository.dart';

class DepartmentProvider extends ChangeNotifier {
  List<dynamic> _departments = [];
  bool _isLoading = false;
  String? _error;

  List<dynamic> get departments => _departments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchDepartments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _departments = await getIt<AdminRepository>().getDepartments(all: true);
    } catch (e) {
      _error = 'Failed to load departments: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
