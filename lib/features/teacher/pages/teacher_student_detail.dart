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
  int currentStreak = 0;
  List<dynamic> studentStreaks = [];
  List<dynamic> historyLogs = [];
  bool isLoadingHistory = true;
  bool isCurrentlyCaptain = false;

  @override
  void initState() {
    super.initState();
    _studentData = Map<String, dynamic>.from(widget.student);
    currentScore = _studentData['score'] ?? 0;
    currentStreak = _studentData['currentStreak'] ?? 0;
    isCurrentlyCaptain =
        _studentData['teamRole'] == 'CAPTAIN' ||
        _studentData['teamRole'] == 'VICE_CAPTAIN';
    _fetchFullStudentDetails();
    _fetchHistoryLogs();
    _fetchStreaks();
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
            currentStreak = _studentData['currentStreak'] ?? currentStreak;
            if (_studentData['streaks'] is List) {
              studentStreaks = _studentData['streaks'];
            }
            isCurrentlyCaptain =
                _studentData['teamRole'] == 'CAPTAIN' ||
                _studentData['teamRole'] == 'VICE_CAPTAIN';
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchStreaks() async {
    final regNo = (_studentData['regNo'] ?? widget.student['regNo'] ?? '').toString().trim();
    if (regNo.isEmpty) return;
    try {
      final token = context.read<AuthProvider>().token ?? '';
      final response = await getIt<TeacherProxyService>().get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/xp/$regNo/streaks'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] is List) {
          final List list = data['data'];
          int maxS = 0;
          for (var item in list) {
            final s = item['currentStreak'] is int
                ? item['currentStreak'] as int
                : int.tryParse(item['currentStreak']?.toString() ?? '0') ?? 0;
            if (s > maxS) maxS = s;
          }
          if (mounted) {
            setState(() {
              studentStreaks = list;
              if (maxS > 0 || currentStreak == 0) {
                currentStreak = maxS;
              }
            });
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchHistoryLogs() async {
    final studentId = _studentData['id'] ?? widget.student['id'];
    final regNo = (_studentData['regNo'] ?? widget.student['regNo'] ?? '').toString().trim();
    final token = context.read<AuthProvider>().token ?? '';
    final headers = {'Authorization': 'Bearer $token'};
    
    List<dynamic> logs = [];

    // 1. Fetch from unified discipline-logs endpoint
    if (studentId != null) {
      try {
        final response = await getIt<TeacherProxyService>().get(
          Uri.parse('${ApiConfig.baseUrl}/api/v1/students/$studentId/discipline-logs'),
          headers: headers,
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true && data['data'] is List) {
            logs.addAll(data['data']);
          }
        }
      } catch (_) {}
    }

    // 2. If empty and regNo available, also query /api/v1/xp/$regNo/history
    if (logs.isEmpty && regNo.isNotEmpty) {
      try {
        final xpRes = await getIt<TeacherProxyService>().get(
          Uri.parse('${ApiConfig.baseUrl}/api/v1/xp/$regNo/history?page=0&size=100'),
          headers: headers,
        );
        if (xpRes.statusCode == 200) {
          final xpData = jsonDecode(xpRes.body);
          if (xpData['data'] != null) {
            final content = xpData['data']['content'] ?? (xpData['data'] is List ? xpData['data'] : []);
            if (content is List) {
              for (var tx in content) {
                logs.add({
                  'id': tx['id'],
                  'points': tx['xpPoints'] ?? tx['points'] ?? 0,
                  'reason': tx['activityName'] ?? tx['reason'] ?? 'XP Award',
                  'subgroupName': tx['category'] ?? 'Activity',
                  'recordedByName': tx['approvedBy'] ?? 'System',
                  'createdAt': tx['submittedAt'] ?? tx['createdAt'],
                });
              }
            }
          }
        }
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      historyLogs = logs;
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
    final String rawSec = (_studentData['section'] ?? _studentData['sectionName'] ?? '-').toString().trim();
    final bool hasSec = rawSec.isNotEmpty &&
        rawSec != '-' &&
        rawSec.toLowerCase() != 'null' &&
        rawSec.toLowerCase() != 'none';
    final String section = hasSec ? rawSec : 'None';
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

    final bool isFemale = gender.toLowerCase().startsWith('f') || gender.toLowerCase() == 'girl';
    final String avatarAsset = isFemale
        ? 'assets/images/avatar_female.png'
        : 'assets/images/avatar_male.png';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Details', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
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
                      Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isFemale ? const Color(0xFFFDF2F8) : const Color(0xFFEFF6FF),
                          border: Border.all(
                            color: isFemale ? const Color(0xFFFBCFE8) : const Color(0xFFBFDBFE),
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (isFemale ? const Color(0xFFEC4899) : const Color(0xFF2563EB)).withValues(alpha: 0.14),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            avatarAsset,
                            width: 92,
                            height: 92,
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              isFemale ? Icons.female_rounded : Icons.male_rounded,
                              size: 48,
                              color: isFemale ? const Color(0xFFDB2777) : const Color(0xFF2563EB),
                            ),
                          ),
                        ),
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
                    _buildInfoRow(
                      Icons.school_outlined,
                      hasSec ? 'Year / Sem / Sec' : 'Year / Semester',
                      hasSec
                          ? 'Year: $year  •  Sem: $semester  •  Sec: $section'
                          : 'Year: $year  •  Sem: $semester  •  No Section',
                    ),
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

            // Student Streaks Card
            const Text(
              'Streak Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFF7ED), Color(0xFFFEF3C7)],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
                          ),
                          child: const Icon(
                            Icons.local_fire_department_rounded,
                            color: Color(0xFFEA580C),
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Current Active Streak',
                                style: TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$currentStreak ${currentStreak == 1 ? "Day" : "Days"} Active',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: currentStreak > 0 ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            currentStreak > 0 ? 'On Track 🔥' : 'Inactive',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: currentStreak > 0 ? const Color(0xFF15803D) : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (studentStreaks.isNotEmpty) ...[
                      const Divider(height: 24),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: studentStreaks.map((s) {
                          final String type = StringUtils.toTitleCase(
                            (s['streakType'] ?? 'Activity').toString().replaceAll('_', ' '),
                          );
                          final dynamic rawCount = s['currentStreak'];
                          final int count = rawCount is int
                              ? rawCount
                              : (int.tryParse(rawCount?.toString() ?? '0') ?? 0);
                          final bool isBroken = s['isBroken'] == true;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isBroken ? const Color(0xFFF1F5F9) : const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isBroken ? const Color(0xFFE2E8F0) : const Color(0xFFFDE68A),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isBroken ? Icons.lock_clock : Icons.local_fire_department_rounded,
                                  size: 14,
                                  color: isBroken ? Colors.grey : const Color(0xFFEA580C),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$type: $count ${count == 1 ? "day" : "days"}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isBroken ? Colors.grey : const Color(0xFF92400E),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

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
                      final dynamic rawPts = log['points'] ?? log['xpPoints'];
                      final int pts = rawPts is int ? rawPts : (int.tryParse(rawPts?.toString() ?? '') ?? 0);
                      final String reason = log['reason'] ?? log['activityName'] ?? 'Score Adjustment';
                      final String recordedBy =
                          log['recordedByName'] ?? log['approvedBy'] ?? 'System';
                      final String actName = StringUtils.toTitleCase(
                        log['subgroupName'] ?? log['category'] ?? 'Activity',
                      );
                      String dtStr = '';
                      final rawDt = log['createdAt'] ?? log['submittedAt'];
                      if (rawDt != null) {
                        final s = rawDt.toString().replaceAll('T', ' ');
                        dtStr = s.length >= 16 ? s.substring(0, 16) : s;
                      }

                      final isPositive = pts >= 0;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: isPositive
                                      ? const Color(0xFFDCFCE7)
                                      : const Color(0xFFFEE2E2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isPositive ? Icons.add_rounded : Icons.remove_rounded,
                                  color: isPositive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      reason,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        if (actName.isNotEmpty) ...[
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              actName,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF475569),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        Expanded(
                                          child: Text(
                                            'By: $recordedBy' + (dtStr.isNotEmpty ? ' • $dtStr' : ''),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF64748B),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isPositive
                                      ? const Color(0xFFECFDF5)
                                      : const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isPositive
                                        ? const Color(0xFFA7F3D0)
                                        : const Color(0xFFFECACA),
                                  ),
                                ),
                                child: Text(
                                  isPositive ? '+$pts pts' : '$pts pts',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: isPositive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
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
