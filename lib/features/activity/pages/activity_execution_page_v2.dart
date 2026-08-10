import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:pragatix/features/activity/models/execution_student_model.dart';
import 'package:pragatix/features/activity/services/activity_service.dart';

class ActivityExecutionPage extends StatefulWidget {
  final int activityId;

  const ActivityExecutionPage({super.key, required this.activityId});

  @override
  State<ActivityExecutionPage> createState() => _ActivityExecutionPageState();
}

class _ActivityExecutionPageState extends State<ActivityExecutionPage> {
  late final ActivityService _service;
  bool _isLoading = true;
  String? _errorMessage;

  MyActivityStudentsResponseModel? _data;
  String _searchQuery = '';
  final Set<int> _awardedStudentIds = {};
  int _totalSessionXpAwarded = 0;

  static const Color _primary = Color(0xFFEA4335);
  static const Color _dark = Color(0xFF1E293B);

  @override
  void initState() {
    super.initState();
    _service = ActivityService(context.read<AuthProvider>());
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final jsonMap = await _service.fetchExecutionStudents(widget.activityId);
      setState(() {
        _data = MyActivityStudentsResponseModel.fromJson(jsonMap);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _submitAward(
    ExecutionStudentModel student,
    int xp,
    String remarks,
    String result,
  ) async {
    if (_data == null) return;
    try {
      await _service.awardXp(
        regNo: student.id,
        activityId: _data!.activity.id,
        assignmentId: _data!.assignment.id,
        xp: xp,
        remarks: remarks,
        result: result,
      );

      setState(() {
        _awardedStudentIds.add(student.id);
        _totalSessionXpAwarded += xp;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Logged $result (${xp >= 0 ? "+" : ""}$xp XP) for ${student.fullName} successfully!',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh list to update scores
      _loadData();
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('Failed to Log Result'),
            ],
          ),
          content: Text(e.toString().replaceAll('Exception: ', '')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _openAwardDialog(ExecutionStudentModel student) {
    if (_data == null) return;
    final act = _data!.activity;
    final formKey = GlobalKey<FormState>();
    final remarksController = TextEditingController();
    String selectedResult = 'PASS';
    if (!act.awardEnabled && act.penaltyEnabled) {
      selectedResult = 'FAIL';
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final int displayXp = selectedResult == 'PASS'
              ? act.awardXp
              : -act.penaltyXp;
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Submit Activity Result',
              style: TextStyle(fontWeight: FontWeight.bold, color: _dark),
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Student: ${student.fullName}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Activity: ${act.name}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (act.awardEnabled && act.penaltyEnabled) ...[
                      const Text(
                        'Select Result:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                'PASS',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              value: 'PASS',
                              groupValue: selectedResult,
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() {
                                    selectedResult = val;
                                  });
                                }
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                'FAIL',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              value: 'FAIL',
                              groupValue: selectedResult,
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() {
                                    selectedResult = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: selectedResult == 'PASS'
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Result: $selectedResult (${displayXp >= 0 ? "+" : ""}$displayXp XP)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: selectedResult == 'PASS'
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: remarksController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Remarks / Comments',
                        border: OutlineInputBorder(),
                        hintText: 'Optional notes...',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  if (formKey.currentState?.validate() == true) {
                    Navigator.pop(ctx);
                    _submitAward(
                      student,
                      displayXp,
                      remarksController.text,
                      selectedResult,
                    );
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final studentsList = _data?.students ?? [];
    final filteredStudents = studentsList.where((student) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final nameMatches = student.fullName.toLowerCase().contains(q);
      final regMatches = student.regNo.toString().contains(q);
      final idMatches = student.regNo.toLowerCase().contains(q);
      return nameMatches || regMatches || idMatches;
    }).toList();
    filteredStudents.sort((a, b) {
      final nameA = a.fullName.trim().toLowerCase();
      final nameB = b.fullName.trim().toLowerCase();
      final comp = nameA.compareTo(nameB);
      if (comp != 0) return comp;
      final regA = a.regNo.trim().toLowerCase();
      final regB = b.regNo.trim().toLowerCase();
      return regA.compareTo(regB);
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Activity Execution',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
          : _errorMessage != null
          ? _buildErrorView()
          : Column(
              children: [
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      // ── Activity Header Card ──
                      SliverToBoxAdapter(child: _buildActivityHeaderCard()),
                      // ── Search Section ──
                      SliverToBoxAdapter(child: _buildSearchSection()),
                      // ── Students List ──
                      if (filteredStudents.isEmpty)
                        SliverFillRemaining(child: _buildEmptyState())
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((ctx, index) {
                              final student = filteredStudents[index];
                              return _buildStudentCard(student);
                            }, childCount: filteredStudents.length),
                          ),
                        ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 80), // spacer for bottom panel
                      ),
                    ],
                  ),
                ),
                // ── Bottom Summary Panel ──
                _buildBottomSummaryPanel(studentsList.length),
              ],
            ),
    );
  }

  Widget _buildActivityHeaderCard() {
    if (_data == null) return const SizedBox.shrink();
    final act = _data!.activity;
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    act.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _dark,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    act.type,
                    style: TextStyle(
                      color: Colors.blue.shade800,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              act.description,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const Divider(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildInfoBadge(Icons.business, 'Dept: ${act.department}'),
                _buildInfoBadge(Icons.timer, 'Freq: ${act.frequency}'),
                _buildInfoBadge(Icons.star, 'XP Limit: ${_data!.xpLimit}'),
                if (act.evidence.isNotEmpty)
                  _buildInfoBadge(
                    Icons.attach_file,
                    'Evidence: ${act.displayEvidence.join(", ")}',
                  ),
                _buildInfoBadge(
                  Icons.person,
                  'Assigned By: ${_data!.assignment.assignedBy}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search by student name, register number or roll number',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
      ),
    );
  }

  Widget _buildStudentCard(ExecutionStudentModel student) {
    final isAwarded = _awardedStudentIds.contains(student.id);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isAwarded
                  ? Colors.green.shade100
                  : Colors.red.shade100,
              radius: 22,
              child: Icon(
                Icons.person,
                color: isAwarded ? Colors.green : _primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: _dark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Reg: ${student.regNo} | Roll: ${student.regNo}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  Text(
                    'Dept: ${student.departmentName} ${student.sectionName.isNotEmpty ? "(${student.sectionName})" : ""}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${student.totalXp} XP',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 6),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAwarded ? Colors.green : _primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 0,
                    ),
                    minimumSize: const Size(60, 32),
                  ),
                  onPressed: () => _openAwardDialog(student),
                  child: Text(
                    isAwarded ? 'Re-Award' : 'Award XP',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No matching students found.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _dark,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSummaryPanel(int totalStudents) {
    final awarded = _awardedStudentIds.length;
    final remaining = totalStudents - awarded;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Awarded', '$awarded', Colors.green),
          _buildSummaryItem('Remaining', '$remaining', Colors.orange),
          _buildSummaryItem(
            'XP Awarded',
            '+$_totalSessionXpAwarded',
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
