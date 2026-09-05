import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pragatix/core/utils/api_client.dart' as http;
import 'package:pragatix/core/config/api_config.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/core/utils/error_handler.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/attendance_service.dart';
import 'teacher_attendance_tab.dart';

class AdminAttendanceHistorySheet extends StatefulWidget {
  final int? initialYearId;
  final int? initialDepartmentId;
  final int? initialSectionId;
  final DateTime? initialDate;
  final int? initialPeriod;
  final List<dynamic> years;
  final List<dynamic> departments;

  const AdminAttendanceHistorySheet({
    super.key,
    this.initialYearId,
    this.initialDepartmentId,
    this.initialSectionId,
    this.initialDate,
    this.initialPeriod,
    this.years = const [],
    this.departments = const [],
  });

  @override
  State<AdminAttendanceHistorySheet> createState() => _AdminAttendanceHistorySheetState();
}

class _AdminAttendanceHistorySheetState extends State<AdminAttendanceHistorySheet> {
  final AttendanceService _service = AttendanceService();
  bool _isLoading = false;
  List<Map<String, dynamic>> _historyItems = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  DateTime? _selectedDate;
  int? _selectedYearId;
  int? _selectedDeptId;
  int? _selectedSectionId;
  int? _selectedPeriod;

  List<dynamic> _years = [];
  List<dynamic> _departments = [];
  List<dynamic> _sections = [];
  bool _isLoadingSections = false;

  bool get isYearAdmin {
    final user = getIt<AuthProvider>().currentUser;
    final roles = user?['roles'] as List<dynamic>?;
    if (roles == null) return false;

    bool hasAdmin = false;
    bool hasSuperAdmin = false;

    for (var r in roles) {
      String roleName = '';
      if (r is String) roleName = r;
      if (r is Map) roleName = r['name']?.toString() ?? '';

      final upperRole = roleName.toUpperCase();
      if (upperRole == 'ROLE_ADMIN' || upperRole == 'ADMIN') hasAdmin = true;
      if (upperRole == 'ROLE_SUPER_ADMIN' || upperRole == 'ROLE_SUPERADMIN' || upperRole == 'SUPER_ADMIN' || upperRole == 'SUPERADMIN') hasSuperAdmin = true;
    }

    return hasAdmin && !hasSuperAdmin;
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _selectedYearId = isYearAdmin ? -1 : widget.initialYearId;
    _selectedDeptId = widget.initialDepartmentId;
    _selectedSectionId = widget.initialSectionId;
    _selectedPeriod = widget.initialPeriod;
    _years = widget.years;
    _departments = widget.departments;

    if (_selectedDeptId != null) {
      _loadSections(_selectedDeptId!);
    }
    _fetchHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSections(int deptId) async {
    setState(() => _isLoadingSections = true);
    try {
      final token = getIt<AuthProvider>().token ?? '';
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/sections/department/$deptId'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      );
      if (res.statusCode == 200 && mounted) {
        final decoded = jsonDecode(res.body);
        if (decoded is List) {
          setState(() => _sections = decoded);
        } else if (decoded is Map && decoded['data'] is List) {
          setState(() => _sections = decoded['data']);
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingSections = false);
    }
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    try {
      final dateStr = _selectedDate != null ? DateFormat('yyyy-MM-dd').format(_selectedDate!) : null;

      final items = await _service.getAdminAttendanceHistory(
        date: dateStr,
        yearId: isYearAdmin ? -1 : _selectedYearId,
        departmentId: _selectedDeptId,
        sectionId: _selectedSectionId,
        period: _selectedPeriod,
      );

      if (mounted) {
        setState(() {
          _historyItems = items;
        });
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showSnackBar(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> get _filteredHistory {
    if (_searchQuery.trim().isEmpty) return _historyItems;
    final q = _searchQuery.trim().toLowerCase();
    return _historyItems.where((item) {
      final faculty = (item['facultyName'] ?? '').toString().toLowerCase();
      final facDept = (item['facultyDepartmentName'] ?? '').toString().toLowerCase();
      final facRole = (item['facultyDesignation'] ?? '').toString().toLowerCase();
      final dept = (item['departmentName'] ?? '').toString().toLowerCase();
      final sec = (item['sectionName'] ?? '').toString().toLowerCase();
      final yr = (item['yearName'] ?? '').toString().toLowerCase();
      final date = (item['date'] ?? '').toString().toLowerCase();
      final period = 'period ${item['period']}';
      return faculty.contains(q) ||
          facDept.contains(q) ||
          facRole.contains(q) ||
          dept.contains(q) ||
          sec.contains(q) ||
          yr.contains(q) ||
          date.contains(q) ||
          period.contains(q);
    }).toList();
  }

  Future<void> _viewSessionDetails(Map<String, dynamic> session) async {
    try {
      final date = session['date']?.toString() ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
      final period = session['period'] as int? ?? 1;
      final yearId = session['yearId'] as int?;
      final deptId = session['departmentId'] as int?;
      final sectionId = session['sectionId'] as int?;
      final yearName = session['yearName']?.toString() ?? 'Year';
      final deptName = session['departmentName']?.toString() ?? 'Department';
      final sectionName = session['sectionName']?.toString() ?? '';

      final effectiveYearId = yearId ?? (isYearAdmin ? -1 : 1);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      );

      final students = await _service.getStudentsWithAttendance(
        date,
        period,
        effectiveYearId,
        deptId ?? 1,
        sectionId: sectionId,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (ctx) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: AttendanceHistoryPopupContent(
              students: students,
              period: period,
              yearName: yearName,
              departmentName: deptName,
              sectionName: (sectionName.isNotEmpty && sectionName != 'All Sections / None') ? sectionName : null,
              dateStr: date,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ErrorHandler.showSnackBar(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredHistory;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Attendance History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            Text(
              isYearAdmin ? 'Year Admin • Staff Attendance Logs' : 'Super Admin • All Attendance Logs',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _fetchHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          // Stacked Form-Style Filter Card (Matches Dashboard exactly)
          _buildStackedFilters(),

          // Count & Status bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Found ${filtered.length} marked session${filtered.length == 1 ? '' : 's'}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
                  ),
              ],
            ),
          ),

          // List View
          Expanded(
            child: _isLoading && filtered.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.history_rounded, size: 56, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            const Text(
                              'No attendance history records found',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Try adjusting the filters or selecting another date',
                              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchHistory,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (ctx, idx) {
                            final session = filtered[idx];
                            return _buildHistoryCard(session);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStackedFilters() {
    final filteredSections = _sections
        .where((s) => _selectedDeptId == null || s['departmentId'] == _selectedDeptId || s['department']?['id'] == _selectedDeptId)
        .toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Academic Year (Super Admin ONLY)
          if (!isYearAdmin) ...[
            DropdownButtonFormField<int?>(
              isExpanded: true,
              value: (_selectedYearId != null && _years.any((y) => y['id'] == _selectedYearId)) ? _selectedYearId : null,
              decoration: InputDecoration(
                labelText: 'Academic Year',
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('All Academic Years'),
                ),
                ..._years.where((y) => y['id'] != null).map<DropdownMenuItem<int?>>((y) {
                  return DropdownMenuItem<int?>(
                    value: y['id'] as int,
                    child: Text(y['yearName']?.toString() ?? y['yearNo']?.toString() ?? 'Unknown'),
                  );
                }).toList(),
              ],
              onChanged: (v) {
                setState(() => _selectedYearId = v);
                _fetchHistory();
              },
            ),
            const SizedBox(height: 10),
          ],

          // 2. Department
          DropdownButtonFormField<int?>(
            isExpanded: true,
            value: (_selectedDeptId != null && _departments.any((d) => d['id'] == _selectedDeptId)) ? _selectedDeptId : null,
            decoration: InputDecoration(
              labelText: 'Department',
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('All Departments'),
              ),
              ..._departments.where((d) => d['id'] != null).map<DropdownMenuItem<int?>>((d) {
                return DropdownMenuItem<int?>(
                  value: d['id'] as int,
                  child: Text(d['name']?.toString() ?? d['deptName']?.toString() ?? d['code']?.toString() ?? 'Unknown'),
                );
              }).toList(),
            ],
            onChanged: (v) {
              setState(() {
                _selectedDeptId = v;
                _selectedSectionId = null;
                _sections = [];
                if (v != null) {
                  _loadSections(v);
                }
              });
              _fetchHistory();
            },
          ),
          const SizedBox(height: 10),

          // 3. Section
          DropdownButtonFormField<int?>(
            isExpanded: true,
            value: (_selectedSectionId != null && filteredSections.any((s) => s['id'] == _selectedSectionId))
                ? _selectedSectionId
                : null,
            decoration: InputDecoration(
              labelText: 'Section',
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              hintText: _selectedDeptId == null
                  ? 'Select Department First'
                  : (_isLoadingSections
                      ? 'Loading Sections...'
                      : (filteredSections.isEmpty ? 'No Sections Available' : 'All Sections')),
            ),
            items: _selectedDeptId == null || filteredSections.isEmpty
                ? null
                : [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('All Sections'),
                    ),
                    ...filteredSections.where((s) => s['id'] != null).map<DropdownMenuItem<int?>>((s) {
                      return DropdownMenuItem<int?>(
                        value: s['id'] as int,
                        child: Text(s['sectionName']?.toString() ?? 'Unknown'),
                      );
                    }).toList(),
                  ],
            onChanged: _selectedDeptId == null || filteredSections.isEmpty
                ? null
                : (v) {
                    setState(() => _selectedSectionId = v);
                    _fetchHistory();
                  },
          ),
          const SizedBox(height: 10),

          // 4. Date Picker with Clear Date Button
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: ListTile(
              dense: true,
              title: const Text(
                'Date',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              subtitle: Text(
                _selectedDate != null ? DateFormat('yyyy-MM-dd').format(_selectedDate!) : 'All Dates (No filter)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _selectedDate != null ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_selectedDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18, color: Color(0xFF64748B)),
                      tooltip: 'Clear Date (Show All Dates)',
                      onPressed: () {
                        setState(() => _selectedDate = null);
                        _fetchHistory();
                      },
                    ),
                  const Icon(Icons.calendar_today_rounded, color: Color(0xFF2563EB), size: 18),
                ],
              ),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (d != null) {
                  setState(() => _selectedDate = d);
                  _fetchHistory();
                }
              },
            ),
          ),
          const SizedBox(height: 10),

          // 5. Period
          DropdownButtonFormField<int?>(
            isExpanded: true,
            value: _selectedPeriod,
            decoration: InputDecoration(
              labelText: 'Period',
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('All Periods'),
              ),
              ...List.generate(8, (i) => DropdownMenuItem<int?>(
                value: i + 1,
                child: Text('Period ${i + 1}'),
              )),
            ],
            onChanged: (v) {
              setState(() => _selectedPeriod = v);
              _fetchHistory();
            },
          ),
          const SizedBox(height: 10),

          // 6. Search Bar
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Search staff name, department, class...',
              prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF64748B)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> session) {
    final period = session['period'] ?? 0;
    final date = session['date']?.toString() ?? '—';
    final facultyName = session['facultyName']?.toString() ?? 'Unknown Staff';
    final facultyEmail = session['facultyEmail']?.toString() ?? '';
    final facultyDept = session['facultyDepartmentName']?.toString() ?? '';
    final facultyDesignation = session['facultyDesignation']?.toString() ?? '';
    final yearName = session['yearName']?.toString() ?? 'Year';
    final deptName = session['departmentName']?.toString() ?? 'Dept';
    final secName = session['sectionName']?.toString() ?? '';
    final total = session['totalStudents'] as int? ?? 0;
    final present = session['presentCount'] as int? ?? 0;
    final absent = session['absentCount'] as int? ?? 0;
    final markedAt = session['markedAt']?.toString() ?? '';

    String markedTimeStr = '';
    if (markedAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(markedAt);
        markedTimeStr = DateFormat('hh:mm a').format(dt);
      } catch (_) {
        markedTimeStr = markedAt;
      }
    }

    String staffSubtitle = '';
    if (facultyDept.isNotEmpty) {
      staffSubtitle = 'Staff Dept: $facultyDept';
    }
    if (facultyDesignation.isNotEmpty && facultyDesignation != 'Faculty') {
      staffSubtitle = staffSubtitle.isNotEmpty ? '$staffSubtitle • $facultyDesignation' : facultyDesignation;
    } else if (staffSubtitle.isEmpty && facultyEmail.isNotEmpty) {
      staffSubtitle = facultyEmail;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _viewSessionDetails(session),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Badges
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF2563EB)),
                          const SizedBox(width: 4),
                          Text(
                            'Period $period',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1D4ED8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        date,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (markedTimeStr.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, size: 13, color: Color(0xFF16A34A)),
                          const SizedBox(width: 4),
                          Text(
                            markedTimeStr,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Staff Information (Staff Name + Staff Dept)
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFC7D2FE)),
                      ),
                      child: const Icon(Icons.person_rounded, color: Color(0xFF4F46E5), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            facultyName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (staffSubtitle.isNotEmpty)
                            Text(
                              staffSubtitle,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6366F1)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Class Info Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.school_outlined, size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Class: $yearName • $deptName ${secName.isNotEmpty && secName != 'All Sections / None' ? '• Sec $secName' : ''}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Stats row
                Row(
                  children: [
                    _buildCountChip(label: 'Total', count: total, color: const Color(0xFF3B82F6), bg: const Color(0xFFEFF6FF)),
                    const SizedBox(width: 8),
                    _buildCountChip(label: 'Present', count: present, color: const Color(0xFF16A34A), bg: const Color(0xFFDCFCE7)),
                    const SizedBox(width: 8),
                    _buildCountChip(label: 'Absent', count: absent, color: const Color(0xFFDC2626), bg: const Color(0xFFFEE2E2)),
                    const Spacer(),
                    const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF94A3B8)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCountChip({required String label, required int count, required Color color, required Color bg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
