import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/core/config/api_config.dart';
import 'package:pragatix/features/team/services/team_proxy_service.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/core/widgets/pragatix_loader.dart';

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
  final int? maxSelectable;
  final int? totalTeamSize;
  final int? currentMemberCount;

  const StudentSearchDialog({
    super.key,
    required this.currentTeamId,
    required this.currentStage,
    this.maxSelectable,
    this.totalTeamSize,
    this.currentMemberCount,
  });

  @override
  State<StudentSearchDialog> createState() => _StudentSearchDialogState();
}

class _StudentSearchDialogState extends State<StudentSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<StudentSearchDTO> _results = [];
  bool _isLoading = false;
  String _errorMsg = '';
  final List<StudentSearchDTO> _selectedStudents = [];

  bool get _canSelectMore {
    if (widget.maxSelectable == null) return true;
    return _selectedStudents.length < widget.maxSelectable!;
  }

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

  void _showLimitReachedSnackBar() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Team size limit of ${widget.totalTeamSize ?? widget.maxSelectable} reached (including captain). Unselect a student first.',
        ),
        backgroundColor: Colors.orange.shade800,
        duration: const Duration(seconds: 2),
      ),
    );
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
        if (!_canSelectMore) {
          _showLimitReachedSnackBar();
          return;
        }
        _selectedStudents.add(student);
      }
    });
  }

  void _toggleSelectAll() {
    FocusScope.of(context).unfocus();
    setState(() {
      final selectableResults = _results.where((s) => s.teamId != widget.currentTeamId).toList();
      if (selectableResults.isEmpty) return;

      final allCurrentlySelected = selectableResults.every((s) => _selectedStudents.any((selected) => selected.id == s.id));
      final maxReached = widget.maxSelectable != null && _selectedStudents.length >= widget.maxSelectable!;

      if (allCurrentlySelected || (_selectedStudents.isNotEmpty && maxReached)) {
        // Deselect all
        _selectedStudents.clear();
      } else {
        final limit = widget.maxSelectable ?? selectableResults.length;
        _selectedStudents.clear();
        for (var s in selectableResults) {
          if (_selectedStudents.length < limit) {
            _selectedStudents.add(s);
          } else {
            break;
          }
        }
        if (widget.maxSelectable != null && selectableResults.length > limit) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Selected maximum of $limit member${limit == 1 ? '' : 's'} (team capacity reached).',
              ),
              backgroundColor: Colors.indigo,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  bool? _getSelectAllValue() {
    final selectableResults = _results.where((s) => s.teamId != widget.currentTeamId).toList();
    if (selectableResults.isEmpty) return false;

    if (widget.maxSelectable != null) {
      if (_selectedStudents.length == widget.maxSelectable && widget.maxSelectable! > 0) {
        return true;
      } else if (_selectedStudents.isNotEmpty) {
        return null;
      } else {
        return false;
      }
    } else {
      if (selectableResults.every((s) => _selectedStudents.any((selected) => selected.id == s.id))) {
        return true;
      } else if (_selectedStudents.isNotEmpty) {
        return null;
      } else {
        return false;
      }
    }
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
            if (widget.totalTeamSize != null && widget.maxSelectable != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedStudents.length >= widget.maxSelectable!
                      ? Colors.amber.shade50
                      : Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _selectedStudents.length >= widget.maxSelectable!
                        ? Colors.amber.shade300
                        : Colors.indigo.shade100,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedStudents.length >= widget.maxSelectable!
                          ? Icons.info_outline
                          : Icons.group_outlined,
                      size: 18,
                      color: _selectedStudents.length >= widget.maxSelectable!
                          ? Colors.amber.shade900
                          : Colors.indigo,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Team Size: ${widget.totalTeamSize} (incl. Captain)  •  Available slots: ${widget.maxSelectable}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _selectedStudents.length >= widget.maxSelectable!
                              ? Colors.amber.shade900
                              : Colors.indigo.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
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
            const SizedBox(height: 12),
            if (!_isLoading && _results.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        tristate: true,
                        value: _getSelectAllValue(),
                        onChanged: (val) => _toggleSelectAll(),
                        activeColor: Colors.indigo,
                      ),
                      Text(
                        widget.maxSelectable != null && widget.maxSelectable! < _results.length
                            ? 'Select Max (${widget.maxSelectable})'
                            : 'Select All',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
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
                        final isAlreadyInThisTeam = s.teamId == widget.currentTeamId;
                        final isSelectionDisabled = !isSelected && !isAlreadyInThisTeam && !_canSelectMore;

                        return Opacity(
                          opacity: (isAlreadyInThisTeam || isSelectionDisabled) ? 0.55 : 1.0,
                          child: Card(
                            elevation: isSelected ? 4 : 1,
                            margin: const EdgeInsets.only(bottom: 12),
                            color: isSelectionDisabled ? Colors.grey.shade50 : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: isSelected
                                  ? const BorderSide(
                                      color: Colors.indigo,
                                      width: 2,
                                    )
                                  : BorderSide(
                                      color: isSelectionDisabled ? Colors.grey.shade300 : Colors.grey.shade200,
                                      width: 1,
                                    ),
                            ),
                            child: ListTile(
                              onTap: isAlreadyInThisTeam
                                  ? null
                                  : (isSelectionDisabled
                                      ? () => _showLimitReachedSnackBar()
                                      : () => _toggleStudent(s)),
                              leading: Checkbox(
                                value: isSelected,
                                onChanged: (isAlreadyInThisTeam || isSelectionDisabled) 
                                    ? null 
                                    : (val) => _toggleStudent(s),
                                activeColor: Colors.indigo,
                              ),
                              title: Text(
                                s.fullName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSelectionDisabled ? Colors.grey.shade700 : Colors.black87,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    'Reg: ${s.regNo}  •  SPR: ${s.sprNo ?? 'N/A'}',
                                    style: TextStyle(color: isSelectionDisabled ? Colors.grey.shade600 : null),
                                  ),
                                  Text(
                                    '${s.departmentName ?? ''} • Year ${s.year ?? ''} • Sec ${s.section ?? ''}',
                                    style: TextStyle(color: isSelectionDisabled ? Colors.grey.shade600 : null),
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
                                  Text(
                                    'Current Stage: Stage ${s.currentStage}',
                                    style: TextStyle(color: isSelectionDisabled ? Colors.grey.shade600 : null),
                                  ),
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
                                  : (isSelectionDisabled
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade200,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'Limit reached',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey.shade700,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        )
                                      : null),
                            ),
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
                    widget.maxSelectable != null
                        ? '${_selectedStudents.length} / ${widget.maxSelectable} Selected${_selectedStudents.length >= widget.maxSelectable! && widget.maxSelectable! > 0 ? ' (Limit Reached)' : ''}'
                        : '${_selectedStudents.length} Selected',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: (widget.maxSelectable != null && _selectedStudents.length >= widget.maxSelectable! && widget.maxSelectable! > 0)
                          ? Colors.indigo
                          : Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: (_selectedStudents.isEmpty ||
                          (widget.maxSelectable != null && _selectedStudents.length > widget.maxSelectable!))
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
