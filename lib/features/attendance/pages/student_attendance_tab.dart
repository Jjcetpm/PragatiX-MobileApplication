import 'package:flutter/material.dart';
import 'package:pragatix/core/widgets/pragatix_loader.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/attendance/providers/attendance_provider.dart';
import '../services/attendance_service.dart';
import 'package:intl/intl.dart';
import '../models/student_attendance_history.dart';
import '../widgets/fire_streak_icon.dart';

class StudentAttendanceTab extends StatefulWidget {
  const StudentAttendanceTab({Key? key}) : super(key: key);

  @override
  State<StudentAttendanceTab> createState() => _StudentAttendanceTabState();
}

class _StudentAttendanceTabState extends State<StudentAttendanceTab> {
  final AttendanceService _service = AttendanceService();
  List<StudentAttendanceHistory>? _history;
  bool _isLoadingHistory = true;
  DateTime? _selectedDate;

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
      final dateStr = _selectedDate != null ? DateFormat('yyyy-MM-dd').format(_selectedDate!) : null;
      final history = await _service.getStudentHistory(date: dateStr);
      setState(() {
        _history = history;
        _isLoadingHistory = false;
      });
    } catch (e) {
      setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Attendance',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          Consumer<AttendanceProvider>(
            builder: (context, provider, child) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: FireStreakIcon(streakCount: provider.currentStreak),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<AttendanceProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: PragatiXLoader(fullScreen: false, message: 'Loading Attendance...'),
            );
          }

          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}'));
          }

          final summary = provider.summary;
          if (summary == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No attendance data available.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.fetchSummary();
                      _fetchHistory();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await provider.fetchSummary();
              await _fetchHistory();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCards(summary),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Attendance History',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _selectDate(context),
                        icon: const Icon(Icons.calendar_today_rounded, size: 18),
                        label: Text(_selectedDate != null
                            ? DateFormat('dd MMM yyyy').format(_selectedDate!)
                            : 'All Dates'),
                      ),
                    ],
                  ),
                  if (_selectedDate != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedDate = null;
                          });
                          _fetchHistory();
                        },
                        child: const Text('Clear Filter', style: TextStyle(color: Colors.red)),
                      ),
                    ),
                  const SizedBox(height: 12),
                  _buildHistoryList(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards(summary) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Overall',
                '${summary.attendancePercentage}%',
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                'Monthly',
                '${summary.monthlyAttendancePercentage}%',
                Colors.teal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Present Days',
                '${summary.totalPresentDays}',
                Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                'Absent Days',
                '${summary.totalAbsentDays}',
                Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    if (_isLoadingHistory) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: PragatiXLoader(),
        ),
      );
    }
    if (_history == null || _history!.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No history available.'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _history!.length,
      itemBuilder: (context, index) {
        final item = _history![index];
        final isPresent = item.status == 'PRESENT';
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            leading: Icon(
              isPresent ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: isPresent ? Colors.green : Colors.red,
            ),
            title: Text('Date: ${item.date} | Period: ${item.period}'),
            subtitle: item.remarks != null && item.remarks!.isNotEmpty
                ? Text('Remarks: ${item.remarks}')
                : null,
            trailing: Text(
              item.status,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isPresent ? Colors.green : Colors.red,
              ),
            ),
          ),
        );
      },
    );
  }
}
