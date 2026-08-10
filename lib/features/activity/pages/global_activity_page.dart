import 'package:flutter/material.dart';
import '../models/activity_model.dart';
import '../providers/activity_provider.dart';
import '../../../shared/widgets/activity_card.dart';
import 'edit_activity_page.dart';
import 'assign_staff_page.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/di/service_locator.dart';
import 'package:pragatix/core/theme/app_colors.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';

class GlobalActivityPage extends StatefulWidget {
  final String? selectedYear;
  const GlobalActivityPage({Key? key, this.selectedYear}) : super(key: key);

  @override
  State<GlobalActivityPage> createState() => _GlobalActivityPageState();
}

class _GlobalActivityPageState extends State<GlobalActivityPage>
    with SingleTickerProviderStateMixin {
  late ActivityProvider _provider;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.selectedYear;
    _provider = getIt<ActivityProvider>();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider.loadActivities(academicYear: _selectedYear);
      if (_provider.departments.isEmpty || _provider.allTeachers.isEmpty) {
        _provider.loadDependencies();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<ActivityModel> get _filteredActivities {
    if (_provider.activities.isEmpty) return [];

    // Tab 0: All
    // Tab 1: Unassigned (mappedStages is empty)

    return _provider.activities.where((a) {
      if (_tabController.index == 1) {
        return a.mappedStages.isEmpty;
      }
      return true;
    }).toList();
  }

  Future<void> _handleDelete(
    ActivityModel activity, {
    bool force = false,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(force ? 'Force Delete Activity' : 'Delete Activity'),
        content: Text(
          force
              ? 'Are you sure you want to FORCE delete this activity? This will permanently wipe all history and XP.'
              : 'Are you sure you want to delete this activity?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _provider.deleteActivity(activity.id, force: force);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Activity deleted successfully.')),
        );
      }
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('409:')) {
        final msg = errorStr.split('409:').last;
        if (mounted) {
          _showDependencyDialog(activity, msg);
        }
      } else {
        if (mounted) ErrorHandler.showSnackBar(context, e);
      }
    }
  }

  void _showDependencyDialog(ActivityModel activity, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cannot Delete Activity'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleDelete(activity, force: true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Force Delete'),
          ),
        ],
      ),
    );
  }

  String? _selectedYear;

  bool get _isSuperAdmin {
    final roles = getIt<AuthProvider>().currentUser?['roles'] as List<dynamic>? ?? [];
    return roles.contains('ROLE_SUPER_ADMIN');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Activity Management'),
        backgroundColor: AppColors.adminPrimary,
        foregroundColor: Colors.white,
        actions: [
          if (_isSuperAdmin &&
              false) // Hide the dropdown as we now use YearSelectionPage
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: DropdownButton<String>(
                value: _selectedYear,
                hint: const Text(
                  'Select Year',
                  style: TextStyle(color: Colors.white70),
                ),
                dropdownColor: AppColors.adminPrimary,
                style: const TextStyle(color: Colors.white),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                underline: Container(),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All Years')),
                  DropdownMenuItem(
                    value: 'FIRST_YEAR',
                    child: Text('1st Year'),
                  ),
                  DropdownMenuItem(
                    value: 'SECOND_YEAR',
                    child: Text('2nd Year'),
                  ),
                  DropdownMenuItem(
                    value: 'THIRD_YEAR',
                    child: Text('3rd Year'),
                  ),
                  DropdownMenuItem(
                    value: 'FOURTH_YEAR',
                    child: Text('4th Year'),
                  ),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedYear = val;
                  });
                  _provider.loadActivities(academicYear: val);
                },
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'All Active'),
            Tab(text: 'Unassigned'),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: _provider,
        builder: (context, _) {
          if (_provider.isLoadingActivities) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    _provider.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  TextButton(
                    onPressed: () => _provider.loadActivities(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final list = _filteredActivities;

          if (list.isEmpty) {
            return const Center(child: Text('No activities found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final act = list[index];
              return ActivityCard(
                activity: act,
                onEdit: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          EditActivityPage(provider: _provider, activity: act),
                    ),
                  ).then((value) {
                    if (value == true) _provider.loadActivities();
                  });
                },
                onDelete: () => _handleDelete(act),
                isCc: false,
                isReadOnly: false,
                showGlobalActions: true,
                onAssign: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AssignStaffPage(provider: _provider, activity: act),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
