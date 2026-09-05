import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/core/config/api_config.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pragatix/features/team/services/team_proxy_service.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/features/team/pages/team_details_page.dart';
import 'package:pragatix/features/team/pages/create_team_page.dart';
import 'package:pragatix/features/admin/pages/captain_reward_settings_page.dart';
import 'package:pragatix/features/admin/pages/captain_reward_year_selection_page.dart';
import 'package:pragatix/features/admin/repository/admin_repository.dart';

// Dialogs removed from here

class TeamGroupManagementTab extends StatefulWidget {
  const TeamGroupManagementTab({super.key});

  @override
  State<TeamGroupManagementTab> createState() => _TeamGroupManagementTabState();
}

class _TeamGroupManagementTabState extends State<TeamGroupManagementTab> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _groups = [];

  // Lookups
  List<dynamic> _departments = [];
  List<dynamic> _academicYears = [];
  List<dynamic> _sections = [];
  List<dynamic> _stages = [];

  // Filter selections
  int? selectedDeptId;
  String? selectedYear;
  int? selectedSectionId;
  int? selectedStage;

  // Role info
  bool isSuperAdmin = false;
  bool isAdmin = false;
  bool isCC = false;
  bool isHOD = false;

  bool get canManage => isSuperAdmin || isAdmin || isCC || isHOD;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initRolesAndLookups();
    });
  }

  Future<void> _initRolesAndLookups() async {
    final auth = context.read<AuthProvider>();
    final currentUser = auth.currentUser;
    final role = auth.role ?? '';
    final subroles = (currentUser?['subRoles'] as List<dynamic>? ?? [])
        .map((e) => (e is Map ? (e['name'] ?? '') : e.toString()).trim().toUpperCase())
        .toList();
    final roles = (currentUser?['roles'] as List<dynamic>? ?? [])
        .map((e) => (e is Map ? (e['name'] ?? '') : e.toString()).trim().toUpperCase())
        .toList();

    isSuperAdmin = auth.isSuperAdmin ||
        roles.contains('ROLE_SUPER_ADMIN') ||
        roles.contains('ROLE_SUPERADMIN') ||
        roles.contains('SUPER_ADMIN');
    isAdmin = !isSuperAdmin &&
        (role == 'ROLE_ADMIN' ||
            role == 'ADMIN' ||
            roles.contains('ROLE_ADMIN') ||
            roles.contains('ADMIN'));
    isCC = subroles.contains('CC') ||
        subroles.contains('CLASS_COORDINATOR') ||
        subroles.contains('ROLE_CLASS_COORDINATOR') ||
        subroles.contains('ROLE_CC');
    isHOD = subroles.contains('HOD') ||
        subroles.contains('ROLE_HOD') ||
        roles.contains('ROLE_HOD') ||
        roles.contains('HOD');

    if (!canManage) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      try {
        final repo = getIt<AdminRepository>();
        final results = await Future.wait([
          repo.getDepartments(all: true),
          repo.getAssignedYears(),
        ]);

        final mainDepartments = (results[0]).where((d) {
          final type = (d['departmentType'] ?? d['type'] ?? '').toString().toUpperCase();
          final name = (d['name'] ?? d['deptName'] ?? '').toString();
          if (type == 'SUB') return false;
          if (name.toLowerCase().startsWith('department of')) return false;
          return true;
        }).toList();

        _departments = mainDepartments;
        _academicYears = results[1];
      } catch (lookupErr) {
        debugPrint('Non-fatal error fetching lookups: $lookupErr');
      }

      if (!mounted) return;

      if (isAdmin && !isSuperAdmin) {
        final String? adminYear = currentUser?['academicYear']?.toString() ??
            currentUser?['adminDetails']?['academicYear']?.toString();
        if (adminYear != null) {
          selectedYear = _mapYearToEnumName(adminYear) ?? adminYear;
        }
      }

      if (isCC || isHOD) {
        String? userDeptName;
        int? userDeptId;
        if (currentUser?['departmentId'] != null) {
          userDeptId = int.tryParse(currentUser!['departmentId'].toString());
        } else if (currentUser?['department'] is Map && (currentUser!['department'] as Map)['id'] != null) {
          userDeptId = int.tryParse((currentUser['department'] as Map)['id'].toString());
        }

        if (currentUser?['department'] is String) {
          userDeptName = currentUser!['department'] as String;
        } else if (currentUser?['department'] is Map) {
          final deptMap = currentUser!['department'] as Map;
          userDeptName = (deptMap['name'] ?? deptMap['deptName'])?.toString();
        }
        userDeptName ??= currentUser?['departmentName']?.toString() ?? currentUser?['deptName']?.toString();

        String? ccSectionName;
        int? ccSectionId;
        if (currentUser?['sectionId'] != null) {
          ccSectionId = int.tryParse(currentUser!['sectionId'].toString());
        } else if (currentUser?['section'] is Map && (currentUser!['section'] as Map)['id'] != null) {
          ccSectionId = int.tryParse((currentUser['section'] as Map)['id'].toString());
        }

        if (currentUser?['section'] is String) {
          ccSectionName = currentUser!['section'] as String;
        } else if (currentUser?['section'] is Map) {
          final secMap = currentUser!['section'] as Map;
          ccSectionName = (secMap['sectionName'] ?? secMap['name'])?.toString();
        }
        ccSectionName ??= currentUser?['sectionName']?.toString() ?? currentUser?['ccDetails']?['section']?.toString();

        final String? ccYear = currentUser?['academicYear']?.toString() ??
            currentUser?['year']?.toString() ??
            currentUser?['ccDetails']?['academicYear']?.toString();
        if (isCC && ccYear != null) {
          selectedYear = _mapYearToEnumName(ccYear) ?? ccYear;
        }

        if (userDeptId != null) {
          selectedDeptId = userDeptId;
        } else if (userDeptName != null && _departments.isNotEmpty) {
          final dMatch = _departments.where((d) {
            final name = (d['name'] ?? d['deptName'] ?? '').toString().toLowerCase();
            final code = (d['deptCode'] ?? d['code'] ?? '').toString().toLowerCase();
            final target = userDeptName!.toLowerCase();
            return name == target || code == target || target.contains(name) || name.contains(target);
          }).toList();
          if (dMatch.isNotEmpty) {
            selectedDeptId = dMatch.first['id'] as int?;
          }
        }

        if (selectedDeptId != null) {
          await _fetchSectionsForDept(selectedDeptId!);
        }

        if (isCC) {
          if (ccSectionId != null) {
            selectedSectionId = ccSectionId;
          } else if (ccSectionName != null && _sections.isNotEmpty) {
            final cleanSec = ccSectionName.trim().toUpperCase().replaceAll('SECTION', '').trim();
            final sMatch = _sections.where((s) {
              final sName = (s['sectionName'] ?? s['name'] ?? '').toString().trim().toUpperCase().replaceAll('SECTION', '').trim();
              return sName == cleanSec;
            }).toList();
            if (sMatch.isNotEmpty) {
              selectedSectionId = sMatch.first['id'] as int?;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error in initialization: $e');
    }

    await _fetchStages();
    await _fetchGroups();
  }

  Future<void> _fetchSectionsForDept(int deptId) async {
    try {
      final response = await getIt<TeamProxyService>().get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/admin/sections?departmentId=$deptId'),
        headers: {
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          if (mounted) {
            setState(() {
              _sections = data['data'] ?? [];
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching sections: $e');
    }
  }

  String? _mapYearToEnumName(String? rawYear) {
    if (rawYear == null) return null;
    final clean = rawYear.trim().toUpperCase();
    if (clean.contains('FIRST') || clean == '1' || clean == 'I' || clean.contains('1ST')) {
      return 'FIRST_YEAR';
    }
    if (clean.contains('SECOND') || clean == '2' || clean == 'II' || clean.contains('2ND')) {
      return 'SECOND_YEAR';
    }
    if (clean.contains('THIRD') || clean == '3' || clean == 'III' || clean.contains('3RD')) {
      return 'THIRD_YEAR';
    }
    if (clean.contains('FOURTH') || clean == '4' || clean == 'IV' || clean.contains('4TH')) {
      return 'FOURTH_YEAR';
    }
    return null;
  }

  Future<void> _fetchStages() async {
    final auth = context.read<AuthProvider>();
    final currentUser = auth.currentUser;

    final String? ccYear = currentUser?['ccDetails']?['academicYear']?.toString() ??
        currentUser?['year']?.toString();
    final String? adminYear = currentUser?['adminDetails']?['academicYear']?.toString();

    String? queryYear;
    if (isCC) {
      queryYear = ccYear;
    } else if (isAdmin) {
      queryYear = adminYear;
    } else if (selectedYear != null && selectedYear != 'All') {
      queryYear = selectedYear;
    }

    final String? mappedYear = _mapYearToEnumName(queryYear);
    String url = '${ApiConfig.baseUrl}/api/v1/admin/stages';
    if (mappedYear != null) {
      url += '?academicYear=$mappedYear';
    }

    try {
      final response = await getIt<TeamProxyService>().get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${auth.token!}',
        },
      );
      if (response.statusCode == 200) {
        final stageData = jsonDecode(response.body);
        if (stageData['data'] is List) {
          if (mounted) {
            setState(() {
              _stages = stageData['data'] ?? [];
              // If the selected stage is no longer in the loaded stages, reset it
              if (selectedStage != null && !_stages.any((s) => s['id'] == selectedStage)) {
                selectedStage = null;
              }
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching stages: $e');
    }
  }

  Future<void> _fetchGroups() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    List<String> queryParams = [];
    if (selectedYear != null && selectedYear != 'All') {
      final mappedYear = _mapYearToEnumName(selectedYear);
      queryParams.add('academicYear=${mappedYear ?? selectedYear}');
    }
    if (selectedDeptId != null) {
      queryParams.add('departmentId=$selectedDeptId');
    }
    if (selectedSectionId != null) {
      queryParams.add('sectionId=$selectedSectionId');
    }

    String queryString = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
    String url = '${ApiConfig.baseUrl}/api/v1/teams$queryString';

    debugPrint('API URL: $url');
    try {
      final auth = context.read<AuthProvider>();
      if (auth.token == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Authentication required';
          });
        }
        return;
      }

      final response = await getIt<TeamProxyService>().get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${auth.token!}',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> groups = data['data'] ?? [];
          setState(() {
            _groups = groups;
            _isLoading = false;
            _errorMessage = null;
          });
          return;
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Failed to load teams';
            _isLoading = false;
          });
          return;
        }
      } else if (response.statusCode == 403) {
        setState(() {
          _errorMessage = 'Access denied: You do not have permission to view teams.';
          _isLoading = false;
        });
        return;
      } else {
        setState(() {
          _errorMessage = 'Error ${response.statusCode}: Failed to load teams';
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      debugPrint('Error fetching teams: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Network error: Failed to connect to server';
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildHeaderActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color iconColor = const Color(0xFF334155),
  }) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: iconColor, size: 20),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!canManage) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('View Groups'),
          backgroundColor: Colors.indigo,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 64,
                  color: Colors.redAccent,
                ),
                SizedBox(height: 16),
                Text(
                  'Access Denied',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'You do not have permission to view or manage groups.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final Set<String> seenNames = {};
    final List<dynamic> filteredSections = [];
    for (var s in _sections) {
      final name = s['sectionName'];
      if (name != null && name.toString().trim().isNotEmpty) {
        if (selectedDeptId == null ||
            s['departmentId'] == selectedDeptId ||
            s['department']?['id'] == selectedDeptId) {
          if (!seenNames.contains(name)) {
            seenNames.add(name);
            filteredSections.add(s);
          }
        }
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: Stack(
        children: [
          // Background mesh subtle gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 240,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFDCE8F6),
                    Color(0xFFE8EFF9),
                    Color(0xFFF4F7FB),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Top Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              'Teams & Groups',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.4,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Manage student teams, sections & captain rewards',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSuperAdmin || isAdmin) ...[
                            _buildHeaderActionButton(
                              icon: Icons.military_tech_rounded,
                              tooltip: 'Captain & Vice Captain Rewards',
                              iconColor: const Color(0xFFD97706),
                              onPressed: () {
                                final auth = Provider.of<AuthProvider>(context, listen: false);
                                if (auth.isSuperAdmin) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const CaptainRewardYearSelectionPage(),
                                    ),
                                  );
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const CaptainRewardSettingsPage(),
                                    ),
                                  );
                                }
                              },
                            ),
                            const SizedBox(width: 6),
                          ],
                          _buildHeaderActionButton(
                            icon: Icons.refresh_rounded,
                            tooltip: 'Refresh',
                            onPressed: _fetchGroups,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Filters card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF64748B).withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (isSuperAdmin || isHOD)
                        _buildDropdown<String>(
                          'Year',
                          _academicYears
                              .map((y) => (y is Map ? (y['yearName'] ?? y['name'] ?? '') : y).toString())
                              .where((s) => s.isNotEmpty)
                              .toList(),
                          (y) => y,
                          selectedYear,
                          (val) {
                            setState(() {
                              selectedYear = val;
                              selectedDeptId = null;
                              selectedSectionId = null;
                              _sections = [];
                            });
                            _fetchStages();
                            _fetchGroups();
                          },
                        ),
                      if (isSuperAdmin || isAdmin)
                        _buildDropdown<int>(
                          'Dept',
                          _departments,
                          (d) =>
                              d['deptCode'] ??
                              d['dept_code'] ??
                              d['code'] ??
                              d['name'] ??
                              d['deptName'],
                          selectedDeptId,
                          (val) async {
                            setState(() {
                              selectedDeptId = val;
                              selectedSectionId = null;
                            });
                            if (val != null) {
                              await _fetchSectionsForDept(val);
                            } else {
                              setState(() {
                                _sections = [];
                              });
                            }
                            _fetchGroups();
                          },
                        ),
                      if (isSuperAdmin || isAdmin || isHOD || (isCC && filteredSections.length > 1))
                        _buildDropdown<int>(
                          'Section',
                          filteredSections,
                          (s) => s['sectionName'],
                          selectedSectionId,
                          (val) {
                            setState(() {
                              selectedSectionId = val;
                            });
                            _fetchGroups();
                          },
                        ),
                      _buildDropdown<int>(
                        'Stage',
                        _stages,
                        (s) => s['name'] ?? 'Stage ${s['id']}',
                        selectedStage,
                        (val) {
                          setState(() {
                            selectedStage = val;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                if (canManage)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final created = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreateTeamPage(
                                initialYear: selectedYear,
                                initialDeptId: selectedDeptId,
                                initialSectionId: selectedSectionId,
                              ),
                            ),
                          );
                          if (created == true) {
                            _fetchGroups();
                          }
                        },
                        icon: const Icon(Icons.add_circle_outline, size: 18),
                        label: const Text(
                          'Create Team',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ),

                // GROUPS LIST
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage != null
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      size: 52,
                                      color: Colors.redAccent,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _errorMessage!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Color(0xFF0F172A),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: _fetchGroups,
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Retry'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF2563EB),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Builder(
                              builder: (context) {
                                final displayGroups = _groups.where((g) {
                                  if (selectedStage != null) {
                                    final stageMatches = _stages.where((s) => s['id'] == selectedStage).toList();
                                    final targetOrder = stageMatches.isNotEmpty
                                        ? (stageMatches.first['displayOrder'] ?? stageMatches.first['id'])
                                        : selectedStage;
                                    int currentStage = 1;
                                    if (g['currentStage'] != null && g['currentStage'] is int && (g['currentStage'] as int) > 0) {
                                      currentStage = g['currentStage'];
                                    } else if ((g['teamMembers'] as List?)?.isNotEmpty == true) {
                                      final memberStage = g['teamMembers'][0]['currentStage'];
                                      if (memberStage is int && memberStage > 0) {
                                        currentStage = memberStage;
                                      }
                                    }
                                    return currentStage == targetOrder;
                                  }
                                  return true;
                                }).toList();

                                if (displayGroups.isEmpty) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(18),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEFF6FF),
                                            borderRadius: BorderRadius.circular(24),
                                          ),
                                          child: const Icon(
                                            Icons.groups_rounded,
                                            size: 48,
                                            color: Color(0xFF2563EB),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'No Groups Found',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        const Text(
                                          'No groups match the selected filters.',
                                          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                return ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                                  itemCount: displayGroups.length,
                                  itemBuilder: (context, index) {
                                    final g = displayGroups[index];
                                    final captainName = g['captainName'] ?? 'No Captain';
                                    final memberCount =
                                        (g['teamMembers'] as List?)?.length ?? 0;
                                    final groupName = g['teamName'] ?? 'Group';
                                    final size = g['teamCapacity'] ?? 0;

                                    int currentStage = 1;
                                    if (g['currentStage'] != null && g['currentStage'] is int && (g['currentStage'] as int) > 0) {
                                      currentStage = g['currentStage'];
                                    } else if ((g['teamMembers'] as List?)?.isNotEmpty == true) {
                                      final memberStage = g['teamMembers'][0]['currentStage'];
                                      if (memberStage is int && memberStage > 0) {
                                        currentStage = memberStage;
                                      }
                                    }

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: const Color(0xFFE2E8F0),
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF64748B).withValues(alpha: 0.06),
                                            blurRadius: 14,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(18),
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(18),
                                          onTap: () async {
                                            final result = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => TeamDetailsPage(
                                                  teamId: g['teamId'] ?? g['id'],
                                                  canManage: canManage,
                                                ),
                                              ),
                                            );
                                            if (result == true) {
                                              _fetchGroups();
                                            }
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 48,
                                                  height: 48,
                                                  decoration: BoxDecoration(
                                                    gradient: const LinearGradient(
                                                      colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                                                    ),
                                                    borderRadius: BorderRadius.circular(14),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: const Color(0xFF3B82F6).withValues(alpha: 0.28),
                                                        blurRadius: 10,
                                                        offset: const Offset(0, 4),
                                                      ),
                                                    ],
                                                  ),
                                                  child: const Icon(
                                                    Icons.groups_rounded,
                                                    color: Colors.white,
                                                    size: 24,
                                                  ),
                                                ),
                                                const SizedBox(width: 14),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              groupName,
                                                              style: const TextStyle(
                                                                fontWeight: FontWeight.w700,
                                                                fontSize: 16,
                                                                color: Color(0xFF0F172A),
                                                              ),
                                                            ),
                                                          ),
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 2.5,
                                                            ),
                                                            decoration: BoxDecoration(
                                                              color: const Color(0xFFFEF3C7),
                                                              borderRadius: BorderRadius.circular(6),
                                                              border: Border.all(color: const Color(0xFFFDE68A)),
                                                            ),
                                                            child: Text(
                                                              'Stage $currentStage',
                                                              style: const TextStyle(
                                                                color: Color(0xFFB45309),
                                                                fontSize: 11,
                                                                fontWeight: FontWeight.w700,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 5),
                                                      Text(
                                                        '👑 $captainName • $memberCount/$size members',
                                                        overflow: TextOverflow.ellipsis,
                                                        maxLines: 1,
                                                        style: const TextStyle(
                                                          fontSize: 12.5,
                                                          fontWeight: FontWeight.w500,
                                                          color: Color(0xFF64748B),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        "${g['departmentName'] ?? '-'} • ${g['year'] ?? '-'} - ${g['sectionName'] ?? '-'}",
                                                        overflow: TextOverflow.ellipsis,
                                                        maxLines: 1,
                                                        style: const TextStyle(
                                                          fontSize: 11.5,
                                                          color: Color(0xFF94A3B8),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                const Icon(
                                                  Icons.chevron_right_rounded,
                                                  color: Color(0xFF94A3B8),
                                                  size: 20,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>(
    String hint,
    List<dynamic> items,
    String Function(dynamic) labelBuilder,
    T? value,
    ValueChanged<T?> onChanged,
  ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: DropdownButtonFormField<T>(
          value: value,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: hint,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            isDense: true,
          ),
          items: [
            DropdownMenuItem<T>(
              value: null,
              child: const Text('All'),
            ),
            ...items.map(
              (e) => DropdownMenuItem<T>(
                value: (e is Map) ? e['id'] as T : e as T,
                child: Text(labelBuilder(e), overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

