import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/core/config/api_config.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pragatix/core/utils/error_handler.dart';
import 'package:pragatix/features/teacher/services/teacher_proxy_service.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/core/utils/string_utils.dart';

part 'teacher_student_detail_dialogs.dart';

class TeacherStudentDetail extends StatefulWidget {
  final Map<String, dynamic> student;
  const TeacherStudentDetail({super.key, required this.student});

  @override
  State<TeacherStudentDetail> createState() => _TeacherStudentDetailState();
}

class _TeacherStudentDetailState extends State<TeacherStudentDetail> {
  int currentScore = 0;
  List<dynamic> historyLogs = [];
  List<dynamic> stagesList = [];
  bool isLoadingHistory = true;
  bool isCurrentlyCaptain = false;

  @override
  void initState() {
    super.initState();
    currentScore = widget.student['score'] ?? 100;
    isCurrentlyCaptain =
        widget.student['teamRole'] == 'CAPTAIN' ||
        widget.student['teamRole'] == 'VICE_CAPTAIN';
    _fetchHistoryLogs();
    _fetchStages();
  }

  Future<void> _fetchHistoryLogs() async {
    try {
      final response = await getIt<TeacherProxyService>().get(
        Uri.parse(
          "${ApiConfig.baseUrl}/api/v1/students/${widget.student['id']}/discipline-logs",
        ),
        headers: {
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            historyLogs = data['data'] ?? [];
            isLoadingHistory = false;
          });
          return;
        }
      }
    } catch (e) {
      // Catch
    }
    setState(() {
      isLoadingHistory = false;
    });
  }

  Future<void> _fetchStages() async {
    try {
      final response = await getIt<TeacherProxyService>().get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/admin/stages'),
        headers: {
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            stagesList = data['data'] ?? [];
          });
        }
      }
    } catch (e) {
      // Catch
    }
  }

  Future<void> _makeCaptain() async {
    try {
      final response = await getIt<TeacherProxyService>().post(
        Uri.parse(
          "${ApiConfig.baseUrl}/api/v1/students/${widget.student['id']}/make-captain",
        ),
        headers: {
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() {
          isCurrentlyCaptain = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student successfully promoted to Captain!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to promote: ${jsonDecode(response.body)['message'] ?? response.statusCode}',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showSnackBar(context, e);
    }
  }

  Future<void> _removeCaptain() async {
    try {
      final response = await getIt<TeacherProxyService>().post(
        Uri.parse(
          "${ApiConfig.baseUrl}/api/v1/students/${widget.student['id']}/remove-captain",
        ),
        headers: {
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() {
          isCurrentlyCaptain = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student successfully removed from Captain status!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to remove: ${jsonDecode(response.body)['message'] ?? response.statusCode}',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showSnackBar(context, e);
    }
  }

  Future<void> _changeScore(int points, String reason, int? subgroupId) async {
    try {
      final response = await getIt<TeacherProxyService>().post(
        Uri.parse(
          "${ApiConfig.baseUrl}/api/v1/students/${widget.student['id']}/adjust-points",
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
        },
        body: jsonEncode({
          'points': points,
          'reason': reason,
          'subgroupId': subgroupId,
        }),
      );

      final data = jsonDecode(response.body);
      if (!mounted) return;
      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          currentScore = data['data']['score'] ?? currentScore;
          isLoadingHistory = true;
        });
        _fetchHistoryLogs();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${points > 0 ? "Added" : "Deducted"} $points points successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Failed to adjust points'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showSnackBar(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        child: Icon(Icons.person, size: 60),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.student['name'] ?? '',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text("Reg No: ${widget.student['regNo'] ?? ''}"),
                      Text("Department: ${widget.student['dept'] ?? ''}"),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            if (widget.student['guardian'] != null) ...[
              const Text(
                'Guardian Information',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.person,
                          color: Colors.blueGrey,
                        ),
                        title: Text(
                          widget.student['guardian']['guardianName'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          widget.student['guardian']['relationship'] ??
                              'Guardian',
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.phone,
                          color: Colors.blueGrey,
                        ),
                        title: Text(
                          widget.student['guardian']['phoneNo'] ?? 'No Phone',
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (widget.student['guardian']['email'] != null &&
                          widget.student['guardian']['email']
                              .toString()
                              .isNotEmpty) ...[
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(
                            Icons.email,
                            color: Colors.blueGrey,
                          ),
                          title: Text(
                            widget.student['guardian']['email'] ?? '',
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],

            Center(
              child: Column(
                children: [
                  const Text(
                    'Current Discipline Score',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$currentScore',
                    style: const TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text('Points', style: TextStyle(fontSize: 18)),
                ],
              ),
            ),

            const SizedBox(height: 40),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showAddPointsSheet,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Points'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 207, 212, 207),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showDeductPointsSheet,
                    icon: const Icon(Icons.remove),
                    label: const Text('Deduct Points'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 211, 206, 206),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),

            // --- PROMOTE/REMOVE CAPTAIN BUTTON ---
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isCurrentlyCaptain ? _removeCaptain : _makeCaptain,
                icon: Icon(
                  isCurrentlyCaptain
                      ? Icons.star_border_rounded
                      : Icons.star_rounded,
                  color: Colors.white,
                ),
                label: Text(
                  isCurrentlyCaptain
                      ? 'Remove from Captain'
                      : 'Promote to Captain',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCurrentlyCaptain
                      ? Colors.redAccent
                      : Colors.amber.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            // --- END OF BUTTON ---
            const SizedBox(height: 30),

            const Text(
              'Score History',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            isLoadingHistory
                ? const Center(child: CircularProgressIndicator())
                : historyLogs.isEmpty
                ? const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No discipline history logged for this student yet.',
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: historyLogs.length,
                    itemBuilder: (context, index) {
                      final log = historyLogs[index];
                      final int pts = log['points'] ?? 0;
                      final String reason = log['reason'] ?? 'No reason given';
                      final String recordedBy =
                          log['recordedByName'] ?? 'Faculty';
                      final String actName = StringUtils.toTitleCase(
                        log['subgroupName'] ?? 'General',
                      );
                      final String dtStr = log['createdAt'] != null
                          ? log['createdAt']
                                .toString()
                                .replaceAll('T', ' ')
                                .substring(0, 16)
                          : '';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: pts >= 0
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.red.withValues(alpha: 0.1),
                            child: Icon(
                              pts >= 0 ? Icons.add_circle : Icons.remove_circle,
                              color: pts >= 0 ? Colors.green : Colors.red,
                            ),
                          ),
                          title: Text(
                            reason,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'By: $recordedBy • Act: $actName\nDate: $dtStr',
                          ),
                          trailing: Text(
                            pts >= 0 ? '+$pts' : '$pts',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: pts >= 0 ? Colors.green : Colors.red,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
