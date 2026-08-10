import 'package:flutter/material.dart';
import 'package:pragatix/core/utils/error_handler.dart';
import 'package:pragatix/features/admin/repository/admin_repository.dart';
import 'package:intl/intl.dart';
import 'package:pragatix/features/activity/pages/stage_details_page.dart';
import 'package:pragatix/features/activity/pages/create_stage_page.dart';
import 'package:pragatix/features/activity/pages/edit_stage_page.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/features/activity/pages/global_activity_page.dart'
    as pragatix;

// ─────────────────────────────────────────────────────────────────────────────
// Activity Tab – Stage list with create / edit / delete.
// Tapping a stage navigates to StageDetailsPage → Subgroup → ActivityListPage.
// ─────────────────────────────────────────────────────────────────────────────

class AdminActivityManagementPage extends StatefulWidget {
  final String? selectedYear;
  const AdminActivityManagementPage({super.key, this.selectedYear});

  @override
  State<AdminActivityManagementPage> createState() =>
      _AdminActivityManagementPageState();
}

class _AdminActivityManagementPageState
    extends State<AdminActivityManagementPage> {
  List<dynamic> _stagesList = [];
  List<dynamic> _teachersList = [];
  bool _isLoading = true;

  static const Color _primary = Color(0xFFEA4335);
  static const Color _dark = Color(0xFF1E293B);

  @override
  void initState() {
    super.initState();
    _fetchStages();
    _fetchTeachers();
  }

  // ── API calls ─────────────────────────────────────────────────────────────

  Future<void> _fetchTeachers() async {
    try {
      final allUsers = await getIt<AdminRepository>().getUsers();
      if (!mounted) return;
      setState(() {
        _teachersList = allUsers.where((u) {
          final roles = u['roles'] as List<dynamic>? ?? [];
          return roles.contains('ROLE_TEACHER');
        }).toList();
      });
    } catch (_) {}
  }

  Future<void> _fetchStages() async {
    try {
      final stages = await getIt<AdminRepository>().getStages(
        academicYear: widget.selectedYear,
      );
      if (!mounted) return;
      setState(() {
        _stagesList = stages;
        _isLoading = false;
      });
      return;
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showSnackBar(context, e);
      setState(() {
        _stagesList = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteStage(int stageId) async {
    try {
      await getIt<AdminRepository>().deleteStage(stageId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stage deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() => _isLoading = true);
      _fetchStages();
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showSnackBar(context, e);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Activity & Thresholds',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: _dark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchStages();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      const Text(
                        'Configure Stages & Thresholds',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _dark,
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => pragatix.GlobalActivityPage(
                                    selectedYear: widget.selectedYear,
                                  ),
                                ),
                              ).then((value) {
                                setState(() => _isLoading = true);
                                _fetchStages();
                              });
                            },
                            icon: const Icon(
                              Icons.list_alt,
                              color: Colors.white,
                              size: 18,
                            ),
                            label: const Text(
                              'All Activities',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CreateStagePage(
                                    academicYear: widget.selectedYear,
                                  ),
                                ),
                              ).then((value) {
                                if (value == true) {
                                  setState(() => _isLoading = true);
                                  _fetchStages();
                                }
                              });
                            },
                            icon: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 18,
                            ),
                            label: const Text(
                              'Add Stage',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _stagesList.length,
                      itemBuilder: (context, index) {
                        final stage =
                            _stagesList[index] as Map<String, dynamic>;
                        final name = stage['name'] as String? ?? '';
                        final desc =
                            stage['description'] as String? ?? 'No description';
                        final String statusStr =
                            stage['status'] as String? ?? 'UPCOMING';
                        final displayOrder = stage['displayOrder'] ?? 0;
                        final expectedXp = stage['expectedXp'] ?? 0;
                        final mThresh = stage['mustThreshold'] ?? 0;
                        final iThresh = stage['individualThreshold'] ?? 0;
                        final gThresh = stage['groupThreshold'] ?? 0;

                        return Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          margin: const EdgeInsets.only(bottom: 20),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => StageDetailsPage(
                                    stageId: stage['id'] as int,
                                    stageName: name,
                                    stageDescription: desc,
                                    teachersList: _teachersList,
                                    selectedYear: widget.selectedYear,
                                  ),
                                ),
                              ).then((_) {
                                setState(() => _isLoading = true);
                                _fetchStages();
                              });
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              name,
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: _dark,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: statusStr == 'ACTIVE'
                                                    ? Colors.green.shade50
                                                    : Colors.grey.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                border: Border.all(
                                                  color: statusStr == 'ACTIVE'
                                                      ? Colors.green.shade300
                                                      : Colors.grey.shade400,
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                statusStr,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: statusStr == 'ACTIVE'
                                                      ? Colors.green.shade800
                                                      : (statusStr == 'UPCOMING'
                                                            ? Colors
                                                                  .blue
                                                                  .shade800
                                                            : Colors
                                                                  .grey
                                                                  .shade700),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          desc,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Wrap(
                                          spacing: 10,
                                          runSpacing: 6,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade200,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'Order: $displayOrder',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: _dark,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'XP: $expectedXp',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.blue.shade800,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.red.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'M: $mThresh',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.red.shade800,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'I: $iThresh',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.blue.shade800,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.green.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'G: $gThresh',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.green.shade800,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          color: Colors.blue,
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  EditStagePage(stage: stage),
                                            ),
                                          ).then((value) {
                                            if (value == true) {
                                              setState(() => _isLoading = true);
                                              _fetchStages();
                                            }
                                          });
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                        ),
                                        onPressed: () {
                                          showDialog<void>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text('Delete Stage'),
                                              content: Text(
                                                'Are you sure you want to delete $name and all its subgroups?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(ctx),
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(ctx);
                                                    _deleteStage(
                                                      stage['id'] as int,
                                                    );
                                                  },
                                                  child: const Text(
                                                    'Delete',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                      const Icon(
                                        Icons.chevron_right_rounded,
                                        color: Colors.grey,
                                      ),
                                    ],
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
