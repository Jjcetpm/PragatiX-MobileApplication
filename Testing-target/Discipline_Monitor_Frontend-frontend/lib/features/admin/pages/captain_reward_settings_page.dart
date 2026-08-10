import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/features/admin/repository/admin_repository.dart';
import 'package:pragatix/core/di/service_locator.dart';

class CaptainRewardSettingsPage extends StatefulWidget {
  final String? academicYear;

  const CaptainRewardSettingsPage({super.key, this.academicYear});

  @override
  State<CaptainRewardSettingsPage> createState() => _CaptainRewardSettingsPageState();
}

class _CaptainRewardSettingsPageState extends State<CaptainRewardSettingsPage> {
  final AdminRepository _repository = getIt<AdminRepository>();
  bool _isLoading = true;
  String? _effectiveAcademicYear;

  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic> _settings = {};

  final TextEditingController _captainXpController = TextEditingController();
  final TextEditingController _viceCaptainXpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _effectiveAcademicYear = widget.academicYear;
    _loadData();
  }

  @override
  void dispose() {
    _captainXpController.dispose();
    _viceCaptainXpController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final String yearParam = _effectiveAcademicYear ?? (auth.currentUser?['academicYear'] ?? 'FIRST_YEAR');
      
      final settings = await _repository.getCaptainRewardSettings(yearParam);
      setState(() {
        _settings = Map<String, dynamic>.from(settings);
        _captainXpController.text = (_settings['captainXp'] ?? 0).toString();
        _viceCaptainXpController.text = (_settings['viceCaptainXp'] ?? 0).toString();
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

    _settings['captainXp'] = int.tryParse(_captainXpController.text) ?? 0;
    _settings['viceCaptainXp'] = int.tryParse(_viceCaptainXpController.text) ?? 0;

    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final String yearParam = _effectiveAcademicYear ?? (auth.currentUser?['academicYear'] ?? 'FIRST_YEAR');
      
      await _repository.updateCaptainRewardSettings(yearParam, _settings);
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

  void _resetSettings() {
    setState(() {
      _settings['engineEnabled'] = false;
      _settings['executionTime'] = '23:30';
      _captainXpController.text = '20';
      _viceCaptainXpController.text = '10';
    });
  }

  Future<void> _selectTime() async {
    final initialTimeStr = _settings['executionTime'] as String?;
    TimeOfDay initialTime = const TimeOfDay(hour: 23, minute: 30);
    if (initialTimeStr != null && initialTimeStr.isNotEmpty) {
      final parts = initialTimeStr.split(':');
      if (parts.length >= 2) {
        initialTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 23,
          minute: int.tryParse(parts[1]) ?? 30,
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
      setState(() {
        _settings['executionTime'] = '$hourStr:$minStr';
      });
    }
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return 'Not configured';
    final parts = timeStr.split(':');
    if (parts.length < 2) return timeStr;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final time = TimeOfDay(hour: hour, minute: minute);
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    final hourOfPeriod = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    return '${hourOfPeriod.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Captain & Vice Captain Reward Settings',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderCard(),
                    const SizedBox(height: 20),
                    _buildSettingsCard(),
                    const SizedBox(height: 24),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.military_tech_rounded, color: Colors.amber, size: 28),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Automatic Leadership Engine',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Awards weekly XP directly to Captains and Vice Captains at week end.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
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

  Widget _buildSettingsCard() {
    final bool isEnabled = _settings['engineEnabled'] ?? false;
    final String executionTime = _settings['executionTime'] ?? '23:30';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Engine Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reward Engine',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Enable/Disable the weekly automated reward engine',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                Switch(
                  value: isEnabled,
                  activeThumbColor: const Color(0xFF4A90E2),
                  onChanged: (val) {
                    setState(() {
                      _settings['engineEnabled'] = val;
                    });
                  },
                ),
              ],
            ),
            const Divider(height: 32),

            // Captain Weekly XP
            const Text(
              'Captain Weekly Reward XP',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _captainXpController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'e.g. 20',
                suffixText: 'XP',
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.star_rounded, color: Colors.amber),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Please enter Captain XP';
                if (int.tryParse(val) == null) return 'Enter a valid number';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Vice Captain Weekly XP
            const Text(
              'Vice Captain Weekly Reward XP',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _viceCaptainXpController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'e.g. 10',
                suffixText: 'XP',
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.star_half_rounded, color: Colors.amber),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Please enter Vice Captain XP';
                if (int.tryParse(val) == null) return 'Enter a valid number';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Execution Time
            const Text(
              'Execution Time',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectTime,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, color: Color(0xFF4A90E2)),
                        const SizedBox(width: 12),
                        Text(
                          _formatTime(executionTime),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                    const Icon(Icons.edit, size: 18, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: const BorderSide(color: Colors.grey),
            ),
            onPressed: _resetSettings,
            child: const Text('Reset', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A90E2),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _saveSettings,
            child: const Text('Save', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
