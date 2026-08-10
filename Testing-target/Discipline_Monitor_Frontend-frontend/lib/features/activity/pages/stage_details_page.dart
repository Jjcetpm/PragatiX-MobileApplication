import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/core/config/api_config.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pragatix/features/activity/services/activity_proxy_service.dart';
import 'package:pragatix/features/activity/pages/activity_list_page.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/core/utils/string_utils.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Stage Details Page – shows subgroup list for a given stage.
// Tapping a subgroup navigates to ActivityListPage.
// ─────────────────────────────────────────────────────────────────────────────

class StageDetailsPage extends StatefulWidget {
  final int stageId;
  final String stageName;
  final String stageDescription;
  final List<dynamic> teachersList;
  final String? selectedYear;

  const StageDetailsPage({
    super.key,
    required this.stageId,
    required this.stageName,
    required this.stageDescription,
    required this.teachersList,
    this.selectedYear,
  });

  @override
  State<StageDetailsPage> createState() => _StageDetailsPageState();
}

class _StageDetailsPageState extends State<StageDetailsPage> {
  List<dynamic> _subgroups = [];
  bool _isLoading = true;

  int _mustThreshold = 0;
  int _individualThreshold = 0;
  int _groupThreshold = 0;

  static const Color _primary = Color(0xFFEA4335);
  static const Color _dark = Color(0xFF1E293B);

  @override
  void initState() {
    super.initState();
    _fetchSubgroups();
  }

  Future<void> _fetchSubgroups() async {
    try {
      final response = await getIt<ActivityProxyService>().get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/admin/stages'),
        headers: {
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final stages = data['data'] as List<dynamic>? ?? [];
          final stage = stages.cast<Map<String, dynamic>?>().firstWhere(
            (s) => s?['id'] == widget.stageId,
            orElse: () => null,
          );
          if (stage != null) {
            setState(() {
              _mustThreshold = stage['mustThreshold'] ?? 0;
              _individualThreshold = stage['individualThreshold'] ?? 0;
              _groupThreshold = stage['groupThreshold'] ?? 0;

              List<dynamic> existingSubs =
                  stage['subgroups'] as List<dynamic>? ?? [];

              if (existingSubs.isNotEmpty) {
                final seenNames = <String>{};
                _subgroups = [];
                for (var s in existingSubs) {
                  final name = s['name'] as String;
                  if (!seenNames.contains(name.toLowerCase())) {
                    seenNames.add(name.toLowerCase());
                    _subgroups.add({
                      'id': s['id'],
                      'name': name,
                      'threshold': s['threshold'] ?? 0,
                      'category': s['category'] ?? name.toLowerCase(),
                    });
                  }
                }
              } else {
                // Fallback if no subgroups are in the database yet
                _subgroups = [
                  {
                    'id': 1,
                    'name': 'Must',
                    'threshold': _mustThreshold,
                    'category': 'must',
                  },
                  {
                    'id': 2,
                    'name': 'Individual',
                    'threshold': _individualThreshold,
                    'category': 'individual',
                  },
                  {
                    'id': 3,
                    'name': 'Group',
                    'threshold': _groupThreshold,
                    'category': 'group',
                  },
                ];
              }
              _isLoading = false;
            });
            return;
          }
        }
      }
    } catch (_) {}
    setState(() {
      if (_subgroups.isEmpty) {
        _subgroups = [
          {'id': 1, 'name': 'Must', 'threshold': 0, 'category': 'must'},
          {
            'id': 2,
            'name': 'Individual',
            'threshold': 0,
            'category': 'individual',
          },
          {'id': 3, 'name': 'Group', 'threshold': 0, 'category': 'group'},
        ];
      }
      _isLoading = false;
    });
  }

  String _getCleanName(String fullName) {
    return StringUtils.toTitleCase(fullName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          widget.stageName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: _dark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Stage header card ────────────────────────────────────
                  Card(
                    elevation: 1.5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.stageName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _dark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.stageDescription,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const Divider(height: 30),
                          const Text(
                            "Stage Progression Thresholds",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _dark,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _ThresholdCard(
                                  title: 'Must',
                                  value: _mustThreshold,
                                  color: Colors.red,
                                  icon: Icons.star,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _ThresholdCard(
                                  title: 'Individual',
                                  value: _individualThreshold,
                                  color: Colors.blue,
                                  icon: Icons.person,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _ThresholdCard(
                            title: 'Group',
                            value: _groupThreshold,
                            color: Colors.green,
                            icon: Icons.group,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Activity Categories',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _dark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // ── Subgroup list ─────────────────────────────────────────
                  Expanded(
                    child: _subgroups.isEmpty
                        ? Center(
                            child: Text(
                              'No activity categories available.',
                              style: TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _subgroups.length,
                            itemBuilder: (context, index) {
                              final sub =
                                  _subgroups[index] as Map<String, dynamic>;
                              final subName = sub['name'] as String? ?? '';
                              final catVal = sub['category'] as String? ?? '';

                              return Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                margin: const EdgeInsets.only(bottom: 12),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ActivityListPage(
                                          subgroupId: sub['id'] as int,
                                          stageId: widget.stageId,
                                          subgroupName: subName,
                                          subgroupCategory: catVal,
                                          teachersList: widget.teachersList,
                                          isAdmin: true,
                                          academicYear: widget.selectedYear,
                                        ),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                      horizontal: 16,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          catVal == 'must'
                                              ? Icons.star_border
                                              : (catVal == 'group'
                                                    ? Icons.groups_outlined
                                                    : Icons.person_outline),
                                          color: _dark,
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Text(
                                            _getCleanName(subName),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
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
            ),
    );
  }
}

class _ThresholdCard extends StatelessWidget {
  final String title;
  final int value;
  final Color color;
  final IconData icon;

  const _ThresholdCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$value XP',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
