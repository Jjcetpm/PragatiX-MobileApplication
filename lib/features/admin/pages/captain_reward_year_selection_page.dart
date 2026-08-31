import 'package:flutter/material.dart';
import 'package:pragatix/core/theme/app_colors.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/features/admin/repository/admin_repository.dart';
import 'package:pragatix/core/widgets/pragatix_loader.dart';
import 'captain_reward_settings_page.dart';

class CaptainRewardYearSelectionPage extends StatefulWidget {
  const CaptainRewardYearSelectionPage({super.key});

  @override
  State<CaptainRewardYearSelectionPage> createState() =>
      _CaptainRewardYearSelectionPageState();
}

class _CaptainRewardYearSelectionPageState
    extends State<CaptainRewardYearSelectionPage> {
  final AdminRepository _repository = getIt<AdminRepository>();
  List<Map<String, dynamic>> _yearsList = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchYears();
  }

  Future<void> _fetchYears() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final List<dynamic> years = await _repository.getYears();
      final List<dynamic> admins = await _repository.getYearAdmins();

      final List<Map<String, dynamic>> matchedYears = [];

      for (var y in years) {
        if (y is! Map) continue;
        final yId = y['id']?.toString().trim();
        final yNo = y['yearNo']?.toString().trim();
        final yName = (y['yearName'] ?? '').toString().trim().toLowerCase();

        Map<String, dynamic>? assignedAdmin;
        for (var a in admins) {
          if (a is! Map) continue;
          final aYearId = a['assignedYearId']?.toString().trim();
          final aYearName = (a['assignedYearName'] ?? '').toString().trim().toLowerCase();

          bool isMatch = false;
          if (yId != null && aYearId != null && yId == aYearId) {
            isMatch = true;
          } else if (aYearName.isNotEmpty && aYearName != 'null' && aYearName != 'not assigned') {
            if (yName == aYearName) {
              isMatch = true;
            } else if (yNo != null && aYearName.contains(yNo)) {
              isMatch = true;
            } else if (yName.contains('first') && aYearName.contains('first')) {
              isMatch = true;
            } else if (yName.contains('second') && aYearName.contains('second')) {
              isMatch = true;
            } else if (yName.contains('third') && aYearName.contains('third')) {
              isMatch = true;
            } else if (yName.contains('fourth') && aYearName.contains('fourth')) {
              isMatch = true;
            }
          }

          if (isMatch) {
            assignedAdmin = Map<String, dynamic>.from(a);
            break;
          }
        }

        if (assignedAdmin != null) {
          final enrichedYear = Map<String, dynamic>.from(y);
          final adminName = (assignedAdmin['fullName'] != null &&
                  assignedAdmin['fullName'].toString().trim().isNotEmpty)
              ? assignedAdmin['fullName']
              : (assignedAdmin['username'] ?? 'Assigned');
          enrichedYear['assignedAdminName'] = adminName;
          matchedYears.add(enrichedYear);
        }
      }

      if (!mounted) return;
      setState(() {
        _yearsList = matchedYears;
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

  IconData _getIconForYear(int yearNumber) {
    switch (yearNumber) {
      case 1:
        return Icons.looks_one;
      case 2:
        return Icons.looks_two;
      case 3:
        return Icons.looks_3;
      case 4:
        return Icons.looks_4;
      default:
        return Icons.school;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Captain & Vice Captain Rewards',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.adminPrimary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Refresh',
            onPressed: _fetchYears,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select Academic Year',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Select an academic year to configure Captain & Vice Captain automated rewards.',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Expanded(
              child: _isLoading
                  ? const Center(child: PragatiXLoader(message: 'Loading assigned years...'))
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 48),
                              const SizedBox(height: 16),
                              Text(_error!, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16)),
                              const SizedBox(height: 16),
                              ElevatedButton(onPressed: _fetchYears, child: const Text('Retry')),
                            ],
                          ),
                        )
                      : _yearsList.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(18),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEE2E2),
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: const Icon(
                                        Icons.admin_panel_settings_outlined,
                                        size: 52,
                                        color: Color(0xFFEF4444),
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    const Text(
                                      'No Year Admins Assigned',
                                      style: TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Only academic years with an assigned Year Admin are displayed here.\nPlease assign a Year Admin in the Admins tab first.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _fetchYears,
                              color: AppColors.adminPrimary,
                              child: ListView.separated(
                                itemCount: _yearsList.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  final year = _yearsList[index];
                                  final String yearName = year['yearName'] ?? 'Unknown Year';
                                  final int yearNo = year['yearNo'] is int
                                      ? year['yearNo']
                                      : (int.tryParse(year['yearNo']?.toString() ?? '') ?? (index + 1));
                                  final String enumValue = yearName.toUpperCase().replaceAll(' ', '_');
                                  final String? adminName = year['assignedAdminName'];

                                  return _buildYearCard(
                                    context,
                                    '🎓 $yearName',
                                    enumValue,
                                    _getIconForYear(yearNo),
                                    adminName: adminName,
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearCard(
    BuildContext context,
    String title,
    String yearValue,
    IconData icon, {
    String? adminName,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CaptainRewardSettingsPage(academicYear: yearValue),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
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
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (adminName != null && adminName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.admin_panel_settings_rounded, size: 14, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Text(
                            'Admin: $adminName',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
