import 'dart:async';
import 'package:pragatix/core/widgets/pragatix_loader.dart';
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
  List<StudentSearchDTO> _selectedStudents = [];

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
          // Retain selected students when clearing search
        });
      }
    });
  }

  Future<void> _performSearch(String keyword) async {
    setState(() {
      _isLoading = true;
      _errorMsg = '';
    });
    try {
      final authProvider = context.read<AuthProvider>();
      final response = await getIt<TeamProxyService>().get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/v1/students/team-member-search?teamId=${widget.currentTeamId}&keyword=${Uri.encodeComponent(keyword)}&currentStage=${widget.currentStage}',
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

  @override
  void initState() {
    super.initState();
    // Load immediately on init
    _performSearch('');
  }

  void _toggleStudent(StudentSearchDTO student) {
    if (student.teamId == widget.currentTeamId) return; // Already in this team

    // Close keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      final isAlreadySelected = _selectedStudents.any((s) => s.id == student.id);
      if (isAlreadySelected) {
        _selectedStudents.removeWhere((s) => s.id == student.id);
      } else {
        _selectedStudents.add(student);
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      final selectableResults = _results.where((s) => s.teamId != widget.currentTeamId).toList();
      final allSelected = selectableResults.every((s) => _selectedStudents.any((selected) => selected.id == s.id));
      
      if (allSelected) {
        // Deselect all from current results
        _selectedStudents.removeWhere((selected) => selectableResults.any((s) => s.id == selected.id));
      } else {
        // Select all selectable results that are not yet selected
        for (var s in selectableResults) {
          if (!_selectedStudents.any((selected) => selected.id == s.id)) {
            _selectedStudents.add(s);
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
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
            if (!_isLoading && _results.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _results.where((s) => s.teamId != widget.currentTeamId).isNotEmpty && 
                               _results.where((s) => s.teamId != widget.currentTeamId).every((s) => _selectedStudents.any((selected) => selected.id == s.id)),
                        onChanged: (val) => _toggleSelectAll(),
                        activeColor: Colors.indigo,
                      ),
                      const Text('Select All', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Text('${_results.length} eligible students', style: const TextStyle(color: Colors.grey)),
                ],
              ),
            Expanded(
              child: _isLoading
                  ? const Center(child: PragatiXLoader())
                  : _errorMsg.isNotEmpty
                  ? Center(
                      child: Text(
                        _errorMsg,
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                  : _results.isEmpty
                  ? Center(
                      child: Text(
                        _searchController.text.isNotEmpty 
                            ? 'No eligible students found' 
                            : 'No eligible students available for this team',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (ctx, index) {
                        final s = _results[index];
                        final isSelected = _selectedStudents.any((selected) => selected.id == s.id);
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
                                  : () => _toggleStudent(s),
                              leading: Checkbox(
                                value: isSelected,
                                onChanged: isAlreadyInThisTeam 
                                    ? null 
                                    : (val) => _toggleStudent(s),
                                activeColor: Colors.indigo,
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${_selectedStudents.length} Selected',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _selectedStudents.isEmpty
                      ? null
                      : () {
                          Navigator.pop(
                            context,
                            _selectedStudents.map((s) => s.regNo).toList(),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_selectedStudents.isEmpty
                      ? 'Add Members'
                      : 'Add ${_selectedStudents.length}'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
