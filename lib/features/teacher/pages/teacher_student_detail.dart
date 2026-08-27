import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/core/widgets/pragatix_loader.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/core/config/api_config.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pragatix/features/teacher/services/teacher_proxy_service.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/core/utils/string_utils.dart';

class TeacherStudentDetail extends StatefulWidget {
  final Map<String, dynamic> student;
  const TeacherStudentDetail({super.key, required this.student});

  @override
  State<TeacherStudentDetail> createState() => _TeacherStudentDetailState();
}

class _TeacherStudentDetailState extends State<TeacherStudentDetail> {
  late Map<String, dynamic> _studentData;
  int currentScore = 0;
  List<dynamic> historyLogs = [];
  bool isLoadingHistory = true;
  bool isCurrentlyCaptain = false;

  @override
  void initState() {
    super.initState();
    _studentData = Map<String, dynamic>.from(widget.student);
    currentScore = _studentData['score'] ?? 100;
    isCurrentlyCaptain =
        _studentData['teamRole'] == 'CAPTAIN' ||
        _studentData['teamRole'] == 'VICE_CAPTAIN';
    _fetchFullStudentDetails();
    _fetchHistoryLogs();
  }

  Future<void> _fetchFullStudentDetails() async {
    final id = _studentData['id'];
    if (id == null) return;
    try {
      final response = await getIt<TeacherProxyService>().get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/students/$id'),
        headers: {
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          if (!mounted) return;
          setState(() {
            _studentData.addAll(Map<String, dynamic>.from(data['data']));
            currentScore = _studentData['score'] ?? currentScore;
            isCurrentlyCaptain =
                _studentData['teamRole'] == 'CAPTAIN' ||
                _studentData['teamRole'] == 'VICE_CAPTAIN';
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchHistoryLogs() async {
    try {
      final response = await getIt<TeacherProxyService>().get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/v1/students/${widget.student['id']}/discipline-logs',
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
    } catch (_) {}
    setState(() {
      isLoadingHistory = false;
    });
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blueGrey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final String name = _studentData['fullName'] ?? _studentData['name'] ?? 'Unknown';
    final String regNo = _studentData['regNo'] ?? _studentData['studentId'] ?? '-';
    final String sprNo = (_studentData['sprNo'] ?? '').toString().trim();
    final String dept = _studentData['departmentName'] ?? _studentData['department'] ?? _studentData['dept'] ?? 'N/A';
    final String year = (_studentData['year'] ?? '-').toString().trim();
    final String semester = (_studentData['semester'] ?? '-').toString().trim();
    final String section = (_studentData['section'] ?? _studentData['sectionName'] ?? '-').toString().trim();
    final String email = (_studentData['email'] ?? '-').toString().trim();
    final String phone = (_studentData['phone'] ?? '-').toString().trim();
    final String gender = (_studentData['gender'] ?? '-').toString().trim();
    final String teamName = (_studentData['teamName'] ?? _studentData['team'] ?? _studentData['group'] ?? '').toString().trim();

    final rawDob = _studentData['dateOfBirth'] ?? _studentData['dob'];
    String dobStr = '';
    if (rawDob != null) {
      try {
        dobStr = rawDob.toString().split('T')[0];
      } catch (_) {}
    }

    // Guardian Information resolution
    final guardian = _studentData['guardian'] is Map ? _studentData['guardian'] as Map : null;
    final String gName = (guardian?['guardianName'] ?? guardian?['name'] ?? _studentData['guardianName'] ?? '').toString().trim();
    String gRel = (guardian?['relationship'] ?? guardian?['relation'] ?? _studentData['guardianRelationship'] ?? _studentData['guardianRel'] ?? 'Guardian').toString().trim();
    gRel = StringUtils.toTitleCase(gRel);
    final String gPhone = (guardian?['phoneNo'] ?? guardian?['phone'] ?? guardian?['mobile'] ?? _studentData['guardianPhone'] ?? _studentData['guardianPhoneNo'] ?? '').toString().trim();
    final String gEmail = (guardian?['email'] ?? _studentData['guardianEmail'] ?? '').toString().trim();
    final bool hasGuardian = gName.isNotEmpty || gPhone.isNotEmpty || gEmail.isNotEmpty;

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
            // Student Main Profile Card
            Center(
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: const Color(0xFFEA4335).withValues(alpha: 0.12),
                        child: const Icon(Icons.person, size: 54, color: Color(0xFFEA4335)),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Reg No: $regNo',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blueGrey),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dept,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      if (teamName.isNotEmpty || isCurrentlyCaptain) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            if (isCurrentlyCaptain)
                              Chip(
                                avatar: const Icon(Icons.star, size: 16, color: Colors.amber),
                                label: const Text('Captain', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                backgroundColor: Colors.amber.shade100,
                              ),
                            if (teamName.isNotEmpty)
                              Chip(
                                avatar: const Icon(Icons.groups, size: 16, color: Colors.indigo),
                                label: Text(teamName, style: const TextStyle(fontSize: 12)),
                                backgroundColor: Colors.indigo.shade50,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Academic & Contact Information Card
            const Text(
              'Academic & Contact Info',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  children: [
                    _buildInfoRow(Icons.school_outlined, 'Year / Sem / Sec', 'Year: $year  •  Sem: $semester  •  Sec: $section'),
                    if (sprNo.isNotEmpty) ...[
                      const Divider(height: 16),
                      _buildInfoRow(Icons.badge_outlined, 'SPR Number', sprNo),
                    ],
                    if (gender != '-' && gender.isNotEmpty) ...[
                      const Divider(height: 16),
                      _buildInfoRow(Icons.person_outline, 'Gender', gender),
                    ],
                    if (dobStr.isNotEmpty) ...[
                      const Divider(height: 16),
                      _buildInfoRow(Icons.cake_outlined, 'Date of Birth', dobStr),
                    ],
                    if (email != '-' && email.isNotEmpty) ...[
                      const Divider(height: 16),
                      _buildInfoRow(Icons.email_outlined, 'Email', email),
                    ],
                    if (phone != '-' && phone.isNotEmpty) ...[
                      const Divider(height: 16),
                      _buildInfoRow(Icons.phone_outlined, 'Phone', phone),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Guardian Information Card
            if (hasGuardian) ...[
              const Text(
                'Guardian Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFF1F5F9),
                          child: Icon(Icons.family_restroom, color: Colors.blueGrey),
                        ),
                        title: Text(
                          gName.isNotEmpty ? gName : 'Guardian',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Text(
                          gRel.isNotEmpty ? gRel : 'Guardian',
                          style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (gPhone.isNotEmpty) ...[
                        const Divider(height: 16),
                        _buildInfoRow(Icons.phone_outlined, 'Phone Number', gPhone),
                      ],
                      if (gEmail.isNotEmpty) ...[
                        const Divider(height: 16),
                        _buildInfoRow(Icons.email_outlined, 'Email', gEmail),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Current Discipline Score (View Only)
            Center(
              child: Column(
                children: [
                  const Text(
                    'Current Discipline Score',
                    style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$currentScore',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEA4335),
                    ),
                  ),
                  const Text('Points', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Score History
            const Text(
              'Score History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            isLoadingHistory
                ? const Center(child: PragatiXLoader())
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
