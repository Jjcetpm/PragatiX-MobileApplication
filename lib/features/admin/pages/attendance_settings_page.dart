import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pragatix/core/widgets/pragatix_loader.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import '../services/attendance_settings_service.dart';
import 'academic_calendar_page.dart';

class AttendanceSettingsPage extends StatefulWidget {
  final String? academicYear;

  const AttendanceSettingsPage({super.key, this.academicYear});

  @override
  State<AttendanceSettingsPage> createState() => _AttendanceSettingsPageState();
}

class _AttendanceSettingsPageState extends State<AttendanceSettingsPage> {
  final AttendanceSettingsService _service = AttendanceSettingsService();
  bool _isLoading = true;
  bool _isDailyRunning = false;
  bool _isWeeklyRunning = false;
  String? _effectiveAcademicYear;

  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic> _settings = {};
  List<dynamic> _history = [];

  @override
  void initState() {
    super.initState();
    _effectiveAcademicYear = widget.academicYear;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final String? yearParam = auth.isSuperAdmin ? _effectiveAcademicYear : null;
      final settings = await _service.getSettings(academicYear: yearParam);
      List<dynamic> history = [];
      try {
        history = await _service.getExecutionHistory(academicYear: yearParam);
      } catch (_) {}
      setState(() {
        _settings = settings;
        _history = history;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading settings: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final String? yearParam = auth.isSuperAdmin ? _effectiveAcademicYear : null;
      await _service.updateSettings(_settings, academicYear: yearParam);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _triggerDailyEngine() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final String? yearParam = auth.isSuperAdmin ? _effectiveAcademicYear : null;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.flash_on_rounded, color: Color(0xFF4F46E5)),
            SizedBox(width: 8),
            Text('Run Daily Engine', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Are you sure you want to run the Daily Attendance Engine now?\n\n'
          '• Evaluates daily attendance for today\'s date.\n'
          '• Full-Day Present students get daily streak +1.\n'
          '• Absent students receive configured day penalties.\n'
          '• Protected against duplicate runs.',
          style: TextStyle(fontSize: 13.5, height: 1.5, color: Color(0xFF334155)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Run Daily Engine'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDailyRunning = true);
    try {
      final result = await _service.runDailyEngine(academicYear: yearParam);
      if (mounted) {
        _showResultDialog('Daily Attendance Engine Result', result);
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Daily engine failed: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDailyRunning = false);
    }
  }

  Future<void> _triggerWeeklyEngine() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final String? yearParam = auth.isSuperAdmin ? _effectiveAcademicYear : null;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.emoji_events_rounded, color: Color(0xFF7C3AED)),
            SizedBox(width: 8),
            Text('Run Weekly Engine', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Are you sure you want to run the Weekly Attendance Engine now?\n\n'
          '• Evaluates all working days in the active academic week.\n'
          '• Students with 100% full attendance on all working days receive weekly award XP.\n'
          '• Protected against duplicate award distribution.',
          style: TextStyle(fontSize: 13.5, height: 1.5, color: Color(0xFF334155)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Run Weekly Engine'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isWeeklyRunning = true);
    try {
      final result = await _service.runWeeklyEngine(academicYear: yearParam);
      if (mounted) {
        _showResultDialog('Weekly Attendance Engine Result', result);
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Weekly engine failed: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isWeeklyRunning = false);
    }
  }

  void _showResultDialog(String title, Map<String, dynamic> result) {
    final status = (result['status'] ?? 'SUCCESS').toString().toUpperCase();
    final bool isSuccess = status == 'SUCCESS';
    final bool isSkipped = status == 'SKIPPED';
    final Color headerColor = isSuccess
        ? const Color(0xFF10B981)
        : (isSkipped ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: headerColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSuccess ? Icons.check_circle_rounded : (isSkipped ? Icons.info_rounded : Icons.error_rounded),
                    color: headerColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  if (result['message'] != null) ...[
                    Text(
                      result['message'],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: headerColor,
                      ),
                    ),
                    const Divider(height: 16),
                  ],
                  _buildResultRow('Status', status, isBadge: true, badgeColor: headerColor),
                  if (result['processedStudents'] != null)
                    _buildResultRow('Processed Students', '${result['processedStudents']}'),
                  if (result['presentStudents'] != null)
                    _buildResultRow('Full-Day Present', '${result['presentStudents']}'),
                  if (result['absentStudents'] != null)
                    _buildResultRow('Absent Students', '${result['absentStudents']}'),
                  if (result['penaltiesApplied'] != null)
                    _buildResultRow('Penalties Applied', '${result['penaltiesApplied']}'),
                  if (result['streaksUpdated'] != null)
                    _buildResultRow('Streaks Incremented', '${result['streaksUpdated']}'),
                  if (result['eligibleStudents'] != null)
                    _buildResultRow('Eligible Students', '${result['eligibleStudents']}'),
                  if (result['awardsApplied'] != null)
                    _buildResultRow('Weekly Awards Applied', '${result['awardsApplied']}'),
                  if (result['executionTimeSeconds'] != null)
                    _buildResultRow('Execution Time', '${result['executionTimeSeconds']}s'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, {bool isBadge = false, Color? badgeColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          isBadge
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: (badgeColor ?? const Color(0xFF4F46E5)).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: badgeColor ?? const Color(0xFF4F46E5),
                    ),
                  ),
                )
              : Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
        ],
      ),
    );
  }

  Future<void> _selectTime(String key) async {
    final initialTimeStr = _settings[key] as String?;
    TimeOfDay initialTime = TimeOfDay.now();
    if (initialTimeStr != null && initialTimeStr.isNotEmpty) {
      final parts = initialTimeStr.split(':');
      if (parts.length >= 2) {
        initialTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      final hourStr = picked.hour.toString().padLeft(2, '0');
      final minStr = picked.minute.toString().padLeft(2, '0');
      setState(() => _settings[key] = '$hourStr:$minStr:00');
    }
  }

  String _formatTime12Hr(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return 'Not set';
    final parts = timeStr.split(':');
    if (parts.length < 2) return timeStr;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final time = TimeOfDay(hour: h, minute: m);
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    final hour12 = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minStr = time.minute.toString().padLeft(2, '0');
    return '$hour12:$minStr $period';
  }

  String _formatDateTime(String? dtStr) {
    if (dtStr == null || dtStr.isEmpty) return 'Never run';
    try {
      final dt = DateTime.parse(dtStr);
      return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    } catch (_) {
      return dtStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _effectiveAcademicYear != null
              ? 'Attendance Settings (${_effectiveAcademicYear!.replaceAll('_', ' ')})'
              : 'Attendance Settings',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 17),
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: PragatiXLoader())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildAcademicCalendarButton(),
                const SizedBox(height: 16),
                _buildDailyEngineControlCard(),
                const SizedBox(height: 16),
                _buildWeeklyEngineControlCard(),
                const SizedBox(height: 16),
                if (_history.isNotEmpty) ...[
                  _buildExecutionHistoryCard(),
                  const SizedBox(height: 16),
                ],
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildXPRulesCard(),
                      const SizedBox(height: 16),
                      _buildBoundaryPenaltiesCard(),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save_rounded, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Save Configuration',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildAcademicCalendarButton() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.calendar_month_rounded, size: 26, color: Color(0xFF3B82F6)),
        ),
        title: const Text(
          'Academic Calendar',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
        ),
        subtitle: const Text('Configure Months, Weeks, and Holidays', style: TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 15, color: Color(0xFF94A3B8)),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AcademicCalendarPage(
                initialAcademicYear: _effectiveAcademicYear,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDailyEngineControlCard() {
    final String lastRun = _formatDateTime(_settings['lastDailyRun']);
    final String runType = (_settings['lastDailyRunType'] ?? 'AUTOMATIC').toString().toUpperCase();
    final String runStatus = (_settings['lastDailyRunStatus'] ?? _settings['dailyEngineStatus'] ?? 'WAITING').toString().toUpperCase();

    Color statusColor;
    if (runStatus == 'SUCCESS') {
      statusColor = const Color(0xFF10B981);
    } else if (runStatus == 'FAILED' || runStatus == 'ERROR') {
      statusColor = const Color(0xFFEF4444);
    } else if (runStatus == 'RUNNING') {
      statusColor = const Color(0xFFF59E0B);
    } else {
      statusColor = const Color(0xFF64748B);
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.bolt_rounded, color: Color(0xFF4F46E5), size: 22),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Daily Attendance Engine',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    runStatus,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Automatic Trigger', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: const Text('Executes daily at scheduled time', style: TextStyle(fontSize: 12)),
              value: _settings['dailyEngineEnabled'] ?? false,
              activeThumbColor: const Color(0xFF4F46E5),
              onChanged: (v) => setState(() => _settings['dailyEngineEnabled'] = v),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Scheduled Time', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: Text(_formatTime12Hr(_settings['dailyProcessingTime']), style: const TextStyle(fontSize: 13, color: Color(0xFF4F46E5), fontWeight: FontWeight.w700)),
              trailing: const Icon(Icons.access_time_rounded, size: 20, color: Color(0xFF4F46E5)),
              onTap: () => _selectTime('dailyProcessingTime'),
            ),
            const Divider(height: 20),
            // Info Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Column(
                children: [
                  _buildEngineInfoLine('Last Run', lastRun),
                  const SizedBox(height: 6),
                  _buildEngineInfoLine(
                    'Last Run Type',
                    runType,
                    badge: true,
                    badgeColor: runType == 'MANUAL' ? const Color(0xFF8B5CF6) : const Color(0xFF3B82F6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: _isDailyRunning ? null : _triggerDailyEngine,
                icon: _isDailyRunning
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.flash_on_rounded, size: 18),
                label: Text(
                  _isDailyRunning ? 'Running Daily Engine...' : 'RUN DAILY ENGINE',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, letterSpacing: 0.3),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyEngineControlCard() {
    final String lastRun = _formatDateTime(_settings['lastWeeklyRun']);
    final String runType = (_settings['lastWeeklyRunType'] ?? 'AUTOMATIC').toString().toUpperCase();
    final String runStatus = (_settings['lastWeeklyRunStatus'] ?? _settings['weeklyEngineStatus'] ?? 'WAITING').toString().toUpperCase();

    Color statusColor;
    if (runStatus == 'SUCCESS') {
      statusColor = const Color(0xFF10B981);
    } else if (runStatus == 'FAILED' || runStatus == 'ERROR') {
      statusColor = const Color(0xFFEF4444);
    } else if (runStatus == 'RUNNING') {
      statusColor = const Color(0xFFF59E0B);
    } else {
      statusColor = const Color(0xFF64748B);
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFF7C3AED), size: 22),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Weekly Attendance Engine',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    runStatus,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Automatic Trigger', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: const Text('Executes at the end of active academic week', style: TextStyle(fontSize: 12)),
              value: _settings['weeklyEngineEnabled'] ?? false,
              activeThumbColor: const Color(0xFF7C3AED),
              onChanged: (v) => setState(() => _settings['weeklyEngineEnabled'] = v),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Scheduled Time', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: Text(_formatTime12Hr(_settings['weeklyProcessingTime']), style: const TextStyle(fontSize: 13, color: Color(0xFF7C3AED), fontWeight: FontWeight.w700)),
              trailing: const Icon(Icons.access_time_rounded, size: 20, color: Color(0xFF7C3AED)),
              onTap: () => _selectTime('weeklyProcessingTime'),
            ),
            const Divider(height: 20),
            // Info Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Column(
                children: [
                  _buildEngineInfoLine('Last Run', lastRun),
                  const SizedBox(height: 6),
                  _buildEngineInfoLine(
                    'Last Run Type',
                    runType,
                    badge: true,
                    badgeColor: runType == 'MANUAL' ? const Color(0xFF8B5CF6) : const Color(0xFF3B82F6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: _isWeeklyRunning ? null : _triggerWeeklyEngine,
                icon: _isWeeklyRunning
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.emoji_events_rounded, size: 18),
                label: Text(
                  _isWeeklyRunning ? 'Running Weekly Engine...' : 'RUN WEEKLY ENGINE',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, letterSpacing: 0.3),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEngineInfoLine(String label, String value, {bool badge = false, Color? badgeColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
        badge
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: (badgeColor ?? const Color(0xFF64748B)).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  value,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: badgeColor ?? const Color(0xFF64748B)),
                ),
              )
            : Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
      ],
    );
  }

  Widget _buildExecutionHistoryCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.history_rounded, size: 22, color: Color(0xFF0F172A)),
                    SizedBox(width: 8),
                    Text(
                      'Recent Engine Executions',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 20, color: Color(0xFF64748B)),
                  onPressed: _loadData,
                  tooltip: 'Refresh History',
                ),
              ],
            ),
            const Divider(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _history.length > 5 ? 5 : _history.length,
              separatorBuilder: (c, i) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final item = _history[index];
                final engineType = item['engineType'] ?? 'DAILY';
                final execType = item['executionType'] ?? 'AUTOMATIC';
                final status = (item['status'] ?? 'SUCCESS').toString().toUpperCase();
                final startedAt = _formatDateTime(item['startedAt']);
                final processed = item['processedCount'] ?? 0;
                final present = item['presentCount'] ?? 0;
                final penalties = item['penaltiesApplied'] ?? 0;
                final streaks = item['streaksUpdated'] ?? 0;

                Color statusColor;
                if (status == 'SUCCESS') {
                  statusColor = const Color(0xFF10B981);
                } else if (status == 'FAILED') {
                  statusColor = const Color(0xFFEF4444);
                } else if (status == 'SKIPPED') {
                  statusColor = const Color(0xFFF59E0B);
                } else {
                  statusColor = const Color(0xFF64748B);
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: engineType == 'DAILY' ? const Color(0xFF4F46E5).withValues(alpha: 0.12) : const Color(0xFF7C3AED).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            engineType,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: engineType == 'DAILY' ? const Color(0xFF4F46E5) : const Color(0xFF7C3AED),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: execType == 'MANUAL' ? const Color(0xFF8B5CF6).withValues(alpha: 0.12) : const Color(0xFF3B82F6).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            execType,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: execType == 'MANUAL' ? const Color(0xFF8B5CF6) : const Color(0xFF3B82F6),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$startedAt • ${item['periodStart'] ?? ''}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      engineType == 'DAILY'
                          ? 'Processed: $processed  •  Present: $present  •  Penalties: $penalties  •  Streaks: $streaks'
                          : 'Processed: $processed  •  Eligible: $present  •  Awards: $penalties',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildXPRulesCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.tune_rounded, color: Color(0xFF0F172A), size: 22),
                SizedBox(width: 8),
                Text(
                  'Daily & Weekly XP Rules',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            const Divider(height: 20),
            TextFormField(
              initialValue: _settings['partialDayPenalty']?.toString(),
              decoration: const InputDecoration(
                labelText: 'Partial Day Penalty (e.g. -5)',
                helperText: 'Applied when student misses at least one period',
                prefixIcon: Icon(Icons.remove_circle_outline_rounded, color: Color(0xFFEF4444), size: 20),
              ),
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Cannot be empty';
                final val = int.tryParse(v);
                if (val == null) return 'Must be a valid integer';
                if (val > 0) return 'Must be negative or zero';
                return null;
              },
              onSaved: (v) => _settings['partialDayPenalty'] = int.tryParse(v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _settings['fullDayPenalty']?.toString(),
              decoration: const InputDecoration(
                labelText: 'Full Day Penalty (e.g. -10)',
                helperText: 'Applied when student is absent for the complete day',
                prefixIcon: Icon(Icons.do_not_disturb_on_rounded, color: Color(0xFFDC2626), size: 20),
              ),
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Cannot be empty';
                final val = int.tryParse(v);
                if (val == null) return 'Must be a valid integer';
                if (val > 0) return 'Must be negative or zero';
                return null;
              },
              onSaved: (v) => _settings['fullDayPenalty'] = int.tryParse(v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _settings['perfectWeekReward']?.toString(),
              decoration: const InputDecoration(
                labelText: 'Perfect Week Reward (e.g. 30)',
                helperText: 'Awarded when student has 100% attendance on all working days',
                prefixIcon: Icon(Icons.emoji_events_rounded, color: Color(0xFFF59E0B), size: 20),
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Cannot be empty';
                final val = int.tryParse(v);
                if (val == null) return 'Must be a valid integer';
                if (val < 0) return 'Must be positive or zero';
                return null;
              },
              onSaved: (v) => _settings['perfectWeekReward'] = int.tryParse(v!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoundaryPenaltiesCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.calendar_view_week_rounded, color: Color(0xFF0F172A), size: 22),
                SizedBox(width: 8),
                Text(
                  'Week Boundary Penalties',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            const Divider(height: 20),
            TextFormField(
              initialValue: _settings['weekStartFullPenalty']?.toString(),
              decoration: const InputDecoration(
                labelText: 'Week Start Full Day Penalty (e.g. -40)',
                helperText: 'Applied on Monday / First working day of week',
              ),
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Cannot be empty';
                final val = int.tryParse(v);
                if (val == null) return 'Must be a valid integer';
                if (val > 0) return 'Must be negative or zero';
                return null;
              },
              onSaved: (v) => _settings['weekStartFullPenalty'] = int.tryParse(v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _settings['weekStartPartialPenalty']?.toString(),
              decoration: const InputDecoration(
                labelText: 'Week Start Partial Penalty (e.g. -10)',
              ),
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Cannot be empty';
                final val = int.tryParse(v);
                if (val == null) return 'Must be a valid integer';
                if (val > 0) return 'Must be negative or zero';
                return null;
              },
              onSaved: (v) => _settings['weekStartPartialPenalty'] = int.tryParse(v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _settings['weekEndFullPenalty']?.toString(),
              decoration: const InputDecoration(
                labelText: 'Week End Full Day Penalty (e.g. -40)',
                helperText: 'Applied on Friday / Last working day of week',
              ),
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Cannot be empty';
                final val = int.tryParse(v);
                if (val == null) return 'Must be a valid integer';
                if (val > 0) return 'Must be negative or zero';
                return null;
              },
              onSaved: (v) => _settings['weekEndFullPenalty'] = int.tryParse(v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _settings['weekEndPartialPenalty']?.toString(),
              decoration: const InputDecoration(
                labelText: 'Week End Partial Penalty (e.g. -10)',
              ),
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Cannot be empty';
                final val = int.tryParse(v);
                if (val == null) return 'Must be a valid integer';
                if (val > 0) return 'Must be negative or zero';
                return null;
              },
              onSaved: (v) => _settings['weekEndPartialPenalty'] = int.tryParse(v!),
            ),
          ],
        ),
      ),
    );
  }
}
