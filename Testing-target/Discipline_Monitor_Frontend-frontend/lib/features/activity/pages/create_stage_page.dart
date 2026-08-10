import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pragatix/features/activity/services/activity_proxy_service.dart';
import 'package:intl/intl.dart';
import 'package:pragatix/core/config/api_config.dart';
import 'package:pragatix/core/di/service_locator.dart';

class CreateStagePage extends StatefulWidget {
  final String? academicYear;
  const CreateStagePage({super.key, this.academicYear});

  @override
  State<CreateStagePage> createState() => _CreateStagePageState();
}

class _CreateStagePageState extends State<CreateStagePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _orderCtrl = TextEditingController(text: '0');
  final _expectedXpCtrl = TextEditingController(text: '0');

  final _mustThresholdCtrl = TextEditingController(text: '0');
  final _indThresholdCtrl = TextEditingController(text: '0');
  final _grpThresholdCtrl = TextEditingController(text: '0');

  String? _selectedAcademicYear;
  bool _isSaving = false;

  static const Color _primary = Color(0xFFEA4335);
  static const Color _dark = Color(0xFF1E293B);

  @override
  void initState() {
    super.initState();
    _selectedAcademicYear = widget.academicYear;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _orderCtrl.dispose();
    _expectedXpCtrl.dispose();
    _mustThresholdCtrl.dispose();
    _indThresholdCtrl.dispose();
    _grpThresholdCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveStage() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final roles = authProvider.currentUser?['roles'] as List<dynamic>? ?? [];
    final isSuperAdmin = roles.contains('ROLE_SUPER_ADMIN');

    if (isSuperAdmin && _selectedAcademicYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an Academic Year.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final response = await getIt<ActivityProxyService>().post(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/admin/stages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
        },
        body: jsonEncode({
          'name': _nameCtrl.text.trim(),
          'description': _descCtrl.text.trim(),
          'expectedXp': int.tryParse(_expectedXpCtrl.text.trim()) ?? 0,
          'displayOrder': int.tryParse(_orderCtrl.text.trim()) ?? 0,
          'mustThreshold': int.tryParse(_mustThresholdCtrl.text.trim()) ?? 0,
          'individualThreshold':
              int.tryParse(_indThresholdCtrl.text.trim()) ?? 0,
          'groupThreshold': int.tryParse(_grpThresholdCtrl.text.trim()) ?? 0,
          if (isSuperAdmin && _selectedAcademicYear != null) 'academicYear': _selectedAcademicYear,
        }),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 201 ||
          (response.statusCode == 200 && data['success'] == true)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stage created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Failed to create stage'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Stage',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: _dark,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Stage Configuration',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _dark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Define a new progression stage for the Student Development Program.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),

                    TextFormField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Stage Name *',
                        hintText: 'e.g. Stage 1',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: _primary,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Stage Name is required'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    if ((context.read<AuthProvider>().currentUser?['roles'] as List<dynamic>? ?? [])
                            .contains('ROLE_SUPER_ADMIN')) ...[
                      DropdownButtonFormField<String>(
                        value: _selectedAcademicYear,
                        decoration: InputDecoration(
                          labelText: 'Academic Year *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: _primary,
                              width: 2,
                            ),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'FIRST_YEAR',
                            child: Text('First Year'),
                          ),
                          DropdownMenuItem(
                            value: 'SECOND_YEAR',
                            child: Text('Second Year'),
                          ),
                          DropdownMenuItem(
                            value: 'THIRD_YEAR',
                            child: Text('Third Year'),
                          ),
                          DropdownMenuItem(
                            value: 'FOURTH_YEAR',
                            child: Text('Fourth Year'),
                          ),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedAcademicYear = val;
                          });
                        },
                        validator: (v) =>
                            v == null ? 'Academic Year is required' : null,
                      ),
                      const SizedBox(height: 20),
                    ],
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        hintText: 'Describe targets or rules for this stage...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: _primary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _expectedXpCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Expected XP *',
                        hintText: 'e.g. 500',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: _primary,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Expected XP is required';
                        if (int.tryParse(v) == null)
                          return 'Must be a valid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    const SizedBox(height: 24),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _orderCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Display Order',
                        hintText: 'e.g. 1',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: _primary,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        if (int.tryParse(v) == null)
                          return 'Must be a valid integer';
                        return null;
                      },
                    ),
                    // Subgroup Thresholds Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Subgroup Thresholds',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _dark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Students must complete all required subgroup thresholds before promoting to the next stage.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _mustThresholdCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Must Threshold',
                              hintText: 'e.g. 50',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _indThresholdCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Individual Threshold',
                              hintText: 'e.g. 100',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _grpThresholdCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Group Threshold',
                              hintText: 'e.g. 150',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _saveStage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Create Stage',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
