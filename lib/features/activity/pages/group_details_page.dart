import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/core/widgets/pragatix_loader.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:pragatix/features/activity/services/activity_proxy_service.dart';
import 'dart:convert';
import 'package:pragatix/core/config/api_config.dart';
import 'package:pragatix/features/team/models/team.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/features/activity/models/execution_student_model.dart';
import 'package:pragatix/features/team/widgets/team_member_card.dart';

class GroupDetailsPage extends StatefulWidget {
  final Team team;
  final ActivityExecutionDetailModel activity;

  const GroupDetailsPage({
    super.key,
    required this.team,
    required this.activity,
  });

  @override
  State<GroupDetailsPage> createState() => _GroupDetailsPageState();
}

class _GroupDetailsPageState extends State<GroupDetailsPage> {
  late Team _team;
  bool _isLoading = false;

  // Theme constants
  static const Color _primary = Color(0xFF1E3A8A);
  static const Color _dark = Color(0xFF0F172A);
  static const Color _bg = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _team = widget.team;
  }

  Future<void> _refreshTeam() async {
    setState(() => _isLoading = true);
    try {
      final response = await getIt<ActivityProxyService>().get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/teams'),
        headers: {
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final teamsList = (data['data'] as List?) ?? [];
        final updatedTeamData = teamsList.firstWhere(
          (t) => t['id'] == _team.id,
          orElse: () => null,
        );
        if (updatedTeamData != null) {
          setState(() {
            _team = Team.fromJson(updatedTeamData);
          });
        }
      }
    } catch (e) {
      // ignore
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addMember(String regNo) async {
    try {
      final response = await getIt<ActivityProxyService>().post(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/v1/teams/${_team.id}/add-member?regNo=$regNo',
        ),
        headers: {
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
        },
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Member added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        await _refreshTeam();
      } else {
        _showError(data['message'] ?? 'Failed to add member');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  Future<void> _removeMember(String regNo) async {
    try {
      final response = await getIt<ActivityProxyService>().post(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/v1/teams/${_team.id}/remove-member?regNo=$regNo',
        ),
        headers: {
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
        },
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Member removed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        await _refreshTeam();
      } else {
        _showError(data['message'] ?? 'Failed to remove member');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  Future<void> _awardXp(String remarks, bool isPenalty) async {
    final xp = isPenalty ? widget.activity.penaltyXp : widget.activity.awardXp;
    print('GROUP XP API METHOD CALLED\nAction: ${isPenalty ? "PENALTY" : "AWARD"}\nTeam ID: ${_team.id}\nXP: $xp');
    final requestBody = jsonEncode({
      'assignmentId': _team.assignmentId ?? widget.activity.id,
      'equalDistribution': true,
      'xp': xp,
      'remarks': remarks,
      'isPenalty': isPenalty,
    });
    
    print('GROUP XP HTTP REQUEST\nURL: ${ApiConfig.baseUrl}/api/v1/group-activities/teams/${_team.id}/award-xp\nMethod: POST\nBody: $requestBody');
    try {
      final response = await getIt<ActivityProxyService>().post(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/v1/group-activities/teams/${_team.id}/award-xp',
        ),
        headers: {
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
          'Content-Type': 'application/json',
        },
        body: requestBody,
      );
      print('GROUP XP HTTP RESPONSE\nStatus: ${response.statusCode}\nBody: ${response.body}');
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isPenalty ? 'XP deducted from group successfully!' : 'XP awarded to group successfully!'),
            backgroundColor: isPenalty ? Colors.red : Colors.green,
          ),
        );
        await _refreshTeam();
        if (mounted) Navigator.pop(context, true); // Close and return to list
      } else {
        _showError(data['message'] ?? 'Failed to award XP');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  void _showAddMemberDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Member'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Student ID (e.g. 24CS01)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final id = ctrl.text.trim();
              if (id.isNotEmpty) {
                Navigator.pop(ctx);
                _addMember(id);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAwardXpDialog(bool isPenalty) {
    print('GROUP ${isPenalty ? "PENALTY" : "AWARD"} BUTTON CLICKED');
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isPenalty ? 'Penalty for Group' : 'Award XP to Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isPenalty 
                ? 'Deduct ${widget.activity.penaltyXp} XP from every member of this group?'
                : 'Award ${widget.activity.awardXp} XP to every member of this group?',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                labelText: 'Remarks (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isPenalty ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              print('GROUP ACTION VALIDATION\nAction: ${isPenalty ? "PENALTY" : "AWARD"}\nTeam ID: ${_team.id}\nValidation Result: PASS');
              _awardXp(ctrl.text.trim(), isPenalty);
            },
            child: Text(isPenalty ? 'Confirm Penalty' : 'Confirm Award'),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final members = _team.members ?? [];
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Group Details'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: PragatiXLoader())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(),
                  const SizedBox(height: 24),
                  const Text(
                    'Captain',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: _dark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_team.captainId != null)
                    ...members
                        .where((m) => m['regNo'] == _team.captainId)
                        .map(
                          (m) => TeamMemberCard(
                            member: m,
                            captainId: _team.captainId,
                            canManage: true,
                            isCaptainRoleSection: true,
                            onRemove: () {},
                          ),
                        )
                  else
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No captain assigned.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Members (${members.length}/${_team.size})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: _dark,
                        ),
                      ),
                      if (members.length < _team.size)
                        TextButton.icon(
                          onPressed: _showAddMemberDialog,
                          icon: const Icon(Icons.person_add),
                          label: const Text('Add Member'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (members
                      .where((m) => m['regNo'] != _team.captainId)
                      .isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          'No additional members found.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ...members
                        .where((m) => m['regNo'] != _team.captainId)
                        .map(
                          (m) => TeamMemberCard(
                            member: m,
                            captainId: _team.captainId,
                            canManage: true,
                            isCaptainRoleSection: false,
                            onRemove: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Remove Member'),
                                  content: Text(
                                    "Are you sure you want to remove ${m['fullName']} from the group?",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        _removeMember(m['regNo']);
                                      },
                                      child: const Text(
                                        'Remove',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                  const SizedBox(height: 32),
                  if (widget.activity.awardEnabled && widget.activity.penaltyEnabled)
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _team.isAwarded == true
                                    ? Colors.grey
                                    : Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _team.isAwarded == true
                                  ? null
                                  : () => _showAwardXpDialog(false),
                              child: Text(
                                _team.isAwarded == true
                                    ? 'Completed'
                                    : 'Award XP',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _team.isAwarded == true
                                    ? Colors.grey
                                    : Colors.red,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _team.isAwarded == true
                                  ? null
                                  : () => _showAwardXpDialog(true),
                              child: Text(
                                _team.isAwarded == true
                                    ? 'Completed'
                                    : 'Penalty',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _team.isAwarded == true
                              ? Colors.grey
                              : (widget.activity.penaltyEnabled ? Colors.red : Colors.green),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _team.isAwarded == true
                            ? null
                            : () => _showAwardXpDialog(widget.activity.penaltyEnabled),
                        child: Text(
                          _team.isAwarded == true
                              ? (widget.activity.penaltyEnabled ? 'XP Already Deducted' : 'XP Already Awarded')
                              : (widget.activity.penaltyEnabled ? 'Deduct XP from Group' : 'Award XP to Group'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _team.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: _primary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem('Captain', _team.captainName ?? 'None'),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Status',
                    _team.isAwarded == true ? 'Completed' : 'Pending',
                  ),
                ),
              ],
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
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: _dark,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
