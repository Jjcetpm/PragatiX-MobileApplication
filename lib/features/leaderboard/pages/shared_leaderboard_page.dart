import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/shared/widgets/shared_leaderboard_tile.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/features/leaderboard/services/leaderboard_service.dart';
import 'package:pragatix/features/leaderboard/widgets/leaderboard_podium.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/features/xp/providers/xp_provider.dart';
import 'package:pragatix/features/admin/repository/admin_repository.dart';
import 'package:pragatix/core/widgets/pragatix_loader.dart';

class SharedLeaderboardPage extends StatefulWidget {
  final String title;
  final bool showFilters;
  final bool? showYearFilter;
  final bool? showDepartmentFilter;
  final bool? showSectionFilter;
  final bool showCurrentUserRank;

  /// Returns a map with keys 'id' and 'name' representing the current user
  final Future<Map<String, String>?> Function()? fetchCurrentUser;

  const SharedLeaderboardPage({
    super.key,
    required this.title,
    this.showFilters = true,
    this.showYearFilter,
    this.showDepartmentFilter,
    this.showSectionFilter,
    this.showCurrentUserRank = false,
    this.fetchCurrentUser,
  });

  @override
  State<SharedLeaderboardPage> createState() => _SharedLeaderboardPageState();
}

class _SharedLeaderboardPageState extends State<SharedLeaderboardPage> {
  bool isLoading = true;

  String? currentUserId;
  String? currentUserName;

  List<Map<String, dynamic>> filteredList = [];

  String? selectedYear;
  String? selectedDept;
  String? selectedSection;
  String selectedSort = 'Total XP';

  List<Map<String, dynamic>> yearOptions = [];
  List<Map<String, dynamic>> deptOptions = [];
  List<Map<String, dynamic>> sectionOptions = [];

  final LeaderboardService _leaderboardService = getIt<LeaderboardService>();

  bool get _effectiveShowYearFilter {
    if (widget.showYearFilter != null) return widget.showYearFilter!;
    final role = context.read<AuthProvider>().role?.toUpperCase() ?? '';
    if (role.contains('SUPER') || role == 'SUPER_ADMIN') return true;
    if (role == 'ADMIN' || role == 'HOD' || role == 'TEACHER' || role == 'STAFF') return true;
    return false; // Student & Captain do not have year filter
  }

  bool get _effectiveShowDepartmentFilter {
    if (widget.showDepartmentFilter != null) return widget.showDepartmentFilter!;
    return true;
  }

  bool get _effectiveShowSectionFilter {
    if (widget.showSectionFilter != null) return widget.showSectionFilter!;
    return true;
  }

  bool get _isSectionFilterEnabled {
    return selectedDept != null && selectedDept!.isNotEmpty && selectedDept != 'All';
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => isLoading = true);

    try {
      final authUser = context.read<AuthProvider>().currentUser;
      if (authUser != null) {
        currentUserName = authUser['fullName'] ?? authUser['name'];
        currentUserId = authUser['regNo'] ?? authUser['username'] ?? authUser['id']?.toString();
      }

      if ((currentUserName == null || currentUserName!.isEmpty) &&
          widget.showCurrentUserRank &&
          widget.fetchCurrentUser != null) {
        try {
          final userProfile = await widget.fetchCurrentUser!();
          if (userProfile != null) {
            currentUserId = userProfile['id'];
            currentUserName = userProfile['name'];
          }
        } catch (_) {}
      }

      if (widget.showFilters) {
        await _fetchFilters().catchError((e) {
          debugPrint('Filter fetch warning: $e');
        });
      }
      await _fetchStudents(setLoading: false).catchError((e) {
        debugPrint('Students fetch warning: $e');
      });
    } catch (e) {
      debugPrint('Error in _loadInitialData: $e');
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchFilters() async {
    try {
      final filters = await _leaderboardService.getFilters(
        yearId: selectedYear,
        departmentId: selectedDept,
      );

      List<Map<String, dynamic>> rawYears = List<Map<String, dynamic>>.from(filters['years'] ?? []);
      final role = context.read<AuthProvider>().role?.toUpperCase() ?? '';
      final bool isAdminRole = role.contains('ADMIN') || role == 'SUPER_ADMIN' || role == 'HOD' || role == 'TEACHER';

      if (isAdminRole && getIt.isRegistered<AdminRepository>()) {
        try {
          final yearAdmins = await getIt<AdminRepository>().getYearAdmins();
          final Set<String> assignedYearNames = {};
          for (var a in yearAdmins) {
            if (a is Map) {
              final ay = a['academicYear']?.toString().toUpperCase().replaceAll('_', ' ');
              if (ay != null && ay.isNotEmpty) assignedYearNames.add(ay);
              final yr = a['year']?.toString().toUpperCase().replaceAll('_', ' ');
              if (yr != null && yr.isNotEmpty) assignedYearNames.add(yr);
              final aId = a['assignedYearId']?.toString();
              if (aId != null && aId.isNotEmpty) assignedYearNames.add(aId);
            }
          }
          if (assignedYearNames.isNotEmpty) {
            rawYears = rawYears.where((y) {
              final name = (y['name'] ?? '').toString().toUpperCase().replaceAll('_', ' ');
              final id = (y['id'] ?? '').toString();
              return assignedYearNames.any((ay) => name.contains(ay) || ay.contains(name) || id == ay);
            }).toList();
          }
        } catch (e) {
          debugPrint('Error filtering year admins in leaderboard: $e');
        }
      }

      if (mounted) {
        setState(() {
          yearOptions = rawYears;
          deptOptions = List<Map<String, dynamic>>.from(filters['departments'] ?? []);
          sectionOptions = List<Map<String, dynamic>>.from(filters['sections'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('Error fetching filters: $e');
    }
  }

  Future<void> _fetchStudents({bool setLoading = true}) async {
    if (!mounted) return;
    if (setLoading) {
      setState(() => isLoading = true);
    }
    try {
      final students = await _leaderboardService.getLeaderboard(
        yearId: selectedYear,
        departmentId: selectedDept,
        sectionId: selectedSection,
      );
      if (mounted) {
        setState(() {
          filteredList = students;
        });
      }
    } catch (e) {
      debugPrint('Error fetching leaderboard: $e');
      if (mounted) {
        setState(() {
          filteredList = [];
        });
      }
    } finally {
      if (setLoading && mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _onYearChanged(String? val) {
    if (val != selectedYear) {
      setState(() {
        selectedYear = (val == 'All' || val == null || val.isEmpty) ? null : val;
        selectedDept = null;
        selectedSection = null;
      });
      _fetchFilters().then((_) => _fetchStudents());
    }
  }

  void _onDeptChanged(String? val) {
    if (val != selectedDept) {
      setState(() {
        selectedDept = (val == 'All' || val == null || val.isEmpty) ? null : val;
        selectedSection = null;
      });
      _fetchFilters().then((_) => _fetchStudents());
    }
  }

  void _onSectionChanged(String? val) {
    if (val != selectedSection) {
      setState(() {
        selectedSection = (val == 'All' || val == null || val.isEmpty) ? null : val;
      });
      _fetchStudents();
    }
  }

  int _getCurrentUserRank() {
    if (currentUserId != null && currentUserId!.isNotEmpty) {
      final cleanId = currentUserId!.trim().toLowerCase();
      for (int i = 0; i < filteredList.length; i++) {
        final reg = (filteredList[i]['regNo'] ?? '').toString().trim().toLowerCase();
        if (reg.isNotEmpty && reg == cleanId) {
          return i + 1;
        }
      }
    }
    if (currentUserName != null && currentUserName!.isNotEmpty) {
      final cleanName = currentUserName!.trim().toLowerCase();
      for (int i = 0; i < filteredList.length; i++) {
        final sName = (filteredList[i]['fullName'] ?? '').toString().trim().toLowerCase();
        if (sName.isNotEmpty && sName == cleanName) {
          return i + 1;
        }
      }
    }
    return -1;
  }

  int _getCurrentUserXp() {
    final userRank = _getCurrentUserRank();
    if (userRank > 0 && userRank <= filteredList.length) {
      final s = filteredList[userRank - 1];
      if (s['totalXp'] is num) return (s['totalXp'] as num).toInt();
      return int.tryParse(s['totalXp']?.toString() ?? '0') ?? 0;
    }
    final xpProv = Provider.of<XpProvider>(context, listen: false);
    if (xpProv.totalXp > 0) return xpProv.totalXp;
    return 0;
  }

  String _cleanSectionName(String raw) {
    return raw.replaceAll(RegExp(r'\s*-\s*\d{4}\s*Batch.*', caseSensitive: false), '').trim();
  }

  @override
  Widget build(BuildContext context) {
    final int userRank = widget.showCurrentUserRank ? _getCurrentUserRank() : -1;
    final int userXp = _getCurrentUserXp();
    final String displayName = currentUserName?.isNotEmpty == true ? currentUserName! : 'SHARUGESH';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Column(
            children: [
              // 1. Role-Adaptive Filter Control Bar (Only if widget.showFilters is true)
              if (widget.showFilters) _buildFilterBar(),

              // 2. Scrollable Body with Top 3 Podium and All Students List
              Expanded(
                child: isLoading
                    ? const Center(
                        child: PragatiXLoader(
                          fullScreen: false,
                          message: 'Loading Leaderboard...',
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchStudents,
                        color: const Color(0xFF0284C7),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                          padding: const EdgeInsets.only(bottom: 110),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Performers Podium
                              LeaderboardPodium(
                                topStudents: filteredList.take(3).toList(),
                                currentUserId: currentUserId,
                              ),

                              // All Students Header
                              const Padding(
                                padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
                                child: Text(
                                  'All Students',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),

                              // List of Students (From Rank 4 onwards)
                              if (filteredList.length > 3)
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: filteredList.length - 3,
                                  itemBuilder: (context, index) {
                                    final studentIndex = index + 3;
                                    final student = filteredList[studentIndex];
                                    final rank = studentIndex + 1;
                                    final isCurrentUser = (student['regNo'] != null &&
                                        currentUserId != null &&
                                        student['regNo'].toString().trim().toLowerCase() ==
                                            currentUserId!.trim().toLowerCase());

                                    final String deptStr = (student['departmentName'] ??
                                            student['department'] ??
                                            '')
                                        .toString()
                                        .trim();
                                    final String rawSec = (student['sectionName'] ??
                                            student['section'] ??
                                            '')
                                        .toString()
                                        .trim();
                                    final String cleanSec = _cleanSectionName(rawSec);
                                    final String rawYear =
                                        (student['year']?.toString() ?? '').trim();

                                    final List<String> details = [];
                                    if (rawYear.isNotEmpty && rawYear != 'null') {
                                      details.add(rawYear.toLowerCase().startsWith('year')
                                          ? rawYear
                                          : 'Year $rawYear');
                                    }
                                    if (cleanSec.isNotEmpty &&
                                        cleanSec != 'null' &&
                                        cleanSec.toLowerCase() != 'section') {
                                      details.add('Sec $cleanSec');
                                    }

                                    final String detailsStr = details.join(' • ');
                                    final String fullSubtitle;
                                    if (deptStr.isNotEmpty && detailsStr.isNotEmpty) {
                                      fullSubtitle = '$deptStr • $detailsStr';
                                    } else if (deptStr.isNotEmpty) {
                                      fullSubtitle = deptStr;
                                    } else if (detailsStr.isNotEmpty) {
                                      fullSubtitle = detailsStr;
                                    } else {
                                      fullSubtitle = 'Student';
                                    }

                                    final int score = (student['totalXp'] is num)
                                        ? (student['totalXp'] as num).toInt()
                                        : (int.tryParse(student['totalXp']?.toString() ?? '0') ?? 0);

                                    return SharedLeaderboardTile(
                                      rank: rank,
                                      name: student['fullName'] ?? 'Unknown Student',
                                      subtitle: fullSubtitle,
                                      score: score,
                                      gender: student['gender']?.toString(),
                                      isCurrentUser: isCurrentUser,
                                      isCaptain: student['teamRole'] == 'CAPTAIN',
                                      isViceCaptain: student['teamRole'] == 'VICE_CAPTAIN',
                                    );
                                  },
                                )
                              else if (filteredList.isEmpty)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(40),
                                    child: Text(
                                      'No students found.',
                                      style: TextStyle(color: Color(0xFF64748B)),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),

          // 3. Fixed / Sticky Bottom "Your Rank" Bar
          if (widget.showCurrentUserRank && userRank > 0)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _buildYourRankBottomBar(
                userRank: userRank,
                userXp: userXp,
                displayName: displayName,
              ),
            ),
        ],
      ),
    );
  }

  // ── Top Gradient App Bar ───────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    final bool canPop = Navigator.canPop(context);
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      leading: canPop
          ? IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.maybePop(context);
                }
              },
            )
          : null,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Leaderboard',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: 2),
          Text(
            'Track • Learn • Grow',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  // ── 1. Role-Adaptive Filter Control Bar ───────────────────────────────────────
  Widget _buildFilterBar() {
    final List<Widget> filterPills = [];

    // Year Filter Pill (All Years support - Only for Admins/Teachers)
    if (_effectiveShowYearFilter) {
      String currentYearName = 'All Years';
      if (selectedYear != null) {
        final y = yearOptions.firstWhere(
          (e) => e['id']?.toString() == selectedYear,
          orElse: () => {'name': selectedYear},
        );
        currentYearName = y['name'] ?? selectedYear!;
      }
      filterPills.add(
        Expanded(
          child: _buildFilterPill(
            label: 'Year',
            value: currentYearName,
            onTap: () {
              _showOptionsBottomSheet('Select Year', yearOptions, selectedYear, (val) {
                _onYearChanged(val);
              });
            },
          ),
        ),
      );
    }

    // Department Filter Pill (Visible on Student, Captain, and Admin sides)
    if (_effectiveShowDepartmentFilter) {
      if (filterPills.isNotEmpty) filterPills.add(const SizedBox(width: 8));
      String currentDeptName = 'All Departments';
      if (selectedDept != null) {
        final d = deptOptions.firstWhere(
          (e) => e['id']?.toString() == selectedDept,
          orElse: () => {'name': selectedDept},
        );
        currentDeptName = d['name'] ?? selectedDept!;
      }
      filterPills.add(
        Expanded(
          child: _buildFilterPill(
            label: 'Department',
            value: currentDeptName,
            onTap: () {
              _showOptionsBottomSheet('Select Department', deptOptions, selectedDept, (val) {
                _onDeptChanged(val);
              });
            },
          ),
        ),
      );
    }

    // Section Filter Pill (Role-Adaptive: requires Department, plus Year if Year filter is active)
    if (_effectiveShowSectionFilter) {
      if (filterPills.isNotEmpty) filterPills.add(const SizedBox(width: 8));
      final bool isSectionEnabled = _isSectionFilterEnabled;
      String currentSecName = 'All Sections';
      if (!isSectionEnabled) {
        currentSecName = 'All Sections';
      } else if (selectedSection != null) {
        final s = sectionOptions.firstWhere(
          (e) => e['id']?.toString() == selectedSection,
          orElse: () => {'name': selectedSection},
        );
        currentSecName = _cleanSectionName(s['name'] ?? selectedSection!);
      }
      filterPills.add(
        Expanded(
          child: _buildFilterPill(
            label: 'Section',
            value: currentSecName,
            isEnabled: isSectionEnabled,
            onTap: () {
              if (!isSectionEnabled) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please select Department first to filter by Section'),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              if (sectionOptions.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No sections available for the selected Department'),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              _showOptionsBottomSheet('Select Section', sectionOptions, selectedSection, (val) {
                _onSectionChanged(val);
              });
            },
          ),
        ),
      );
    }

    if (filterPills.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      color: const Color(0xFFF8FAFC),
      child: Row(
        children: filterPills,
      ),
    );
  }

  Widget _buildFilterPill({
    required String label,
    required String value,
    required VoidCallback onTap,
    bool isEnabled = true,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isEnabled ? Colors.white : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isEnabled ? const Color(0xFFF1F5F9) : const Color(0xFFE2E8F0), width: 1.5),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isEnabled ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isEnabled ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 17,
              color: isEnabled ? const Color(0xFF64748B) : const Color(0xFFCBD5E1),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsBottomSheet(
    String title,
    List<Map<String, dynamic>> items,
    String? selectedId,
    Function(String?) onSelect,
  ) {
    final List<Map<String, dynamic>> processedItems = [];
    if (title.toLowerCase().contains('section')) {
      final Set<String> seenNames = {};
      for (var it in items) {
        final clean = _cleanSectionName(it['name']?.toString() ?? '').trim();
        if (clean.isNotEmpty && seenNames.add(clean.toLowerCase())) {
          processedItems.add({
            'id': it['id'],
            'name': clean,
          });
        }
      }
    } else {
      processedItems.addAll(items);
    }

    final List<Map<String, dynamic>> allOptions = [
      {'id': null, 'name': 'All ${title.replaceAll("Select ", "")}s'},
      ...processedItems.map((it) => {
        'id': it['id'],
        'name': _cleanSectionName(it['name']?.toString() ?? ''),
      }),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: allOptions.length,
                itemBuilder: (context, index) {
                  final item = allOptions[index];
                  final name = item['name']?.toString() ?? '';
                  final id = item['id']?.toString();
                  final isSelected = (id == selectedId) || (id == null && selectedId == null);

                  return ListTile(
                    title: Text(
                      name,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                        color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF1E293B),
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_rounded, color: Color(0xFF4F46E5), size: 20)
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      onSelect(id);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Leaderboard Filters',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          selectedYear = null;
                          selectedDept = null;
                          selectedSection = null;
                        });
                        Navigator.pop(context);
                        _fetchFilters().then((_) => _fetchStudents());
                      },
                      child: const Text(
                        'Reset All',
                        style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Year Filter (Only if enabled)
                if (_effectiveShowYearFilter && yearOptions.isNotEmpty) ...[
                  const Text('Year / Batch', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedYear,
                    isExpanded: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    hint: const Text('All Years'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Years')),
                      ...yearOptions.map((y) => DropdownMenuItem(value: y['id']?.toString(), child: Text(y['name']?.toString() ?? ''))),
                    ],
                    onChanged: (val) {
                      setModalState(() {
                        selectedYear = val;
                        selectedSection = null;
                      });
                      setState(() {
                        selectedYear = val;
                        selectedSection = null;
                      });
                      _fetchFilters().then((_) {
                        if (mounted) setModalState(() {});
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                ],

                // Department Filter
                if (_effectiveShowDepartmentFilter && deptOptions.isNotEmpty) ...[
                  const Text('Department', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedDept,
                    isExpanded: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    hint: const Text('All Departments'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Departments')),
                      ...deptOptions.map((d) => DropdownMenuItem(value: d['id']?.toString(), child: Text(d['name']?.toString() ?? ''))),
                    ],
                    onChanged: (val) {
                      setModalState(() {
                        selectedDept = val;
                        selectedSection = null;
                      });
                      setState(() {
                        selectedDept = val;
                        selectedSection = null;
                      });
                      _fetchFilters().then((_) {
                        if (mounted) setModalState(() {});
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                ],

                // Section Filter (Enabled only when both Year & Department are selected)
                if (_effectiveShowSectionFilter) ...[
                  const Text('Section', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                  const SizedBox(height: 6),
                  if (!_isSectionFilterEnabled) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Text(
                        'Select Department first',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ] else if (sectionOptions.isEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Text(
                        'No sections for selected Department',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ] else ...[
                    DropdownButtonFormField<String>(
                      value: sectionOptions.any((s) => s['id']?.toString() == selectedSection) ? selectedSection : null,
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      hint: const Text('All Sections'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Sections')),
                        ...(() {
                          final Set<String> seenNames = {};
                          final List<DropdownMenuItem<String>> dItems = [];
                          for (var s in sectionOptions) {
                            final clean = _cleanSectionName(s['name']?.toString() ?? '').trim();
                            if (clean.isNotEmpty && seenNames.add(clean.toLowerCase())) {
                              dItems.add(DropdownMenuItem(
                                value: s['id']?.toString(),
                                child: Text(clean),
                              ));
                            }
                          }
                          return dItems;
                        })(),
                      ],
                      onChanged: (val) {
                        setModalState(() => selectedSection = val);
                        setState(() => selectedSection = val);
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ],

                // Apply Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _fetchFilters().then((_) => _fetchStudents());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      'Apply Filters',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── 3. Sticky Bottom "Your Rank" Bar ───────────────────────────────────────
  Widget _buildYourRankBottomBar({
    required int userRank,
    required int userXp,
    required String displayName,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar Initial inside Circular Badge (Replaces Trophy Symbol)
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Center(
              child: Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : 'S',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0284C7),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Your Rank Column
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Your Rank',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                '#$userRank',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(width: 18),

          // Total XP Column
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Total XP',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                '$userXp XP',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const Spacer(),

          // User Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 85),
                  child: Text(
                    displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
