import 'package:flutter/material.dart';
import 'package:pragatix/core/theme/app_colors.dart';
import 'package:pragatix/core/utils/string_utils.dart';
import 'package:pragatix/features/activity/models/activity_model.dart';
import 'package:pragatix/features/activity/pages/assign_staff_page.dart';
import 'package:pragatix/features/activity/pages/edit_activity_page.dart';
import 'package:pragatix/features/activity/providers/activity_provider.dart';

class AdminActivityDetailsPage extends StatefulWidget {
  final ActivityModel activity;
  final ActivityProvider provider;
  final int? stageId;
  final String? subgroupName;
  final String? academicYear;
  final bool isCc;

  const AdminActivityDetailsPage({
    super.key,
    required this.activity,
    required this.provider,
    this.stageId,
    this.subgroupName,
    this.academicYear,
    this.isCc = false,
  });

  @override
  State<AdminActivityDetailsPage> createState() => _AdminActivityDetailsPageState();
}

class _AdminActivityDetailsPageState extends State<AdminActivityDetailsPage> {
  static const Color _primary = Color(0xFF2563EB);
  static const Color _dark = AppColors.darkSlate;

  late ActivityModel _currentActivity;

  @override
  void initState() {
    super.initState();
    _currentActivity = widget.activity;
    _loadDependencies();
  }

  Future<void> _loadDependencies() async {
    if (widget.provider.departments.isEmpty || widget.provider.allTeachers.isEmpty) {
      await widget.provider.loadDependencies();
      if (mounted) setState(() {});
    }
  }

  void _refreshActivity() {
    try {
      final updated = widget.provider.activities.firstWhere(
        (a) => a.id == _currentActivity.id,
        orElse: () => _currentActivity,
      );
      setState(() {
        _currentActivity = updated;
      });
    } catch (_) {}
  }

  Future<void> _openAssignStaff() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AssignStaffPage(
          provider: widget.provider,
          activity: _currentActivity,
          stageId: widget.stageId,
          isCc: widget.isCc,
        ),
      ),
    );
    if (mounted) {
      await widget.provider.loadActivities(
        stageId: widget.stageId,
        subgroupName: widget.subgroupName,
        academicYear: widget.academicYear,
      );
      _refreshActivity();
    }
  }

  Future<void> _openEditActivity() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditActivityPage(
          provider: widget.provider,
          activity: _currentActivity,
          isCc: widget.isCc,
          stageId: widget.stageId,
          subgroupName: widget.subgroupName,
          academicYear: widget.academicYear,
        ),
      ),
    );
    if (mounted && result == true) {
      await widget.provider.loadActivities(
        stageId: widget.stageId,
        subgroupName: widget.subgroupName,
        academicYear: widget.academicYear,
      );
      _refreshActivity();
    }
  }

  Future<void> _confirmDelete({required bool isGlobalDelete}) async {
    final title = isGlobalDelete ? 'Delete Activity Everywhere' : 'Remove from Stage';
    final content = isGlobalDelete
        ? 'Are you sure you want to permanently delete "${_currentActivity.name}"? This action cannot be undone.'
        : 'Are you sure you want to remove "${_currentActivity.name}" from this stage?';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isGlobalDelete ? const Color(0xFFEF4444) : const Color(0xFFD97706),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              if (!isGlobalDelete && widget.stageId != null) {
                try {
                  await widget.provider.unmapActivityFromStage(
                    widget.stageId!,
                    _currentActivity.id,
                    subgroupName: widget.subgroupName,
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Activity removed from stage successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context, true);
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceAll('Exception: ', '')),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } else {
                _executeGlobalDelete(_currentActivity, force: false);
              }
            },
            child: Text(isGlobalDelete ? 'Delete' : 'Remove'),
          ),
        ],
      ),
    );
  }

  Future<void> _executeGlobalDelete(ActivityModel activity, {bool force = false}) async {
    try {
      await widget.provider.deleteActivity(activity.id, force: force);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activity deleted everywhere'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('409:')) {
        final msg = errorStr.split('409:').last;
        if (mounted) {
          _showDependencyDialog(activity, msg);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $errorStr')),
          );
        }
      }
    }
  }

  void _showDependencyDialog(ActivityModel activity, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cannot Delete Activity'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _executeGlobalDelete(activity, force: true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Force Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cleanCategory = StringUtils.toTitleCase(
      _currentActivity.subgroup ?? widget.subgroupName ?? _currentActivity.xpCategory,
    );
    final activityType = _currentActivity.type.trim();
    final bool isCategorySameAsType = cleanCategory.trim().toLowerCase() == activityType.toLowerCase();

    final List<dynamic> allDepts = widget.provider.departments.isNotEmpty
        ? widget.provider.departments
        : _fallbackDepartmentsFromAssignments();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Activity Details',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
        ),
        backgroundColor: _primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Activity Overview Card ──────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and status badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          _currentActivity.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 19,
                            color: _dark,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _currentActivity.status.toUpperCase() == 'ACTIVE'
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _currentActivity.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _currentActivity.status.toUpperCase() == 'ACTIVE'
                                ? const Color(0xFF16A34A)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Subgroup and Type badges (NO DUPLICATES)
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _buildPill(
                        cleanCategory.toUpperCase(),
                        const Color(0xFFEEF2FF),
                        const Color(0xFF4F46E5),
                      ),
                      if (!isCategorySameAsType && activityType.isNotEmpty)
                        _buildPill(
                          activityType.toUpperCase(),
                          const Color(0xFFF3E8FF),
                          const Color(0xFF7C3AED),
                        ),
                      if (_currentActivity.assignmentMode.isNotEmpty)
                        _buildPill(
                          'MODE: ${_currentActivity.assignmentMode}',
                          const Color(0xFFE0F2FE),
                          const Color(0xFF0284C7),
                        ),
                    ],
                  ),

                  if (_currentActivity.description.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      _currentActivity.description,
                      style: TextStyle(fontSize: 13.5, color: Colors.grey.shade700, height: 1.4),
                    ),
                  ],

                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // Properties Grid (Reward, Penalty, Cap, Frequency)
                  Row(
                    children: [
                      if (_currentActivity.awardEnabled)
                        Expanded(
                          child: _buildMetricTile(
                            label: 'Reward XP',
                            value: '+${_currentActivity.awardXp} XP',
                            color: const Color(0xFF16A34A),
                            bgColor: const Color(0xFFDCFCE7),
                            icon: Icons.star_rounded,
                          ),
                        ),
                      if (_currentActivity.awardEnabled && _currentActivity.penaltyEnabled)
                        const SizedBox(width: 10),
                      if (_currentActivity.penaltyEnabled)
                        Expanded(
                          child: _buildMetricTile(
                            label: 'Penalty XP',
                            value: '-${_currentActivity.penaltyXp} XP',
                            color: const Color(0xFFDC2626),
                            bgColor: const Color(0xFFFEE2E2),
                            icon: Icons.warning_amber_rounded,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          label: 'Frequency',
                          value: _currentActivity.awardFrequency,
                          color: const Color(0xFFD97706),
                          bgColor: const Color(0xFFFEF3C7),
                          icon: Icons.repeat_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricTile(
                          label: 'Cap Limit',
                          value: '${_currentActivity.cap} / period',
                          color: const Color(0xFF0D9488),
                          bgColor: const Color(0xFFCCFBF1),
                          icon: Icons.speed_rounded,
                        ),
                      ),
                    ],
                  ),

                  // Evidence & Attendance info
                  if (_currentActivity.displayEvidence.isNotEmpty || _currentActivity.attendanceEngineEnabled) ...[
                    const SizedBox(height: 14),
                    if (_currentActivity.displayEvidence.isNotEmpty)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.assignment_outlined, size: 16, color: Color(0xFF64748B)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Evidence: ${_currentActivity.displayEvidence.join(", ")}',
                              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
                            ),
                          ),
                        ],
                      ),
                    if (_currentActivity.attendanceEngineEnabled) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.fact_check_outlined, size: 16, color: Color(0xFF2563EB)),
                          const SizedBox(width: 8),
                          Text(
                            'Attendance Engine: ${_currentActivity.attendanceRule ?? "Daily"}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── 2. Top Action Buttons (Placed right at the top) ─────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  // Row 1: Assign / Edit Staff (Primary action)
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: _openAssignStaff,
                      icon: const Icon(Icons.assignment_ind_rounded, size: 20),
                      label: const Text(
                        'Assign / Edit Staff',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Row 2: Edit Activity, Unmap from Stage, Delete Activity
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openEditActivity,
                          icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF2563EB)),
                          label: const Text('Edit', style: TextStyle(color: Color(0xFF2563EB), fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF93C5FD)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      if (widget.stageId != null) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _confirmDelete(isGlobalDelete: false),
                            icon: const Icon(Icons.remove_circle_outline, size: 16, color: Color(0xFFD97706)),
                            label: const Text('Unmap', style: TextStyle(color: Color(0xFFD97706), fontSize: 13)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFFDE68A)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _confirmDelete(isGlobalDelete: true),
                          icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                          label: const Text('Delete', style: TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFFECACA)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── 3. Staff Assignments Section (Department-wise for ALL classes) ───
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.badge_outlined, color: _primary, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Staff Assignments',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: _dark,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentActivity.assignmentSummary.length} Assigned',
                    style: const TextStyle(
                      color: _primary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Mode banners
            if (_currentActivity.assignmentMode == 'GLOBAL')
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.public, color: Color(0xFF2563EB), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Global Assignment Mode: Staff can evaluate students across all departments.',
                        style: TextStyle(fontSize: 12.5, color: Color(0xFF1E40AF), fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),

            if (_currentActivity.assignmentMode == 'CLASS_COORDINATOR')
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.supervised_user_circle_outlined, color: Color(0xFF16A34A), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Class Coordinator Mode: Automatically assigned to all section Class Coordinators.',
                        style: TextStyle(fontSize: 12.5, color: Color(0xFF166534), fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),

            // Department-wise cards for ALL departments and their sections
            if (allDepts.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.domain_disabled_rounded, size: 40, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text(
                      'No Departments Configured',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: allDepts.length,
                itemBuilder: (context, idx) {
                  final dept = allDepts[idx];
                  final deptId = dept['id']?.toString();
                  final deptName = dept['name'] as String? ?? 'Department';
                  final rawSections = dept['sections'] as List<dynamic>? ?? [];

                  // Count how many sections in this dept have an assignment
                  int assignedCount = 0;
                  for (final sec in rawSections) {
                    final secId = sec['id']?.toString();
                    final secName = sec['sectionName'] as String?;
                    if (_findAssignment(deptId, secId, secName) != null) {
                      assignedCount++;
                    }
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Department Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.domain_rounded, size: 18, color: Color(0xFF475569)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  deptName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: assignedCount > 0 ? const Color(0xFFDCFCE7) : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  rawSections.isNotEmpty
                                      ? '$assignedCount / ${rawSections.length} assigned'
                                      : (assignedCount > 0 ? 'Assigned' : 'Unassigned'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: assignedCount > 0 ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Section List (shows all sections whether assigned or not!)
                        if (rawSections.isNotEmpty)
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: rawSections.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
                            itemBuilder: (context, secIdx) {
                              final sec = rawSections[secIdx];
                              final secId = sec['id']?.toString();
                              final secName = sec['sectionName'] as String? ?? 'Section';

                              final assign = _findAssignment(deptId, secId, secName);
                              final bool isAssigned = assign != null;
                              final teacherName = assign?['teacherName'] as String? ?? (assign?['teacher'] as String?);
                              final username = assign?['username'] as String?;
                              final isTemporary = assign?['isTemporary'] == true;

                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    // Section Badge
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: isAssigned ? const Color(0xFFEEF2FF) : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Text(
                                          secName.replaceAll('Section ', '').replaceAll('SEC ', '').trim(),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12.5,
                                            color: isAssigned ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Teacher Info & Status
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  isAssigned ? (teacherName ?? 'Assigned') : 'No Staff Assigned',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13.5,
                                                    color: isAssigned ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                                                    fontStyle: isAssigned ? FontStyle.normal : FontStyle.italic,
                                                  ),
                                                ),
                                              ),
                                              if (isTemporary)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFFEF3C7),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: const Text(
                                                    'Temp Today',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFFD97706),
                                                    ),
                                                  ),
                                                ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: isAssigned ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  isAssigned ? 'Assigned' : 'Unassigned',
                                                  style: TextStyle(
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: isAssigned ? const Color(0xFF16A34A) : const Color(0xFFEF4444),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Section $secName${username != null && username != "any" ? " • $username" : ""}',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          )
                        else
                          // Single Dept row when no sections
                          Builder(builder: (context) {
                            final assign = _findAssignment(deptId, null, null);
                            final bool isAssigned = assign != null;
                            final teacherName = assign?['teacherName'] as String? ?? (assign?['teacher'] as String?);

                            return Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(
                                    isAssigned ? Icons.check_circle_rounded : Icons.cancel_outlined,
                                    size: 20,
                                    color: isAssigned ? const Color(0xFF16A34A) : const Color(0xFFEF4444),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      isAssigned ? (teacherName ?? 'Assigned') : 'No Staff Assigned for this Department',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isAssigned ? FontWeight.w600 : FontWeight.normal,
                                        color: isAssigned ? const Color(0xFF1E293B) : Colors.grey.shade500,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isAssigned ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isAssigned ? 'Assigned' : 'Unassigned',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: isAssigned ? const Color(0xFF16A34A) : const Color(0xFFEF4444),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic>? _findAssignment(String? deptId, String? secId, String? secName) {
    for (final a in _currentActivity.assignmentSummary) {
      final aDeptId = a['departmentId']?.toString();
      final aSecId = a['sectionId']?.toString();
      final aSecName = a['sectionName'] as String? ?? (a['section'] as String?);

      if (deptId != null && aDeptId != null && aDeptId == deptId) {
        if (secId != null && aSecId != null && aSecId == secId) {
          return a;
        }
        if (secName != null && aSecName != null && aSecName.trim().toLowerCase() == secName.trim().toLowerCase()) {
          return a;
        }
        if (secId == null && aSecId == null) {
          return a;
        }
      }
    }
    return null;
  }

  List<dynamic> _fallbackDepartmentsFromAssignments() {
    final Map<String, Map<String, dynamic>> deptMap = {};
    for (final a in _currentActivity.assignmentSummary) {
      final deptName = a['departmentName'] as String? ?? (a['department'] as String? ?? 'General');
      final deptId = a['departmentId'] ?? 1;
      final secName = a['sectionName'] as String? ?? (a['section'] as String?);
      final secId = a['sectionId'] ?? 1;

      if (!deptMap.containsKey(deptName)) {
        deptMap[deptName] = {
          'id': deptId,
          'name': deptName,
          'sections': <Map<String, dynamic>>[],
        };
      }
      if (secName != null && secName.isNotEmpty) {
        final List<dynamic> secs = deptMap[deptName]!['sections'];
        if (!secs.any((s) => s['sectionName'] == secName)) {
          secs.add({'id': secId, 'sectionName': secName});
        }
      }
    }
    return deptMap.values.toList();
  }

  Widget _buildPill(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 10.5, color: color.withValues(alpha: 0.8), fontWeight: FontWeight.w600),
                ),
                Text(
                  value,
                  style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
