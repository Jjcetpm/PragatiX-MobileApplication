import 'package:flutter/material.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/core/utils/error_handler.dart';
import 'package:pragatix/features/activity/models/activity_model.dart';
import 'package:pragatix/features/activity/pages/cc_teacher_assign_page.dart';
import 'package:pragatix/features/activity/services/cc_activity_service.dart';
import 'package:pragatix/shared/widgets/activity_card.dart';

class CCActivityListPage extends StatefulWidget {
  final int? stageId;
  final String? stageName;
  final String? categoryTitle;
  final String? subgroupFilter;
  final String? academicYear;
  final bool showAppBar;

  const CCActivityListPage({
    super.key,
    this.stageId,
    this.stageName,
    this.categoryTitle,
    this.subgroupFilter,
    this.academicYear,
    this.showAppBar = true,
  });

  @override
  State<CCActivityListPage> createState() => _CCActivityListPageState();
}

class _CCActivityListPageState extends State<CCActivityListPage> {
  final CCActivityService _ccActivityService = getIt<CCActivityService>();
  final TextEditingController _searchController = TextEditingController();

  List<ActivityModel> _activities = [];
  List<ActivityModel> _filteredActivities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchActivities();
    _searchController.addListener(_filterActivities);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchActivities() async {
    setState(() => _isLoading = true);
    try {
      final list = await _ccActivityService.fetchActivities(
        stageId: widget.stageId,
        subgroup: widget.subgroupFilter,
      );
      if (mounted) {
        setState(() {
          _activities = list;
          _isLoading = false;
        });
        _filterActivities();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ErrorHandler.showSnackBar(context, e);
      }
    }
  }

  void _filterActivities() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredActivities = _activities.where((act) {
        final matchesQuery = query.isEmpty ||
            act.name.toLowerCase().contains(query) ||
            act.description.toLowerCase().contains(query) ||
            (act.subgroup != null && act.subgroup!.toLowerCase().contains(query));

        return matchesQuery;
      }).toList();
    });
  }

  void _openAssignPage(ActivityModel activity) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CCTeacherAssignPage(
          activity: activity,
          stageId: widget.stageId,
          stageName: widget.stageName,
          categoryTitle: widget.categoryTitle,
        ),
      ),
    );

    if (result == true) {
      _fetchActivities();
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.categoryTitle != null
        ? '${widget.categoryTitle}'
        : (widget.stageName != null ? widget.stageName! : 'Class Activities');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: widget.showAppBar
          ? AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  if (widget.stageName != null && widget.categoryTitle != null)
                    Text(
                      widget.stageName!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                ],
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
              leading: widget.stageId != null
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    )
                  : null,
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _fetchActivities,
        color: const Color(0xFF11998E),
        child: Column(
          children: [
            // Search Bar Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              color: Colors.white,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search activities...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF11998E)),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // Main Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF11998E),
                      ),
                    )
                  : _filteredActivities.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.4,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.assignment_late_outlined,
                                      size: 64,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _searchController.text.isNotEmpty
                                          ? 'No matching activities found'
                                          : 'No activities in this category',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Pull down to refresh',
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
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredActivities.length,
                          itemBuilder: (context, index) {
                            final activity = _filteredActivities[index];
                            return ActivityCard(
                              activity: activity,
                              isReadOnly: false,
                              isCc: true,
                              onEdit: () {},
                              onDelete: () {},
                              onTap: () => _openAssignPage(activity),
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
