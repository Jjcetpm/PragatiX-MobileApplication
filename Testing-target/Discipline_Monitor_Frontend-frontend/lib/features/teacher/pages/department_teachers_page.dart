import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/core/config/api_config.dart';
import 'package:pragatix/core/utils/api_client.dart' as http;
import 'package:pragatix/features/auth/providers/auth_provider.dart';

class DepartmentTeacherListPage extends StatefulWidget {
  final int? departmentId;
  final String departmentName;

  const DepartmentTeacherListPage({
    Key? key,
    this.departmentId,
    required this.departmentName,
  }) : super(key: key);

  @override
  State<DepartmentTeacherListPage> createState() => _DepartmentTeacherListPageState();
}

class _DepartmentTeacherListPageState extends State<DepartmentTeacherListPage> {
  bool _isLoading = true;
  String _searchQuery = '';
  String _sortBy = 'name'; // 'name', 'role', 'email'
  bool _sortAsc = true;
  int _currentPage = 0;
  final int _pageSize = 15;

  List<Map<String, dynamic>> _allTeachers = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchTeachers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchTeachers() async {
    setState(() => _isLoading = true);
    try {
      final token = getIt<AuthProvider>().token ?? '';
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/admin/users'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        List<dynamic> rawList = [];
        if (decoded['data'] is List) {
          rawList = decoded['data'];
        }

        // Filter by Teachers / Faculty in this department
        final filteredDept = rawList.where((item) {
          if (item is! Map) return false;

          // Check if user is a teacher / faculty
          final roles = item['roles'];
          bool isTeacherRole = false;
          if (roles is List) {
            for (var r in roles) {
              final rName = (r is Map ? r['name'] : r)?.toString().toUpperCase() ?? '';
              if (rName.contains('TEACHER') || rName.contains('FACULTY') || rName.contains('HOD') || rName.contains('CC')) {
                isTeacherRole = true;
                break;
              }
            }
          }
          if (!isTeacherRole) {
            // Also check role string field
            final roleStr = item['role']?.toString().toUpperCase() ?? '';
            if (roleStr.contains('TEACHER') || roleStr.contains('FACULTY') || roleStr.contains('HOD')) {
              isTeacherRole = true;
            }
          }

          if (!isTeacherRole) return false;

          // Check department matching
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
            _allTeachers = filteredDept;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load teachers: ${res.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading teachers: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> _getFilteredAndSortedTeachers() {
    var list = _allTeachers.where((t) {
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final name = (t['fullName'] ?? t['name'] ?? t['username'] ?? '').toString().toLowerCase();
        final email = (t['email'] ?? '').toString().toLowerCase();
        final phone = (t['phoneNumber'] ?? t['phone'] ?? '').toString().toLowerCase();
        if (!name.contains(q) && !email.contains(q) && !phone.contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();

    list.sort((a, b) {
      int cmp = 0;
      switch (_sortBy) {
        case 'email':
          final eA = (a['email'] ?? '').toString().toLowerCase();
          final eB = (b['email'] ?? '').toString().toLowerCase();
          cmp = eA.compareTo(eB);
          break;
        case 'role':
          final rA = _extractRoleNames(a).toLowerCase();
          final rB = _extractRoleNames(b).toLowerCase();
          cmp = rA.compareTo(rB);
          break;
        case 'name':
        default:
          final nA = (a['fullName'] ?? a['name'] ?? a['username'] ?? '').toString().toLowerCase();
          final nB = (b['fullName'] ?? b['name'] ?? b['username'] ?? '').toString().toLowerCase();
          cmp = nA.compareTo(nB);
          break;
      }
      return _sortAsc ? cmp : -cmp;
    });

    return list;
  }

  String _extractRoleNames(Map<String, dynamic> teacher) {
    final List<String> roleNames = [];
    final roles = teacher['roles'];
    if (roles is List) {
      for (var r in roles) {
        String name = (r is Map ? r['name'] : r)?.toString() ?? '';
        name = name.replaceAll('ROLE_', '').replaceAll('_', ' ');
        if (name.isNotEmpty && !roleNames.contains(name)) {
          roleNames.add(name);
        }
      }
    }
    final subRoles = teacher['subRoles'];
    if (subRoles is List) {
      for (var sr in subRoles) {
        String name = (sr is Map ? sr['name'] : sr)?.toString() ?? '';
        if (name.isNotEmpty && !roleNames.contains(name)) {
          roleNames.add(name);
        }
      }
    }
    if (roleNames.isEmpty) {
      final r = teacher['role']?.toString() ?? 'Faculty';
      roleNames.add(r.replaceAll('ROLE_', ''));
    }
    return roleNames.join(', ');
  }

  String _extractSectionInfo(Map<String, dynamic> teacher) {
    final sec = teacher['section'];
    if (sec is Map && sec['sectionName'] != null) {
      return 'Section ${sec['sectionName']}';
    }
    if (teacher['sectionName'] != null) {
      return 'Section ${teacher['sectionName']}';
    }
    return 'All Sections';
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _getFilteredAndSortedTeachers();
    final totalCount = filteredList.length;
    final totalPages = (totalCount / _pageSize).ceil();
    final safePage = totalPages > 0 ? _currentPage.clamp(0, totalPages - 1) : 0;

    final startIndex = safePage * _pageSize;
    final endIndex = (startIndex + _pageSize < totalCount) ? startIndex + _pageSize : totalCount;
    final pagedList = totalCount > 0 ? filteredList.sublist(startIndex, endIndex) : <Map<String, dynamic>>[];

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
              'Department Faculty & Staff',
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
            onPressed: _fetchTeachers,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)))
            : RefreshIndicator(
                onRefresh: _fetchTeachers,
                color: const Color(0xFF38BDF8),
                backgroundColor: const Color(0xFF1E293B),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ribbon Stats Overview
                      _buildStatsRibbon(totalCount),
                      const SizedBox(height: 16),

                      // Filter & Search Controls
                      _buildControlPanel(),
                      const SizedBox(height: 16),

                      // Teacher List Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Showing ${pagedList.length} of $totalCount Faculty Members',
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

                      // Teachers List or Empty State
                      if (pagedList.isEmpty)
                        _buildEmptyState()
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: pagedList.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            return _buildTeacherCard(pagedList[index], startIndex + index + 1);
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

  Widget _buildStatsRibbon(int total) {
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
                icon: Icons.person_pin_outlined,
                iconColor: const Color(0xFF38BDF8),
                label: 'Total Faculty',
                value: '$total',
                isNarrow: isNarrow,
              ),
              _buildRibbonItem(
                icon: Icons.domain_outlined,
                iconColor: const Color(0xFF10B981),
                label: 'Department',
                value: widget.departmentName,
                isNarrow: isNarrow,
              ),
              _buildRibbonItem(
                icon: Icons.verified_outlined,
                iconColor: const Color(0xFF818CF8),
                label: 'Active Staff',
                value: '$total Active',
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
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
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
              hintText: 'Search faculty by name, email or phone...',
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
                          DropdownMenuItem(value: 'role', child: Text('Sort: Role / Designation')),
                          DropdownMenuItem(value: 'email', child: Text('Sort: Email')),
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

  Widget _buildTeacherCard(Map<String, dynamic> t, int rank) {
    final name = (t['fullName'] ?? t['name'] ?? t['username'] ?? 'Faculty Member').toString();
    final email = (t['email'] ?? '-').toString();
    final rolesStr = _extractRoleNames(t);
    final sectionInfo = _extractSectionInfo(t);

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
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF4338CA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'T',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Teacher details
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
                        const Icon(Icons.email_outlined, size: 13, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            email,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Active Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 12, color: Color(0xFF10B981)),
                    SizedBox(width: 4),
                    Text(
                      'Active',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(color: Color(0xFF334155), height: 1),
          const SizedBox(height: 10),

          // Bottom Details: Roles & Section assignment
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Roles Tag
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.badge_outlined, size: 13, color: Color(0xFF38BDF8)),
                          const SizedBox(width: 4),
                          Text(
                            rolesStr,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF38BDF8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Section info
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
                    const Icon(Icons.group_work_outlined, size: 13, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text(
                      sectionInfo,
                      style: const TextStyle(fontSize: 11, color: Color(0xFFE2E8F0)),
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
          const Icon(Icons.person_off_outlined, size: 48, color: Color(0xFF64748B)),
          const SizedBox(height: 12),
          const Text(
            'No Faculty Found',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            _searchQuery.isNotEmpty
                ? 'No faculty matching "$_searchQuery"'
                : 'No faculty members registered for ${widget.departmentName}',
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
