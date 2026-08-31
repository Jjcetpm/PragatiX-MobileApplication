import 'package:flutter/material.dart';
import 'package:pragatix/core/theme/app_colors.dart';
import 'package:pragatix/features/admin/pages/activity_tab.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/features/admin/repository/admin_repository.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/core/widgets/pragatix_loader.dart';

class YearSelectionPage extends StatefulWidget {
  const YearSelectionPage({super.key});

  @override
  State<YearSelectionPage> createState() => _YearSelectionPageState();
}

class _YearSelectionPageState extends State<YearSelectionPage> {
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

        // Check if any admin is assigned to this year
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

        // Only include this year if an admin is assigned to it
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

  List<Color> _getGradientForYear(int yearNo) {
    switch (yearNo) {
      case 1:
        return const [Color(0xFF3B82F6), Color(0xFF2563EB)];
      case 2:
        return const [Color(0xFF10B981), Color(0xFF059669)];
      case 3:
        return const [Color(0xFFF59E0B), Color(0xFFD97706)];
      case 4:
        return const [Color(0xFF8B5CF6), Color(0xFF7C3AED)];
      default:
        return const [Color(0xFF6366F1), Color(0xFF4F46E5)];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              'Activity & Thresholds',
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
                              'Select academic year to manage stages & activities',
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
                        tooltip: 'Refresh',
                        onPressed: _fetchYears,
                      ),
                    ],
                  ),
                ),

                // Body content
                Expanded(
                  child: _isLoading
                      ? const Center(child: PragatiXLoader(message: 'Loading assigned years...'))
                      : _error != null
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEE2E2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Icon(
                                        Icons.error_outline_rounded,
                                        color: Color(0xFFEF4444),
                                        size: 40,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _error!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Color(0xFF0F172A),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _fetchYears,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF2563EB),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
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
                                            size: 48,
                                            color: Color(0xFFEF4444),
                                          ),
                                        ),
                                        const SizedBox(height: 18),
                                        const Text(
                                          'No Year Admins Assigned',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Only academic years with an assigned Year Admin are displayed here.\nPlease assign a Year Admin in the Admins tab first.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF64748B),
                                            height: 1.4,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        ElevatedButton.icon(
                                          onPressed: _fetchYears,
                                          icon: const Icon(Icons.refresh_rounded, size: 18),
                                          label: const Text('Refresh'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF2563EB),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: _fetchYears,
                                  color: const Color(0xFF2563EB),
                                  child: ListView.separated(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
                                    itemCount: _yearsList.length,
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      final year = _yearsList[index];
                                      final String yearName =
                                          year['yearName'] ?? 'Unknown Year';
                                      final int yearNo = year['yearNo'] is int
                                          ? year['yearNo']
                                          : (int.tryParse(year['yearNo']?.toString() ?? '') ?? (index + 1));
                                      final String enumValue = yearName
                                          .toUpperCase()
                                          .replaceAll(' ', '_');
                                      final String? adminName = year['assignedAdminName'];

                                      return _buildYearCard(
                                        context,
                                        yearName,
                                        enumValue,
                                        _getIconForYear(yearNo),
                                        yearNo: yearNo,
                                        adminName: adminName,
                                      );
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

  Widget _buildYearCard(
    BuildContext context,
    String title,
    String yearValue,
    IconData icon, {
    required int yearNo,
    String? adminName,
  }) {
    final gradientColors = _getGradientForYear(yearNo);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            final authProvider = context.read<AuthProvider>();
            await authProvider.setSelectedAcademicYear(yearValue);

            if (!context.mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    AdminActivityManagementPage(selectedYear: yearValue),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradientColors,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors.first.withValues(alpha: 0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 5),
                      if (adminName != null && adminName.isNotEmpty)
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(7),
                                border: Border.all(color: const Color(0xFFBFDBFE)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.admin_panel_settings_rounded,
                                    size: 13,
                                    color: Color(0xFF1D4ED8),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    adminName,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1D4ED8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      else
                        const Text(
                          'Configure stages and activity limits',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
