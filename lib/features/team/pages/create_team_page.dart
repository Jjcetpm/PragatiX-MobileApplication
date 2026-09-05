import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/core/config/api_config.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/core/utils/error_handler.dart';
import 'package:pragatix/core/widgets/pragatix_loader.dart';
import 'package:pragatix/features/admin/repository/admin_repository.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/features/team/services/team_proxy_service.dart';
import 'package:pragatix/shared/widgets/student_search/student_search_field.dart';

class CreateTeamPage extends StatefulWidget {
  final String? initialYear;
  final int? initialDeptId;
  final int? initialSectionId;

  const CreateTeamPage({
    super.key,
    this.initialYear,
    this.initialDeptId,
    this.initialSectionId,
  });

  @override
  State<CreateTeamPage> createState() => _CreateTeamPageState();
}

class _CreateTeamPageState extends State<CreateTeamPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _limitController = TextEditingController(text: '5');

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isLoadingSections = false;

  // Lookups
  List<dynamic> _assignedYears = [];
  List<dynamic> _departments = [];
  List<dynamic> _sections = [];

  // Form State
  String? _selectedYear;
  int? _selectedDeptId;
  int? _selectedSectionId;
  Map<String, dynamic>? _selectedCaptain;

  // Role booleans
  bool _isSuperAdmin = false;
  bool _isAdmin = false;
  bool _isCC = false;
  bool _isHOD = false;

  @override
  void initState() {
    super.initState();
    _loadLookups();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  String _resolveYearDisplay(String rawYear, List<dynamic> yearsList) {
    final clean = rawYear.trim();
    for (var y in yearsList) {
      final yName = (y is Map ? (y['yearName'] ?? y['name'] ?? '') : y).toString().trim();
      if (yName.isEmpty) continue;
      if (yName.toLowerCase() == clean.toLowerCase()) return yName;
      if ((clean == '1' || clean.toUpperCase().contains('FIRST') || clean.toUpperCase().contains('1ST')) &&
          yName.toLowerCase().contains('first')) {
        return yName;
      }
      if ((clean == '2' || clean.toUpperCase().contains('SECOND') || clean.toUpperCase().contains('2ND')) &&
          yName.toLowerCase().contains('second')) {
        return yName;
      }
      if ((clean == '3' || clean.toUpperCase().contains('THIRD') || clean.toUpperCase().contains('3RD')) &&
          yName.toLowerCase().contains('third')) {
        return yName;
      }
      if ((clean == '4' || clean.toUpperCase().contains('FOURTH') || clean.toUpperCase().contains('4TH')) &&
          yName.toLowerCase().contains('fourth')) {
        return yName;
      }
    }
    return clean;
  }

  String get _resolvedDeptDisplayName {
    if (_selectedDeptId != null && _departments.isNotEmpty) {
      final match = _departments.where((d) => d['id'] == _selectedDeptId).toList();
      if (match.isNotEmpty) {
        final m = match.first;
        return m['deptCode'] != null
            ? '${m['deptCode']} - ${m['name']}'
            : (m['name'] ?? m['deptName'] ?? 'Department');
      }
    }
    final auth = context.read<AuthProvider>();
    final currentUser = auth.currentUser;
    if (currentUser?['department'] is String) return currentUser!['department'] as String;
    if (currentUser?['department'] is Map) {
      final dMap = currentUser!['department'] as Map;
      return (dMap['name'] ?? dMap['deptName'])?.toString() ?? 'Department';
    }
    return currentUser?['departmentName']?.toString() ?? 'Assigned Department';
  }

  String get _resolvedSecDisplayName {
    if (_selectedSectionId != null && _sections.isNotEmpty) {
      final match = _sections.where((s) => s['id'] == _selectedSectionId).toList();
      if (match.isNotEmpty) {
        final m = match.first;
        final name = m['sectionName'] ?? m['name'] ?? '';
        return name.toString().toUpperCase().startsWith('SECTION') ? name.toString() : 'Section $name';
      }
    }
    final auth = context.read<AuthProvider>();
    final currentUser = auth.currentUser;
    String? name;
    if (currentUser?['section'] is String) name = currentUser!['section'] as String;
    if (currentUser?['section'] is Map) {
      final sMap = currentUser!['section'] as Map;
      name = (sMap['sectionName'] ?? sMap['name'])?.toString();
    }
    name ??= currentUser?['sectionName']?.toString() ?? currentUser?['ccDetails']?['section']?.toString();
    if (name != null && name.isNotEmpty) {
      return name.toUpperCase().startsWith('SECTION') ? name : 'Section $name';
    }
    return 'Assigned Section';
  }

  Future<void> _loadLookups() async {
    final auth = context.read<AuthProvider>();
    final currentUser = auth.currentUser;
    final role = auth.role ?? '';
    final subroles = (currentUser?['subRoles'] as List<dynamic>? ?? [])
        .map((e) => (e is Map ? (e['name'] ?? '') : e.toString()).trim().toUpperCase())
        .toList();
    final roles = (currentUser?['roles'] as List<dynamic>? ?? [])
        .map((e) => (e is Map ? (e['name'] ?? '') : e.toString()).trim().toUpperCase())
        .toList();

    _isSuperAdmin = auth.isSuperAdmin ||
        roles.contains('ROLE_SUPER_ADMIN') ||
        roles.contains('ROLE_SUPERADMIN') ||
        roles.contains('SUPER_ADMIN');
    _isAdmin = !_isSuperAdmin &&
        (role == 'ROLE_ADMIN' ||
            role == 'ADMIN' ||
            roles.contains('ROLE_ADMIN') ||
            roles.contains('ADMIN'));
    _isCC = subroles.contains('CC') ||
        subroles.contains('CLASS_COORDINATOR') ||
        subroles.contains('ROLE_CLASS_COORDINATOR') ||
        subroles.contains('ROLE_CC');
    _isHOD = subroles.contains('HOD') ||
        subroles.contains('ROLE_HOD') ||
        roles.contains('ROLE_HOD') ||
        roles.contains('HOD');

    try {
      final repo = getIt<AdminRepository>();
      final results = await Future.wait([
        repo.getAssignedYears(),
        repo.getDepartments(type: 'MAIN'),
      ]);

      _assignedYears = results[0];
      final allDepts = results[1];

      // Filter 9 main departments only
      _departments = allDepts.where((d) {
        final type = (d['departmentType'] ?? d['type'] ?? '').toString().toUpperCase();
        final name = (d['name'] ?? d['deptName'] ?? '').toString();
        if (type == 'SUB') return false;
        if (name.toLowerCase().startsWith('department of')) return false;
        return true;
      }).toList();

      // 1. Year Resolution
      if (_isSuperAdmin) {
        // Super Admin selects Year manually via dropdown.
        // Pre-fill with widget.initialYear or auth.selectedAcademicYear if provided
        if (widget.initialYear != null && widget.initialYear!.isNotEmpty && widget.initialYear != 'All') {
          _selectedYear = _resolveYearDisplay(widget.initialYear!, _assignedYears);
        } else if (auth.selectedAcademicYear != null &&
            auth.selectedAcademicYear!.isNotEmpty &&
            auth.selectedAcademicYear != 'All') {
          _selectedYear = _resolveYearDisplay(auth.selectedAcademicYear!, _assignedYears);
        }
      } else if (_isAdmin) {
        // Admin: Year is automatically selected and fixed/locked
        String? adminYear = widget.initialYear;
        if (adminYear == null || adminYear.isEmpty || adminYear == 'All') {
          adminYear = currentUser?['academicYear']?.toString() ??
              currentUser?['adminDetails']?['academicYear']?.toString() ??
              currentUser?['year']?.toString() ??
              currentUser?['assignedYearName']?.toString();
        }
        if (adminYear != null && adminYear.isNotEmpty && adminYear != 'All') {
          _selectedYear = _resolveYearDisplay(adminYear, _assignedYears);
        } else if (_assignedYears.isNotEmpty) {
          final first = _assignedYears.first;
          _selectedYear = (first is Map ? (first['yearName'] ?? first['name']) : first).toString();
        }
      } else if (_isCC) {
        // CC: Year is automatically picked from CC credentials and locked
        String? ccYear = widget.initialYear;
        if (ccYear == null || ccYear.isEmpty || ccYear == 'All') {
          ccYear = currentUser?['academicYear']?.toString() ??
              currentUser?['year']?.toString() ??
              currentUser?['ccDetails']?['academicYear']?.toString() ??
              auth.selectedAcademicYear;
        }
        if (ccYear != null && ccYear.isNotEmpty && ccYear != 'All') {
          _selectedYear = _resolveYearDisplay(ccYear, _assignedYears);
        } else if (_assignedYears.isNotEmpty) {
          final first = _assignedYears.first;
          _selectedYear = (first is Map ? (first['yearName'] ?? first['name']) : first).toString();
        }
      }

      // 2. Department Resolution
      if (_isCC || _isHOD) {
        // CC / HOD: Department is automatically resolved and locked
        int? deptId = widget.initialDeptId;
        if (deptId == null) {
          if (currentUser?['departmentId'] != null) {
            deptId = int.tryParse(currentUser!['departmentId'].toString());
          } else if (currentUser?['department'] is Map && (currentUser!['department'] as Map)['id'] != null) {
            deptId = int.tryParse((currentUser['department'] as Map)['id'].toString());
          }
        }

        String? deptName;
        if (currentUser?['department'] is String) {
          deptName = currentUser!['department'] as String;
        } else if (currentUser?['department'] is Map) {
          final deptMap = currentUser!['department'] as Map;
          deptName = (deptMap['name'] ?? deptMap['deptName'])?.toString();
        }
        deptName ??= currentUser?['departmentName']?.toString() ?? currentUser?['deptName']?.toString();

        if (deptId != null) {
          _selectedDeptId = deptId;
        } else if (deptName != null && _departments.isNotEmpty) {
          final match = _departments.where((d) {
            final dName = (d['name'] ?? d['deptName'] ?? '').toString().toLowerCase();
            final dCode = (d['deptCode'] ?? d['code'] ?? '').toString().toLowerCase();
            final target = deptName!.toLowerCase();
            return dName == target || dCode == target || target.contains(dName) || dName.contains(target);
          }).toList();
          if (match.isNotEmpty) {
            _selectedDeptId = match.first['id'] as int?;
          }
        }
      } else {
        // Super Admin & Admin: Manual Department selection (pre-fill from initialDeptId if passed)
        if (widget.initialDeptId != null) {
          _selectedDeptId = widget.initialDeptId;
        }
      }

      // 3. Fetch Sections for selected department
      if (_selectedDeptId != null) {
        try {
          final secs = await repo.getFilterSections(
            year: _selectedYear,
            departmentId: _selectedDeptId,
          );
          _sections = secs;
        } catch (_) {
          _sections = [];
        }
      }

      // 4. Section Resolution
      if (_isCC) {
        // CC: Section is automatically resolved and locked
        int? secId = widget.initialSectionId;
        if (secId == null) {
          if (currentUser?['sectionId'] != null) {
            secId = int.tryParse(currentUser!['sectionId'].toString());
          } else if (currentUser?['section'] is Map && (currentUser!['section'] as Map)['id'] != null) {
            secId = int.tryParse((currentUser['section'] as Map)['id'].toString());
          }
        }

        String? secName;
        if (currentUser?['section'] is String) {
          secName = currentUser!['section'] as String;
        } else if (currentUser?['section'] is Map) {
          final secMap = currentUser!['section'] as Map;
          secName = (secMap['sectionName'] ?? secMap['name'])?.toString();
        }
        secName ??= currentUser?['sectionName']?.toString() ?? currentUser?['ccDetails']?['section']?.toString();

        if (secId != null) {
          _selectedSectionId = secId;
        } else if (secName != null && _sections.isNotEmpty) {
          final cleanSec = secName.trim().toUpperCase().replaceAll('SECTION', '').trim();
          final match = _sections.where((s) {
            final sName = (s['sectionName'] ?? s['name'] ?? '').toString().trim().toUpperCase().replaceAll('SECTION', '').trim();
            return sName == cleanSec;
          }).toList();
          if (match.isNotEmpty) {
            _selectedSectionId = match.first['id'] as int?;
          }
        }
      } else {
        if (widget.initialSectionId != null) {
          _selectedSectionId = widget.initialSectionId;
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading create team lookups: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchSections(int deptId) async {
    setState(() {
      _isLoadingSections = true;
      if (!_isCC) {
        _selectedSectionId = null;
      }
      _sections = [];
    });

    try {
      final secs = await getIt<AdminRepository>().getFilterSections(
        year: _selectedYear,
        departmentId: deptId,
      );
      if (mounted) {
        setState(() {
          _sections = secs;
          _isLoadingSections = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _sections = [];
          _isLoadingSections = false;
        });
      }
    }
  }

  Future<void> _submitCreateTeam() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCaptain == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a Team Captain.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    if (_selectedYear == null || _selectedYear!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a Year for the team.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    if (_selectedDeptId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a Department for the team.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final name = _nameController.text.trim();
      final limit = int.tryParse(_limitController.text.trim()) ?? 5;
      final captainRegNo = _selectedCaptain!['regNo']?.toString() ?? '';

      final body = jsonEncode({
        'name': name,
        'size': limit,
        'captainStudentId': captainRegNo,
        if (_selectedDeptId != null) 'departmentId': _selectedDeptId,
        if (_selectedYear != null && _selectedYear!.isNotEmpty) 'academicYear': _selectedYear!.trim(),
        if (_selectedSectionId != null) 'sectionId': _selectedSectionId,
      });

      final auth = context.read<AuthProvider>();
      final response = await getIt<TeamProxyService>().post(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/teams'),
        headers: {
          'Authorization': 'Bearer ${auth.token!}',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      final data = json.decode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Team created successfully!'),
              backgroundColor: Color(0xFF16A34A),
            ),
          );
          Navigator.pop(context, true);
        } else {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Failed to create team'),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      } else {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? data['error'] ?? 'Failed to create team'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ErrorHandler.showSnackBar(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: const Color(0xFFE2E8F0),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Create New Team',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Configure team class, capacity, and captain',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: PragatiXLoader())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Class & Academic Hierarchy
                    _buildSectionHeader(
                      icon: Icons.account_tree_outlined,
                      title: 'Class Hierarchy',
                      subtitle: _isCC
                          ? 'Assigned class details for your team'
                          : 'Select the Year and Department for this team',
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF64748B).withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_isCC) ...[
                            // CC: Auto-populated and locked Class Hierarchy (no manual selection)
                            _buildLockedInfoTile(
                              label: 'Year',
                              icon: Icons.calendar_today_rounded,
                              value: _selectedYear ?? 'Assigned Year',
                              badgeText: 'Assigned',
                            ),
                            const SizedBox(height: 12),
                            _buildLockedInfoTile(
                              label: 'Department',
                              icon: Icons.school_rounded,
                              value: _resolvedDeptDisplayName,
                              badgeText: 'Assigned',
                            ),
                            const SizedBox(height: 12),
                            _buildLockedInfoTile(
                              label: 'Section',
                              icon: Icons.meeting_room_rounded,
                              value: _resolvedSecDisplayName,
                              badgeText: 'Assigned',
                            ),
                          ] else ...[
                            // Super Admin & Admin Class Hierarchy:
                            // 1. Year Field
                            _buildFieldLabel('Year', isRequired: true),
                            const SizedBox(height: 6),
                            if (_isAdmin && !_isSuperAdmin) ...[
                              // Admin: Year is automatically selected and fixed/locked
                              _buildLockedYearTile(),
                            ] else ...[
                              // Super Admin: Year is manually selected via dropdown
                              _buildYearDropdown(),
                            ],
                            const SizedBox(height: 16),

                            // 2. Department Field
                            if (!_isHOD) ...[
                              _buildFieldLabel('Department', isRequired: true),
                              const SizedBox(height: 6),
                              _buildDepartmentDropdown(),
                              const SizedBox(height: 16),
                            ],

                            // 3. Section Field
                            _buildFieldLabel('Section', isRequired: false),
                            const SizedBox(height: 6),
                            _buildSectionDropdown(),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section 2: Team Details
                    _buildSectionHeader(
                      icon: Icons.groups_rounded,
                      title: 'Team Details',
                      subtitle: 'Set team name and member capacity',
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF64748B).withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Team Name', isRequired: true),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _nameController,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'e.g. Alpha Warriors, Team Titans',
                              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                              prefixIcon: const Icon(Icons.shield_outlined, color: Color(0xFF2563EB), size: 20),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.8),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Team name is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          _buildFieldLabel('Team Capacity Limit', isRequired: true),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _limitController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'e.g. 5 or 10',
                              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                              prefixIcon: const Icon(Icons.people_alt_outlined, color: Color(0xFF2563EB), size: 20),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.8),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Team capacity is required';
                              }
                              final count = int.tryParse(val.trim());
                              if (count == null || count < 1) {
                                return 'Capacity must be at least 1';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section 3: Team Captain
                    _buildSectionHeader(
                      icon: Icons.military_tech_rounded,
                      title: 'Leadership',
                      subtitle: 'Search and assign the Team Captain',
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF64748B).withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Team Captain', isRequired: true),
                          const SizedBox(height: 6),
                          Builder(
                            builder: (context) {
                              final bool isClassConfigured = _selectedYear != null &&
                                  _selectedYear!.isNotEmpty &&
                                  _selectedDeptId != null;

                              return StudentSearchField(
                                selectedStudent: _selectedCaptain,
                                unassignedOnly: true,
                                year: _selectedYear,
                                departmentId: _selectedDeptId,
                                departmentName: _resolvedDeptDisplayName,
                                sectionId: _selectedSectionId,
                                sectionName: _resolvedSecDisplayName,
                                enabled: isClassConfigured,
                                labelText: 'Search Captain',
                                onDisabledTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(_selectedYear == null || _selectedYear!.isEmpty
                                          ? 'Please select Year first before picking a Captain.'
                                          : 'Please select Department first before picking a Captain.'),
                                      backgroundColor: const Color(0xFFEF4444),
                                    ),
                                  );
                                },
                                onStudentSelected: (student) {
                                  setState(() {
                                    _selectedCaptain = student;
                                  });
                                },
                              );
                            },
                          ),
                          if (_selectedCaptain != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFBFDBFE)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2563EB),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.star_rounded, color: Colors.white, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _selectedCaptain!['fullName'] ?? 'Captain',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: Color(0xFF1E3A8A),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Reg No: ${_selectedCaptain!['regNo'] ?? 'N/A'} • ${_selectedCaptain!['department'] ?? ''}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF3B82F6),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF64748B)),
                                    onPressed: () {
                                      setState(() {
                                        _selectedCaptain = null;
                                      });
                                    },
                                    tooltip: 'Remove Captain',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitCreateTeam,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFF93C5FD),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSubmitting
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Creating Team...',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ],
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_circle_outline_rounded, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Create Team',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLockedInfoTile({
    required String label,
    required IconData icon,
    required String value,
    required String badgeText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label, isRequired: true),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF2563EB)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E7FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_rounded, size: 12, color: Color(0xFF3730A3)),
                    const SizedBox(width: 4),
                    Text(
                      badgeText,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3730A3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLockedYearTile() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF2563EB)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _selectedYear ?? 'Assigned Year',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
                fontSize: 14,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE0E7FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_rounded, size: 12, color: Color(0xFF3730A3)),
                SizedBox(width: 4),
                Text(
                  'Assigned',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3730A3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedYear,
          hint: const Text('Select Year', style: TextStyle(fontSize: 13.5, color: Color(0xFF94A3B8))),
          items: _assignedYears.map((y) {
            final yName = (y is Map ? (y['yearName'] ?? y['name'] ?? 'Year ${y['yearNo'] ?? ''}') : y.toString()).toString();
            return DropdownMenuItem<String>(
              value: yName,
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  Text(yName, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedYear = val;
              _selectedCaptain = null;
            });
            if (_selectedDeptId != null) {
              _fetchSections(_selectedDeptId!);
            }
          },
        ),
      ),
    );
  }

  Widget _buildDepartmentDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isExpanded: true,
          value: _selectedDeptId,
          hint: const Text('Select Department (9 Main Departments)', style: TextStyle(fontSize: 13.5, color: Color(0xFF94A3B8))),
          items: _departments.map((d) {
            final dId = d['id'] as int;
            final dName = d['deptCode'] != null ? '${d['deptCode']} - ${d['name']}' : (d['name'] ?? 'Department');
            return DropdownMenuItem<int>(
              value: dId,
              child: Text(
                dName.toString(),
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedDeptId = val;
              _selectedCaptain = null;
            });
            if (val != null) {
              _fetchSections(val);
            } else {
              setState(() {
                _selectedSectionId = null;
                _sections = [];
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildSectionDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _selectedDeptId == null ? const Color(0xFFF8FAFC) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _selectedDeptId == null ? const Color(0xFFE2E8F0) : const Color(0xFFCBD5E1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isExpanded: true,
          value: _selectedSectionId,
          hint: _isLoadingSections
              ? const Row(
                  children: [
                    SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 8),
                    Text('Loading sections...', style: TextStyle(fontSize: 13)),
                  ],
                )
              : Text(
                  _selectedDeptId == null
                      ? 'Select Department first'
                      : (_sections.isEmpty ? 'All / No Specific Section' : 'Select Section'),
                  style: TextStyle(
                    fontSize: 13.5,
                    color: _selectedDeptId == null ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
          items: [
            const DropdownMenuItem<int>(
              value: null,
              child: Text('All / No Specific Section', style: TextStyle(fontSize: 13.5)),
            ),
            ..._sections.map((sec) {
              final secId = sec['id'] as int;
              final secName = sec['sectionName'] ?? sec['name'] ?? 'Section';
              return DropdownMenuItem<int>(
                value: secId,
                child: Text(secName.toString(), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
              );
            }),
          ],
          onChanged: _selectedDeptId == null
              ? null
              : (val) {
                  setState(() {
                    _selectedSectionId = val;
                    _selectedCaptain = null;
                  });
                },
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF2563EB), size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label, {bool isRequired = false}) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF334155),
          ),
        ),
        if (isRequired)
          const Text(
            ' *',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFFEF4444),
            ),
          ),
      ],
    );
  }
}
