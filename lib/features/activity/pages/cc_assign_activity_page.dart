import 'package:flutter/material.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/core/theme/app_colors.dart';
import 'package:pragatix/core/utils/error_handler.dart';
import 'package:pragatix/features/activity/models/activity_model.dart';
import 'package:pragatix/features/activity/services/cc_activity_service.dart';

class CCAssignActivityPage extends StatefulWidget {
  final ActivityModel activity;

  const CCAssignActivityPage({super.key, required this.activity});

  @override
  State<CCAssignActivityPage> createState() => _CCAssignActivityPageState();
}

class _CCAssignActivityPageState extends State<CCAssignActivityPage> {
  final CCActivityService _ccActivityService = getIt<CCActivityService>();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;

  Map<String, dynamic>? _classDetails;
  List<Map<String, dynamic>> _allStudents = [];
  List<Map<String, dynamic>> _filteredStudents = [];
  final Set<int> _selectedStudentIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterStudents);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final classDetailsFuture = _ccActivityService.fetchClassDetails();
      final studentsFuture = _ccActivityService.fetchClassStudents(activityId: widget.activity.id);

      final results = await Future.wait([classDetailsFuture, studentsFuture]);

      if (mounted) {
        final details = results[0] as Map<String, dynamic>;
        final students = results[1] as List<Map<String, dynamic>>;
        students.sort((a, b) {
          final nameA = (a['fullName'] ?? '').toString().trim().toLowerCase();
          final nameB = (b['fullName'] ?? '').toString().trim().toLowerCase();
          final comp = nameA.compareTo(nameB);
          if (comp != 0) return comp;
          final regA = (a['regNo'] ?? '').toString().trim().toLowerCase();
          final regB = (b['regNo'] ?? '').toString().trim().toLowerCase();
          return regA.compareTo(regB);
        });

        setState(() {
          _classDetails = details;
          _allStudents = students;
          // By default, select all students in the class
          _selectedStudentIds.addAll(
            students.map((s) => (s['id'] as num).toInt()),
          );
          _isLoading = false;
        });
        _filterStudents();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ErrorHandler.showSnackBar(context, e);
      }
    }
  }

  void _filterStudents() {
    final query = _searchController.text.trim().toLowerCase();
    List<Map<String, dynamic>> list;
    if (query.isEmpty) {
      list = List.from(_allStudents);
    } else {
      list = _allStudents.where((s) {
        final name = (s['fullName'] ?? '').toString().toLowerCase();
        final regNo = (s['regNo'] ?? '').toString().toLowerCase();
        return name.contains(query) || regNo.contains(query);
      }).toList();
    }
    list.sort((a, b) {
      final nameA = (a['fullName'] ?? '').toString().trim().toLowerCase();
      final nameB = (b['fullName'] ?? '').toString().trim().toLowerCase();
      final comp = nameA.compareTo(nameB);
      if (comp != 0) return comp;
      final regA = (a['regNo'] ?? '').toString().trim().toLowerCase();
      final regB = (b['regNo'] ?? '').toString().trim().toLowerCase();
      return regA.compareTo(regB);
    });
    setState(() {
      _filteredStudents = list;
    });
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      if (value == true) {
        for (var s in _filteredStudents) {
          _selectedStudentIds.add((s['id'] as num).toInt());
        }
      } else {
        for (var s in _filteredStudents) {
          _selectedStudentIds.remove((s['id'] as num).toInt());
        }
      }
    });
  }

  void _toggleStudent(int studentId) {
    setState(() {
      if (_selectedStudentIds.contains(studentId)) {
        _selectedStudentIds.remove(studentId);
      } else {
        _selectedStudentIds.add(studentId);
      }
    });
  }

  Future<void> _submitAssignment() async {
    if (_selectedStudentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one student to assign.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Assignment'),
        content: Text(
          'Assign "${widget.activity.name}" to ${_selectedStudentIds.length} student(s) in ${_classDetails?['departmentName'] ?? 'your department'} (${_classDetails?['yearName'] ?? ''} - Sec ${_classDetails?['sectionName'] ?? ''})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF11998E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);
    try {
      final response = await _ccActivityService.assignActivity(
        activityId: widget.activity.id,
        studentIds: _selectedStudentIds.toList(),
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        final assignedCount = response['studentsAssigned'] ?? _selectedStudentIds.length;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Activity assigned successfully to $assignedCount student(s)!',
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF11998E),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ErrorHandler.showSnackBar(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final areAllFilteredSelected = _filteredStudents.isNotEmpty &&
        _filteredStudents.every((s) => _selectedStudentIds.contains((s['id'] as num).toInt()));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Assign Activity',
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
              colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF11998E)),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Activity Summary Card
                      _buildActivityHeaderCard(),
                      const SizedBox(height: 16),

                      // Auto-loaded Class Details (READ ONLY)
                      _buildClassDetailsCard(),
                      const SizedBox(height: 16),

                      // Student Selection Header
                      _buildStudentSelectionHeader(areAllFilteredSelected),
                      const SizedBox(height: 8),

                      // Student Search Box
                      _buildSearchBox(),
                      const SizedBox(height: 12),

                      // Student List
                      _buildStudentList(),
                    ],
                  ),
                ),

                // Sticky Bottom Action Button
                _buildBottomActionBar(),
              ],
            ),
    );
  }

  Widget _buildActivityHeaderCard() {
    final isPenalty = widget.activity.xpType.toLowerCase() == 'penalty';
    final xpDisplay = isPenalty
        ? '-${widget.activity.penaltyXp} XP'
        : '+${widget.activity.awardXp > 0 ? widget.activity.awardXp : widget.activity.xp} XP';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.activity.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkSlate,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPenalty
                      ? Colors.red.shade50
                      : const Color(0xFF11998E).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isPenalty ? Colors.red.shade200 : const Color(0xFF11998E).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  xpDisplay,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isPenalty ? Colors.red.shade700 : const Color(0xFF11998E),
                  ),
                ),
              ),
            ],
          ),
          if (widget.activity.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              widget.activity.description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildBadge(
                icon: Icons.category_outlined,
                label: widget.activity.subgroup ?? widget.activity.xpCategory,
                color: Colors.indigo,
              ),
              _buildBadge(
                icon: widget.activity.type.toLowerCase() == 'group'
                    ? Icons.groups_outlined
                    : Icons.person_outline,
                label: widget.activity.type,
                color: Colors.teal,
              ),
              _buildBadge(
                icon: Icons.check_circle_outline,
                label: 'Active',
                color: Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClassDetailsCard() {
    final deptName = _classDetails?['departmentName'] ?? 'Not Assigned';
    final yearName = _classDetails?['yearName'] ?? '1st Year';
    final secName = _classDetails?['sectionName'] ?? 'A';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF11998E).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.admin_panel_settings_rounded,
                color: Color(0xFF11998E),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Class Scope (Auto-Assigned)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF0F766E),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF11998E).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'READ ONLY',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F766E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildClassInfoTile(
                  title: 'Department',
                  value: deptName,
                  icon: Icons.account_balance_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 1,
                child: _buildClassInfoTile(
                  title: 'Year',
                  value: yearName,
                  icon: Icons.calendar_today_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 1,
                child: _buildClassInfoTile(
                  title: 'Section',
                  value: 'Sec $secName',
                  icon: Icons.meeting_room_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClassInfoTile({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.darkSlate,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStudentSelectionHeader(bool areAllFilteredSelected) {
    return Row(
      children: [
        const Text(
          'Students to Assign',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.darkSlate,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF11998E).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${_selectedStudentIds.length} / ${_allStudents.length}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF11998E),
            ),
          ),
        ),
        const Spacer(),
        InkWell(
          onTap: () => _toggleSelectAll(!areAllFilteredSelected),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Checkbox(
                  value: areAllFilteredSelected,
                  onChanged: _toggleSelectAll,
                  activeColor: const Color(0xFF11998E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 4),
                const Text(
                  'Select All',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF11998E),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBox() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search student by name or Reg No...',
        prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF11998E)),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () => _searchController.clear(),
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF11998E), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildStudentList() {
    if (_filteredStudents.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(Icons.person_off_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isNotEmpty
                  ? 'No students match your search'
                  : 'No active students found in this class',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredStudents.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final student = _filteredStudents[index];
        final studentId = (student['id'] as num).toInt();
        final isSelected = _selectedStudentIds.contains(studentId);
        final name = student['fullName'] ?? 'Unnamed';
        final regNo = student['regNo'] ?? '';

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _toggleStudent(studentId),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF11998E).withOpacity(0.5)
                      : Colors.grey.shade200,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggleStudent(studentId),
                    activeColor: const Color(0xFF11998E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: isSelected
                        ? const Color(0xFF11998E)
                        : Colors.grey.shade200,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'S',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? const Color(0xFF0F766E)
                                : AppColors.darkSlate,
                          ),
                        ),
                        if (regNo.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            regNo,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitAssignment,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF11998E),
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.assignment_turned_in_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Assign Activity (${_selectedStudentIds.length} Students)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
