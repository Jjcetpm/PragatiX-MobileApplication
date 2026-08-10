import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:pragatix/features/activity/services/activity_proxy_service.dart';
import 'dart:convert';
import 'package:pragatix/core/config/api_config.dart';

import 'package:pragatix/features/activity/pages/group_activity_dept_page.dart';
import 'package:pragatix/core/di/service_locator.dart';

class GroupActivityYearPage extends StatefulWidget {
  final int activityId;
  final int? stageId;

  const GroupActivityYearPage({
    super.key,
    required this.activityId,
    this.stageId,
  });

  @override
  State<GroupActivityYearPage> createState() => _GroupActivityYearPageState();
}

class _GroupActivityYearPageState extends State<GroupActivityYearPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _availableYearsList = [];

  // Theme constants
  static const Color _primary = Color(0xFF1E3A8A); // Deep blue
  static const Color _bg = Color(0xFFF8FAFC);
  static const Color _dark = Color(0xFF0F172A);

  final List<Map<String, dynamic>> _fixedYears = [
    {'yearNo': 1, 'yearName': '1st Year'},
    {'yearNo': 2, 'yearName': '2nd Year'},
    {'yearNo': 3, 'yearName': '3rd Year'},
    {'yearNo': 4, 'yearName': '4th Year'},
  ];

  List<String> _getYearAliases(Map<String, dynamic> fy) {
    final no = fy['yearNo'];
    if (no == 1) return ['1', '1st year', 'i', 'first year', '1st'];
    if (no == 2) return ['2', '2nd year', 'ii', 'second year', '2nd'];
    if (no == 3) return ['3', '3rd year', 'iii', 'third year', '3rd'];
    if (no == 4) return ['4', '4th year', 'iv', 'fourth year', '4th'];
    return [];
  }

  @override
  void initState() {
    super.initState();
    _fetchYearsForEvent();
  }

  Future<void> _fetchYearsForEvent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await getIt<ActivityProxyService>().get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/v1/my-activities/${widget.activityId}/years',
        ),
        headers: {
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> yrs = data['data'] ?? [];
          setState(() {
            _availableYearsList = _fixedYears.where((fy) {
              final aliases = _getYearAliases(fy);
              return yrs.any(
                (y) => aliases.contains(y.toString().toLowerCase().trim()),
              );
            }).toList();
          });
        }
      } else {
        _errorMessage = 'Failed to load years';
      }
    } catch (e) {
      _errorMessage = 'Failed to load years: $e';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToNext(dynamic year) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GroupActivityDeptPage(
          activityId: widget.activityId,
          selectedYear: year,
          stageId: widget.stageId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Select Academic Year'),
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
                    onPressed: _fetchYearsForEvent,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _availableYearsList.length,
              itemBuilder: (context, index) {
                final year = _availableYearsList[index];
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
                      year['yearName'],
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
                    onTap: () => _navigateToNext(year),
                  ),
                );
              },
            ),
    );
  }
}
