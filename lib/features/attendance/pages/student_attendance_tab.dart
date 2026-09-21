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
  final VoidCallback? onBack;

  const StudentAttendanceTab({super.key, this.onBack});

  @override
  State<StudentAttendanceTab> createState() => _StudentAttendanceTabState();
}

class _StudentAttendanceTabState extends State<StudentAttendanceTab> {
  final AttendanceService _service = AttendanceService();
  List<StudentAttendanceHistory>? _history;
  bool _isLoadingHistory = true;
  DateTime? _selectedDate;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);

  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + offset, 1);
    });
  }

  Future<void> _selectMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDatePickerMode: DatePickerMode.year,
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
    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month, 1);
      });
    }
  }

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
            color: const Color(0xFF0284C7),
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
                  _buildDarkHeader(),

                  // 2. Main Content Body with smooth overlap
                  Transform.translate(
                    offset: const Offset(0, -30),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 2. Overall Attendance Hero Card
                          _buildOverallAttendanceCard(summary, dayMap),
                          const SizedBox(height: 16),

                          // 3. This Month Card
                          _buildMonthMetricCard(summary, dayMap),
                          const SizedBox(height: 16),

                          // 4. Monthly Overview Calendar Strip
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

  // ── 1. Top Sky Blue Header ────────────────────────────────────────────────
  Widget _buildDarkHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      if (widget.onBack != null) {
                        widget.onBack!();
                      } else if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Attendance',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  Consumer<AttendanceProvider>(
                    builder: (context, provider, child) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 4),
                            Text(
                              '${provider.currentStreak}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Track your attendance & stay consistent.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.9),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 2. Overall Attendance Hero Card ────────────────────────────────────────
  Widget _buildOverallAttendanceCard(
    StudentAttendanceSummary summary,
    Map<String, DayAttendanceSummary> dayMap,
  ) {
    // Calculate total days from actual day-wise records
    int calcPresent = 0;
    int calcAbsent = 0;
    for (var day in dayMap.values) {
      final st = day.overallStatus;
      if (st == 'P' || st == 'PARTIAL') calcPresent++;
      if (st == 'A') calcAbsent++;
    }

    // If dayMap has records, use actual calculated counts; otherwise fallback to summary
    final int totalPresent = (calcPresent > 0 || calcAbsent > 0)
        ? calcPresent
        : summary.totalPresentDays;
    final int totalAbsent = (calcPresent > 0 || calcAbsent > 0)
        ? calcAbsent
        : summary.totalAbsentDays;
    final int totalDays = totalPresent + totalAbsent;

    final double percentage = totalDays > 0
        ? ((totalPresent / totalDays) * 100.0)
        : (summary.attendancePercentage > 0 ? summary.attendancePercentage : 0.0);
    final double percentDouble = (percentage / 100.0).clamp(0.0, 1.0);
    final int percentInt = percentage.round();

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
                          backgroundColor: const Color(0xFFE0F2FE),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
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
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Keep it up!',
                      style: TextStyle(
                        color: Color(0xFF0284C7),
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
                      dotColor: const Color(0xFF0284C7),
                      label: 'Present Days',
                      value: '$totalPresent',
                      valueColor: const Color(0xFF16A34A),
                    ),
                    const Divider(height: 20, color: Color(0xFFF1F5F9), thickness: 1),
                    _buildBreakdownRow(
                      dotColor: const Color(0xFFEF4444),
                      label: 'Absent Days',
                      value: '$totalAbsent',
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

  // ── 3. This Month Metric Card ──────────────────────────────────────────────
  Widget _buildMonthMetricCard(
    StudentAttendanceSummary summary,
    Map<String, DayAttendanceSummary> dayMap,
  ) {
    final now = DateTime.now();
    final bool isCurrentMonth =
        _selectedMonth.year == now.year && _selectedMonth.month == now.month;
    final String monthTitle =
        isCurrentMonth ? 'This Month' : DateFormat('MMMM yyyy').format(_selectedMonth);

    // Calculate month stats from dayMap
    int monthPresent = 0;
    int monthAbsent = 0;
    final daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;

    for (int d = 1; d <= daysInMonth; d++) {
      final dt = DateTime(_selectedMonth.year, _selectedMonth.month, d);
      final key = DateFormat('yyyy-MM-dd').format(dt);
      if (dayMap.containsKey(key)) {
        final st = dayMap[key]!.overallStatus;
        if (st == 'P' || st == 'PARTIAL') monthPresent++;
        if (st == 'A') monthAbsent++;
      }
    }

    final int totalDays = monthPresent + monthAbsent;
    final int presentDays = monthPresent;
    final double percentage = totalDays > 0
        ? (presentDays / totalDays * 100.0)
        : (isCurrentMonth && summary.monthlyAttendancePercentage > 0
            ? summary.monthlyAttendancePercentage
            : 0.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCFCE7), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF16A34A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
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
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  monthTitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$presentDays Present of $totalDays Days',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF16A34A),
            ),
          ),
        ],
      ),
    );
  }

  // ── 4. Monthly Overview Calendar Section ──────────────────────────────────
  Widget _buildCalendarSection(Map<String, DayAttendanceSummary> dayMap) {
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
          // Header row with Icon, Title, and Month Navigator Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    size: 18,
                    color: Color(0xFF0284C7),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Monthly Overview',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              // Month Switcher pill ( < Month Year > )
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => _changeMonth(-1),
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.chevron_left_rounded,
                          size: 18,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => _selectMonth(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DateFormat('MMM yyyy').format(_selectedMonth),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 14,
                              color: Color(0xFF0284C7),
                            ),
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => _changeMonth(1),
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Render Monthly Calendar Grid
          _buildMonthlyGrid(dayMap, _selectedMonth),

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

  // ── Monthly Grid View ──────────────────────────────────────────────────────
  Widget _buildMonthlyGrid(Map<String, DayAttendanceSummary> dayMap, DateTime displayMonth) {
    final daysInMonth = DateTime(displayMonth.year, displayMonth.month + 1, 0).day;
    final firstDayWeekday = DateTime(displayMonth.year, displayMonth.month, 1).weekday; // 1 = Mon, 7 = Sun
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
                DateFormat('MMMM yyyy').format(displayMonth),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0284C7),
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

                final cellDate = DateTime(displayMonth.year, displayMonth.month, dayNumber);
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
            // Empty icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFF1F5F9),
              ),
              child: const Icon(
                Icons.assignment_outlined,
                size: 40,
                color: Color(0xFF94A3B8),
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
