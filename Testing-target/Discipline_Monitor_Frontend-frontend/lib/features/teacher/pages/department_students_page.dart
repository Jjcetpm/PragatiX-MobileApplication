import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/core/config/api_config.dart';
import 'package:pragatix/core/utils/api_client.dart' as http;
import 'package:pragatix/features/auth/providers/auth_provider.dart';

class DepartmentStudentListPage extends StatefulWidget {
  final int? departmentId;
  final String departmentName;
  final String initialYear;

  const DepartmentStudentListPage({
    Key? key,
    this.departmentId,
    required this.departmentName,
    this.initialYear = 'All Years',
  }) : super(key: key);

  @override
  State<DepartmentStudentListPage> createState() => _DepartmentStudentListPageState();
}

class _DepartmentStudentListPageState extends State<DepartmentStudentListPage> {
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedYear = 'All Years';
  String _sortBy = 'name'; // 'name', 'regNo', 'score', 'xp'
  bool _sortAsc = true;
  int _currentPage = 0;
  final int _pageSize = 15;

  List<Map<String, dynamic>> _allStudents = [];
  final TextEditingController _searchController = TextEditingController();

  static const List<String> _yearsList = [
    'All Years',
    'First Year',
    'Second Year',
    'Third Year',
    'Fourth Year',
  ];

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear;
    _fetchStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchStudents() async {
    setState(() => _isLoading = true);
    try {
      final token = getIt<AuthProvider>().token ?? '';
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/students?size=1000'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        List<dynamic> rawList = [];
        if (decoded['data'] is Map && decoded['data']['content'] is List) {
          rawList = decoded['data']['content'];
        } else if (decoded['data'] is List) {
          rawList = decoded['data'];
        }

        // Filter by HOD department
        final filteredDept = rawList.where((item) {
          if (item is! Map) return false;
          if (widget.departmentId == null) return true;

          final dept = item['department'];
          if (dept is Map) {
            final dId = dept['id'];
            if (dId != null && dId.toString() == widget.departmentId.toString()) {
              return true;
            }
            final dName = dept['name']?.toString().toLowerCase() ?? '';
            if (dName == widget.departmentName.toLowerCase()) {
              return true;
            }
          }
          final deptIdDirect = item['departmentId'];
          if (deptIdDirect != null && deptIdDirect.toString() == widget.departmentId.toString()) {
            return true;
          }
          return false;
        }).map((e) => Map<String, dynamic>.from(e as Map)).toList();

        if (mounted) {
          setState(() {
            _allStudents = filteredDept;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load students: ${res.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading students: $e')),
        );
      }
    }
  }

  bool _matchesYear(Map<String, dynamic> student, String yearFilter) {
    if (yearFilter == 'All Years') return true;

    final lower = yearFilter.toLowerCase();
    int targetYearNo = 0;
    if (lower.contains('first') || lower.contains('1')) targetYearNo = 1;
    else if (lower.contains('second') || lower.contains('2')) targetYearNo = 2;
    else if (lower.contains('third') || lower.contains('3')) targetYearNo = 3;
    else if (lower.contains('fourth') || lower.contains('4')) targetYearNo = 4;

    final yearRef = student['yearRef'];
    if (yearRef is Map) {
      final yNo = yearRef['yearNo'];
      if (yNo != null && yNo.toString() == targetYearNo.toString()) return true;
      final yName = yearRef['yearName']?.toString().toLowerCase() ?? '';
      if (yName.contains(lower)) return true;
    }

    final yr = student['year']?.toString().toLowerCase() ?? '';
    if (yr == targetYearNo.toString() || yr.contains(lower)) return true;

    final acYr = student['academicYear']?.toString().toLowerCase() ?? '';
    if (acYr.contains(lower)) return true;

    return false;
  }

  List<Map<String, dynamic>> _getFilteredAndSortedStudents() {
    var list = _allStudents.where((s) {
      if (!_matchesYear(s, _selectedYear)) return false;

      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final name = (s['fullName'] ?? s['name'] ?? '').toString().toLowerCase();
        final reg = (s['regNo'] ?? s['registerNumber'] ?? '').toString().toLowerCase();
        final sec = (s['section'] is Map ? s['section']['sectionName'] : s['section'])?.toString().toLowerCase() ?? '';
        if (!name.contains(q) && !reg.contains(q) && !sec.contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();

    list.sort((a, b) {
      int cmp = 0;
      switch (_sortBy) {
        case 'regNo':
          final rA = (a['regNo'] ?? '').toString();
          final rB = (b['regNo'] ?? '').toString();
          cmp = rA.compareTo(rB);
          break;
        case 'score':
          final sA = (a['score'] ?? 100) as num;
          final sB = (b['score'] ?? 100) as num;
          cmp = sA.compareTo(sB);
          break;
        case 'xp':
          final xA = (a['totalXp'] ?? a['xp'] ?? 0) as num;
          final xB = (b['totalXp'] ?? b['xp'] ?? 0) as num;
          cmp = xA.compareTo(xB);
          break;
        case 'name':
        default:
          final nA = (a['fullName'] ?? a['name'] ?? '').toString().toLowerCase();
          final nB = (b['fullName'] ?? b['name'] ?? '').toString().toLowerCase();
          cmp = nA.compareTo(nB);
          break;
      }
      return _sortAsc ? cmp : -cmp;
    });

    return list;
  }

  String _formatStudyYear(Map<String, dynamic> student) {
    final yearRef = student['yearRef'];
    if (yearRef is Map && yearRef['yearName'] != null) {
      return yearRef['yearName'].toString();
    }
    if (yearRef is Map && yearRef['yearNo'] != null) {
      final no = yearRef['yearNo'].toString();
      if (no == '1') return 'First Year';
      if (no == '2') return 'Second Year';
      if (no == '3') return 'Third Year';
      if (no == '4') return 'Fourth Year';
    }
    final yr = student['year']?.toString() ?? '';
    if (yr == '1') return 'First Year';
    if (yr == '2') return 'Second Year';
    if (yr == '3') return 'Third Year';
    if (yr == '4') return 'Fourth Year';
    return yr.isNotEmpty ? yr : 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _getFilteredAndSortedStudents();
    final totalCount = filteredList.length;
    final totalPages = (totalCount / _pageSize).ceil();
    final safePage = totalPages > 0 ? _currentPage.clamp(0, totalPages - 1) : 0;

    final startIndex = safePage * _pageSize;
    final endIndex = (startIndex + _pageSize < totalCount) ? startIndex + _pageSize : totalCount;
    final pagedList = totalCount > 0 ? filteredList.sublist(startIndex, endIndex) : <Map<String, dynamic>>[];

    // Calculate Summary stats
    final avgXp = totalCount > 0
        ? (filteredList.map((s) => (s['totalXp'] ?? s['xp'] ?? 0) as num).reduce((a, b) => a + b) / totalCount).round()
        : 0;
    final avgScore = totalCount > 0
        ? (filteredList.map((s) => ((s['score'] ?? 100) as num).clamp(0, 100)).reduce((a, b) => a + b) / totalCount)
        : 100.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Department Students',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              widget.departmentName,
              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF38BDF8)),
            tooltip: 'Refresh',
            onPressed: _fetchStudents,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)))
            : RefreshIndicator(
                onRefresh: _fetchStudents,
                color: const Color(0xFF38BDF8),
                backgroundColor: const Color(0xFF1E293B),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ribbon Stats Overview
                      _buildStatsRibbon(totalCount, avgXp, avgScore.clamp(0.0, 100.0)),
                      const SizedBox(height: 16),

                      // Filter & Search Controls
                      _buildControlPanel(),
                      const SizedBox(height: 16),

                      // Student List Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Showing ${pagedList.length} of $totalCount Students',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (totalPages > 1)
                            Text(
                              'Page ${safePage + 1} of $totalPages',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Students List or Empty State
                      if (pagedList.isEmpty)
                        _buildEmptyState()
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: pagedList.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            return _buildStudentCard(pagedList[index], startIndex + index + 1);
                          },
                        ),

                      // Pagination Controls
                      if (totalPages > 1) ...[
                        const SizedBox(height: 16),
                        _buildPaginationControls(safePage, totalPages),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildStatsRibbon(int total, int avgXp, double avgScore) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 400;
          return Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.spaceAround,
            children: [
              _buildRibbonItem(
                icon: Icons.people_alt_outlined,
                iconColor: const Color(0xFF38BDF8),
                label: 'Total Students',
                value: '$total',
                isNarrow: isNarrow,
              ),
              _buildRibbonItem(
                icon: Icons.bolt_outlined,
                iconColor: const Color(0xFFF59E0B),
                label: 'Avg XP',
                value: '$avgXp XP',
                isNarrow: isNarrow,
              ),
              _buildRibbonItem(
                icon: Icons.verified_user_outlined,
                iconColor: const Color(0xFF10B981),
                label: 'Avg Score',
                value: '${avgScore.toStringAsFixed(1)}/100',
                isNarrow: isNarrow,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRibbonItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required bool isNarrow,
  }) {
    return Container(
      constraints: BoxConstraints(minWidth: isNarrow ? 90 : 100),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Field
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search by student name or register number...',
              hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Color(0xFF94A3B8), size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                          _currentPage = 0;
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFF0F172A),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF334155)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF334155)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF38BDF8)),
              ),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
                _currentPage = 0;
              });
            },
          ),
          const SizedBox(height: 12),

          // Filters Row
          LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  // Year Filter Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedYear,
                        dropdownColor: const Color(0xFF1E293B),
                        icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF94A3B8), size: 18),
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                        items: _yearsList.map((y) {
                          return DropdownMenuItem<String>(
                            value: y,
                            child: Text(y),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedYear = val;
                              _currentPage = 0;
                            });
                          }
                        },
                      ),
                    ),
                  ),

                  // Sort By Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _sortBy,
                        dropdownColor: const Color(0xFF1E293B),
                        icon: const Icon(Icons.sort, color: Color(0xFF94A3B8), size: 18),
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                        items: const [
                          DropdownMenuItem(value: 'name', child: Text('Sort: Name')),
                          DropdownMenuItem(value: 'regNo', child: Text('Sort: Reg No')),
                          DropdownMenuItem(value: 'score', child: Text('Sort: Discipline Score')),
                          DropdownMenuItem(value: 'xp', child: Text('Sort: Total XP')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _sortBy = val);
                          }
                        },
                      ),
                    ),
                  ),

                  // Sort Asc/Desc Toggle Button
                  InkWell(
                    onTap: () => setState(() => _sortAsc = !_sortAsc),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _sortAsc ? Icons.arrow_upward : Icons.arrow_downward,
                            color: const Color(0xFF38BDF8),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _sortAsc ? 'Asc' : 'Desc',
                            style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> s, int rank) {
    final name = (s['fullName'] ?? s['name'] ?? 'Unnamed Student').toString();
    final regNo = (s['regNo'] ?? s['registerNumber'] ?? '-').toString();
    final section = (s['section'] is Map ? s['section']['sectionName'] : s['section'])?.toString() ?? '-';
    final studyYear = _formatStudyYear(s);

    final rawScore = ((s['score'] ?? 100) as num).toDouble();
    final score = rawScore.clamp(0.0, 100.0);
    final xp = (s['totalXp'] ?? s['xp'] ?? 0) as num;

    Color scoreColor;
    if (score >= 85) {
      scoreColor = const Color(0xFF10B981); // Emerald Green
    } else if (score >= 60) {
      scoreColor = const Color(0xFFF59E0B); // Amber
    } else {
      scoreColor = const Color(0xFFEF4444); // Red
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with initial or index
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'S',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Student details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Reg: $regNo',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF334155),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Sec $section',
                            style: const TextStyle(fontSize: 11, color: Color(0xFFCBD5E1)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Discipline Score Badge (Clamped to 100)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: scoreColor.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      '${score.toInt()}/100',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                      ),
                    ),
                    Text(
                      'Score',
                      style: TextStyle(
                        fontSize: 10,
                        color: scoreColor.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(color: Color(0xFF334155), height: 1),
          const SizedBox(height: 10),

          // Bottom Details: Study Year & Total XP
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Study Year tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.school_outlined, size: 14, color: Color(0xFF38BDF8)),
                    const SizedBox(width: 5),
                    Text(
                      studyYear,
                      style: const TextStyle(fontSize: 11, color: Color(0xFFE2E8F0), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),

              // XP Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt, size: 14, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 4),
                    Text(
                      '$xp XP',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF59E0B),
                      ),
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

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        children: [
          const Icon(Icons.person_search_outlined, size: 48, color: Color(0xFF64748B)),
          const SizedBox(height: 12),
          const Text(
            'No Students Found',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            _searchQuery.isNotEmpty
                ? 'No students matching "$_searchQuery" in $_selectedYear'
                : 'No students registered for $_selectedYear in ${widget.departmentName}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls(int currentPage, int totalPages) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          color: currentPage > 0 ? const Color(0xFF38BDF8) : const Color(0xFF475569),
          onPressed: currentPage > 0
              ? () => setState(() => _currentPage--)
              : null,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Text(
            '${currentPage + 1} / $totalPages',
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          color: currentPage < totalPages - 1 ? const Color(0xFF38BDF8) : const Color(0xFF475569),
          onPressed: currentPage < totalPages - 1
              ? () => setState(() => _currentPage++)
              : null,
        ),
      ],
    );
  }
}
