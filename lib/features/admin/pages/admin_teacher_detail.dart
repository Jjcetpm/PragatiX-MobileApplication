import 'package:flutter/material.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/string_utils.dart';
import '../repository/admin_repository.dart';

class AdminTeacherDetail extends StatefulWidget {
  final Map<String, dynamic> teacher;

  const AdminTeacherDetail({super.key, required this.teacher});

  @override
  State<AdminTeacherDetail> createState() => _AdminTeacherDetailState();
}

class _AdminTeacherDetailState extends State<AdminTeacherDetail> {
  late Map<String, dynamic> _teacherData;
  bool _isLoading = true;

  int _totalPositivePoints = 0;
  int _totalPenaltyPoints = 0;
  int _totalActions = 0;
  int _studentsImpacted = 0;
  List<dynamic> _historyList = [];

  String _searchQuery = '';
  String _selectedFilter = 'ALL'; // ALL, AWARDS, DEDUCTIONS
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _teacherData = Map<String, dynamic>.from(widget.teacher);
    _fetchPointsHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPointsHistory() async {
    final teacherId = _teacherData['id'];
    if (teacherId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final data = await getIt<AdminRepository>().getTeacherPointsHistory(teacherId);
      if (mounted) {
        setState(() {
          if (data['teacher'] != null && data['teacher'] is Map) {
            _teacherData.addAll(Map<String, dynamic>.from(data['teacher']));
          }
          _totalPositivePoints = int.tryParse(data['totalPositivePoints']?.toString() ?? '0') ?? 0;
          _totalPenaltyPoints = int.tryParse(data['totalPenaltyPoints']?.toString() ?? '0') ?? 0;
          _totalActions = int.tryParse(data['totalActions']?.toString() ?? '0') ?? 0;
          _studentsImpacted = int.tryParse(data['studentsImpacted']?.toString() ?? '0') ?? 0;
          _historyList = data['history'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<dynamic> get _filteredHistory {
    return _historyList.where((item) {
      final int pts = item['points'] is int
          ? item['points']
          : int.tryParse(item['points']?.toString() ?? '0') ?? 0;

      // Filter by type
      if (_selectedFilter == 'AWARDS' && pts < 0) return false;
      if (_selectedFilter == 'DEDUCTIONS' && pts >= 0) return false;

      // Search filter
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.toLowerCase().trim();
        final sName = (item['studentName'] ?? '').toString().toLowerCase();
        final sReg = (item['studentRegNo'] ?? '').toString().toLowerCase();
        final teamName = (item['teamName'] ?? '').toString().toLowerCase();
        final dept = (item['department'] ?? '').toString().toLowerCase();
        final yr = (item['year'] ?? '').toString().toLowerCase();
        final sec = (item['section'] ?? '').toString().toLowerCase();
        final reason = (item['reason'] ?? '').toString().toLowerCase();
        final cat = (item['category'] ?? '').toString().toLowerCase();

        bool matchMembers = false;
        final members = item['members'] as List<dynamic>?;
        if (members != null) {
          for (final m in members) {
            final mName = (m['name'] ?? '').toString().toLowerCase();
            final mReg = (m['regNo'] ?? '').toString().toLowerCase();
            if (mName.contains(query) || mReg.contains(query)) {
              matchMembers = true;
              break;
            }
          }
        }

        if (!sName.contains(query) &&
            !sReg.contains(query) &&
            !teamName.contains(query) &&
            !dept.contains(query) &&
            !yr.contains(query) &&
            !sec.contains(query) &&
            !reason.contains(query) &&
            !cat.contains(query) &&
            !matchMembers) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final String fullName = _teacherData['fullName'] ?? 'Faculty Member';
    final String email = _teacherData['email'] ?? '';
    final String deptName = _teacherData['departmentName'] ?? _teacherData['department']?['name'] ?? 'No Department';
    final String designation = _teacherData['designation'] ?? 'Faculty';
    final String phone = _teacherData['phone'] ?? _teacherData['phoneNo'] ?? '';

    final List<dynamic> roles = _teacherData['roles'] ?? [];
    final List<dynamic> subRoles = _teacherData['subRoles'] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Teacher Details',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 19,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Refresh',
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchPointsHistory();
            },
          ),
        ],
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Card
                  _buildProfileCard(
                    fullName: fullName,
                    designation: designation,
                    deptName: deptName,
                    roles: roles,
                    subRoles: subRoles,
                  ),
                  const SizedBox(height: 16),

                  // Contact & Department Info
                  _buildContactCard(
                    email: email,
                    phone: phone,
                    deptName: deptName,
                  ),
                  const SizedBox(height: 20),

                  // Points Impact Metrics
                  const Text(
                    'Points Awarded Summary',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildMetricCardsGrid(),
                  const SizedBox(height: 24),

                  // Points History Header & Filter
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Points Awarded History',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_historyList.length} Records',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Search Bar & Filter Chips
                  _buildSearchAndFilters(),
                  const SizedBox(height: 12),

                  // History Records List
                  _buildHistoryList(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileCard({
    required String fullName,
    required String designation,
    required String deptName,
    required List<dynamic> roles,
    required List<dynamic> subRoles,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    fullName.isNotEmpty ? fullName[0].toUpperCase() : 'T',
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                fullName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                designation,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                deptName,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [
                  ...roles.map((r) {
                    final cleanRole = r.toString().replaceAll('ROLE_', '');
                    return Chip(
                      avatar: const Icon(Icons.verified_user_rounded, size: 14, color: Color(0xFF2563EB)),
                      label: Text(
                        cleanRole,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1E40AF)),
                      ),
                      backgroundColor: const Color(0xFFEFF6FF),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    );
                  }),
                  ...subRoles.map((sr) {
                    return Chip(
                      avatar: const Icon(Icons.star_rounded, size: 14, color: Color(0xFFD97706)),
                      label: Text(
                        sr.toString(),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
                      ),
                      backgroundColor: const Color(0xFFFEF3C7),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required String email,
    required String phone,
    required String deptName,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Faculty Information',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              if (email.isNotEmpty)
                _buildInfoRow(Icons.email_outlined, 'Email', email),
              if (deptName.isNotEmpty) ...[
                if (email.isNotEmpty) const Divider(height: 16),
                _buildInfoRow(Icons.business_outlined, 'Department', deptName),
              ],
              if (phone.isNotEmpty) ...[
                const Divider(height: 16),
                _buildInfoRow(Icons.phone_outlined, 'Phone', phone),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 10),
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCardsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'Total Points Awarded',
                value: '+$_totalPositivePoints pts',
                icon: Icons.add_circle_outline_rounded,
                bgColor: const Color(0xFFDCFCE7),
                borderColor: const Color(0xFFA7F3D0),
                textColor: const Color(0xFF15803D),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                title: 'Penalties Deducted',
                value: '-$_totalPenaltyPoints pts',
                icon: Icons.remove_circle_outline_rounded,
                bgColor: const Color(0xFFFEE2E2),
                borderColor: const Color(0xFFFECACA),
                textColor: const Color(0xFFDC2626),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'Students Impacted',
                value: '$_studentsImpacted Students',
                icon: Icons.people_alt_outlined,
                bgColor: const Color(0xFFEFF6FF),
                borderColor: const Color(0xFFBFDBFE),
                textColor: const Color(0xFF1D4ED8),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                title: 'Total Actions',
                value: '$_totalActions Logs',
                icon: Icons.history_rounded,
                bgColor: const Color(0xFFFAF5FF),
                borderColor: const Color(0xFFE9D5FF),
                textColor: const Color(0xFF7E22CE),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: textColor),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          onChanged: (val) => setState(() => _searchQuery = val),
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Search student name, Reg No, activity...',
            prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildFilterChip('ALL', 'All (${_historyList.length})'),
            const SizedBox(width: 8),
            _buildFilterChip('AWARDS', 'Awards (+)'),
            const SizedBox(width: 8),
            _buildFilterChip('DEDUCTIONS', 'Penalties (-)'),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip(String filterKey, String label) {
    final isSelected = _selectedFilter == filterKey;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filterKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    final filtered = _filteredHistory;

    if (filtered.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Icon(
              _searchQuery.isNotEmpty ? Icons.search_off_rounded : Icons.history_edu_rounded,
              size: 48,
              color: const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No matching points history found.'
                  : 'No points awarded by this teacher yet.',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
        final dynamic rawPts = item['points'];
        final int pts = rawPts is int ? rawPts : (int.tryParse(rawPts?.toString() ?? '0') ?? 0);
        final bool isPositive = pts >= 0;

        final bool isGroup = item['isGroup'] == true;
        final String teamName = item['teamName'] ?? 'Team Activity';
        final String dept = item['department'] ?? '';
        final String yr = item['year'] ?? '';
        final String sec = item['section'] ?? '';
        final int memberCount = item['memberCount'] is int
            ? item['memberCount']
            : (int.tryParse(item['memberCount']?.toString() ?? '1') ?? 1);

        final List<String> classParts = [];
        if (yr.isNotEmpty) classParts.add('Year $yr');
        if (dept.isNotEmpty) classParts.add(dept);
        if (sec.isNotEmpty) classParts.add('Sec $sec');
        final String classInfo = classParts.join(' • ');

        final String studentName = item['studentName'] ?? 'Student';
        final String studentRegNo = item['studentRegNo'] ?? '';
        final String reason = item['reason'] ?? 'Points Update';
        final String category = StringUtils.toTitleCase(
          (item['category'] ?? (isGroup ? 'Group Activity' : 'Activity')).toString(),
        );

        String dtStr = '';
        final rawDt = item['createdAt'];
        if (rawDt != null) {
          final s = rawDt.toString().replaceAll('T', ' ');
          dtStr = s.length >= 16 ? s.substring(0, 16) : s;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isGroup ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isGroup ? () => _showTeamMembersModal(context, item) : null,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Award/Penalty / Team Icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isGroup
                            ? (isPositive ? const Color(0xFFEFF6FF) : const Color(0xFFFEE2E2))
                            : (isPositive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2)),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isGroup
                            ? Icons.groups_rounded
                            : (isPositive ? Icons.add_rounded : Icons.remove_rounded),
                        color: isGroup
                            ? (isPositive ? const Color(0xFF2563EB) : const Color(0xFFDC2626))
                            : (isPositive ? const Color(0xFF16A34A) : const Color(0xFFDC2626)),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Details Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isGroup) ...[
                            Text(
                              teamName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (classInfo.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                classInfo,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2563EB),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ] else ...[
                            Text(
                              studentRegNo.isNotEmpty ? '$studentName ($studentRegNo)' : studentName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 2),
                          Text(
                            reason,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF475569),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (isGroup)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFDBEAFE)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.people_alt_rounded, size: 11, color: Color(0xFF1D4ED8)),
                                      const SizedBox(width: 3),
                                      Text(
                                        '$memberCount Members',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1D4ED8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (category.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    category,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ),
                              if (dtStr.isNotEmpty)
                                Text(
                                  dtStr,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Points Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: isPositive ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isPositive ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA),
                        ),
                      ),
                      child: Text(
                        isPositive ? '+$pts pts' : '$pts pts',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: isPositive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                          fontSize: 12,
                        ),
                      ),
                    ),

                    if (isGroup) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF94A3B8),
                        size: 20,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showTeamMembersModal(BuildContext context, Map<String, dynamic> item) {
    final String teamName = item['teamName'] ?? 'Team Activity';
    final String dept = item['department'] ?? '';
    final String yr = item['year'] ?? '';
    final String sec = item['section'] ?? '';
    final dynamic rawPts = item['points'];
    final int pts = rawPts is int ? rawPts : (int.tryParse(rawPts?.toString() ?? '0') ?? 0);
    final bool isPositive = pts >= 0;
    final String reason = item['reason'] ?? 'Points Update';
    final List<dynamic> members = item['members'] as List<dynamic>? ?? [];

    final List<String> classParts = [];
    if (yr.isNotEmpty) classParts.add('Year $yr');
    if (dept.isNotEmpty) classParts.add(dept);
    if (sec.isNotEmpty) classParts.add('Sec $sec');
    final String classInfo = classParts.join(' • ');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.groups_rounded, color: Color(0xFF2563EB), size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            teamName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          if (classInfo.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              classInfo,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            reason,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isPositive ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isPositive ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA),
                        ),
                      ),
                      child: Text(
                        isPositive ? '+$pts pts' : '$pts pts',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: isPositive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),

              // Title: Awarded Students List
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Awarded Students',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${members.length} Students',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Students ListView
              Expanded(
                child: members.isEmpty
                    ? const Center(
                        child: Text(
                          'No student details available for this team.',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                        itemCount: members.length,
                        separatorBuilder: (context, index) => const Divider(height: 12, color: Color(0xFFF1F5F9)),
                        itemBuilder: (ctx, idx) {
                          final member = members[idx] as Map<String, dynamic>;
                          final String mName = member['name'] ?? 'Student';
                          final String mReg = member['regNo'] ?? '';
                          final String mDept = member['dept'] ?? '';
                          final dynamic mRawPts = member['points'] ?? pts;
                          final int mPts = mRawPts is int
                              ? mRawPts
                              : (int.tryParse(mRawPts?.toString() ?? '0') ?? pts);

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                  ),
                                  child: Center(
                                    child: Text(
                                      mName.isNotEmpty ? mName[0].toUpperCase() : 'S',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF334155),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        mName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      if (mReg.isNotEmpty || mDept.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          mReg.isNotEmpty && mDept.isNotEmpty
                                              ? '$mReg • $mDept'
                                              : (mReg.isNotEmpty ? mReg : mDept),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isPositive ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isPositive ? '+$mPts pts' : '$mPts pts',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isPositive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
