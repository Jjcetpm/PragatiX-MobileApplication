import 'package:flutter/material.dart';
import 'package:pragatix/shared/widgets/shared_leaderboard_tile.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/features/leaderboard/services/leaderboard_service.dart';
import 'package:pragatix/features/leaderboard/widgets/leaderboard_podium.dart';

class SharedLeaderboardPage extends StatefulWidget {
  final String title;
  final bool showFilters;
  final bool showCurrentUserRank;

  /// Returns a map with keys 'id' and 'name' representing the current user
  final Future<Map<String, String>?> Function()? fetchCurrentUser;

  const SharedLeaderboardPage({
    super.key,
    required this.title,
    this.showFilters = false,
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

  List<Map<String, dynamic>> yearOptions = [];
  List<Map<String, dynamic>> deptOptions = [];
  List<Map<String, dynamic>> sectionOptions = [];

  final LeaderboardService _leaderboardService = getIt<LeaderboardService>();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => isLoading = true);

    try {
      if (widget.showCurrentUserRank && widget.fetchCurrentUser != null) {
        final userProfile = await widget.fetchCurrentUser!();
        if (userProfile != null) {
          currentUserId = userProfile['id'];
          currentUserName = userProfile['name'];
        }
      }

      if (widget.showFilters) {
        await _fetchFilters();
      }

      await _fetchStudents();
    } catch (e) {
      filteredList = [];
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
      if (mounted) {
        setState(() {
          yearOptions = List<Map<String, dynamic>>.from(filters['years'] ?? []);
          deptOptions = List<Map<String, dynamic>>.from(
            filters['departments'] ?? [],
          );
          sectionOptions = List<Map<String, dynamic>>.from(
            filters['sections'] ?? [],
          );

          if (yearOptions.isNotEmpty && selectedYear == null) {
            // we don't force select unless we want to, let's leave it null for "All"
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching filters: $e");
    }
  }

  Future<void> _fetchStudents() async {
    if (!mounted) return;
    setState(() => isLoading = true);
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
      debugPrint("Error fetching leaderboard: $e");
      if (mounted) {
        setState(() {
          filteredList = [];
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _onYearChanged(String? val) {
    if (val != selectedYear) {
      setState(() {
        selectedYear = val;
        selectedDept = null;
        selectedSection = null;
      });
      _fetchFilters().then((_) => _fetchStudents());
    }
  }

  void _onDeptChanged(String? val) {
    if (val != selectedDept) {
      setState(() {
        selectedDept = val;
        selectedSection = null;
      });
      _fetchFilters().then((_) => _fetchStudents());
    }
  }

  void _onSectionChanged(String? val) {
    if (val != selectedSection) {
      setState(() {
        selectedSection = val;
      });
      _fetchStudents();
    }
  }

  int _getCurrentUserRank() {
    if (currentUserId == null) return -1;
    for (int i = 0; i < filteredList.length; i++) {
      if (filteredList[i]['regNo'] == currentUserId) {
        return i + 1;
      }
    }
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    final int userRank = widget.showCurrentUserRank
        ? _getCurrentUserRank()
        : -1;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: Column(
        children: [
          if (widget.showFilters)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: const Color(0xFF1E293B),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _buildDynamicFilterDropdown(
                      label: 'Year',
                      value: selectedYear,
                      items: yearOptions,
                      onChanged: _onYearChanged,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDynamicFilterDropdown(
                      label: 'Department',
                      value: selectedDept,
                      items: deptOptions,
                      onChanged: _onDeptChanged,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDynamicFilterDropdown(
                      label: 'Section',
                      value: selectedSection,
                      items: sectionOptions,
                      onChanged: _onSectionChanged,
                    ),
                  ),
                ],
              ),
            ),

          if (!widget.showFilters && !isLoading)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Student Standings (Sorted by Discipline Score)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredList.isEmpty
                ? const Center(child: Text('No students found.'))
                : RefreshIndicator(
                    onRefresh: _fetchStudents,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredList.length > 3
                          ? filteredList.length - 2
                          : 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return LeaderboardPodium(
                            topStudents: filteredList.take(3).toList(),
                            currentUserId: currentUserId,
                          );
                        }

                        final studentIndex = index + 2;
                        final student = filteredList[studentIndex];
                        final rank = studentIndex + 1;
                        final isCurrentUser =
                            (student['regNo'] == currentUserId);

                        return SharedLeaderboardTile(
                          rank: rank,
                          name: student['fullName'] ?? 'Unknown',
                          score: student['score'] ?? 0,
                          isCurrentUser: isCurrentUser,
                          subtitle:
                              '${student['departmentName'] ?? ''} - ${student['year'] ?? ''} (${student['section'] ?? ''})',
                          isCaptain: student['teamRole'] == 'CAPTAIN',
                          isViceCaptain: student['teamRole'] == 'VICE_CAPTAIN',
                        );
                      },
                    ),
                  ),
          ),

          if (widget.showCurrentUserRank && userRank != -1 && !isLoading)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Text(
                    'Your Rank:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF3B82F6).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      '#$userRank',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    currentUserName ?? 'Student',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDynamicFilterDropdown({
    required String label,
    required String? value,
    required List<Map<String, dynamic>> items,
    required ValueChanged<String?> onChanged,
  }) {
    List<DropdownMenuItem<String>> menuItems = [
      DropdownMenuItem(
        value: null,
        child: Text(label, style: const TextStyle(color: Colors.white70)),
      ),
    ];

    menuItems.addAll(
      items.map((item) {
        return DropdownMenuItem<String>(
          value: item['id'].toString(),
          child: Text(
            item['name'].toString(),
            style: const TextStyle(color: Colors.white),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }),
    );

    // Ensure the value exists in the list to prevent assertion errors
    if (value != null && !items.any((item) => item['id'].toString() == value)) {
      value = null; // reset if not found
    }

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF334155),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF475569)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          isExpanded: true,
          icon: const Icon(
            Icons.arrow_drop_down,
            color: Colors.white54,
            size: 20,
          ),
          dropdownColor: const Color(0xFF334155),
          items: menuItems,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
