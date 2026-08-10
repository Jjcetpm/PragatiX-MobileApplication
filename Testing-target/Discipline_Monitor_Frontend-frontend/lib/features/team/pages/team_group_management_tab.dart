import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/core/config/api_config.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pragatix/features/team/services/team_proxy_service.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/shared/widgets/student_search/student_search_field.dart';

import 'package:pragatix/features/team/pages/team_details_page.dart';
import 'package:pragatix/features/admin/pages/captain_reward_settings_page.dart';
import 'package:pragatix/features/admin/pages/captain_reward_year_selection_page.dart';

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

  // Filter selections
  int? selectedDeptId;
  String? selectedYear;
  int? selectedSectionId;

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
      final headers = {
        'Authorization': 'Bearer ${auth.token!}',
      };

      try {
        final results = await Future.wait([
          getIt<TeamProxyService>().get(
            Uri.parse('${ApiConfig.baseUrl}/api/v1/admin/departments'),
            headers: headers,
          ),
          getIt<TeamProxyService>().get(
            Uri.parse('${ApiConfig.baseUrl}/api/v1/admin/years'),
            headers: headers,
          ),
        ]);

        if (results[0].statusCode == 200) {
          final deptData = jsonDecode(results[0].body);
          if (deptData['data'] is List) {
            _departments = deptData['data'];
          }
        }

        if (results[1].statusCode == 200) {
          final yearData = jsonDecode(results[1].body);
          if (yearData['data'] is List) {
            _academicYears = yearData['data'];
          }
        }
      } catch (lookupErr) {
        debugPrint('Non-fatal error fetching lookups: $lookupErr');
      }

      if (!mounted) return;

      if (isCC || isHOD) {
        final String? userDeptName =
            currentUser?['department']?['name'] ?? currentUser?['departmentName'];
        final String? ccSectionName =
            currentUser?['section']?['sectionName'] ?? currentUser?['section'];

        if (userDeptName != null && _departments.isNotEmpty) {
          final dMatch = _departments
              .where((d) => (d['name'] ?? d['deptName']) == userDeptName)
              .toList();
          if (dMatch.isNotEmpty) {
            selectedDeptId = dMatch.first['id'];
          }
        } else if (currentUser?['department']?['id'] != null) {
          selectedDeptId = currentUser!['department']['id'];
        }

        if (selectedDeptId != null) {
          await _fetchSectionsForDept(selectedDeptId!);
        }

        if (isCC && ccSectionName != null) {
          final sMatch = _sections
              .where((s) => s['sectionName'] == ccSectionName)
              .toList();
          if (sMatch.isNotEmpty) {
            selectedSectionId = sMatch.first['id'];
          }
        }
      }
    } catch (e) {
      debugPrint('Error in initialization: $e');
    }

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

  Future<void> _fetchGroups() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    List<String> queryParams = [];
    if (selectedYear != null && selectedYear != 'All') {
      queryParams.add('academicYear=$selectedYear');
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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('View Groups'),
        backgroundColor: Colors.indigo,
        actions: [
          if (isSuperAdmin || isAdmin)
            IconButton(
              icon: const Icon(Icons.military_tech_rounded, color: Colors.amber),
              tooltip: 'Captain & Vice Captain Rewards',
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
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchGroups),
        ],
      ),
      body: _isLoading
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
                          size: 64,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.black87,
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
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // FILTERS
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      color: Colors.indigo.shade50,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (isSuperAdmin)
                            _buildDropdown<String>(
                              'Year',
                              _academicYears.map((y) => y['yearName'].toString()).toList(),
                              (y) => y,
                              selectedYear,
                              (val) {
                                setState(() {
                                  selectedYear = val;
                                  selectedDeptId = null;
                                  selectedSectionId = null;
                                  _sections = [];
                                });
                                _fetchGroups();
                              },
                            ),
                          if (isSuperAdmin || isAdmin)
                            _buildDropdown<int>(
                              'Dept',
                              _departments,
                              (d) => d['name'] ?? d['deptName'],
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
                        ],
                      ),
                    ),
                    if (canManage)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _showCreateGroupDialog,
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text(
                              'Create Team',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ),
                    // GROUPS LIST
                    Expanded(
                      child: _groups.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.group_off_rounded,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No groups found',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    onPressed: _fetchGroups,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Refresh'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.indigo,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _groups.length,
                          itemBuilder: (context, index) {
                            final g = _groups[index];
                            final captainName = g['captainName'] ?? 'No Captain';
                            final viceCaptainName = g['viceCaptainName'] ?? 'No Vice Captain';
                            final memberCount =
                                (g['teamMembers'] as List?)?.length ?? 0;
                            final groupName = g['teamName'] ?? 'Group';
                            final size = g['teamCapacity'] ?? 0;

                            final currentStage =
                                (g['teamMembers'] as List?)?.isNotEmpty == true
                                ? (g['teamMembers'][0]['currentStage'] ?? 1)
                                : 1;

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
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
                                  // Refresh if a team was deleted or changed
                                  if (result == true) {
                                    _fetchGroups();
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Colors.indigo
                                            .withValues(alpha: 0.1),
                                        child: const Icon(
                                          Icons.groups_rounded,
                                          color: Colors.indigo,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              groupName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Captain: $captainName  •  Vice: $viceCaptainName  •  $memberCount/$size members',
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                              softWrap: false,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.location_on_outlined,
                                                  size: 14,
                                                  color: Colors.grey,
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    "${g['departmentName'] ?? '-'} • ${g['year'] ?? '-'} - ${g['sectionName'] ?? '-'}",
                                                    overflow: TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                    softWrap: false,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.amber.shade50,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    'Stage $currentStage',
                                                    style: TextStyle(
                                                      color:
                                                          Colors.amber.shade800,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.chevron_right,
                                        color: Colors.grey,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
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
                value: (T == String) ? e as T : e['id'] as T,
                child: Text(labelBuilder(e), overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Future<void> _createGroup(
    String name,
    int limit,
    String captainStudentId,
  ) async {
    try {
      final body = jsonEncode({
        'name': name,
        'size': limit,
        'captainStudentId': captainStudentId,
      });

      final response = await getIt<TeamProxyService>().post(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/teams'),
        headers: {
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
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
              backgroundColor: Colors.green,
            ),
          );
          _fetchGroups();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Failed to create team'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Failed to create team'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.orange),
      );
    }
  }

  void _showCreateGroupDialog() {
    final nameCtrl = TextEditingController();
    final limitCtrl = TextEditingController(text: "5");
    Map<String, dynamic>? selectedCaptain;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Create New Team'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Team Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: limitCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Max Size Limit',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    StudentSearchField(
                      selectedStudent: selectedCaptain,
                      onStudentSelected: (student) {
                        setState(() {
                          selectedCaptain = student;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    final limit = int.tryParse(limitCtrl.text) ?? 5;

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Team Name is required'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return;
                    }
                    if (limit < 1) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Team Capacity must be at least 1'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return;
                    }
                    if (selectedCaptain == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Captain is required'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return;
                    }

                    Navigator.pop(context);
                    _createGroup(name, limit, selectedCaptain!['regNo']);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                  ),
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
