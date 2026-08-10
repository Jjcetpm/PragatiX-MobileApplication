import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:pragatix/features/activity/services/activity_proxy_service.dart';
import 'dart:convert';
import 'package:pragatix/core/config/api_config.dart';

import 'package:pragatix/features/activity/pages/group_activity_sec_page.dart';
import 'package:pragatix/features/activity/pages/group_activity_execution_page.dart';
import 'package:pragatix/core/di/service_locator.dart';

class GroupActivityDeptPage extends StatefulWidget {
  final int activityId;
  final dynamic selectedYear;
  final int? stageId;

  const GroupActivityDeptPage({
    super.key,
    required this.activityId,
    required this.selectedYear,
    this.stageId,
  });

  @override
  State<GroupActivityDeptPage> createState() => _GroupActivityDeptPageState();
}

class _GroupActivityDeptPageState extends State<GroupActivityDeptPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _availableDeptsList = [];

  // Theme constants
  static const Color _primary = Color(0xFF1E3A8A); // Deep blue
  static const Color _bg = Color(0xFFF8FAFC);
  static const Color _dark = Color(0xFF0F172A);

  @override
  void initState() {
    super.initState();
    _fetchDeptsForYear();
  }

  Future<void> _fetchDeptsForYear() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final yearNo = widget.selectedYear['yearNo'];
      String yearParam = 'I';
      if (yearNo == 2) yearParam = 'II';
      if (yearNo == 3) yearParam = 'III';
      if (yearNo == 4) yearParam = 'IV';

      final response = await getIt<ActivityProxyService>().get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/v1/my-activities/${widget.activityId}/departments?year=$yearParam',
        ),
        headers: {
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _availableDeptsList = data['data'] ?? [];
          });
        }
      } else {
        _errorMessage = 'Failed to load departments';
      }
    } catch (e) {
      _errorMessage = 'Failed to load departments: $e';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkSectionsAndNavigate(dynamic dept) async {
    // Show a loading dialog during silent check
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final yearNo = widget.selectedYear['yearNo'];
      String yearParam = 'I';
      if (yearNo == 2) yearParam = 'II';
      if (yearNo == 3) yearParam = 'III';
      if (yearNo == 4) yearParam = 'IV';
      final deptId = dept['id'];

      final response = await getIt<ActivityProxyService>().get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/v1/my-activities/${widget.activityId}/sections?year=$yearParam&departmentId=$deptId',
        ),
        headers: {
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
        },
      );

      // Close the loading dialog
      if (mounted) Navigator.pop(context);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> list = data['data'] ?? [];
          if (list.isNotEmpty) {
            // Sections exist, go to Section page
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GroupActivitySecPage(
                    activityId: widget.activityId,
                    selectedYear: widget.selectedYear,
                    selectedDept: dept,
                    availableSections: list,
                    stageId: widget.stageId,
                  ),
                ),
              );
            }
          } else {
            // No sections, skip to Groups page
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GroupActivityExecutionPage(
                    activityId: widget.activityId,
                    selectedYear: widget.selectedYear,
                    selectedDept: dept,
                    selectedSection: null, // skipped
                    stageId: widget.stageId,
                  ),
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close dialog on error
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error checking sections: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Select Department'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchDeptsForYear,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _availableDeptsList.length,
              itemBuilder: (context, index) {
                final dept = _availableDeptsList[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 1,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    title: Text(
                      dept['name'] ?? dept['departmentName'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _dark,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),
                    onTap: () => _checkSectionsAndNavigate(dept),
                  ),
                );
              },
            ),
    );
  }
}
