import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:pragatix/core/config/api_config.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/features/team/services/team_proxy_service.dart';

class StudentTeamDetailsPage extends StatefulWidget {
  const StudentTeamDetailsPage({super.key});

  @override
  State<StudentTeamDetailsPage> createState() => _StudentTeamDetailsPageState();
}

class _StudentTeamDetailsPageState extends State<StudentTeamDetailsPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _teamData;
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
        Uri.parse('${ApiConfig.baseUrl}/api/v1/teams/my-team/details'),
        headers: {
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            _teamData = data['data'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Failed to load team details';
            _isLoading = false;
          });
        }
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

  Widget _buildHeaderCard() {
    final currentMembers =
        _teamData!['currentMemberCount'] ??
        (_teamData!['members'] as List?)?.length ??
        0;
    final maxMembers = _teamData!['maxTeamSize'] ?? 10;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade800, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _teamData!['teamName'] ?? 'Team Name',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_teamData!['stage'] ?? 'Stage 1'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChip(Icons.domain, _teamData!['department'] ?? 'N/A'),
              _buildChip(
                Icons.class_,
                'Sec: ${_teamData!['section'] ?? 'N/A'}',
              ),
              _buildChip(
                Icons.calendar_today,
                _teamData!['academicYear'] ?? 'N/A',
              ),
              _buildChip(Icons.book, _teamData!['semester'] ?? 'N/A'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildHeaderInfoItem(
                Icons.star,
                '${_teamData!['totalTeamXp'] ?? 0} XP',
                'Total Team XP',
              ),
              _buildHeaderInfoItem(
                Icons.group,
                '$currentMembers / $maxMembers',
                'Members',
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white30),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildRoleInfo(
                  'Captain',
                  _teamData!['captainName'] ?? 'N/A',
                ),
              ),
              Expanded(
                child: _buildRoleInfo(
                  'Vice Captain',
                  _teamData!['viceCaptainName'] ?? 'N/A',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderInfoItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildRoleInfo(String role, String name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(role, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 2),
        Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardCard(Map<String, dynamic> member) {
    final rank = member['rankInsideTeam'] as int? ?? 0;

    Color backgroundColor = Colors.white;
    Color rankColor = Colors.grey;
    IconData? rankIcon;

    if (rank == 1) {
      backgroundColor = Colors.amber.shade50;
      rankColor = Colors.amber.shade700;
      rankIcon = Icons.emoji_events;
    } else if (rank == 2) {
      backgroundColor = Colors.grey.shade100;
      rankColor = Colors.grey.shade600;
      rankIcon = Icons.military_tech;
    } else if (rank == 3) {
      backgroundColor = Colors.orange.shade50;
      rankColor = Colors.orange.shade800;
      rankIcon = Icons.military_tech;
    }

    return Card(
      elevation: rank <= 3 ? 4 : 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: rankColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: rankIcon != null
                  ? Icon(rankIcon, color: rankColor, size: 24)
                  : Text(
                      '#$rank',
                      style: TextStyle(
                        color: rankColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(
                (member['studentName'] as String?)?.isNotEmpty == true
                    ? member['studentName'].toString()[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: Colors.blue.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (member['teamRole'] == 'CAPTAIN')
                        const Text('👑 ', style: TextStyle(fontSize: 16)),
                      if (member['teamRole'] == 'VICE_CAPTAIN')
                        const Text('🥈 ', style: TextStyle(fontSize: 16)),
                      Expanded(
                        child: Text(
                          member['studentName'] ?? 'Unknown',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: member['teamRole'] == 'CAPTAIN'
                              ? Colors.amber.withValues(alpha: 0.1)
                              : (member['teamRole'] == 'VICE_CAPTAIN'
                                    ? Colors.grey.withValues(alpha: 0.2)
                                    : Colors.blue.withValues(alpha: 0.1)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          member['teamRole']?.toString().replaceAll('_', ' ') ??
                              'MEMBER',
                          style: TextStyle(
                            color: member['teamRole'] == 'CAPTAIN'
                                ? Colors.amber.shade800
                                : (member['teamRole'] == 'VICE_CAPTAIN'
                                      ? Colors.grey.shade800
                                      : Colors.blue.shade800),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${member['currentStage'] ?? 'Stage 1'} - ${member['currentLevel'] ?? 'Explorer'}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${member['totalXp'] ?? 0}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Team Leaderboard'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            )
          : _teamData == null
          ? const Center(child: Text('No team data found'))
          : RefreshIndicator(
              onRefresh: _fetchTeamDetails,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeaderCard(),
                  const SizedBox(height: 24),
                  const Text(
                    'Team Leaderboard',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (_teamData!['members'] != null)
                    ...(_teamData!['members'] as List).map(
                      (m) => _buildLeaderboardCard(m as Map<String, dynamic>),
                    ),
                ],
              ),
            ),
    );
  }
}
