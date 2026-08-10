import 'package:flutter/material.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/core/utils/error_handler.dart';
import 'package:pragatix/features/activity/models/activity_model.dart';
import 'package:pragatix/features/activity/pages/cc_stage_details_page.dart';
import 'package:pragatix/features/activity/pages/cc_teacher_assign_page.dart';
import 'package:pragatix/features/activity/services/cc_activity_service.dart';

class CCStageListPage extends StatefulWidget {
  final bool isSubPage;

  const CCStageListPage({
    super.key,
    this.isSubPage = false,
  });

  @override
  State<CCStageListPage> createState() => _CCStageListPageState();
}

class _CCStageListPageState extends State<CCStageListPage> {
  final CCActivityService _ccActivityService = getIt<CCActivityService>();

  static const Color _dark = Color(0xFF1E293B);

  List<Map<String, dynamic>> _stages = [];
  bool _isLoading = true;
  Map<String, dynamic>? _classDetails;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final details = await _ccActivityService.fetchClassDetails().catchError((_) => <String, dynamic>{});
      if (mounted && details.isNotEmpty) {
        setState(() {
          _classDetails = details;
        });
      }
    } catch (_) {}

    _fetchStages();
  }

  Future<void> _fetchStages() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final list = await _ccActivityService.fetchStages();
      if (mounted) {
        setState(() {
          _stages = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ErrorHandler.showSnackBar(context, e);
      }
    }
  }

  void _onStageSelected(Map<String, dynamic> stage) {
    final stageId = (stage['id'] as num).toInt();
    final stageName = (stage['name'] ?? 'Stage').toString();
    final stageDescription = (stage['description'] ?? '').toString();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CCStageDetailsPage(
          stageId: stageId,
          stageName: stageName,
          stageDescription: stageDescription,
          stageData: stage,
        ),
      ),
    ).then((_) => _fetchStages());
  }

  void _openQuickAssignStaffModal() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _QuickAssignActivityPicker(
          ccActivityService: _ccActivityService,
          stages: _stages,
          onActivitySelected: (activity, stageId, stageName) {
            Navigator.pop(ctx);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CCTeacherAssignPage(
                  activity: activity,
                  stageId: stageId,
                  stageName: stageName,
                ),
              ),
            ).then((_) => _fetchStages());
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          widget.isSubPage ? 'Assign Staff' : 'Activities',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Refresh',
            onPressed: _fetchStages,
          ),
        ],
      ),
      body: Column(
        children: [
          // Class Info Header Banner
          if (_classDetails != null && _classDetails!['departmentName'] != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF11998E).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      size: 20,
                      color: Color(0xFF11998E),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_classDetails!['departmentName']} • Section ${_classDetails!['sectionName'] ?? 'A'}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _dark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Academic Year: ${_classDetails!['yearName'] ?? _classDetails!['year'] ?? 'First Year'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _openQuickAssignStaffModal,
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 16, color: Colors.white),
                    label: const Text(
                      'Assign Staff',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF11998E),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 1,
                    ),
                  ),
                ],
              ),
            ),

          // Stages List View
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchStages,
              color: const Color(0xFF11998E),
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF11998E),
                      ),
                    )
                  : _stages.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.5,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.layers_clear_outlined,
                                      size: 64,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No stages found for selected Academic Year',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Pull down to refresh or select another year',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          itemCount: _stages.length,
                          itemBuilder: (context, index) {
                            final stage = _stages[index];
                            final name = (stage['name'] ?? 'Stage ${index + 1}').toString();
                            final desc = (stage['description'] ?? 'No description available').toString();
                            final statusStr = (stage['status'] ?? 'ACTIVE').toString().toUpperCase();
                            final displayOrder = stage['displayOrder'] ?? (index + 1);
                            final expectedXp = stage['expectedXp'] ?? 0;
                            final mThresh = stage['mustThreshold'] ?? 0;
                            final iThresh = stage['individualThreshold'] ?? 0;
                            final gThresh = stage['groupThreshold'] ?? 0;

                            // Admin stage card styling replica
                            return Card(
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              margin: const EdgeInsets.only(bottom: 16),
                              child: InkWell(
                                onTap: () => _onStageSelected(stage),
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    name,
                                                    style: const TextStyle(
                                                      fontSize: 19,
                                                      fontWeight: FontWeight.bold,
                                                      color: _dark,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: statusStr == 'ACTIVE'
                                                        ? Colors.green.shade50
                                                        : Colors.grey.shade100,
                                                    borderRadius: BorderRadius.circular(4),
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
                                                              ? Colors.blue.shade800
                                                              : Colors.grey.shade700),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              desc,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey.shade600,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 12),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 6,
                                              crossAxisAlignment: WrapCrossAlignment.center,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey.shade200,
                                                    borderRadius: BorderRadius.circular(4),
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
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue.shade50,
                                                    borderRadius: BorderRadius.circular(4),
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
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red.shade50,
                                                    borderRadius: BorderRadius.circular(4),
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
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue.shade50,
                                                    borderRadius: BorderRadius.circular(4),
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
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green.shade50,
                                                    borderRadius: BorderRadius.circular(4),
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
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        color: Colors.grey.shade400,
                                        size: 26,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper Modal for CC to pick an activity to assign staff directly from the home page
class _QuickAssignActivityPicker extends StatefulWidget {
  final CCActivityService ccActivityService;
  final List<Map<String, dynamic>> stages;
  final void Function(ActivityModel activity, int? stageId, String? stageName) onActivitySelected;

  const _QuickAssignActivityPicker({
    required this.ccActivityService,
    required this.stages,
    required this.onActivitySelected,
  });

  @override
  State<_QuickAssignActivityPicker> createState() => _QuickAssignActivityPickerState();
}

class _QuickAssignActivityPickerState extends State<_QuickAssignActivityPicker> {
  int? _selectedStageId;
  String? _selectedStageName;
  List<ActivityModel> _activities = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.stages.isNotEmpty) {
      _selectedStageId = (widget.stages.first['id'] as num).toInt();
      _selectedStageName = widget.stages.first['name']?.toString();
      _loadActivities();
    }
  }

  Future<void> _loadActivities() async {
    setState(() => _loading = true);
    try {
      final list = await widget.ccActivityService.fetchActivities(stageId: _selectedStageId);
      if (mounted) {
        setState(() {
          _activities = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.assignment_ind_rounded, color: Color(0xFF11998E)),
                const SizedBox(width: 8),
                const Text(
                  'Select Activity to Assign Staff',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Stage Selector
          if (widget.stages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: widget.stages.map((stage) {
                    final id = (stage['id'] as num).toInt();
                    final name = (stage['name'] ?? 'Stage').toString();
                    final isSelected = _selectedStageId == id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(name),
                        selected: isSelected,
                        selectedColor: const Color(0xFF11998E),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _selectedStageId = id;
                              _selectedStageName = name;
                            });
                            _loadActivities();
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF11998E)))
                : _activities.isEmpty
                    ? Center(
                        child: Text(
                          'No activities available in this stage.',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _activities.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (ctx, i) {
                          final act = _activities[i];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF11998E).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.event_note_rounded, color: Color(0xFF11998E)),
                            ),
                            title: Text(
                              act.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            subtitle: Text(
                              'Subgroup: ${act.subgroup ?? 'General'} • XP: ${act.awardXp}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                            onTap: () => widget.onActivitySelected(act, _selectedStageId, _selectedStageName),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
