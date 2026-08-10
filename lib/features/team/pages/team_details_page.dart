import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:pragatix/core/config/api_config.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/features/team/models/team.dart';
import 'package:pragatix/features/team/services/team_proxy_service.dart';
import 'package:pragatix/features/team/widgets/team_member_card.dart';
import 'package:pragatix/features/team/widgets/student_search_dialog.dart';


class TeamDetailsPage extends StatefulWidget {
  final int teamId;
  final bool canManage;

  const TeamDetailsPage({
    super.key,
    required this.teamId,
    this.canManage = false,
  });

  @override
  State<TeamDetailsPage> createState() => _TeamDetailsPageState();
}

class _TeamDetailsPageState extends State<TeamDetailsPage> {
  bool _isLoading = true;
  Team? _team;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchTeamDetails();
  }

  Future<void> _fetchTeamDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await getIt<TeamProxyService>().get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/teams/${widget.teamId}'),
        headers: {
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            _team = Team.fromJson(data['data']);
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Failed to load team details';
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 403) {
        setState(() {
          _errorMessage =
              'Access Denied: You do not have permission to view this team.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              'Failed to load team details. Status: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading team: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _addMember(String regNo) async {
    try {
      final response = await getIt<TeamProxyService>().post(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/v1/teams/${widget.teamId}/add-member?regNo=$regNo',
        ),
        headers: {
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
        },
      );
      final data = jsonDecode(response.body);
      if (!mounted) return;
      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Member added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchTeamDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Failed to add member'),
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

  Future<void> _removeMember(String regNo) async {
    try {
      final response = await getIt<TeamProxyService>().post(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/v1/teams/${widget.teamId}/remove-member?regNo=$regNo',
        ),
        headers: {
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
        },
      );
      final data = jsonDecode(response.body);
      if (!mounted) return;
      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Member removed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchTeamDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Failed to remove member'),
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

  Future<void> _changeCaptain(String regNo) async {
    try {
      final response = await getIt<TeamProxyService>().put(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/v1/teams/${widget.teamId}/captain?regNo=$regNo',
        ),
        headers: {
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
        },
      );
      final data = jsonDecode(response.body);
      if (!mounted) return;
      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Captain changed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchTeamDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Failed to change captain'),
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

  Future<void> _changeViceCaptain(String regNo) async {
    try {
      final response = await getIt<TeamProxyService>().put(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/v1/teams/${widget.teamId}/vice-captain?regNo=$regNo',
        ),
        headers: {
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
        },
      );
      final data = jsonDecode(response.body);
      if (!mounted) return;
      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vice Captain assigned successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchTeamDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Failed to assign vice captain'),
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

  Future<void> _removeViceCaptain() async {
    try {
      final response = await getIt<TeamProxyService>().delete(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/v1/teams/${widget.teamId}/vice-captain',
        ),
        headers: {
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
        },
      );
      final data = jsonDecode(response.body);
      if (!mounted) return;
      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vice Captain removed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchTeamDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Failed to remove vice captain'),
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

  Future<void> _updateTeam(String name, int limit) async {
    try {
      final response = await getIt<TeamProxyService>().put(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/teams/${widget.teamId}'),
        headers: {
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'name': name, 'size': limit}),
      );
      final data = jsonDecode(response.body);
      if (!mounted) return;
      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Team updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchTeamDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Failed to update team'),
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

  Future<void> _deleteTeam() async {
    try {
      final response = await getIt<TeamProxyService>().delete(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/teams/${widget.teamId}'),
        headers: {
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
        },
      );
      final data = jsonDecode(response.body);
      if (!mounted) return;
      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Team deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Pop back to groups list, signal refresh
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Failed to delete team'),
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

  void _showAddMemberDialog() async {
    final regNo = await showDialog<String>(
      context: context,
      builder: (ctx) => StudentSearchDialog(
        currentTeamId: widget.teamId,
        currentStage: _team?.currentStage ?? 1,
      ),
    );
    if (regNo != null && regNo.isNotEmpty) {
      _addMember(regNo);
    }
  }

  void _showEditTeamDialog() {
    final nameCtrl = TextEditingController(text: _team!.name);
    final limitCtrl = TextEditingController(text: _team!.size.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Team'),
        content: Column(
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final limit = int.tryParse(limitCtrl.text);
              if (name.isEmpty || limit == null || limit <= 0) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Invalid input')));
                return;
              }
              Navigator.pop(ctx);
              _updateTeam(name, limit);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showChangeCaptainDialog() {
    final members = _team!.members ?? [];
    if (members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No members in team to promote')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Captain'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: members.length,
            itemBuilder: (ctx, index) {
              final m = members[index];
              return ListTile(
                title: Text(m['fullName'] ?? 'Student'),
                subtitle: Text(m['regNo'] ?? ''),
                onTap: () {
                  Navigator.pop(ctx);
                  _changeCaptain(m['regNo']);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showChangeViceCaptainDialog() {
    final members = _team!.members ?? [];
    if (members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No members in team to promote')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Vice Captain'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: members.length,
            itemBuilder: (ctx, index) {
              final m = members[index];
              return ListTile(
                title: Text(m['fullName'] ?? 'Student'),
                subtitle: Text(m['regNo'] ?? ''),
                onTap: () {
                  Navigator.pop(ctx);
                  _changeViceCaptain(m['regNo']);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }


  void _showDeleteTeamDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Team'),
        content: Text(
          'Are you sure you want to delete the team "${_team!.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteTeam();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Team Details'),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Team Details'),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
        ),
        body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _fetchTeamDetails,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
      );
    }

    final members = _team!.members ?? [];
    final currentStage = _team!.currentStage;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Team Details'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchTeamDetails,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(currentStage, members.length),
            if (widget.canManage) ...[
              const SizedBox(height: 24),
              const Text(
                'Management Actions',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: _showAddMemberDialog,
                    icon: const Icon(Icons.person_add, size: 18),
                    label: const Text('Add Member'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade50,
                      foregroundColor: Colors.green.shade700,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showEditTeamDialog,
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit Team'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade50,
                      foregroundColor: Colors.indigo,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showChangeCaptainDialog,
                    icon: const Icon(Icons.star, size: 18),
                    label: const Text('Change Captain'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade50,
                      foregroundColor: Colors.amber.shade800,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showChangeViceCaptainDialog,
                    icon: const Icon(Icons.shield, size: 18),
                    label: const Text('Change Vice Captain'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey.shade50,
                      foregroundColor: Colors.blueGrey,
                    ),
                  ),
                  if (_team!.viceCaptainId != null)
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Remove Vice Captain'),
                            content: const Text(
                              'Are you sure you want to remove the vice captain?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _removeViceCaptain();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text('Remove'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.remove_moderator, size: 18),
                      label: const Text('Remove Vice Captain'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ElevatedButton.icon(
                    onPressed: _showDeleteTeamDialog,
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Delete Team'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Team Members (${members.length}/${_team!.size})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (members.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    'No members in this team',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...members.map(
                (m) => TeamMemberCard(
                  member: m,
                  captainId: _team!.captainId,
                  canManage: widget.canManage,
                  onRemove: () => _removeMember(m['regNo']),
                  onChangeCaptainRequest: members.length == 1
                      ? null
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Cannot remove Captain. Please change the captain first.',
                              ),
                            ),
                          );
                          _showChangeCaptainDialog();
                        },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(int stage, int memberCount) {
    String getVal(String? val) =>
        (val == null || val.trim().isEmpty) ? '-' : val;

    String? vcName;
    if (_team?.members != null) {
      for (var m in _team!.members!) {
        if (m['teamRole'] == 'VICE_CAPTAIN') {
          vcName = m['fullName'];
          break;
        }
      }
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _team!.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: Colors.indigo,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Level $stage',
                    style: TextStyle(
                      color: Colors.amber.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildInfoItem('Captain', getVal(_team!.captainName)),
                ),
                Expanded(child: _buildInfoItem('Vice Captain', getVal(vcName))),
                Expanded(
                  child: _buildInfoItem(
                    'Members',
                    '$memberCount / ${_team!.size}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Department',
                    getVal(_team!.departmentName),
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Academic Year',
                    getVal(_team!.academicYear),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildInfoItem('Year', getVal(_team!.yearName)),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Semester',
                    getVal(_team!.semesterName),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildInfoItem('Section', getVal(_team!.sectionName)),
                ),
                const Expanded(child: SizedBox()),
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
            color: Color(0xFF0F172A),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
