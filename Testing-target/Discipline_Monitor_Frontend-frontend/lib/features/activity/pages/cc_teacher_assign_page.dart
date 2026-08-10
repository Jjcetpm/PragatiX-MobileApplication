import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/activity/models/activity_model.dart';
import 'package:pragatix/features/activity/services/cc_activity_service.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';

class CCTeacherAssignPage extends StatefulWidget {
  final ActivityModel activity;
  final int? stageId;
  final String? stageName;
  final String? categoryTitle;

  const CCTeacherAssignPage({
    super.key,
    required this.activity,
    this.stageId,
    this.stageName,
    this.categoryTitle,
  });

  @override
  State<CCTeacherAssignPage> createState() => _CCTeacherAssignPageState();
}

class _CCTeacherAssignPageState extends State<CCTeacherAssignPage> {
  late final CCActivityService _service;
  bool _isLoading = true;
  bool _isAssigning = false;
  String? _errorMessage;

  List<Map<String, dynamic>> _allTeachers = [];
  int? _selectedTeacherId;
  String _assignmentDuration = 'PERMANENT'; // 'ONLY_TODAY' or 'PERMANENT'
  String _remarks = '';

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  Map<String, dynamic>? _classDetails;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _service = CCActivityService(authProvider);
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _service.fetchClassTeachers(),
        _service.fetchClassDetails().catchError((_) => <String, dynamic>{}),
      ]);

      final teachers = results[0] as List<Map<String, dynamic>>;
      final classDet = results[1] as Map<String, dynamic>;

      // Check if current activity has an assignment
      int? initialTeacherId;
      if (widget.activity.assignmentSummary.isNotEmpty) {
        final first = widget.activity.assignmentSummary.first;
        final tId = first['teacherId'];
        if (tId is int && tId > 0) {
          initialTeacherId = tId;
        } else if (tId is num && tId > 0) {
          initialTeacherId = tId.toInt();
        }
      }

      setState(() {
        _allTeachers = teachers;
        _classDetails = classDet;
        _selectedTeacherId = initialTeacherId;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredTeachers {
    if (_searchQuery.trim().isEmpty) return _allTeachers;
    final query = _searchQuery.toLowerCase().trim();
    return _allTeachers.where((t) {
      final name = (t['fullName'] ?? '').toString().toLowerCase();
      final username = (t['username'] ?? '').toString().toLowerCase();
      final email = (t['email'] ?? '').toString().toLowerCase();
      final dept = (t['departmentName'] ?? t['department'] ?? '').toString().toLowerCase();
      return name.contains(query) || username.contains(query) || email.contains(query) || dept.contains(query);
    }).toList();
  }

  Future<void> _handleAssign() async {
    if (_selectedTeacherId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a teacher to assign this activity.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final selectedTeacher = _allTeachers.firstWhere(
      (t) => t['id'] == _selectedTeacherId,
      orElse: () => <String, dynamic>{},
    );
    final teacherName = selectedTeacher['fullName'] ?? 'Teacher';

    setState(() => _isAssigning = true);

    try {
      await _service.assignTeacherToActivity(
        activityId: widget.activity.id,
        teacherId: _selectedTeacherId!,
        stageId: widget.stageId,
        assignmentDuration: _assignmentDuration,
        remarks: _remarksController.text.trim().isNotEmpty ? _remarksController.text.trim() : null,
      );

      if (!mounted) return;

      final durationText = _assignmentDuration == 'ONLY_TODAY' ? 'for today (Only Today)' : 'permanently';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Activity assigned $durationText to $teacherName successfully!',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAssigning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception:', '').trim()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final act = widget.activity;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Assign Staff',
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Activity & Assignment Status Header
          _buildActivityHeader(act),

          // Duration Selector: Only Today vs Permanent
          _buildDurationSelector(),

          // Search Bar
          if (!_isLoading && _allTeachers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search faculty by name, department, email...',
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF11998E), width: 1.5),
                  ),
                ),
              ),
            ),

          // Teacher List (Single selection with Radio buttons)
          Expanded(
            child: _buildBody(),
          ),

          // Bottom Assign Action Bar
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildDurationSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.schedule_rounded, size: 16, color: Color(0xFF11998E)),
              SizedBox(width: 6),
              Text(
                'Assignment Duration',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Only Today Option
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _assignmentDuration = 'ONLY_TODAY';
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: _assignmentDuration == 'ONLY_TODAY'
                          ? const Color(0xFF11998E).withOpacity(0.12)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _assignmentDuration == 'ONLY_TODAY'
                            ? const Color(0xFF11998E)
                            : const Color(0xFFE2E8F0),
                        width: _assignmentDuration == 'ONLY_TODAY' ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.today_rounded,
                          size: 18,
                          color: _assignmentDuration == 'ONLY_TODAY'
                              ? const Color(0xFF11998E)
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Only Today',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _assignmentDuration == 'ONLY_TODAY'
                                    ? const Color(0xFF11998E)
                                    : const Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              'Temporary (Expires midnight)',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Permanent Option
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _assignmentDuration = 'PERMANENT';
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: _assignmentDuration == 'PERMANENT'
                          ? const Color(0xFF11998E).withOpacity(0.12)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _assignmentDuration == 'PERMANENT'
                            ? const Color(0xFF11998E)
                            : const Color(0xFFE2E8F0),
                        width: _assignmentDuration == 'PERMANENT' ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.verified_user_rounded,
                          size: 18,
                          color: _assignmentDuration == 'PERMANENT'
                              ? const Color(0xFF11998E)
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Permanent',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _assignmentDuration == 'PERMANENT'
                                    ? const Color(0xFF11998E)
                                    : const Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              'Fixed assigned faculty',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityHeader(ActivityModel act) {
    final deptName = _classDetails?['departmentName'] ?? '';
    final sectionName = _classDetails?['sectionName'] ?? '';

    // Check if there is already an assigned teacher in summary
    String currentTeacherName = 'Unassigned / Any Faculty';
    bool isTempCurrent = false;
    String? originalTeacher;

    if (act.assignmentSummary.isNotEmpty) {
      final first = act.assignmentSummary.first;
      final tName = first['teacherName'] ?? first['teacher'];
      if (tName != null && tName.toString().isNotEmpty && tName.toString() != 'Any Faculty') {
        currentTeacherName = tName.toString();
        isTempCurrent = first['isTemporary'] == true || currentTeacherName.contains('(Temporary');
        originalTeacher = first['originalTeacherName']?.toString();
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF11998E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.assignment_turned_in_rounded,
                  color: Color(0xFF11998E),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      act.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Stage: ${widget.stageName ?? 'Current Stage'} • Points: ${act.awardXp} XP',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.person_pin_rounded, size: 16, color: isTempCurrent ? Colors.amber.shade900 : const Color(0xFF11998E)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Currently Assigned: $currentTeacherName' + (originalTeacher != null ? ' (Replaced: $originalTeacher)' : ''),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isTempCurrent ? Colors.amber.shade900 : const Color(0xFF1E293B),
                    ),
                  ),
                ),
                if (isTempCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'TEMP TODAY',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF11998E)),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF11998E),
                ),
                child: const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    final teachers = _filteredTeachers;

    if (teachers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No faculty matched "$_searchQuery"'
                  : 'No faculty members found in class.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: teachers.length,
      itemBuilder: (context, index) {
        final teacher = teachers[index];
        final teacherId = teacher['id'] as int;
        final fullName = (teacher['fullName'] ?? 'Unknown Teacher').toString();
        final username = (teacher['username'] ?? '').toString();
        final dept = (teacher['departmentName'] ?? teacher['department'] ?? '').toString();
        final isSelected = _selectedTeacherId == teacherId;

        return Card(
          elevation: isSelected ? 2 : 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? const Color(0xFF11998E) : const Color(0xFFE2E8F0),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() {
                _selectedTeacherId = teacherId;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  // Radio Button (Only one teacher can be selected)
                  Radio<int>(
                    value: teacherId,
                    groupValue: _selectedTeacherId,
                    activeColor: const Color(0xFF11998E),
                    onChanged: (val) {
                      setState(() {
                        _selectedTeacherId = val;
                      });
                    },
                  ),
                  const SizedBox(width: 6),
                  // Teacher Avatar
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: isSelected
                        ? const Color(0xFF11998E)
                        : const Color(0xFFE2E8F0),
                    child: Text(
                      fullName.isNotEmpty ? fullName[0].toUpperCase() : 'T',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isSelected ? Colors.white : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Teacher Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@$username ${dept.isNotEmpty ? "• $dept" : ""}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF11998E).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'SELECTED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF11998E),
                        ),
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

  Widget _buildBottomBar() {
    final hasSelection = _selectedTeacherId != null;
    final selectedTeacher = hasSelection
        ? _allTeachers.firstWhere((t) => t['id'] == _selectedTeacherId, orElse: () => {})
        : null;
    final teacherName = selectedTeacher?['fullName'] ?? 'Select Faculty';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasSelection) ...[
              Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded, size: 16, color: Color(0xFF11998E)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Assigning to: $teacherName (${_assignmentDuration == "ONLY_TODAY" ? "Today Only" : "Permanent"})',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (hasSelection && !_isAssigning) ? _handleAssign : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF11998E),
                  disabledBackgroundColor: Colors.grey.shade300,
                  elevation: hasSelection ? 2 : 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isAssigning
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _assignmentDuration == 'ONLY_TODAY'
                            ? 'Confirm Temporary Assignment'
                            : 'Confirm Permanent Assignment',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
