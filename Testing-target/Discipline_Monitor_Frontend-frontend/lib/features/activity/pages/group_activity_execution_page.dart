import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

import 'package:pragatix/features/team/models/team.dart';
import 'package:pragatix/features/activity/services/group_activity_service.dart';
import 'package:pragatix/features/activity/models/execution_student_model.dart';
import 'package:pragatix/features/activity/services/activity_service.dart';
import 'package:pragatix/features/activity/pages/create_group_page.dart';
import 'package:pragatix/features/activity/pages/group_details_page.dart';

class GroupActivityExecutionPage extends StatefulWidget {
  final int activityId;
  final dynamic selectedYear;
  final dynamic selectedDept;
  final dynamic selectedSection;
  final int? stageId;

  const GroupActivityExecutionPage({
    super.key,
    required this.activityId,
    required this.selectedYear,
    required this.selectedDept,
    this.selectedSection,
    this.stageId,
  });

  @override
  State<GroupActivityExecutionPage> createState() =>
      _GroupActivityExecutionPageState();
}

class _GroupActivityExecutionPageState
    extends State<GroupActivityExecutionPage> {
  late final ActivityService _activityService;
  late final GroupActivityService _groupService;

  // Groups Data
  bool _isLoadingGroups = true;
  String? _errorMessage;
  MyActivityStudentsResponseModel? _data;
  List<Team> _teams = [];

  // Theme constants
  static const Color _primary = Color(0xFF1E3A8A); // Deep blue
  static const Color _accent = Color(0xFF3B82F6);
  static const Color _dark = Color(0xFF0F172A);
  static const Color _bg = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _activityService = ActivityService(context.read<AuthProvider>());
    _groupService = GroupActivityService(context.read<AuthProvider>());
    _loadGroupsForScope();
  }

  Future<void> _loadGroupsForScope() async {
    setState(() {
      _isLoadingGroups = true;
      _errorMessage = null;
    });

    try {
      String yearParam = 'I';
      if (widget.selectedYear != null) {
        final yearNo = widget.selectedYear['yearNo'];
        if (yearNo == 2) yearParam = 'II';
        if (yearNo == 3) yearParam = 'III';
        if (yearNo == 4) yearParam = 'IV';
      }

      final int? deptId = widget.selectedDept != null
          ? widget.selectedDept['id']
          : null;
      final int? secId = widget.selectedSection != null
          ? widget.selectedSection['id']
          : null;

      // 1. Fetch the activity details and get the specific assignment for this scope
      final actData = await _activityService.fetchExecutionStudents(
        widget.activityId,
        year: yearParam,
        departmentId: deptId,
        sectionId: secId,
        stageId: widget.stageId,
      );
      final model = MyActivityStudentsResponseModel.fromJson(actData);

      // 2. Fetch the groups for this specific assignment
      final teams = await _groupService.getTeamsForAssignment(
        model.assignment.id,
        stageId: widget.stageId,
      );

      setState(() {
        _data = model;
        _teams = teams;
        _isLoadingGroups = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoadingGroups = false;
      });
    }
  }

  Future<void> _deleteTeam(Team team) async {
    final bool confirm =
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Group?'),
            content: const Text(
              'Are you sure you want to delete this group?\n\nThis action will permanently remove the group and its member mappings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    setState(() => _isLoadingGroups = true);
    try {
      await _groupService.deleteTeam(team.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group deleted successfully')),
      );
      _loadGroupsForScope();
    } catch (e) {
      setState(() => _isLoadingGroups = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _navigateToCreateGroup() async {
    if (_data == null) return;

    String yearParam = 'I';
    if (widget.selectedYear != null) {
      final yearNo = widget.selectedYear['yearNo'];
      if (yearNo == 2) yearParam = 'II';
      if (yearNo == 3) yearParam = 'III';
      if (yearNo == 4) yearParam = 'IV';
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateGroupPage(
          assignmentId: _data!.assignment.id,
          preselectedYear: yearParam,
          preselectedDept: widget.selectedDept != null
              ? (widget.selectedDept['name'] ??
                    widget.selectedDept['departmentName'])
              : null,
          preselectedSection: widget.selectedSection != null
              ? widget.selectedSection['sectionName']
              : null,
        ),
      ),
    );

    if (result == true) {
      _loadGroupsForScope();
    }
  }

  void _navigateToGroupDetails(Team team) async {
    if (_data == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            GroupDetailsPage(team: team, xpPerMember: _data!.activity.awardXp),
      ),
    );

    if (result == true) {
      _loadGroupsForScope();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Groups'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoadingGroups
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorView()
          : _buildGroupsListStep(),
      floatingActionButton: null,
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _dark,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadGroupsForScope,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupsListStep() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildActivityHeaderCard()),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                const Text(
                  'Existing Groups',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: _dark,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_teams.length} Teams',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_teams.isEmpty)
          SliverFillRemaining(hasScrollBody: false, child: _buildEmptyState())
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((ctx, index) {
                return _buildTeamCard(_teams[index]);
              }, childCount: _teams.length),
            ),
          ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 100), // spacer for FAB
        ),
      ],
    );
  }

  Widget _buildActivityHeaderCard() {
    final act = _data!.activity;
    final assign = _data!.assignment;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              act.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: _dark,
              ),
            ),
            const Divider(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final double itemWidth = (constraints.maxWidth - 16) / 2;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildDetailItem(
                      'Category',
                      act.xpCategory.isNotEmpty ? act.xpCategory : 'N/A',
                      itemWidth,
                    ),
                    _buildDetailItem(
                      'Award XP',
                      act.awardEnabled ? '+${act.awardXp} XP' : 'Disabled',
                      itemWidth,
                    ),
                    _buildDetailItem(
                      'Penalty',
                      act.penaltyEnabled ? '-${act.penaltyXp} XP' : 'Disabled',
                      itemWidth,
                    ),
                    _buildDetailItem(
                      'Frequency',
                      act.frequency.isNotEmpty ? act.frequency : 'N/A',
                      itemWidth,
                    ),
                    _buildDetailItem('Cap', act.cap.toString(), itemWidth),
                    _buildDetailItem(
                      'Evidence',
                      act.evidence.isNotEmpty
                          ? act.displayEvidence.join(', ')
                          : 'None',
                      itemWidth,
                    ),
                    _buildDetailItem('Activity Type', act.type, itemWidth),
                    _buildDetailItem(
                      'Assigned Faculty',
                      assign.assignedFacultyName,
                      itemWidth,
                    ),
                    _buildDetailItem(
                      'Assignment Mode',
                      assign.assignmentMode,
                      itemWidth,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, double width) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _dark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCard(Team team) {
    final int memberCount = team.members?.length ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.groups, color: _accent, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    team.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: _dark,
                    ),
                  ),
                ),
                if (team.canDelete)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Delete Group',
                    onPressed: () => _deleteTeam(team),
                  ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem('Captain', team.captainName ?? 'None'),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Members',
                    '$memberCount / ${team.size}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Faculty',
                    _data!.assignment.assignedFacultyName,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Status',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: team.isAwarded == true
                              ? Colors.green.shade50
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          team.isAwarded == true ? 'Completed' : 'Active',
                          style: TextStyle(
                            color: team.isAwarded == true
                                ? Colors.green.shade700
                                : Colors.orange.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _navigateToGroupDetails(team),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _accent,
                  side: const BorderSide(color: _accent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: _dark,
            fontSize: 13,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final String yearName = widget.selectedYear != null
        ? widget.selectedYear['yearName']
        : '';
    final String deptName = widget.selectedDept != null
        ? (widget.selectedDept['name'] ?? widget.selectedDept['departmentName'])
        : '';
    final String secName = widget.selectedSection != null
        ? widget.selectedSection['sectionName']
        : '';
    String scopeString = '$yearName / $deptName';
    if (widget.selectedSection != null) scopeString += ' / $secName';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No Groups Created Yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'No groups have been created for $scopeString.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );
  }
}
