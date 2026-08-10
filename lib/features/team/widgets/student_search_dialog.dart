import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/core/config/api_config.dart';
import 'package:pragatix/features/team/services/team_proxy_service.dart';
import 'package:pragatix/core/di/service_locator.dart';

class StudentSearchDTO {
  final int id;
  final String fullName;
  final String regNo;
  final String? sprNo;
  final String? departmentName;
  final String? year;
  final String? section;
  final String? teamName;
  final int? teamId;
  final int currentStage;

  StudentSearchDTO({
    required this.id,
    required this.fullName,
    required this.regNo,
    this.sprNo,
    this.departmentName,
    this.year,
    this.section,
    this.teamName,
    this.teamId,
    required this.currentStage,
  });

  factory StudentSearchDTO.fromJson(Map<String, dynamic> json) {
    return StudentSearchDTO(
      id: json['id'],
      fullName: json['fullName'] ?? '',
      regNo: json['regNo'] ?? '',
      sprNo: json['sprNo'],
      departmentName: json['departmentName'],
      year: json['year'],
      section: json['section'],
      teamName: json['teamName'],
      teamId: json['teamId'],
      currentStage: json['currentStage'] ?? 1,
    );
  }
}

class StudentSearchDialog extends StatefulWidget {
  final int currentTeamId;
  final int currentStage;

  const StudentSearchDialog({
    Key? key,
    required this.currentTeamId,
    required this.currentStage,
  }) : super(key: key);

  @override
  State<StudentSearchDialog> createState() => _StudentSearchDialogState();
}

class _StudentSearchDialogState extends State<StudentSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<StudentSearchDTO> _results = [];
  bool _isLoading = false;
  String _errorMsg = '';
  StudentSearchDTO? _selectedStudent;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().isNotEmpty) {
        _performSearch(query.trim());
      } else {
        setState(() {
          _results = [];
          _errorMsg = '';
          _selectedStudent = null;
        });
      }
    });
  }

  Future<void> _performSearch(String keyword) async {
    setState(() {
      _isLoading = true;
      _errorMsg = '';
      _selectedStudent = null;
    });
    try {
      final authProvider = context.read<AuthProvider>();
      final response = await getIt<TeamProxyService>().get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/v1/students/team-member-search?keyword=${Uri.encodeComponent(keyword)}',
        ),
        headers: {'Authorization': 'Bearer ${authProvider.token}'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List list = data['data'] ?? [];
          setState(() {
            _results = list.map((e) => StudentSearchDTO.fromJson(e)).toList();
          });
        } else {
          setState(() => _errorMsg = data['message'] ?? 'Search failed');
        }
      } else {
        setState(() => _errorMsg = 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _errorMsg = 'Network error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _selectStudent(StudentSearchDTO student) {
    if (student.teamId == widget.currentTeamId) return; // Already in this team

    // Close keyboard
    FocusScope.of(context).unfocus();

    if (student.teamId != null && student.teamId != widget.currentTeamId) {
      // Different team same stage prompt handled by caller or we handle it here
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Move Student?'),
          content: Text(
            'Move ${student.fullName} from ${student.teamName} to this team?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => _selectedStudent = student);
              },
              child: const Text('Yes'),
            ),
          ],
        ),
      );
    } else {
      setState(() => _selectedStudent = student);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        height: 600,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.person_add, color: Colors.indigo),
                const SizedBox(width: 8),
                const Text(
                  'Add Team Member',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by Name, Reg No, or SPR No...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMsg.isNotEmpty
                  ? Center(
                      child: Text(
                        _errorMsg,
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                  : _results.isEmpty && _searchController.text.isNotEmpty
                  ? const Center(
                      child: Text(
                        'No students found',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (ctx, index) {
                        final s = _results[index];
                        final isSelected = _selectedStudent?.id == s.id;
                        final isAlreadyInThisTeam =
                            s.teamId == widget.currentTeamId;

                        return Card(
                          elevation: isSelected ? 4 : 1,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: isSelected
                                ? const BorderSide(
                                    color: Colors.indigo,
                                    width: 2,
                                  )
                                : BorderSide.none,
                          ),
                          child: ListTile(
                            onTap: isAlreadyInThisTeam
                                ? null
                                : () => _selectStudent(s),
                            leading: CircleAvatar(
                              backgroundColor: isSelected
                                  ? Colors.indigo
                                  : Colors.grey.shade200,
                              foregroundColor: isSelected
                                  ? Colors.white
                                  : Colors.indigo,
                              child: const Icon(Icons.person),
                            ),
                            title: Text(
                              s.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  'Reg: ${s.regNo}  •  SPR: ${s.sprNo ?? 'N/A'}',
                                ),
                                Text(
                                  '${s.departmentName ?? ''} • Year ${s.year ?? ''} • Sec ${s.section ?? ''}',
                                ),
                                if (s.teamName != null)
                                  Text(
                                    'Current Team: ${s.teamName}',
                                    style: TextStyle(
                                      color: isAlreadyInThisTeam
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                  ),
                                Text('Current Stage: Stage ${s.currentStage}'),
                              ],
                            ),
                            trailing: isAlreadyInThisTeam
                                ? const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                      ),
                                      Text(
                                        'Added',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  )
                                : isSelected
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Colors.indigo,
                                    size: 32,
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _selectedStudent == null
                      ? null
                      : () {
                          Navigator.pop(context, _selectedStudent!.regNo);
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add Member'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
