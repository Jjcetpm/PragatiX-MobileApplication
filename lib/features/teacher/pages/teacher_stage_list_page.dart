import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/core/config/api_config.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/core/utils/error_handler.dart';
import 'package:pragatix/features/activity/pages/cc_stage_list_page.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/features/badge/pages/cc_badge_requests_page.dart';
import 'package:pragatix/features/penalty/pages/penalty_requests_page.dart'
    as spdms_penalty;
import 'package:pragatix/features/penalty/providers/penalty_provider.dart';
import 'package:pragatix/features/teacher/pages/students_tab.dart';
import 'package:pragatix/features/teacher/pages/teacher_stage_details_page.dart';
import 'package:pragatix/features/teacher/services/teacher_activity_service.dart';
import 'package:pragatix/features/teacher/services/teacher_proxy_service.dart';

class TeacherStageListPage extends StatefulWidget {
  final List<String> subRoles;

  const TeacherStageListPage({
    super.key,
    this.subRoles = const [],
  });

  @override
  State<TeacherStageListPage> createState() => _TeacherStageListPageState();
}

class _TeacherStageListPageState extends State<TeacherStageListPage> {
  late final TeacherActivityService _activityService;

  static const Color _dark = Color(0xFF1E293B);
  static const Color _tealPrimary = Color(0xFF11998E);

  final List<Map<String, String>> _academicYears = [
    {'label': 'FIRST YEAR', 'value': 'FIRST_YEAR'},
    {'label': 'SECOND YEAR', 'value': 'SECOND_YEAR'},
    {'label': 'THIRD YEAR', 'value': 'THIRD_YEAR'},
    {'label': 'FOURTH YEAR', 'value': 'FOURTH_YEAR'},
  ];

  String _selectedAcademicYear = 'FIRST_YEAR';
  List<Map<String, dynamic>> _stages = [];
  bool _isLoading = true;
  int _pendingBadgeRequests = 0;
  int _pendingPenaltyRequests = 0;

  bool get _isCc => widget.subRoles.any(
        (r) =>
            r.toUpperCase() == 'CC' ||
            r.toUpperCase() == 'CLASS_COORDINATOR' ||
            r.toUpperCase() == 'ROLE_CC' ||
            r.toUpperCase() == 'ROLE_CLASS_COORDINATOR',
      );

  @override
  void initState() {
    super.initState();
    _activityService = TeacherActivityService(context.read<AuthProvider>());
    _loadInitialData();
    if (_isCc) {
      _fetchPendingBadges();
    }
  }

  Future<void> _loadInitialData() async {
    try {
      final token = context.read<AuthProvider>().token;
      if (token != null && _isCc) {
        final response = await getIt<TeacherProxyService>().get(
          Uri.parse('${ApiConfig.baseUrl}/api/v1/cc/class-details'),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true && data['data'] != null) {
            final year = (data['data']['year'] ?? '').toString().toUpperCase();
            if (year.contains('2') || year.contains('SECOND')) {
              _selectedAcademicYear = 'SECOND_YEAR';
            } else if (year.contains('3') || year.contains('THIRD')) {
              _selectedAcademicYear = 'THIRD_YEAR';
            } else if (year.contains('4') || year.contains('FOURTH')) {
              _selectedAcademicYear = 'FOURTH_YEAR';
            } else {
              _selectedAcademicYear = 'FIRST_YEAR';
            }
          }
        }
      }
    } catch (_) {}

    _fetchStages();
  }

  Future<void> _fetchPendingBadges() async {
    try {
      final token = context.read<AuthProvider>().token;
      if (token == null) return;
      final response = await getIt<TeacherProxyService>().get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/cc/dashboard/stats'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && mounted) {
          final pBadges = data['data']['pendingBadgeRequests'] ?? 0;
          final pPenalties = data['data']['pendingPenaltyRequests'] ?? 0;
          setState(() {
            _pendingBadgeRequests = pBadges;
            _pendingPenaltyRequests = pPenalties;
          });
          context.read<PenaltyProvider>().setPendingCount(pPenalties);
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchStages() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final list = await _activityService.fetchStages(
        academicYear: _selectedAcademicYear,
      );
      if (mounted) {
        setState(() {
          _stages = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ErrorHandler.showSnackBar(context, e);
      }
    }
  }

  void _onStageSelected(Map<String, dynamic> stage) {
    final stageId = (stage['id'] as num).toInt();
    final stageName = (stage['name'] ?? 'Stage').toString();
    final stageDescription = (stage['description'] ?? '').toString();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TeacherStageDetailsPage(
          stageId: stageId,
          stageName: stageName,
          stageDescription: stageDescription,
          stageData: stage,
          academicYear: _selectedAcademicYear,
        ),
      ),
    ).then((_) => _fetchStages());
  }

  void _navigateToAssignStaff() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CCStageListPage(
          isSubPage: true,
        ),
      ),
    ).then((_) => _fetchStages());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Activities',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF334155)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 2,
        actions: [
          if (_isCc) ...[
            IconButton(
              icon: Badge(
                isLabelVisible: _pendingBadgeRequests > 0,
                label: Text(
                  _pendingBadgeRequests.toString(),
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.red,
                child: const Icon(
                  Icons.notifications,
                  color: Colors.white,
                ),
              ),
              tooltip: 'Badge Requests',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CCBadgeRequestsPage(),
                  ),
                ).then((_) => _fetchPendingBadges());
              },
            ),
            IconButton(
              icon: const Icon(
                Icons.people_alt_rounded,
                color: Colors.white,
              ),
              tooltip: 'Students Directory',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        StudentsTab(subRoles: widget.subRoles),
                  ),
                );
              },
            ),
          ],
          Consumer<PenaltyProvider>(
            builder: (context, penaltyProvider, _) {
              final count = penaltyProvider.pendingCount > 0
                  ? penaltyProvider.pendingCount
                  : _pendingPenaltyRequests;
              return IconButton(
                icon: Badge(
                  isLabelVisible: count > 0,
                  label: Text(
                    count.toString(),
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.gavel_rounded, color: Colors.white),
                ),
                tooltip: 'Penalty Requests',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => spdms_penalty.PenaltyRequestsPage(
                        isCC: _isCc,
                      ),
                    ),
                  ).then((_) => _fetchPendingBadges());
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Refresh',
            onPressed: _fetchStages,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Top Control Panel: Academic Year Dropdown & CC Assign Staff Button ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Academic Year Selector
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.calendar_today_rounded,
                        color: Color(0xFF1E293B),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Academic Year:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedAcademicYear,
                            isExpanded: true,
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Color(0xFF1E293B),
                            ),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                            items: _academicYears.map((ay) {
                              return DropdownMenuItem<String>(
                                value: ay['value'],
                                child: Text(ay['label']!),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null && val != _selectedAcademicYear) {
                                setState(() => _selectedAcademicYear = val);
                                _fetchStages();
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // CC Only: "Assign Staff" Action Button
                if (_isCc) ...[
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _navigateToAssignStaff,
                    icon: const Icon(Icons.assignment_ind_rounded, size: 18),
                    label: const Text(
                      'Assign Staff',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _tealPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 1,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Stage Cards List ──
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchStages,
              color: _tealPrimary,
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: _tealPrimary),
                    )
                  : _stages.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.45,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.layers_clear_outlined,
                                      size: 64,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No stages for ${_academicYears.firstWhere((ay) => ay['value'] == _selectedAcademicYear)['label']}',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Select another Academic Year or pull down to refresh',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          itemCount: _stages.length,
                          itemBuilder: (context, index) {
                            final stage = _stages[index];
                            final stageName = (stage['name'] ?? 'Stage ${index + 1}').toString();
                            final description = (stage['description'] ?? 'No description available').toString();
                            final status = (stage['status'] ?? 'ACTIVE').toString().toUpperCase();
                            final displayOrder = (stage['displayOrder'] ?? (index + 1)).toString();
                            final expectedXp = (stage['expectedXp'] ?? stage['xp'] ?? 0).toString();
                            final mThresh = (stage['mustThreshold'] ?? 0).toString();
                            final iThresh = (stage['individualThreshold'] ?? 0).toString();
                            final gThresh = (stage['groupThreshold'] ?? 0).toString();

                            Color statusColor = Colors.green;
                            if (status == 'UPCOMING') statusColor = Colors.amber.shade800;
                            if (status == 'INACTIVE') statusColor = Colors.grey;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 14),
                              elevation: 3,
                              shadowColor: Colors.black.withOpacity(0.12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => _onStageSelected(stage),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Header Row: Status badge & Expected XP
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: statusColor.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: statusColor.withOpacity(0.3)),
                                            ),
                                            child: Text(
                                              status,
                                              style: TextStyle(
                                                color: statusColor,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          if (expectedXp != '0')
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF1E293B).withOpacity(0.08),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'Expected: $expectedXp XP',
                                                style: const TextStyle(
                                                  color: _dark,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),

                                      // Stage Name & Chevron
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              stageName,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: _dark,
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            Icons.chevron_right_rounded,
                                            color: Colors.grey.shade400,
                                            size: 26,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),

                                      // Description
                                      Text(
                                        description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600,
                                          height: 1.3,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Divider(height: 1, color: Colors.grey.shade100),
                                      const SizedBox(height: 10),

                                      // Threshold Chips Row
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Order: $displayOrder',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade700,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.red.shade50,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'M: $mThresh',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.red.shade800,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade50,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'I: $iThresh',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.blue.shade800,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade50,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'G: $gThresh',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.green.shade800,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
