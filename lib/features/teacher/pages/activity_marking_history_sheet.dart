import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/core/config/api_config.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/core/widgets/pragatix_loader.dart';
import 'package:pragatix/features/activity/models/activity_model.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/features/teacher/services/teacher_proxy_service.dart';

class ActivityMarkingHistorySheet extends StatefulWidget {
  final ActivityModel activity;
  final dynamic selectedYear;
  final dynamic selectedDept;
  final dynamic selectedSection;
  final int? stageId;
  final String? academicYear;

  const ActivityMarkingHistorySheet({
    super.key,
    required this.activity,
    this.selectedYear,
    this.selectedDept,
    this.selectedSection,
    this.stageId,
    this.academicYear,
  });

  @override
  State<ActivityMarkingHistorySheet> createState() =>
      _ActivityMarkingHistorySheetState();
}

class _ActivityMarkingHistorySheetState
    extends State<ActivityMarkingHistorySheet> {
  bool _isLoading = false;
  bool _isAllDatesMode = true;
  DateTime _selectedDate = DateTime.now();
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _evaluatedStudents = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getYearParam(dynamic year) {
    if (year is Map) {
      final yearNo = year['yearNo'];
      if (yearNo == 2) return 'II';
      if (yearNo == 3) return 'III';
      if (yearNo == 4) return 'IV';
      return 'I';
    }
    return 'I';
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoading = true;
      _evaluatedStudents = [];
    });

    try {
      final token = context.read<AuthProvider>().token;
      final yearParam = widget.selectedYear != null
          ? _getYearParam(widget.selectedYear)
          : 'I';
      final deptId = widget.selectedDept is Map
          ? widget.selectedDept['id']
          : widget.selectedDept;
      final stageParam =
          widget.stageId != null ? '&stageId=${widget.stageId}' : '';

      final isAttendance = widget.activity.name.toLowerCase().contains('attendance') ||
          (widget.activity.type.toLowerCase().contains('attendance'));

      final List<Map<String, dynamic>> loadedRecords = [];

      // 1. If Attendance activity, check attendance history API
      if (isAttendance) {
        try {
          String attendanceUrl =
              '${ApiConfig.baseUrl}/api/admin/attendance/history?';
          if (deptId != null) attendanceUrl += 'departmentId=$deptId&';
          if (widget.selectedSection != null) {
            final secId = widget.selectedSection is Map
                ? widget.selectedSection['id']
                : widget.selectedSection;
            attendanceUrl += 'sectionId=$secId&';
          }
          if (!_isAllDatesMode) {
            final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
            attendanceUrl += 'date=$dateStr';
          }

          final attRes = await getIt<TeacherProxyService>().get(
            Uri.parse(attendanceUrl),
            headers: {'Authorization': 'Bearer $token'},
          );

          if (attRes.statusCode == 200) {
            final body = jsonDecode(attRes.body);
            final list = body['data'] is List ? body['data'] : [];
            for (var item in list) {
              final students = item['students'] ?? item['studentAttendanceList'] ?? [];
              if (students is List) {
                for (var s in students) {
                  final bool isPresent = (s['status'] ?? '').toString().toUpperCase() == 'PRESENT';
                  loadedRecords.add({
                    'id': s['id'] ?? s['studentId'],
                    'fullName': s['studentName'] ?? s['fullName'] ?? 'Student',
                    'regNo': s['registerNumber'] ?? s['regNo'],
                    'sprNo': s['sprNo'],
                    'status': isPresent ? 'AWARDED' : 'PENALIZED',
                    'xpChange': isPresent ? widget.activity.awardXp : -widget.activity.penaltyXp,
                    'markedAt': item['markedAt'] ?? item['date'] ?? DateFormat('yyyy-MM-dd').format(_selectedDate),
                    'markedBy': item['facultyName'] ?? 'Faculty',
                    'remarks': s['remarks'] ?? (isPresent ? 'Present (+XP)' : 'Absent (-XP)'),
                  });
                }
              }
            }
          }
        } catch (_) {}
      }

      // 2. Fetch from activity students endpoint
      if (loadedRecords.isEmpty) {
        String actUrl =
            '${ApiConfig.baseUrl}/api/v1/my-activities/${widget.activity.id}/students?year=$yearParam';
        if (deptId != null) actUrl += '&departmentId=$deptId';
        if (widget.selectedSection != null) {
          final secId = widget.selectedSection is Map
              ? widget.selectedSection['id']
              : widget.selectedSection;
          actUrl += '&sectionId=$secId';
        }
        actUrl += stageParam;

        final res = await getIt<TeacherProxyService>().get(
          Uri.parse(actUrl),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final resData = data['data'] ?? data;
          final List<dynamic> studentsList =
              resData['students'] ?? (resData is List ? resData : []);

          for (var s in studentsList) {
            final bool isAwarded = s['isAwarded'] == true ||
                s['isCapReached'] == true ||
                (s['awardsInPeriod'] != null && s['awardsInPeriod'] > 0) ||
                (s['score'] != null && s['score'] > 0);
            final bool isPenalized =
                s['isPenalized'] == true || s['penaltyApplied'] == true;

            // ONLY include evaluated students!
            if (isAwarded || isPenalized) {
              final String status = isPenalized ? 'PENALIZED' : 'AWARDED';
              loadedRecords.add({
                'id': s['id'] ?? s['studentId'],
                'fullName': s['fullName'] ?? s['studentName'] ?? 'Student',
                'regNo': s['regNo'] ?? s['registerNumber'],
                'sprNo': s['sprNo'],
                'status': status,
                'xpChange': isPenalized
                    ? -widget.activity.penaltyXp
                    : widget.activity.awardXp,
                'markedAt': s['lastAwardedAt'] ??
                    s['awardedAt'] ??
                    s['lastMarkedAt'],
                'markedBy': s['assignedFacultyName'] ??
                    resData['assignment']?['assignedFacultyName'] ??
                    'Assigned Faculty',
                'remarks': s['remarks'] ??
                    (status == 'AWARDED'
                        ? 'Awarded Points'
                        : 'Penalized Points'),
              });
            }
          }
        }
      }

      setState(() {
        _evaluatedStudents = loadedRecords;
      });
    } catch (e) {
      debugPrint('Error loading history: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _extractDateYMD(dynamic rawDate) {
    if (rawDate == null) return null;
    final str = rawDate.toString().trim();
    if (str.isEmpty) return null;

    final lower = str.toLowerCase();
    final now = DateTime.now();

    // 1. Check "Today"
    if (lower.startsWith('today')) {
      return DateFormat('yyyy-MM-dd').format(now);
    }

    // 2. Check "Yesterday"
    if (lower.startsWith('yesterday')) {
      final yesterday = now.subtract(const Duration(days: 1));
      return DateFormat('yyyy-MM-dd').format(yesterday);
    }

    // 3. Format: "dd MMM yyyy, hh:mm a" e.g. "17 Sep 2026, 10:06 pm" or "17 Sep 2026"
    final dMmmYRegex = RegExp(r'^(\d{1,2})[\s-]+([a-zA-Z]{3,9})[\s-]+(\d{4})');
    final match = dMmmYRegex.firstMatch(str);
    if (match != null) {
      final day = match.group(1)!.padLeft(2, '0');
      final monthStr = match.group(2)!.substring(0, 3).toLowerCase();
      final year = match.group(3)!;
      const monthsMap = {
        'jan': '01',
        'feb': '02',
        'mar': '03',
        'apr': '04',
        'may': '05',
        'jun': '06',
        'jul': '07',
        'aug': '08',
        'sep': '09',
        'oct': '10',
        'nov': '11',
        'dec': '12'
      };
      final month = monthsMap[monthStr];
      if (month != null) {
        return '$year-$month-$day';
      }
    }

    // 4. ISO yyyy-MM-dd
    final isoRegex = RegExp(r'^(\d{4})-(\d{2})-(\d{2})');
    final isoMatch = isoRegex.firstMatch(str);
    if (isoMatch != null) {
      return '${isoMatch.group(1)}-${isoMatch.group(2)}-${isoMatch.group(3)}';
    }

    // 5. dd-MM-yyyy or dd/MM/yyyy
    final ddmmyyyyRegex = RegExp(r'^(\d{1,2})[-/](\d{1,2})[-/](\d{4})');
    final ddmmyyyyMatch = ddmmyyyyRegex.firstMatch(str);
    if (ddmmyyyyMatch != null) {
      final day = ddmmyyyyMatch.group(1)!.padLeft(2, '0');
      final month = ddmmyyyyMatch.group(2)!.padLeft(2, '0');
      final year = ddmmyyyyMatch.group(3)!;
      return '$year-$month-$day';
    }

    // 6. DateTime.tryParse
    final parsed = DateTime.tryParse(str);
    if (parsed != null) {
      return DateFormat('yyyy-MM-dd').format(parsed);
    }

    return null;
  }

  List<Map<String, dynamic>> get _filteredList {
    return _evaluatedStudents.where((rec) {
      // Date filter when in BY_DATE mode
      if (!_isAllDatesMode) {
        final markedDate = _extractDateYMD(rec['markedAt']);
        final selectedStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
        if (markedDate != null && markedDate != selectedStr) {
          return false;
        }
      }

      // Search Query
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase().trim();
      final name = (rec['fullName'] ?? '').toString().toLowerCase();
      final reg = (rec['regNo'] ?? '').toString().toLowerCase();
      final spr = (rec['sprNo'] ?? '').toString().toLowerCase();
      final rem = (rec['remarks'] ?? '').toString().toLowerCase();
      return name.contains(q) || reg.contains(q) || spr.contains(q) || rem.contains(q);
    }).toList();
  }

  void _shiftDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
      _isAllDatesMode = false;
    });
    _fetchHistory();
  }

  String _formatDateTime(dynamic raw) {
    if (raw == null) return '—';
    try {
      final str = raw.toString();
      final dt = DateTime.parse(str).toLocal();
      return DateFormat('dd/MM/yyyy, hh:mm a').format(dt);
    } catch (_) {
      return raw.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredList;

    final deptName = widget.selectedDept is Map
        ? (widget.selectedDept['name'] ?? widget.selectedDept['departmentName'] ?? '')
        : '';
    final secName = widget.selectedSection is Map
        ? (widget.selectedSection['sectionName'] ?? widget.selectedSection['name'] ?? '')
        : '';
    final yearName = widget.selectedYear is Map
        ? (widget.selectedYear['yearName'] ?? '')
        : (widget.academicYear ?? '');

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.history_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.activity.name} History',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (yearName.isNotEmpty) yearName,
                          if (deptName.isNotEmpty) deptName,
                          if (secName.isNotEmpty) 'Sec $secName',
                        ].join(' • '),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _fetchHistory,
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
                  tooltip: 'Refresh',
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),

          // Date Toggle & Search Controls
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // All Dates vs By Date Toggle
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() => _isAllDatesMode = true);
                        _fetchHistory();
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _isAllDatesMode
                              ? const Color(0xFF1E293B)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _isAllDatesMode
                                ? const Color(0xFF1E293B)
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_month_rounded,
                              size: 15,
                              color: _isAllDatesMode ? Colors.white : Colors.grey.shade700,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'All Marked Records',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _isAllDatesMode ? Colors.white : Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        setState(() => _isAllDatesMode = false);
                        _fetchHistory();
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: !_isAllDatesMode
                              ? const Color(0xFF1E293B)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: !_isAllDatesMode
                                ? const Color(0xFF1E293B)
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.today_rounded,
                              size: 15,
                              color: !_isAllDatesMode ? Colors.white : Colors.grey.shade700,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'By Date',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: !_isAllDatesMode ? Colors.white : Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Date Picker Controls (if By Date mode)
                if (!_isAllDatesMode) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _shiftDate(-1),
                        icon: const Icon(Icons.chevron_left_rounded),
                        visualDensity: VisualDensity.compact,
                      ),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setState(() {
                              _selectedDate = picked;
                              _isAllDatesMode = false;
                            });
                            _fetchHistory();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text(
                                DateFormat('dd-MM-yyyy').format(_selectedDate),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _shiftDate(1),
                        icon: const Icon(Icons.chevron_right_rounded),
                        visualDensity: VisualDensity.compact,
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedDate = DateTime.now();
                            _isAllDatesMode = false;
                          });
                          _fetchHistory();
                        },
                        child: const Text('Today', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 10),
                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search evaluated students by name, Reg No, or SPR...',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Colors.grey),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF1E293B)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Evaluated Students List
          Expanded(
            child: _isLoading
                ? const Center(child: PragatiXLoader())
                : filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.assignment_turned_in_outlined,
                                  size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              const Text(
                                'No Evaluated Students Found',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'No evaluated students matching "$_searchQuery" in this class.'
                                    : !_isAllDatesMode
                                        ? 'No students were awarded or penalized on ${DateFormat('dd-MM-yyyy').format(_selectedDate)}.'
                                        : 'No students have been awarded or penalized yet for this activity in this class.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, idx) {
                          final rec = filtered[idx];
                          final bool isAward = rec['status'] == 'AWARDED';
                          final name = rec['fullName'] ?? 'Student';
                          final regNo = rec['regNo']?.toString();
                          final sprNo = rec['sprNo']?.toString();
                          final remarks = rec['remarks']?.toString();
                          final markedBy = rec['markedBy']?.toString();
                          final markedAt = rec['markedAt'];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            elevation: 0.5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: isAward
                                        ? const Color(0xFF10B981).withOpacity(0.12)
                                        : const Color(0xFFEF4444).withOpacity(0.12),
                                    child: Text(
                                      name.isNotEmpty ? name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase() : 'ST',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: isAward
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFFEF4444),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: Color(0xFF1E293B),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            if (regNo != null && regNo.isNotEmpty)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade100,
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: Colors.grey.shade300),
                                                ),
                                                child: Text(
                                                  regNo,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.grey.shade700,
                                                  ),
                                                ),
                                              ),
                                            if (sprNo != null && sprNo.isNotEmpty) ...[
                                              const SizedBox(width: 6),
                                              Text(
                                                'SPR: $sprNo',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        if (remarks != null && remarks.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            '"$remarks"',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontStyle: FontStyle.italic,
                                              color: Color(0xFF475569),
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 4),
                                        Text(
                                          '${markedBy != null ? 'Marked by: $markedBy • ' : ''}${_formatDateTime(markedAt)}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: isAward
                                          ? const Color(0xFF10B981).withOpacity(0.1)
                                          : const Color(0xFFEF4444).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isAward
                                            ? const Color(0xFF10B981).withOpacity(0.3)
                                            : const Color(0xFFEF4444).withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isAward ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                          size: 13,
                                          color: isAward
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFFEF4444),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isAward
                                              ? '+${rec['xpChange'] ?? widget.activity.awardXp} XP'
                                              : '${rec['xpChange'] ?? -widget.activity.penaltyXp} XP',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: isAward
                                                ? const Color(0xFF10B981)
                                                : const Color(0xFFEF4444),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
