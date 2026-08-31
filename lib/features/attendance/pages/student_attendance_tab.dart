import 'package:flutter/material.dart';
import 'package:pragatix/core/widgets/pragatix_loader.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/attendance/providers/attendance_provider.dart';
import '../services/attendance_service.dart';
import 'package:intl/intl.dart';
import '../models/student_attendance_history.dart';
import '../models/student_attendance_summary.dart';
import 'package:pragatix/core/utils/error_handler.dart';

class DayAttendanceSummary {
  int totalPeriods = 0;
  int presentPeriods = 0;
  int absentPeriods = 0;

  void addRecord(String status) {
    totalPeriods++;
    final s = status.toUpperCase();
    if (s == 'PRESENT') {
      presentPeriods++;
    } else if (s == 'ABSENT') {
      absentPeriods++;
    }
  }

  /// Returns:
  /// - 'P'       -> All periods present (Green)
  /// - 'PARTIAL' -> Some periods present, some absent (Orange P)
  /// - 'A'       -> All periods absent (Red A)
  String get overallStatus {
    if (totalPeriods == 0) return '-';
    if (presentPeriods == totalPeriods) return 'P';
    if (absentPeriods == totalPeriods) return 'A';
    if (presentPeriods > 0 && absentPeriods > 0) return 'PARTIAL';
    return presentPeriods > 0 ? 'PARTIAL' : 'A';
  }
}

class StudentAttendanceTab extends StatefulWidget {
  const StudentAttendanceTab({super.key});

  @override
  State<StudentAttendanceTab> createState() => _StudentAttendanceTabState();
}

class _StudentAttendanceTabState extends State<StudentAttendanceTab> {
  final AttendanceService _service = AttendanceService();
  List<StudentAttendanceHistory>? _history;
  bool _isLoadingHistory = true;
  DateTime? _selectedDate;
  String _calendarViewFilter = 'This Week';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AttendanceProvider>(context, listen: false);
      if (provider.summary == null) {
        provider.fetchSummary();
      }
    });
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final dateStr = _selectedDate != null
          ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
          : null;
      final history = await _service.getStudentHistory(date: dateStr);
      if (mounted) {
        setState(() {
          _history = history;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4F46E5),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchHistory();
    }
  }

  Map<String, DayAttendanceSummary> _buildDayAttendanceMap() {
    final map = <String, DayAttendanceSummary>{};
    if (_history != null) {
      for (var item in _history!) {
        map.putIfAbsent(item.date, () => DayAttendanceSummary()).addRecord(item.status);
      }
    }
    return map;
  }

  String _getStatusForDate(DateTime dt, Map<String, DayAttendanceSummary> dayMap) {
    final dateKey = DateFormat('yyyy-MM-dd').format(dt);
    if (dayMap.containsKey(dateKey)) {
      return dayMap[dateKey]!.overallStatus;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);

    // Only past days without attendance record are marked as Holiday 'H'
    if (target.isBefore(today)) {
      return 'H';
    }

    // Today or upcoming dates
    return '-';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Consumer<AttendanceProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.summary == null) {
            return const Center(
              child: PragatiXLoader(fullScreen: false, message: 'Loading Attendance...'),
            );
          }

          if (provider.error != null && provider.summary == null) {
            return ErrorHandler.buildErrorWidget(
              provider.error,
              onRetry: () {
                provider.fetchSummary();
                _fetchHistory();
              },
            );
          }

          final summary = provider.summary ??
              StudentAttendanceSummary(
                attendancePercentage: 0.0,
                monthlyAttendancePercentage: 0.0,
                currentStreak: 0,
                totalPresentDays: 0,
                totalAbsentDays: 0,
              );

          final dayMap = _buildDayAttendanceMap();

          return RefreshIndicator(
            color: const Color(0xFF4F46E5),
            onRefresh: () async {
              await provider.fetchSummary();
              await _fetchHistory();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Top Dark Indigo Header with Safe Area
                  _buildDarkHeader(provider.currentStreak),

                  // 2. Main Content Body with smooth overlap
                  Transform.translate(
                    offset: const Offset(0, -30),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 2. Overall Attendance Hero Card
                          _buildOverallAttendanceCard(summary),
                          const SizedBox(height: 16),

                          // 3. Dual Metrics: This Month & This Week Cards
                          _buildDualMetricCards(summary),
                          const SizedBox(height: 16),

                          // 4. Monthly / Weekly Overview Calendar Strip
                          _buildCalendarSection(dayMap),
                          const SizedBox(height: 20),

                          // 5. Attendance History Section
                          _buildHistoryHeader(),
                          const SizedBox(height: 12),
                          _buildHistoryList(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── 1. Top Dark Indigo Header ──────────────────────────────────────────────
  Widget _buildDarkHeader(int streakCount) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 3D Calendar & Clock Illustration positioned on the right
              Positioned(
                right: 25,
                top: -12,
                child: Opacity(
                  opacity: 0.95,
                  child: Image.asset(
                    'assets/images/attendance_calendar_clock.png',
                    height: 85,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),

              // Title & Subtitle + Streak Row
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Attendance',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      // Streak Pill Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 4),
                            Text(
                              '$streakCount',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Track your attendance & stay consistent.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.8),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 2. Overall Attendance Hero Card ────────────────────────────────────────
  Widget _buildOverallAttendanceCard(StudentAttendanceSummary summary) {
    final double percentDouble = (summary.attendancePercentage / 100.0).clamp(0.0, 1.0);
    final int percentInt = summary.attendancePercentage.toInt();
    final int totalDays = summary.totalPresentDays + summary.totalAbsentDays;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overall Attendance',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 18),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: Circular Percentage Gauge + Keep it up! Chip
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 90,
                        height: 90,
                        child: CircularProgressIndicator(
                          value: percentDouble > 0 ? percentDouble : 0.001,
                          strokeWidth: 8,
                          backgroundColor: const Color(0xFFEDE9FE),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                        ),
                      ),
                      Text(
                        '$percentInt%',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Keep it up!',
                      style: TextStyle(
                        color: Color(0xFF6366F1),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),

              // Right: 3 Metric breakdown rows with dividers
              Expanded(
                child: Column(
                  children: [
                    _buildBreakdownRow(
                      dotColor: const Color(0xFF6366F1),
                      label: 'Present Days',
                      value: '${summary.totalPresentDays}',
                      valueColor: const Color(0xFF16A34A),
                    ),
                    const Divider(height: 20, color: Color(0xFFF1F5F9), thickness: 1),
                    _buildBreakdownRow(
                      dotColor: const Color(0xFFEF4444),
                      label: 'Absent Days',
                      value: '${summary.totalAbsentDays}',
                      valueColor: const Color(0xFFEF4444),
                    ),
                    const Divider(height: 20, color: Color(0xFFF1F5F9), thickness: 1),
                    _buildBreakdownRow(
                      dotColor: Colors.transparent,
                      label: 'Total Days',
                      value: '$totalDays',
                      valueColor: const Color(0xFF1E293B),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow({
    required Color dotColor,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  // ── 3. Dual Metric Cards (This Month & This Week) ──────────────────────────
  Widget _buildDualMetricCards(StudentAttendanceSummary summary) {
    final int presentDays = summary.totalPresentDays;
    final int totalDays = summary.totalPresentDays + summary.totalAbsentDays;

    return Row(
      children: [
        // This Month Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFDCFCE7), width: 1.2),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: Color(0xFF16A34A),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'This Month',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${summary.monthlyAttendancePercentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$presentDays Present of $totalDays Days',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // This Week Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE0F2FE), width: 1.2),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.date_range_rounded,
                    color: Color(0xFF0284C7),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'This Week',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${summary.attendancePercentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$presentDays Present of $totalDays Days',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── 4. Monthly / Weekly Overview Calendar Section ──────────────────────────
  Widget _buildCalendarSection(Map<String, DayAttendanceSummary> dayMap) {
    final bool isMonthly = _calendarViewFilter == 'This Month';
    final now = DateTime.now();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with Icon, Title, and Filter Dropdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    size: 18,
                    color: Color(0xFF6366F1),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isMonthly ? 'Monthly Overview' : 'Weekly Overview',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              // Dropdown button
              PopupMenuButton<String>(
                initialValue: _calendarViewFilter,
                onSelected: (val) {
                  setState(() {
                    _calendarViewFilter = val;
                  });
                },
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _calendarViewFilter,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: Color(0xFF4F46E5),
                      ),
                    ],
                  ),
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'This Week',
                    child: Text('This Week', style: TextStyle(fontSize: 13)),
                  ),
                  const PopupMenuItem(
                    value: 'This Month',
                    child: Text('This Month', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Render Either Weekly Strip or Monthly Calendar Grid
          if (!isMonthly)
            _buildWeeklyStrip(dayMap, now)
          else
            _buildMonthlyGrid(dayMap, now),

          const SizedBox(height: 18),

          // Legend Row at bottom with Present (P), Partial (P), Absent (A), Holiday (H)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 6,
            children: [
              _buildLegendItem(const Color(0xFF16A34A), 'Present (P)'),
              _buildLegendItem(const Color(0xFFEA580C), 'Partial (P)'),
              _buildLegendItem(const Color(0xFFEF4444), 'Absent (A)'),
              _buildLegendItem(const Color(0xFFEAB308), 'Holiday (H)'),
            ],
          ),
        ],
      ),
    );
  }

  // ── Weekly Strip View ──────────────────────────────────────────────────────
  Widget _buildWeeklyStrip(Map<String, DayAttendanceSummary> dayMap, DateTime now) {
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekDays = List.generate(7, (i) => monday.add(Duration(days: i)));
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final dt = weekDays[index];
        final dayName = dayNames[index];
        final status = _getStatusForDate(dt, dayMap);

        return Column(
          children: [
            Text(
              dayName,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${dt.day}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            _buildStatusNode(status),
          ],
        );
      }),
    );
  }

  // ── Monthly Grid View ──────────────────────────────────────────────────────
  Widget _buildMonthlyGrid(Map<String, DayAttendanceSummary> dayMap, DateTime now) {
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstDayWeekday = DateTime(now.year, now.month, 1).weekday; // 1 = Mon, 7 = Sun
    final dayHeaders = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    final totalCells = (firstDayWeekday - 1) + daysInMonth;
    final rowCount = (totalCells / 7).ceil();

    return Column(
      children: [
        // Month name & year banner
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMMM yyyy').format(now),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4F46E5),
                ),
              ),
              Text(
                '$daysInMonth Days',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),

        // Day of week headers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: dayHeaders.map((h) {
            return SizedBox(
              width: 32,
              child: Center(
                child: Text(
                  h,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),

        // Date cells grid
        ...List.generate(rowCount, (row) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (col) {
                final cellIndex = row * 7 + col;
                final dayNumber = cellIndex - (firstDayWeekday - 1) + 1;

                if (dayNumber < 1 || dayNumber > daysInMonth) {
                  return const SizedBox(width: 32, height: 32);
                }

                final cellDate = DateTime(now.year, now.month, dayNumber);
                final status = _getStatusForDate(cellDate, dayMap);

                return SizedBox(
                  width: 32,
                  child: Column(
                    children: [
                      Text(
                        '$dayNumber',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      _buildStatusNode(status, size: 26, fontSize: 11),
                    ],
                  ),
                );
              }),
            ),
          );
        }),
      ],
    );
  }

  // ── Reusable Status Indicator Node ─────────────────────────────────────────
  Widget _buildStatusNode(String status, {double size = 30, double fontSize = 13}) {
    Color bgColor = const Color(0xFFF8FAFC);
    Color textColor = const Color(0xFF94A3B8);
    Color borderColor = const Color(0xFFF1F5F9);
    String displayChar = status;

    if (status == 'P') {
      // Full Day Present: Green P
      bgColor = const Color(0xFFDCFCE7);
      textColor = const Color(0xFF16A34A);
      borderColor = const Color(0xFF86EFAC);
      displayChar = 'P';
    } else if (status == 'PARTIAL') {
      // Partial Day Present: Vibrant Orange P
      bgColor = const Color(0xFFFFEDD5);
      textColor = const Color(0xFFEA580C);
      borderColor = const Color(0xFFFB923C);
      displayChar = 'P';
    } else if (status == 'A') {
      // Full Day Absent: Red A
      bgColor = const Color(0xFFFEE2E2);
      textColor = const Color(0xFFEF4444);
      borderColor = const Color(0xFFFCA5A5);
      displayChar = 'A';
    } else if (status == 'H') {
      // Holiday: Light Pastel Yellow H
      bgColor = const Color(0xFFFEF9C3);
      textColor = const Color(0xFFCA8A04);
      borderColor = const Color(0xFFFDE047);
      displayChar = 'H';
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Center(
        child: Text(
          displayChar,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: textColor,
            fontSize: fontSize,
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  // ── 5. Attendance History Section ──────────────────────────────────────────
  Widget _buildHistoryHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Attendance History',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () => _selectDate(context),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 15,
                      color: Color(0xFF4F46E5),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _selectedDate != null
                          ? DateFormat('dd MMM yyyy').format(_selectedDate!)
                          : 'All Dates',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_selectedDate != null) ...[
              const SizedBox(width: 6),
              InkWell(
                onTap: () {
                  setState(() => _selectedDate = null);
                  _fetchHistory();
                },
                child: const Text(
                  'Clear',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildHistoryList() {
    if (_isLoadingHistory) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: PragatiXLoader(fullScreen: false),
        ),
      );
    }

    if (_history == null || _history!.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Clipboard with magnifying glass illustration
            Image.asset(
              'assets/images/attendance_clipboard_empty.png',
              height: 100,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.assignment_outlined,
                size: 56,
                color: Color(0xFFCBD5E1),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'No history available',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Your attendance records will appear here\nonce available.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: Color(0xFF64748B),
                height: 1.35,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _history!.length,
      itemBuilder: (context, index) {
        final item = _history![index];
        final bool isPresent = item.status.toUpperCase() == 'PRESENT';
        final bool isAbsent = item.status.toUpperCase() == 'ABSENT';

        final Color statusBg = isPresent
            ? const Color(0xFFDCFCE7)
            : (isAbsent ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7));
        final Color statusColor = isPresent
            ? const Color(0xFF16A34A)
            : (isAbsent ? const Color(0xFFEF4444) : const Color(0xFFD97706));

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isPresent
                      ? Icons.check_circle_rounded
                      : (isAbsent ? Icons.cancel_rounded : Icons.info_rounded),
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date: ${item.date} • Period: ${item.period}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                        fontSize: 14,
                      ),
                    ),
                    if (item.remarks != null && item.remarks!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Remarks: ${item.remarks}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  item.status,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11.5,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
