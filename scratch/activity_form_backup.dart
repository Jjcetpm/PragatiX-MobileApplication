import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:pragatix/features/activity/services/activity_proxy_service.dart';
import 'package:pragatix/core/config/api_config.dart';
import 'package:pragatix/features/activity/models/activity_model.dart';
import 'package:pragatix/features/activity/providers/activity_provider.dart';
import 'package:pragatix/features/activity/utils/validators.dart';
import 'package:pragatix/features/activity/widgets/activity_section.dart';
import 'package:pragatix/features/activity/widgets/evidence_selector.dart';
import 'package:pragatix/features/activity/widgets/type_selector.dart';
import 'package:pragatix/core/di/service_locator.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared activity form used by both CreateActivityPage and EditActivityPage.
// Parent pages access buildBody() via GlobalKey<ActivityFormState>.
// ─────────────────────────────────────────────────────────────────────────────

class ActivityForm extends StatefulWidget {
  final List<dynamic> allTeachers;
  final List<dynamic> sections;
  final ActivityModel? initialData;
  final bool isCc;
  final ActivityProvider provider;

  const ActivityForm({
    super.key,
    required this.allTeachers,
    required this.sections,
    
    required this.provider,
    this.initialData,
    this.isCc = false,
  });

  @override
  ActivityFormState createState() => ActivityFormState();
}

// Public state class so parent pages can call buildBody() via GlobalKey.
class ActivityFormState extends State<ActivityForm> {
  // ── Design tokens ──────────────────────────────────────────────────────────
  static const Color _primary = Color(0xFFEA4335);
  static const Color _dark = Color(0xFF1E293B);
  static const Color _surface = Color(0xFFF8FAFC);

  // ── Form ──────────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _justCtrl = TextEditingController();
  final _teacherSearchCtrl = TextEditingController();
  final _capCtrl = TextEditingController(text: '1');
  final _displayOrderCtrl = TextEditingController(text: '0');
  bool _awardEnabled = true;
  bool _penaltyEnabled = false;
  final _awardXpCtrl = TextEditingController(text: '0');
  final _penaltyXpCtrl = TextEditingController(text: '0');
  String _selectedStatus = 'ACTIVE';

  // ── Selection state ───────────────────────────────────────────────────────
  dynamic _selectedTeacher;
  dynamic _selectedSection;
  Set<String> _selectedEvidence = {};
  String _selectedAwardType = 'Fixed XP';
  String _selectedAwardFrequency = 'One Time';
  Set<String> _selectedAwardDays = {};
  String _selectedType = 'Individual';
  String _teacherSearchQuery = '';
  String? _selectedXpCategory;
  String _selectedXpType = 'Reward';
  static const List<String> _xpCategories = [
    'Academic',
    'Skill',
    'Communication',
    'Leadership',
    'Discipline',
    'Placement',
    'Innovation',
    'Community',
    'Sports',
    'Cultural',
  ];


  static const List<String> _workingDays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday',
  ];

  bool _submitted = false;

  String? _ccYear;
  int? _ccDeptId;
  String? _ccDeptName;
  String? _ccSection;
  bool _isLoadingCcProfile = false;

  Future<void> _fetchMeProfile() async {
    if (!widget.isCc) return;
    setState(() => _isLoadingCcProfile = true);
    try {
      final response = await getIt<ActivityProxyService>().get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/me'),
        headers: {'Authorization': 'Bearer ${context.read<AuthProvider>().token!}'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final profile = data['data'];
          setState(() {
            _ccYear = profile['year']?.toString();
            _ccDeptId = profile['departmentId'] != null ? (profile['departmentId'] as num).toInt() : null;
            _ccDeptName = profile['departmentName']?.toString();
            _ccSection = profile['section']?.toString();

            // Auto-select the CC's own section if it matches!
            if (_ccSection != null && _ccSection!.isNotEmpty) {
              try {
                _selectedSection = _filteredSections.firstWhere(
                  (s) => s['sectionName']?.toString().toLowerCase() == _ccSection!.toLowerCase(),
                );
              } catch (_) {}
            }
          });
        }
      }
    } catch (_) {}
    setState(() => _isLoadingCcProfile = false);
  }

  void _showCustomFrequencyDialog() {
    String name = '';
    String capType = 'UNLIMITED';
    String maxCountStr = '1';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              title: const Text('New Custom Frequency', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(labelText: 'Frequency Name (e.g. Assignment)'),
                    onChanged: (val) => name = val,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Radio<String>(
                        value: 'UNLIMITED',
                        groupValue: capType,
                        onChanged: (val) => setStateDialog(() => capType = val!),
                      ),
                      const Text('Unlimited'),
                      Radio<String>(
                        value: 'MANUAL_CAP',
                        groupValue: capType,
                        onChanged: (val) => setStateDialog(() => capType = val!),
                      ),
                      const Text('Manual Cap'),
                    ],
                  ),
                  if (capType == 'MANUAL_CAP')
                    TextField(
                      decoration: const InputDecoration(labelText: 'Maximum Count'),
                      keyboardType: TextInputType.number,
                      onChanged: (val) => maxCountStr = val,
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (name.trim().isEmpty) return;
                    int defaultCap = 0;
                    if (capType == 'MANUAL_CAP') {
                      defaultCap = int.tryParse(maxCountStr) ?? 1;
                      if (defaultCap <= 0) defaultCap = 1;
                    }
                    final res = await widget.provider.createCustomFrequency({
                      'name': name.trim(),
                      'capType': capType,
                      'defaultCap': defaultCap,
                    });
                    if (res != null) {
                      if (!context.mounted) return;
                      Navigator.pop(ctx, res);
                    } else {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text(widget.provider.error ?? 'Error creating frequency')),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    ).then((result) {
      if (result != null && result is Map) {
        setState(() {
          _selectedAwardFrequency = result['name'];
          if (result['capType'] == 'UNLIMITED') {
            _capCtrl.text = '1';
          } else {
            _capCtrl.text = result['defaultCap'].toString();
          }
        });
      } else {
        if (_selectedAwardFrequency == 'Manual') {
            setState(() => _selectedAwardFrequency = 'One Time');
        }
      }
    });
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fetchMeProfile();
    final d = widget.initialData;
    if (d != null) {
      _nameCtrl.text = d.name;
      _descCtrl.text = d.description;
      _justCtrl.text = d.justification;
      _capCtrl.text = d.cap.toString();
      _displayOrderCtrl.text = d.displayOrder.toString();
      _selectedStatus = d.status.isNotEmpty ? d.status : 'ACTIVE';
      _awardEnabled = d.awardEnabled;
      _penaltyEnabled = d.penaltyEnabled;
      _awardXpCtrl.text = d.awardXp.toString();
      _penaltyXpCtrl.text = d.penaltyXp.toString();
      _selectedAwardType = d.awardType.isNotEmpty ? d.awardType : 'Fixed XP';
      _selectedAwardFrequency = d.awardFrequency.isNotEmpty ? d.awardFrequency : 'One Time';
      _selectedAwardDays = Set<String>.from(d.awardDays);
      _selectedType = d.type.isNotEmpty ? d.type : 'Individual';
      _selectedEvidence = Set<String>.from(d.evidence);
      _selectedXpCategory = _normalizeXpCategory(d.xpCategory);
      _selectedXpType = d.xpType.isNotEmpty ? d.xpType : 'Reward';

      if (widget.isCc && d.assignmentSummary.isNotEmpty) {
        final assign = d.assignmentSummary.first;
        final tId = assign['teacherId'];
        if (tId != null) {
          if (tId == 0 || tId.toString() == '0') {
            _selectedTeacher = {
              'id': 0,
              'fullName': 'Any Faculty',
              'username': 'any',
              'departmentName': 'Global'
            };
          } else {
            try {
              _selectedTeacher = widget.allTeachers.firstWhere(
                (t) => t['id'].toString() == tId.toString(),
              );
            } catch (_) {}
          }
        }
        final secId = assign['sectionId'];
        if (secId != null) {
          try {
            _selectedSection = widget.sections.firstWhere(
              (s) => s['id'].toString() == secId.toString(),
            );
          } catch (_) {}
        }
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _capCtrl.dispose();
    _displayOrderCtrl.dispose();
    _descCtrl.dispose();
    _justCtrl.dispose();
    _teacherSearchCtrl.dispose();
    _awardXpCtrl.dispose();
    _penaltyXpCtrl.dispose();
    super.dispose();
  }

  String? _normalizeXpCategory(String? cat) {
    if (cat == null || cat.trim().isEmpty) return null;
    final normalized = cat.trim().toLowerCase();
    for (final key in _xpCategories) {
      if (key.toLowerCase() == normalized) {
        return key;
      }
    }
    return null;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  List<dynamic> get _searchedTeachers {
    final virtualAny = {
      'id': 0,
      'fullName': 'Any Faculty',
      'username': 'any',
      'departmentName': 'Global'
    };
    if (_teacherSearchQuery.trim().isEmpty) {
      return [virtualAny, ...widget.allTeachers];
    }
    final query = _teacherSearchQuery.toLowerCase();
    final matchesVirtual = 'any faculty'.contains(query) || 'any'.contains(query) || 'global'.contains(query);
    final filtered = widget.allTeachers.where((t) {
      final name = (t['fullName'] as String? ?? '').toLowerCase();
      final username = (t['username'] as String? ?? '').toLowerCase();
      final dept = (t['departmentName'] as String? ?? '').toLowerCase();
      return name.contains(query) || username.contains(query) || dept.contains(query);
    }).toList();
    return matchesVirtual ? [virtualAny, ...filtered] : filtered;
  }

  List<dynamic> get _filteredSections {
    if (widget.isCc) {
      return widget.sections.where((s) {
        final sName = s['sectionName']?.toString().trim().toLowerCase() ?? '';
        final sDeptId = s['department'] != null ? s['department']['id'] : null;

        final targetSection = _ccSection?.trim().toLowerCase() ?? '';
        final targetDeptId = _ccDeptId;

        final bool sectionMatches = targetSection.isEmpty || sName == targetSection;
        final bool deptMatches = targetDeptId == null || sDeptId == targetDeptId;

        return sectionMatches && deptMatches;
      }).toList();
    }
    return widget.sections;
  }

  List<Widget> _buildAdminAssignmentSummaryRows() {
    final summary = widget.initialData?.assignmentSummary ?? [];
    if (summary.isEmpty) {
      return [
        const Text(
          'No assignments defined for this department.',
          style: TextStyle(fontSize: 13, color: Colors.grey, fontStyle: FontStyle.italic),
        )
      ];
    }

    return summary.map((assign) {
      final secName = assign['section'] as String?;
      final teachName = assign['teacherName'] as String? ?? 'Not Assigned';
      final isAssigned = teachName.toLowerCase() != 'not assigned';

      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            if (secName != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  secName,
                  style: const TextStyle(
                    color: _primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            CircleAvatar(
              radius: 12,
              backgroundColor: isAssigned ? Colors.blue.shade50 : Colors.grey.shade100,
              child: Icon(
                Icons.person_rounded,
                size: 14,
                color: isAssigned ? Colors.blue : Colors.grey.shade400,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                teachName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isAssigned ? _dark : Colors.grey.shade500,
                ),
              ),
            ),
            if (!isAssigned)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Text(
                  'Not Assigned',
                  style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      );
    }).toList();
  }

  InputDecoration _deco(String label, IconData icon,
      {bool alignHint = false}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _primary, size: 20),
      alignLabelWithHint: alignHint,
      filled: true,
      fillColor: _surface,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Validates the form and returns the assembled body, or null if invalid.
  Map<String, dynamic>? buildBody() {
    setState(() => _submitted = true);
    final formOk = _formKey.currentState?.validate() ?? false;
    final evidOk = _selectedEvidence.isNotEmpty;
    final catOk = _selectedXpCategory != null;
    final weeklyDaysOk = _selectedAwardFrequency != 'Weekly' || _selectedAwardDays.isNotEmpty;

    if (!formOk || !evidOk || !catOk || !weeklyDaysOk) {
      return null;
    }

    final int cap = int.tryParse(_capCtrl.text.trim()) ?? 1;
    final bool capLocked = _selectedAwardFrequency == 'One Time' || _selectedAwardFrequency == 'Manual';
    final bool isEveryPeriod = _selectedAwardFrequency == 'Every Period';

    final payload = {
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'teacherId': '',
      'ownerSubrole': '',
      'evidence': _selectedEvidence.toList(),
      'xp': _awardEnabled ? _awardXpCtrl.text.trim() : '0',
      'type': _selectedType,
      'justification': _justCtrl.text.trim(),
      'xpCategory': _selectedXpCategory,
      'cap': isEveryPeriod ? 8 : (capLocked ? 1 : cap),
      'awardFrequency': _selectedAwardFrequency,
      'awardDays': _selectedAwardFrequency == 'Weekly' ? _selectedAwardDays.toList() : [],
      'displayOrder': int.tryParse(_displayOrderCtrl.text.trim()) ?? 0,
      'status': _selectedStatus,
      'awardXp': _awardEnabled ? (int.tryParse(_awardXpCtrl.text.trim()) ?? 0) : 0,
      'awardEnabled': _awardEnabled,
      'penaltyEnabled': _penaltyEnabled,
      'penaltyXp': _penaltyEnabled ? (int.tryParse(_penaltyXpCtrl.text.trim()) ?? 0) : 0,
      'awardType': _selectedAwardType,
      'xpType': _selectedXpType,
    };
    debugPrint('Award Enabled : ${payload['awardEnabled']}');
    debugPrint('Award XP : ${payload['awardXp']}');
    debugPrint('Penalty Enabled : ${payload['penaltyEnabled']}');
    debugPrint('Penalty XP : ${payload['penaltyXp']}');
    return payload;
  }



  Map<String, dynamic>? buildCcAssignmentBody() {
    setState(() => _submitted = true);
    final hasSections = _filteredSections.isNotEmpty;
    if (_selectedTeacher == null || (hasSections && _selectedSection == null)) {
      return null;
    }
    return {
      'sectionId': _selectedSection?['id'],
      'teacherId': _selectedTeacher['id'],
    };
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (widget.isCc && _isLoadingCcProfile) {
      return const Center(child: CircularProgressIndicator());
    }

    int stepNum = 1;
    final filteredSecs = _filteredSections;
    final hasSections = filteredSecs.isNotEmpty;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          AbsorbPointer(
            absorbing: widget.isCc,
            child: Opacity(
              opacity: widget.isCc ? 0.75 : 1.0,
              child: Column(
                children: [
                  ActivitySection(
                    number: (stepNum++).toString(),
                    title: 'Activity Details',
                    child: _buildDetailsSection(),
                  ),
                  const SizedBox(height: 16),
                  ActivitySection(
                    number: (stepNum++).toString(),
                    title: 'Award Rules',
                    child: _buildAwardRulesSection(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (widget.isCc)
            ActivitySection(
              number: (stepNum++).toString(),
              title: 'Assign Teacher',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.initialData != null && widget.initialData!.assignmentSummary.isNotEmpty) ...[
                    const Text(
                      'Current Assignments:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _dark),
                    ),
                    const SizedBox(height: 6),
                    ...widget.initialData!.assignmentSummary.map((assign) {
                      final secName = assign['section'] as String?;
                      final teachName = assign['teacher'] as String?;
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          secName != null ? 'Section $secName → $teachName' : 'Assigned to → $teachName',
                          style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
                        ),
                      );
                    }),
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                  ],
                  const Text(
                    'New Assignment:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _dark),
                  ),
                  const SizedBox(height: 10),
                  // Teacher search (no department filter needed for CC — all teachers visible)
                  const SizedBox.shrink(),
                  const SizedBox(height: 16),
                  if (hasSections) ...[
                    InputDecorator(
                      decoration: _deco('Section', Icons.class_outlined).copyWith(
                        errorText: (_submitted && _selectedSection == null) ? 'Section is required' : null,
                      ),
                      child: DropdownButton<dynamic>(
                        value: _selectedSection != null
                            ? filteredSecs.firstWhere(
                                (s) => s['id'] == _selectedSection['id'],
                                orElse: () => null,
                              )
                            : null,
                        isExpanded: true,
                        underline: const SizedBox.shrink(),
                        icon: const Icon(Icons.expand_more_rounded, color: _primary),
                        hint: const Text('Select section', style: TextStyle(fontSize: 14)),
                        items: filteredSecs.map((s) {
                          return DropdownMenuItem<dynamic>(
                            value: s,
                            child: Text(s['sectionName'].toString(), style: const TextStyle(fontSize: 14, color: _dark)),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedSection = val),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_selectedTeacher != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.blue.shade100,
                                child: const Icon(Icons.person_rounded, size: 16, color: Colors.blue),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedTeacher['fullName']?.toString() ?? '',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _dark),
                                    ),
                                    Text(
                                      '${_selectedTeacher['username'] ?? ''} • ${_selectedTeacher['departmentName'] ?? ''}',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18, color: Colors.red),
                                onPressed: () => setState(() => _selectedTeacher = null),
                                tooltip: 'Clear selection',
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ),
                      ],
                      TextFormField(
                        controller: _teacherSearchCtrl,
                        style: const TextStyle(color: _dark, fontSize: 14),
                        decoration: _deco('Search Teacher by Name/Dept', Icons.search_rounded).copyWith(
                          suffixIcon: _teacherSearchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _teacherSearchCtrl.clear();
                                    setState(() => _teacherSearchQuery = '');
                                  },
                                )
                              : null,
                        ),
                        onChanged: (val) {
                          setState(() => _teacherSearchQuery = val);
                        },
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 320,
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Builder(
                            builder: (context) {
                              final list = _searchedTeachers;
                              if (list.isEmpty) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'No teachers found',
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _dark),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Try another keyword.',
                                          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              return ListView.separated(
                                padding: const EdgeInsets.all(12),
                                itemCount: list.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 12),
                                itemBuilder: (context, idx) {
                                    final t = list[idx];
                                    final isSelected = _selectedTeacher != null && _selectedTeacher['id'] == t['id'];
                                    final deptName = t['departmentName'] ?? 'No Department';
                                    final uName = t['username'] ?? '';
                                    final fullName = t['fullName'] ?? '';

                                    return Card(
                                      margin: EdgeInsets.zero,
                                      elevation: isSelected ? 2 : 1,
                                      shadowColor: Colors.black.withValues(alpha: 0.08),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        side: BorderSide(
                                          color: isSelected ? Colors.blue : Colors.grey.shade200,
                                          width: isSelected ? 1.5 : 1,
                                        ),
                                      ),
                                      color: isSelected ? Colors.blue.shade50 : Colors.white,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(14),
                                        onTap: () {
                                          setState(() {
                                            _selectedTeacher = t;
                                          });
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 24,
                                                backgroundColor: _primary.withValues(alpha: 0.1),
                                                child: const Icon(
                                                  Icons.person_rounded,
                                                  size: 26,
                                                  color: _primary,
                                                ),
                                              ),
                                              const SizedBox(width: 14),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      fullName,
                                                      style: const TextStyle(
                                                        fontSize: 17,
                                                        fontWeight: FontWeight.w600,
                                                        color: _dark,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      '$uName • $deptName',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey.shade600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              if (isSelected)
                                                const Icon(
                                                  Icons.check_circle_rounded,
                                                  color: Colors.green,
                                                  size: 24,
                                                )
                                              else
                                                Icon(
                                                  Icons.arrow_forward_ios_rounded,
                                                  color: Colors.grey.shade400,
                                                  size: 16,
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                },
                              );
                            }
                          ),
                        ),
                      ),
                      if (_submitted && _selectedTeacher == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 12),
                          child: Text(
                            'Teacher is required',
                            style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          AbsorbPointer(
            absorbing: widget.isCc,
            child: Opacity(
              opacity: widget.isCc ? 0.75 : 1.0,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  ActivitySection(
                    number: (stepNum++).toString(),
                    title: 'Evidence',
                    child: EvidenceSelector(
                      selected: _selectedEvidence,
                      onChanged: (next) => setState(() => _selectedEvidence = next),
                      showError: _submitted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ActivitySection(
                    number: (stepNum++).toString(),
                    title: 'Activity Type',
                    child: TypeSelector(
                      selected: _selectedType,
                      onChanged: (v) => setState(() => _selectedType = v),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ActivitySection(
                    number: (stepNum++).toString(),
                    title: 'Justification',
                    child: _buildJustificationSection(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Column(
      children: [
        TextFormField(
          controller: _nameCtrl,
          style: const TextStyle(color: _dark, fontSize: 15),
          decoration: _deco('Event Name', Icons.title_rounded),
          validator: ActivityValidators.validateName,
        ),
        const SizedBox(height: 16),
        InputDecorator(
          decoration: _deco('XP Category', Icons.category_rounded).copyWith(
            errorText: (_submitted && _selectedXpCategory == null) ? 'XP Category is required' : null,
          ),
          child: DropdownButton<String>(
            dropdownColor: Colors.white,
            value: _selectedXpCategory,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            icon: const Icon(Icons.expand_more_rounded, color: _primary),
            hint: const Text('Select XP Category', style: TextStyle(fontSize: 14)),
            items: _xpCategories.map((c) {
              return DropdownMenuItem<String>(
                value: c,
                child: Text(c, style: const TextStyle(fontSize: 14, color: _dark)),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedXpCategory = val;
              });
            },
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descCtrl,
          maxLines: 3,
          style: const TextStyle(color: _dark, fontSize: 15),
          decoration: _deco('Description', Icons.notes_rounded,
              alignHint: true),
          validator: ActivityValidators.validateDescription,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _displayOrderCtrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: _dark, fontSize: 15),
          decoration: _deco('Display Order', Icons.sort_rounded),
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Display order is required';
            }
            if (int.tryParse(val) == null) {
              return 'Must be a valid integer';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        InputDecorator(
          decoration: _deco('Status', Icons.check_circle_outline_rounded),
          child: DropdownButton<String>(
            dropdownColor: Colors.white,
            value: _selectedStatus,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            icon: const Icon(Icons.expand_more_rounded, color: _primary),
            items: const [
              DropdownMenuItem<String>(value: 'ACTIVE', child: Text('Active', style: TextStyle(fontSize: 14, color: _dark))),
              DropdownMenuItem<String>(value: 'INACTIVE', child: Text('Inactive', style: TextStyle(fontSize: 14, color: _dark))),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedStatus = val);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAwardRulesSection() {
    final bool isOneTimeOrManual = _selectedAwardFrequency == 'One Time' || _selectedAwardFrequency == 'Manual';
    final bool isEveryPeriod = _selectedAwardFrequency == 'Every Period';
    final bool isPerAssignment = _selectedAwardFrequency == 'Per Assignment';
    final bool isCapDisabled = isOneTimeOrManual || isEveryPeriod || isPerAssignment;
    final bool isWeekly = _selectedAwardFrequency == 'Weekly';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── XP Configuration Section Header ──
        const Text(
          'XP Configuration',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _dark),
        ),
        const SizedBox(height: 12),

        // ── Award XP SwitchListTile ──
        SwitchListTile(
          activeThumbColor: _primary,
          title: const Text('Award XP', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: _dark)),
          subtitle: const Text('Award points when student satisfies the activity condition', style: TextStyle(fontSize: 12)),
          value: _awardEnabled,
          onChanged: (val) {
            setState(() {
              _awardEnabled = val;
            });
          },
        ),
        if (_awardEnabled) ...[
          const SizedBox(height: 8),
          TextFormField(
            key: const ValueKey('award_xp_field'),
            controller: _awardXpCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: _dark, fontSize: 15),
            decoration: _deco('Award XP Value', Icons.add_circle_outline_rounded),
            validator: (val) {
              if (!_awardEnabled) return null;
              if (val == null || val.trim().isEmpty) return 'Award XP is required when enabled';
              final parsed = int.tryParse(val);
              if (_penaltyEnabled) {
                if (parsed == null || parsed < 0) return 'Must be a non-negative integer';
              } else {
                if (parsed == null || parsed <= 0) return 'Must be a positive integer greater than zero';
              }
              return null;
            },
          ),
        ],
        const SizedBox(height: 16),

        // ── Penalty XP SwitchListTile ──
        SwitchListTile(
          activeThumbColor: _primary,
          title: const Text('Penalty XP', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: _dark)),
          subtitle: const Text('Deduct points when student violates/fails the activity condition', style: TextStyle(fontSize: 12)),
          value: _penaltyEnabled,
          onChanged: (val) {
            setState(() {
              _penaltyEnabled = val;
            });
          },
        ),
        if (_penaltyEnabled) ...[
          const SizedBox(height: 8),
          TextFormField(
            key: const ValueKey('penalty_xp_field'),
            controller: _penaltyXpCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: _dark, fontSize: 15),
            decoration: _deco('Penalty XP Value', Icons.remove_circle_outline_rounded),
            validator: (val) {
              if (!_penaltyEnabled) return null;
              if (val == null || val.trim().isEmpty) return 'Penalty XP is required when enabled';
              final parsed = int.tryParse(val);
              if (parsed == null || parsed <= 0) return 'Must be a positive integer greater than zero';
              return null;
            },
          ),
        ],

        // ── Global Validation Warning ──
        if (!_awardEnabled && !_penaltyEnabled) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red.shade800),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'At least one toggle (Award XP or Penalty XP) must be enabled.',
                    style: TextStyle(color: Colors.red.shade800, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),

        // ── Award Type ───────────────────────────────────────────────────────
        InputDecorator(
          decoration: _deco('Award Type', Icons.stars_rounded),
          child: DropdownButton<String>(
            dropdownColor: Colors.white,
            value: _selectedAwardType,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            icon: const Icon(Icons.expand_more_rounded, color: _primary),
            items: const [
              DropdownMenuItem<String>(value: 'Fixed XP', child: Text('Fixed XP', style: TextStyle(fontSize: 14, color: _dark))),
              DropdownMenuItem<String>(value: 'Variable XP (future use)', child: Text('Variable XP (future use)', style: TextStyle(fontSize: 14, color: _dark))),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _selectedAwardType = val);
            },
          ),
        ),
        const SizedBox(height: 16),

        // ── Award Frequency ──────────────────────────────────────────────────
        InputDecorator(
          decoration: _deco('Award Frequency', Icons.repeat_rounded),
          child: DropdownButton<String>(
            dropdownColor: Colors.white,
            value: _selectedAwardFrequency,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            icon: const Icon(Icons.expand_more_rounded, color: _primary),
            items: {
              'One Time', 'Daily', 'Weekly', 'Monthly', 'Per Assignment', 'Every Period', 
              ...widget.provider.customFrequencies.map((f) => f['name'] as String),
              'Manual'
            }.toList().map((f) {
              return DropdownMenuItem<String>(
                value: f,
                child: Text(f, style: const TextStyle(fontSize: 14, color: _dark)),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                if (val == 'Manual') {
                  _showCustomFrequencyDialog();
                } else {
                  setState(() {
                    _selectedAwardFrequency = val;
                    final customMatch = widget.provider.customFrequencies.where((f) => f['name'] == val).toList();
                    if (customMatch.isNotEmpty) {
                        final cf = customMatch.first;
                        if (cf['capType'] == 'UNLIMITED') {
                            _capCtrl.text = '1'; // Unlimited bypasses cap on backend anyway
                        } else {
                            _capCtrl.text = cf['defaultCap'].toString();
                        }
                    } else if (val == 'One Time') {
                      _capCtrl.text = '1';
                      _selectedAwardDays = {};
                    } else if (val == 'Per Assignment') {
                      _capCtrl.text = 'Unlimited';
                      _selectedAwardDays = {};
                    } else if (val == 'Weekly' && _selectedAwardDays.isEmpty) {
                      _selectedAwardDays = {'Monday','Tuesday','Wednesday','Thursday','Friday'};
                      if (_capCtrl.text == '1') _capCtrl.text = '5';
                    } else if (val == 'Every Period') {
                      _capCtrl.text = '8';
                      _selectedAwardDays = {};
                    } else {
                      if (_capCtrl.text == '1') _capCtrl.text = '1';
                    }
                  });
                }
              }
            },
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _frequencyHint(_selectedAwardFrequency),
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 16),

        // ── Award Days (Weekly only) ─────────────────────────────────────────
        if (isWeekly) ...[
          Container(
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: (_submitted && _selectedAwardDays.isEmpty) ? Colors.red : Colors.grey.shade300,
                width: (_submitted && _selectedAwardDays.isEmpty) ? 2 : 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, color: _primary, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'Award Days',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _dark),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => setState(() => _selectedAwardDays = Set.from(_workingDays)),
                      child: const Text('All', style: TextStyle(fontSize: 12)),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _selectedAwardDays = {}),
                      child: const Text('None', style: TextStyle(fontSize: 12, color: Colors.red)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _workingDays.map((day) {
                    final selected = _selectedAwardDays.contains(day);
                    return FilterChip(
                      label: Text(day.substring(0, 3), style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : _dark,
                      )),
                      selected: selected,
                      selectedColor: _primary,
                      checkmarkColor: Colors.white,
                      backgroundColor: Colors.grey.shade100,
                      onSelected: (val) => setState(() {
                        if (val) {
                          _selectedAwardDays.add(day);
                        } else {
                          _selectedAwardDays.remove(day);
                        }
                      }),
                    );
                  }).toList(),
                ),
                if (_submitted && _selectedAwardDays.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'At least one Award Day is required for Weekly frequency.',
                      style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ── Cap ──────────────────────────────────────────────────────────────
        // ── Cap ──────────────────────────────────────────────────────────────
        AbsorbPointer(
          absorbing: isCapDisabled,
          child: Opacity(
            opacity: isCapDisabled ? 0.5 : 1.0,
            child: TextFormField(
              controller: _capCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: _dark, fontSize: 15),
              decoration: _deco(
                isEveryPeriod
                    ? 'Cap (fixed at 8)'
                    : (isPerAssignment ? 'Cap (Unlimited)' : (isOneTimeOrManual ? 'Cap (fixed at 1)' : 'Cap (max awards per frequency window)')),
                Icons.bar_chart_rounded,
              ),
              validator: (val) {
                if (isCapDisabled) return null;
                if (val == null || val.trim().isEmpty) return 'Cap is required';
                final parsed = int.tryParse(val);
                if (parsed == null || parsed <= 0) return 'Must be an integer greater than zero';
                return null;
              },
            ),
          ),
        ),
      ],
    );
  }

  String _frequencyHint(String freq) {
    switch (freq) {
      case 'One Time':     return 'XP is awarded only once to the student. No repetition allowed.';
      case 'Daily':        return 'XP can be awarded once per day (resets at midnight).';
      case 'Weekly':       return 'XP can be awarded on selected days. Cap resets every Monday.';
      case 'Monthly':      return 'Cap resets at the start of each calendar month.';
      case 'Per Assignment':return 'XP is awarded for every assignment submission. No cap limit.';
      case 'Every Period': return 'XP can be awarded or penalized up to 8 times per day for each student.';
      case 'Manual':       return 'XP is awarded manually by admin reset. Cap is fixed at 1.';
      default:             return '';
    }
  }

  Widget _buildJustificationSection() {
    return TextFormField(
      controller: _justCtrl,
      maxLines: 5,
      style: const TextStyle(color: _dark, fontSize: 15),
      decoration: _deco(
        'Enter manual justification here…',
        Icons.edit_note_rounded,
        alignHint: true,
      ),
      validator: ActivityValidators.validateJustification,
    );
  }
}