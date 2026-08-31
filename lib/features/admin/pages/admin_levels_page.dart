import 'package:flutter/material.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/core/widgets/pragatix_loader.dart';
import 'package:pragatix/features/admin/repository/admin_repository.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class AdminLevelsPage extends StatefulWidget {
  final String? initialYear;
  const AdminLevelsPage({super.key, this.initialYear});

  @override
  State<AdminLevelsPage> createState() => _AdminLevelsPageState();
}

class _AdminLevelsPageState extends State<AdminLevelsPage> {
  final AdminRepository _repository = getIt<AdminRepository>();

  bool _isLoading = true;
  String? _error;
  List<dynamic> _levels = [];

  // Dynamic year choices for Super Admin (filtered by assigned admins)
  List<Map<String, String>> _yearOptions = [
    {'label': '1st Year', 'value': 'FIRST_YEAR'},
    {'label': '2nd Year', 'value': 'SECOND_YEAR'},
    {'label': '3rd Year', 'value': 'THIRD_YEAR'},
    {'label': '4th Year', 'value': 'FOURTH_YEAR'},
    {'label': 'All Years', 'value': 'ALL'},
  ];

  late String _selectedYear;
  bool _isSuperAdmin = false;
  String? _assignedYear;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final currentUser = auth.currentUser ?? {};
    _isSuperAdmin = auth.isSuperAdmin;
    _assignedYear = currentUser['academicYear'] ?? currentUser['year'];

    if (_isSuperAdmin) {
      _selectedYear = widget.initialYear ?? 'FIRST_YEAR';
    } else {
      _selectedYear = _assignedYear != null && _assignedYear!.isNotEmpty
          ? _assignedYear!
          : 'FIRST_YEAR';
    }

    _fetchLevels();
  }

  Future<void> _fetchLevels() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_isSuperAdmin) {
        try {
          final admins = await _repository.getYearAdmins();
          final Set<String> assignedYearsEnum = {};
          for (var a in admins) {
            if (a is Map) {
              final aYearName = (a['assignedYearName'] ?? '').toString().trim().toLowerCase();
              final aYearId = a['assignedYearId']?.toString().trim();
              if (aYearId == '1' || aYearName.contains('first') || aYearName.contains('1')) {
                assignedYearsEnum.add('FIRST_YEAR');
              }
              if (aYearId == '2' || aYearName.contains('second') || aYearName.contains('2')) {
                assignedYearsEnum.add('SECOND_YEAR');
              }
              if (aYearId == '3' || aYearName.contains('third') || aYearName.contains('3')) {
                assignedYearsEnum.add('THIRD_YEAR');
              }
              if (aYearId == '4' || aYearName.contains('fourth') || aYearName.contains('4')) {
                assignedYearsEnum.add('FOURTH_YEAR');
              }
            }
          }

          final List<Map<String, String>> filteredOptions = [];
          if (assignedYearsEnum.contains('FIRST_YEAR')) {
            filteredOptions.add({'label': '1st Year', 'value': 'FIRST_YEAR'});
          }
          if (assignedYearsEnum.contains('SECOND_YEAR')) {
            filteredOptions.add({'label': '2nd Year', 'value': 'SECOND_YEAR'});
          }
          if (assignedYearsEnum.contains('THIRD_YEAR')) {
            filteredOptions.add({'label': '3rd Year', 'value': 'THIRD_YEAR'});
          }
          if (assignedYearsEnum.contains('FOURTH_YEAR')) {
            filteredOptions.add({'label': '4th Year', 'value': 'FOURTH_YEAR'});
          }

          if (filteredOptions.isNotEmpty) {
            if (filteredOptions.length > 1) {
              filteredOptions.add({'label': 'All Assigned', 'value': 'ALL'});
            }
            _yearOptions = filteredOptions;
            if (!_yearOptions.any((opt) => opt['value'] == _selectedYear)) {
              _selectedYear = _yearOptions.first['value']!;
            }
          }
        } catch (_) {}
      }

      final String? queryYear = _isSuperAdmin
          ? (_selectedYear == 'ALL' ? null : _selectedYear)
          : _selectedYear;

      final result = await _repository.getLevels(academicYear: queryYear);
      if (!mounted) return;
      setState(() {
        _levels = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteLevel(int id, String title, int levelNumber) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
            ),
            const SizedBox(width: 12),
            const Text(
              'Delete Level',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete Level $levelNumber: "$title"?\n\nIt will be moved to the Recycle Bin and can be restored if needed.',
          style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Move to Bin'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _repository.deleteLevel(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Level $levelNumber moved to Recycle Bin.'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _fetchLevels();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete level: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openAddEditLevelModal([Map<String, dynamic>? levelToEdit]) {
    final bool isEditing = levelToEdit != null;
    final int? id = levelToEdit?['id'];

    final levelNumberCtrl = TextEditingController(
      text: isEditing ? (levelToEdit['levelNumber']?.toString() ?? '') : '${_levels.length + 1}',
    );
    final titleCtrl = TextEditingController(text: isEditing ? (levelToEdit['title'] ?? '') : '');
    final xpMinCtrl = TextEditingController(
      text: isEditing
          ? (levelToEdit['xpMin']?.toString() ?? '')
          : (_levels.isNotEmpty ? ((_levels.last['xpMax'] ?? 0) + 1).toString() : '0'),
    );
    final xpMaxCtrl = TextEditingController(
      text: isEditing
          ? (levelToEdit['xpMax']?.toString() ?? '')
          : (_levels.isNotEmpty ? ((_levels.last['xpMax'] ?? 0) + 500).toString() : '100'),
    );
    final stageCtrl = TextEditingController(
      text: isEditing ? (levelToEdit['stage']?.toString() ?? '1') : '1',
    );
    final primaryObjectiveCtrl = TextEditingController(
      text: isEditing ? (levelToEdit['primaryObjective'] ?? '') : '',
    );
    final keyUnlocksCtrl = TextEditingController(
      text: isEditing ? (levelToEdit['keyUnlocks'] ?? '') : '',
    );

    String selectedYearForModal;
    if (_isSuperAdmin) {
      selectedYearForModal = isEditing
          ? (levelToEdit['academicYear'] ?? _selectedYear)
          : (_selectedYear == 'ALL' ? 'FIRST_YEAR' : _selectedYear);
    } else {
      selectedYearForModal = _selectedYear;
    }

    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.only(
                top: 24,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
              ),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(modalCtx).size.height * 0.88,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Modal Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isEditing ? Icons.edit_rounded : Icons.add_chart_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              isEditing ? 'Edit Level' : 'Create New Level',
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(modalCtx),
                          icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Academic Year Picker (if Super Admin)
                    if (_isSuperAdmin) ...[
                      const Text(
                        'Target Academic Year',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: selectedYearForModal,
                            items: _yearOptions
                                .where((y) => y['value'] != 'ALL')
                                .map((y) => DropdownMenuItem(
                                      value: y['value'],
                                      child: Text(y['label']!),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() => selectedYearForModal = val);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Level Number & Title Row
                    Row(
                      children: [
                        SizedBox(
                          width: 100,
                          child: _buildTextField(
                            controller: levelNumberCtrl,
                            label: 'Level #',
                            hint: '1',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: titleCtrl,
                            label: 'Level Title',
                            hint: 'e.g. Explorer, Builder',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Stage & XP Fields
                    Row(
                      children: [
                        SizedBox(
                          width: 100,
                          child: _buildTextField(
                            controller: stageCtrl,
                            label: 'Stage',
                            hint: '1',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: xpMinCtrl,
                            label: 'Min XP',
                            hint: '0',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: xpMaxCtrl,
                            label: 'Max XP',
                            hint: '100',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Primary Objective
                    _buildTextField(
                      controller: primaryObjectiveCtrl,
                      label: 'Primary Objective',
                      hint: 'e.g. Build participation habits & consistency',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 14),

                    // Key Unlocks
                    _buildTextField(
                      controller: keyUnlocksCtrl,
                      label: 'Key Unlocks & Privileges',
                      hint: 'e.g. Onboarding missions, basic badges, attendance streaks',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 22),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final title = titleCtrl.text.trim();
                                if (title.isEmpty) {
                                  ScaffoldMessenger.of(modalCtx).showSnackBar(
                                    const SnackBar(content: Text('Please enter a level title')),
                                  );
                                  return;
                                }

                                final levelNumber = int.tryParse(levelNumberCtrl.text.trim()) ?? 1;
                                final stage = int.tryParse(stageCtrl.text.trim()) ?? 1;
                                final xpMin = int.tryParse(xpMinCtrl.text.trim()) ?? 0;
                                final xpMax = int.tryParse(xpMaxCtrl.text.trim()) ?? 100;

                                if (xpMin >= xpMax) {
                                  ScaffoldMessenger.of(modalCtx).showSnackBar(
                                    const SnackBar(content: Text('Min XP must be less than Max XP')),
                                  );
                                  return;
                                }

                                setModalState(() => isSubmitting = true);

                                final body = {
                                  'levelNumber': levelNumber,
                                  'title': title,
                                  'stage': stage,
                                  'xpMin': xpMin,
                                  'xpMax': xpMax,
                                  'primaryObjective': primaryObjectiveCtrl.text.trim(),
                                  'keyUnlocks': keyUnlocksCtrl.text.trim(),
                                  'academicYear': selectedYearForModal,
                                };

                                try {
                                  if (isEditing) {
                                    await _repository.updateLevel(id!, body);
                                  } else {
                                    await _repository.createLevel(body);
                                  }
                                  if (!modalCtx.mounted) return;
                                  Navigator.pop(modalCtx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isEditing
                                            ? 'Level updated successfully!'
                                            : 'Level created successfully!',
                                      ),
                                      backgroundColor: const Color(0xFF10B981),
                                    ),
                                  );
                                  _fetchLevels();
                                } catch (e) {
                                  setModalState(() => isSubmitting = false);
                                  if (!modalCtx.mounted) return;
                                  ScaffoldMessenger.of(modalCtx).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
                                      backgroundColor: const Color(0xFFEF4444),
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                isEditing ? 'Save Changes' : 'Create Level',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: const Color(0xFF334155), size: 20),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEditLevelModal(),
        backgroundColor: const Color(0xFF2563EB),
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add Level',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          // Background mesh subtle gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 240,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFDCE8F6),
                    Color(0xFFE8EFF9),
                    Color(0xFFF4F7FB),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Top Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: Row(
                    children: [
                      if (Navigator.canPop(context)) ...[
                        _buildHeaderActionButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          tooltip: 'Back',
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              'Level Progression',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.4,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Year-wise levels, milestones & unlocks',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildHeaderActionButton(
                        icon: Icons.refresh_rounded,
                        tooltip: 'Refresh Levels',
                        onPressed: _fetchLevels,
                      ),
                    ],
                  ),
                ),

                // ── Academic Year Selector / Banner ────────────────────────────────
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF64748B).withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
            child: _isSuperAdmin
                ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _yearOptions.map((opt) {
                        final bool isSelected = _selectedYear == opt['value'];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              opt['label']!,
                              style: TextStyle(
                                color: isSelected ? Colors.white : const Color(0xFF334155),
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: const Color(0xFF4F46E5),
                            backgroundColor: const Color(0xFFF1F5F9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedYear = opt['value']!);
                                _fetchLevels();
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  )
                : Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFC7D2FE)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.school_rounded, size: 16, color: Color(0xFF4F46E5)),
                            const SizedBox(width: 6),
                            Text(
                              'Scope: ${_selectedYear.replaceAll('_', ' ')}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4F46E5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_levels.length} configured',
                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
          ),

          // ── Levels List / State Views ──────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: PragatiXLoader(message: 'Loading levels...'))
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 48),
                              const SizedBox(height: 12),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _fetchLevels,
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
                                child: const Text('Try Again', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _levels.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEEF2FF),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Icon(
                                      Icons.military_tech_rounded,
                                      size: 38,
                                      color: Color(0xFF6366F1),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No levels configured for this academic year',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Create the first progression level to define XP milestones, objectives, and unlocks.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton.icon(
                                    onPressed: () => _openAddEditLevelModal(),
                                    icon: const Icon(Icons.add, color: Colors.white, size: 18),
                                    label: const Text('Add First Level', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4F46E5),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchLevels,
                            color: const Color(0xFF4F46E5),
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                              itemCount: _levels.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 14),
                              itemBuilder: (context, index) {
                                final lvl = _levels[index];
                                return _buildLevelCard(lvl);
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  Widget _buildLevelCard(Map<String, dynamic> lvl) {
    final int id = lvl['id'] ?? 0;
    final int levelNum = lvl['levelNumber'] ?? 1;
    final String title = lvl['title'] ?? 'Untitled Level';
    final int xpMin = lvl['xpMin'] ?? 0;
    final int xpMax = lvl['xpMax'] ?? 0;
    final int stage = lvl['stage'] ?? 1;
    final String? objective = lvl['primaryObjective'];
    final String? unlocks = lvl['keyUnlocks'];
    final String? academicYear = lvl['academicYear'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Level Badge + Title + Action Buttons
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.28),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'L$levelNum',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Level $levelNum: $title',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Stage chip
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Stage $stage',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Academic Year chip (if available)
                          if (academicYear != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                academicYear.replaceAll('_', ' '),
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF4F46E5),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Edit Button
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF4F46E5)),
                  tooltip: 'Edit Level',
                  onPressed: () => _openAddEditLevelModal(lvl),
                ),

                // Delete Button
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFFEF4444)),
                  tooltip: 'Delete Level',
                  onPressed: () => _deleteLevel(id, title, levelNum),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // XP Range Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt_rounded, size: 18, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 6),
                  Text(
                    'XP Range: $xpMin — $xpMax pts',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Span: ${xpMax - xpMin + 1} XP',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),

            // Primary Objective
            if (objective != null && objective.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.flag_outlined, size: 15, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Objective: $objective',
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569), height: 1.3),
                    ),
                  ),
                ],
              ),
            ],

            // Key Unlocks
            if (unlocks != null && unlocks.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lock_open_rounded, size: 15, color: Color(0xFF10B981)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Unlocks: $unlocks',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF047857),
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
