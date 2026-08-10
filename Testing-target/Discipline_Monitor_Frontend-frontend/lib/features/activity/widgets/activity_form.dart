import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/activity/widgets/activity_basic_information_section.dart';
import 'package:pragatix/features/activity/widgets/activity_xp_section.dart';
import 'package:pragatix/features/activity/widgets/activity_frequency_section.dart';
import 'package:pragatix/features/activity/widgets/activity_owner_section.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:pragatix/features/activity/services/activity_proxy_service.dart';
import 'package:pragatix/core/config/api_config.dart';
import 'package:pragatix/features/activity/models/activity_model.dart';
import 'package:pragatix/features/activity/providers/activity_provider.dart';
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
  final _manualEvidenceNameCtrl = TextEditingController();
  bool _awardEnabled = true;
  bool _penaltyEnabled = false;
  final _awardXpCtrl = TextEditingController(text: '0');
  final _penaltyXpCtrl = TextEditingController(text: '0');
  String _selectedStatus = 'ACTIVE';
  bool _allowStudentRequest = false;
  bool _streakEnabled = false;
  String? _selectedSubgroup;

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
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
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
        headers: {
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final profile = data['data'];
          setState(() {
            _ccYear = profile['year']?.toString();
            _ccDeptId = profile['departmentId'] != null
                ? (profile['departmentId'] as num).toInt()
                : null;
            _ccDeptName = profile['departmentName']?.toString();
            _ccSection = profile['section']?.toString();

            // Auto-select the CC's own section if it matches!
            if (_ccSection != null && _ccSection!.isNotEmpty) {
              try {
                _selectedSection = _filteredSections.firstWhere(
                  (s) =>
                      s['sectionName']?.toString().toLowerCase() ==
                      _ccSection!.toLowerCase(),
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
              title: const Text(
                'New Custom Frequency',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Frequency Name (e.g. Assignment)',
                    ),
                    onChanged: (val) => name = val,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Radio<String>(
                        value: 'UNLIMITED',
                        groupValue: capType,
                        onChanged: (val) =>
                            setStateDialog(() => capType = val!),
                      ),
                      const Text('Unlimited'),
                      Radio<String>(
                        value: 'MANUAL_CAP',
                        groupValue: capType,
                        onChanged: (val) =>
                            setStateDialog(() => capType = val!),
                      ),
                      const Text('Manual Cap'),
                    ],
                  ),
                  if (capType == 'MANUAL_CAP')
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Maximum Count',
                      ),
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
                      if (!mounted) return;
                      Navigator.pop(ctx, res);
                    } else {
                      if (!mounted) return;
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text(
                            widget.provider.error ?? 'Error creating frequency',
                          ),
                        ),
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
      _allowStudentRequest = d.allowStudentRequest;
      _streakEnabled = d.streakEnabled;
      _awardXpCtrl.text = d.awardXp.toString();
      _penaltyXpCtrl.text = d.penaltyXp.toString();
      _selectedAwardType = d.awardType.isNotEmpty ? d.awardType : 'Fixed XP';
      _selectedAwardFrequency = d.awardFrequency.isNotEmpty
          ? d.awardFrequency
          : 'One Time';
      _selectedAwardDays = Set<String>.from(d.awardDays);
      _selectedType = d.type.isNotEmpty ? d.type : 'Individual';
      _selectedEvidence = Set<String>.from(d.evidence);
      _manualEvidenceNameCtrl.text = d.manualEvidenceName ?? '';
      _selectedXpCategory = _normalizeXpCategory(d.xpCategory);
      _selectedSubgroup = d.subgroup;

      if (widget.isCc && d.assignmentSummary.isNotEmpty) {
        final assign = d.assignmentSummary.first;
        final tId = assign['teacherId'];
        if (tId != null) {
          if (tId == 0 || tId.toString() == '0') {
            _selectedTeacher = {
              'id': 0,
              'fullName': 'Any Faculty',
              'username': 'any',
              'departmentName': 'Global',
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
    _manualEvidenceNameCtrl.dispose();
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
      'departmentName': 'Global',
    };
    if (_teacherSearchQuery.trim().isEmpty) {
      return [virtualAny, ...widget.allTeachers];
    }
    final query = _teacherSearchQuery.toLowerCase();
    final matchesVirtual =
        'any faculty'.contains(query) ||
        'any'.contains(query) ||
        'global'.contains(query);
    final filtered = widget.allTeachers.where((t) {
      final name = (t['fullName'] as String? ?? '').toLowerCase();
      final username = (t['username'] as String? ?? '').toLowerCase();
      final dept = (t['departmentName'] as String? ?? '').toLowerCase();
      return name.contains(query) ||
          username.contains(query) ||
          dept.contains(query);
    }).toList();
    return matchesVirtual ? [virtualAny, ...filtered] : filtered;
  }

  List<dynamic> get _filteredSections {
    if (widget.isCc) {
      return widget.sections.where((s) {
        final sName = s['sectionName']?.toString().trim().toLowerCase() ?? '';
        final sDeptId = s['departmentId'];

        final targetSection = _ccSection?.trim().toLowerCase() ?? '';
        final targetDeptId = _ccDeptId;

        final bool sectionMatches =
            targetSection.isEmpty || sName == targetSection;
        final bool deptMatches =
            targetDeptId == null || sDeptId == targetDeptId;

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
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
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
              backgroundColor: isAssigned
                  ? Colors.blue.shade50
                  : Colors.grey.shade100,
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
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      );
    }).toList();
  }

  InputDecoration _deco(String label, IconData icon, {bool alignHint = false}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _primary, size: 20),
      alignLabelWithHint: alignHint,
      filled: true,
      fillColor: _surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
    final weeklyDaysOk =
        _selectedAwardFrequency != 'Weekly' || _selectedAwardDays.isNotEmpty;

    final authProvider = context.read<AuthProvider>();
    final roles = authProvider.currentUser?['roles'] as List<dynamic>? ?? [];
    final isSuperAdmin = roles.contains('ROLE_SUPER_ADMIN');

    if (!formOk || !evidOk || !catOk || !weeklyDaysOk) {
      return null;
    }

    if (_selectedEvidence.contains('Manual') && _manualEvidenceNameCtrl.text.trim().isEmpty) {
      return null;
    }

    final int cap = int.tryParse(_capCtrl.text.trim()) ?? 1;
    final bool capLocked =
        _selectedAwardFrequency == 'One Time' ||
        _selectedAwardFrequency == 'Manual';
    final bool isEveryPeriod = _selectedAwardFrequency == 'Every Period';

    String computedXpType = 'Reward';
    if (_awardEnabled && _penaltyEnabled) {
      computedXpType = 'Mixed';
    } else if (_penaltyEnabled && !_awardEnabled) {
      computedXpType = 'Penalty';
    } else {
      computedXpType = 'Reward';
    }

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
      'awardDays': _selectedAwardFrequency == 'Weekly'
          ? _selectedAwardDays.toList()
          : [],
      'displayOrder': int.tryParse(_displayOrderCtrl.text.trim()) ?? 0,
      'status': _selectedStatus,
      'awardXp': _awardEnabled
          ? (int.tryParse(_awardXpCtrl.text.trim()) ?? 0)
          : 0,
      'awardEnabled': _awardEnabled,
      'penaltyEnabled': _penaltyEnabled,
      'penaltyXp': _penaltyEnabled
          ? (int.tryParse(_penaltyXpCtrl.text.trim()) ?? 0)
          : 0,
      'awardType': _selectedAwardType,
      'xpType': computedXpType,
      'allowStudentRequest': _allowStudentRequest,
      'subgroup': _selectedSubgroup,
      'manualEvidenceName': _manualEvidenceNameCtrl.text.trim(),
      'attendanceEngineEnabled': widget.initialData?.attendanceEngineEnabled ?? false,
      'attendanceRule': widget.initialData?.attendanceRule,
      'streakEnabled': _streakEnabled,
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
    _selectedSection = null;

    if (widget.initialData != null) {}
    if (_selectedTeacher == null || (hasSections && _selectedSection == null)) {
      return null;
    }
    return {
      'sectionId': _selectedSection?['id'],
      'teacherId': _selectedTeacher['id'],
    };
  }

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
                    child: ActivityBasicInformationSection(
                      nameCtrl: _nameCtrl,
                      descCtrl: _descCtrl,
                      displayOrderCtrl: _displayOrderCtrl,
                      selectedXpCategory: _selectedXpCategory,
                      selectedStatus: _selectedStatus,
                      submitted: _submitted,
                      onXpCategoryChanged: (val) {
                        setState(() {
                          _selectedXpCategory = val;
                        });
                      },
                      onStatusChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedStatus = val);
                        }
                      },
                      isEdit: widget.initialData != null,
                      selectedSubgroup: _selectedSubgroup,
                      onSubgroupChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedSubgroup = val);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!(widget.initialData?.attendanceEngineEnabled == true)) ...[
                    ActivitySection(
                      number: (stepNum++).toString(),
                      title: 'Award Rules',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ActivityXpSection(
                            awardEnabled: _awardEnabled,
                            penaltyEnabled: _penaltyEnabled,
                            awardXpCtrl: _awardXpCtrl,
                            penaltyXpCtrl: _penaltyXpCtrl,
                            selectedAwardType: _selectedAwardType,
                            onAwardEnabledChanged: (val) {
                              setState(() => _awardEnabled = val);
                            },
                            onPenaltyEnabledChanged: (val) {
                              setState(() => _penaltyEnabled = val);
                            },
                            onAwardTypeChanged: (val) {
                              if (val != null)
                                setState(() => _selectedAwardType = val);
                            },
                          ),
                          const SizedBox(height: 16),
                          ActivityFrequencySection(
                            selectedAwardFrequency: _selectedAwardFrequency,
                            selectedAwardDays: _selectedAwardDays,
                            capCtrl: _capCtrl,
                            submitted: _submitted,
                            onFrequencyChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedAwardFrequency = val;
                                  if (val == 'One Time') {
                                    _capCtrl.text = '1';
                                    _selectedAwardDays = {};
                                  } else if (val == 'Per Assignment') {
                                    _capCtrl.text = 'Unlimited';
                                    _selectedAwardDays = {};
                                  } else if (val == 'Weekly' &&
                                      _selectedAwardDays.isEmpty) {
                                    _selectedAwardDays = {
                                      'Monday',
                                      'Tuesday',
                                      'Wednesday',
                                      'Thursday',
                                      'Friday',
                                    };
                                    if (_capCtrl.text == '1') _capCtrl.text = '5';
                                  } else if (val == 'Every Period') {
                                    _capCtrl.text = '8';
                                    _selectedAwardDays = {};
                                  } else if (val == 'Week 1 (Once)' || val == 'Week 2 (Once)') {
                                    _capCtrl.text = '1';
                                    _selectedAwardDays = {};
                                  } else {
                                    if (_capCtrl.text == '1') _capCtrl.text = '1';
                                  }
                                });
                              }
                            },
                            onDaysChanged: (val) {
                              setState(() => _selectedAwardDays = val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ActivitySection(
                      number: (stepNum++).toString(),
                      title: 'Evidence',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          EvidenceSelector(
                            selected: _selectedEvidence,
                            onChanged: (next) =>
                                setState(() => _selectedEvidence = next),
                            showError: _submitted,
                          ),
                          if (_selectedEvidence.contains('Manual')) ...[
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _manualEvidenceNameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Evidence Name',
                                hintText: 'e.g. Attendance Register, Physical Verification',
                                prefixIcon: Icon(Icons.edit_note, color: _primary, size: 20),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(10)),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Please enter a custom evidence name.';
                                }
                                return null;
                              },
                            ),
                          ]
                        ],
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
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: SwitchListTile(
                        title: const Text(
                          'Allow Student Request',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: const Text(
                          'Students can submit a completion request for this activity.',
                          style: TextStyle(color: Colors.grey),
                        ),
                        value: _allowStudentRequest,
                        activeColor: _primary,
                        onChanged: (val) =>
                            setState(() => _allowStudentRequest = val),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: SwitchListTile(
                        title: const Text(
                          'Enable Streak',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: const Text(
                          'Track consecutive streaks for this activity automatically.',
                          style: TextStyle(color: Colors.grey),
                        ),
                        value: _streakEnabled,
                        activeColor: _primary,
                        onChanged: (val) =>
                            setState(() => _streakEnabled = val),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    ActivitySection(
                      number: (stepNum++).toString(),
                      title: 'Award Rules',
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.blue.shade700),
                                const SizedBox(width: 8),
                                const Text(
                                  'Attendance Engine Activity',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'This activity is managed automatically by the Attendance Engine.\nXP Rules:\n• Partial Day Penalty\n• Full Day Penalty\n• Weekly Reward\nare configured from Attendance Settings.',
                              style: TextStyle(height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ActivitySection(
                      number: (stepNum++).toString(),
                      title: 'Evidence',
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.verified_user_outlined, color: Colors.blue.shade700),
                                const SizedBox(width: 8),
                                const Text(
                                  'Evidence',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'This activity is evaluated automatically using Attendance Records.\nNo manual evidence is required.\n\nEvidence Source:\n• Daily Attendance Records\n• Attendance Sessions\n• Attendance Engine',
                              style: TextStyle(height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  ActivitySection(
                    number: (stepNum++).toString(),
                    title: 'Justification (Optional)',
                    child: TextFormField(
                      controller: _justCtrl,
                      maxLines: 3,
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Justification (Optional)',
                        prefixIcon: const Icon(
                          Icons.notes_rounded,
                          color: Color(0xFFEA4335),
                          size: 20,
                        ),
                        alignLabelWithHint: true,
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
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
                          borderSide: const BorderSide(
                            color: Color(0xFFEA4335),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
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
              child: ActivityOwnerSection(
                selectedSection: _selectedSection,
                selectedTeacher: _selectedTeacher,
                teacherSearchCtrl: _teacherSearchCtrl,
                teacherSearchQuery: _teacherSearchQuery,
                filteredSections: filteredSecs,
                searchedTeachers: _searchedTeachers,
                hasSections: hasSections,
                submitted: _submitted,
                initialData: widget.initialData,
                onSectionChanged: (val) =>
                    setState(() => _selectedSection = val),
                onTeacherChanged: (val) =>
                    setState(() => _selectedTeacher = val),
                onTeacherSearchQueryChanged: (val) =>
                    setState(() => _teacherSearchQuery = val),
                onClearTeacher: () => setState(() => _selectedTeacher = null),
              ),
            ),
        ],
      ),
    );
  }
}
