import 'package:flutter/material.dart';
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
  String? _effectiveAcademicYear;

  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic> _settings = {};

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
      setState(() => _settings = settings);
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
          const SnackBar(content: Text('Settings saved successfully')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Attendance Settings',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildAcademicCalendarButton(),
                const SizedBox(height: 16),
                _buildEngineConfigCard(),
                const SizedBox(height: 16),
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
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Save All Settings',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildAcademicCalendarButton() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.calendar_month, size: 28, color: Color(0xFF3B82F6)),
        ),
        title: const Text(
          'Academic Calendar Configuration',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('Configure Months, Weeks, and Holidays'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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

  Widget _buildEngineConfigCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Engine Configuration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Daily Attendance Engine'),
              subtitle: const Text('Process daily attendance XP at the configured time'),
              value: _settings['dailyEngineEnabled'] ?? false,
              onChanged: (v) => setState(() => _settings['dailyEngineEnabled'] = v),
            ),
            ListTile(
              title: const Text('Daily Processing Time'),
              subtitle: Text(_formatTime12Hr(_settings['dailyProcessingTime'])),
              trailing: const Icon(Icons.access_time),
              onTap: () => _selectTime('dailyProcessingTime'),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Weekly Attendance Engine'),
              subtitle: const Text('Process weekly perfect attendance rewards'),
              value: _settings['weeklyEngineEnabled'] ?? false,
              onChanged: (v) => setState(() => _settings['weeklyEngineEnabled'] = v),
            ),
            ListTile(
              title: const Text('Weekly Processing Time'),
              subtitle: Text(_formatTime12Hr(_settings['weeklyProcessingTime'])),
              trailing: const Icon(Icons.access_time),
              onTap: () => _selectTime('weeklyProcessingTime'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildXPRulesCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Attendance XP Rules',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            TextFormField(
              initialValue: _settings['partialDayPenalty']?.toString(),
              decoration: const InputDecoration(
                labelText: 'Partial Day Penalty (e.g. -5)',
                helperText: 'Applied when student misses at least one period',
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
                helperText: 'Applied when student is absent for all periods',
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
                labelText: 'Perfect Weekly Reward (e.g. 30)',
                helperText: 'Awarded when student has zero absences for the full week',
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Week Boundary Penalties',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            TextFormField(
              initialValue: _settings['weekStartFullPenalty']?.toString(),
              decoration: const InputDecoration(
                labelText: 'Week Start Full Day Penalty (e.g. -40)',
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
