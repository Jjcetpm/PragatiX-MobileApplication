import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/core/config/api_config.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pragatix/features/student/services/student_proxy_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/xp/providers/xp_provider.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pragatix/features/attendance/providers/attendance_provider.dart';
import 'package:pragatix/core/widgets/pragatix_loader.dart';

class PointReviewTab extends StatefulWidget {
  final VoidCallback? onBack;

  const PointReviewTab({super.key, this.onBack});

  @override
  State<PointReviewTab> createState() => _PointReviewTabState();
}

class _PointReviewTabState extends State<PointReviewTab> {
  bool isLoading = true;
  String regNo = '';
  int currentStage = 1;

  // Category Configuration
  final Map<String, Map<String, dynamic>> categoryConfig = {
    'ACADEMIC': {
      'color': Colors.blue,
      'priority': 'HIGH',
      'decay': 'Streak decays if broken ↺',
    },
    'SKILL': {
      'color': Colors.purple,
      'priority': 'HIGH',
      'decay': 'Permanent ✓',
    },
    'COMMUNICATION': {
      'color': Colors.indigo,
      'priority': 'HIGH',
      'decay': 'Permanent ✓',
    },
    'LEADERSHIP': {
      'color': Colors.amber,
      'priority': 'MEDIUM-HIGH',
      'decay': 'Permanent ✓',
    },
    'INNOVATION': {
      'color': Colors.orange,
      'priority': 'HIGH',
      'decay': 'Permanent ✓',
    },
    'PLACEMENT': {
      'color': Colors.green,
      'priority': 'HIGH',
      'decay': 'Permanent ✓',
    },
    'DISCIPLINE': {
      'color': Colors.red,
      'priority': 'MEDIUM',
      'decay': 'Resets if streak broken ↺',
    },
    'COMMUNITY': {
      'color': Colors.teal,
      'priority': 'MEDIUM',
      'decay': 'Resets per semester ↺',
    },
    'SPORTS': {
      'color': Colors.pink,
      'priority': 'MEDIUM',
      'decay': 'Permanent ✓',
    },
    'CULTURAL': {
      'color': Colors.cyan,
      'priority': 'MEDIUM',
      'decay': 'Permanent ✓',
    },
  };

  String _selectedTimeFilter = 'All Time';

  @override
  void initState() {
    super.initState();
    _loadProfileAndData();
  }

  Future<void> _loadProfileAndData() async {
    if (mounted) setState(() => isLoading = true);
    try {
      final token = context.read<AuthProvider>().token ?? '';
      if (token.isEmpty || token == 'debug_token') {
        if (mounted) setState(() => isLoading = false);
        return;
      }

      final response = await getIt<StudentProxyService>().get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/me'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final resData = data['data'];
          if (mounted) {
            setState(() {
              regNo = resData['username'] ?? '';
              currentStage = resData['stage'] ?? 1;
            });
          }
        }
      }

      if (!mounted) return;
      final xpProv = Provider.of<XpProvider>(context, listen: false);

      await Future.wait([
        xpProv.fetchSummary(regNo, token).catchError((_) {}),
        xpProv.fetchHistory(regNo, token).catchError((_) {}),
        if (xpProv.stages.isEmpty) xpProv.fetchStages(token).catchError((_) {}),
      ]).timeout(const Duration(seconds: 8), onTimeout: () => []);
    } catch (e) {
      debugPrint('Error in point review _loadProfileAndData: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final xpProvider = Provider.of<XpProvider>(context);

    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: PragatiXLoader(fullScreen: false, message: 'Loading Points...'),
        ),
      );
    }

    // Check if streak bonuses are active (e.g. coding streak > 7)
    final codingStreak = xpProvider.streaks.firstWhere(
      (s) => s['streakType'] == 'C_CODING',
      orElse: () => null,
    );
    final hasCodingBonus =
        codingStreak != null &&
        (codingStreak['currentStreak'] ?? 0) >= 7 &&
        !(codingStreak['isBroken'] ?? false);

    final attendanceProvider = Provider.of<AttendanceProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header Section with Sky Blue Gradient
          _buildTopHeader(attendanceProvider.currentStreak),
          const SizedBox(height: 16),

          // Active Streak Bonuses Banner
          if (hasCodingBonus)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Text('🔥 ', style: TextStyle(fontSize: 16)),
                  Expanded(
                    child: Text(
                      '7-Day Coding Streak Active — 2x XP all coding this week!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // XP Summary Header & Dropdown
          _buildSummaryHeader(),
          const SizedBox(height: 12),

          // XP Summary Cards (dynamically computed for selected timeframe)
          _buildSummaryCards(_getFilteredSummary(xpProvider.xpByCategory, xpProvider.history)),

          const SizedBox(height: 20),

          // XP Submission History Header
          _buildHistoryHeader(_getFilteredHistory(xpProvider.history)),
          const SizedBox(height: 8),

          // XP Submission History List (filtered by selected timeframe)
          Expanded(child: _buildHistoryList(_getFilteredHistory(xpProvider.history))),
        ],
      ),
    );
  }

  // ── Section 0: Top Header ──────────────────────────────────────────────────
  Widget _buildTopHeader(int streakCount) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.onBack != null || Navigator.canPop(context)) ...[
                InkWell(
                  onTap: () {
                    if (widget.onBack != null) {
                      widget.onBack!();
                    } else if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1.2,
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'XP Tracker',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Monitor your XP breakdown\nand activity submission history.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Streak pill badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      '$streakCount',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Time Filter Helper Methods ─────────────────────────────────────────────
  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is int) {
      if (value > 1000000000000) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } else if (value > 1000000000) {
        return DateTime.fromMillisecondsSinceEpoch(value * 1000);
      }
    }
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  bool _isWithinSelectedFilter(dynamic dateValue) {
    if (_selectedTimeFilter == 'All Time') return true;
    final dt = _parseDateTime(dateValue);
    if (dt == null) return true; // If no date, retain by default

    final now = DateTime.now();
    if (_selectedTimeFilter == 'This Week') {
      final startOfWeek = DateTime(now.year, now.month, now.day - (now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 7));
      return (dt.isAfter(startOfWeek) || dt.isAtSameMomentAs(startOfWeek)) && dt.isBefore(endOfWeek);
    } else if (_selectedTimeFilter == 'This Month') {
      final startOfMonth = DateTime(now.year, now.month, 1);
      final nextMonth = (now.month == 12)
          ? DateTime(now.year + 1, 1, 1)
          : DateTime(now.year, now.month + 1, 1);
      return (dt.isAfter(startOfMonth) || dt.isAtSameMomentAs(startOfMonth)) && dt.isBefore(nextMonth);
    }
    return true;
  }

  List<dynamic> _getFilteredHistory(List<dynamic> history) {
    if (_selectedTimeFilter == 'All Time') {
      return history;
    }
    return history.where((log) {
      final dateVal = log['submittedAt'] ?? log['createdAt'] ?? log['date'];
      return _isWithinSelectedFilter(dateVal);
    }).toList();
  }

  Map<String, int> _getFilteredSummary(
    Map<String, int> allTimeCategories,
    List<dynamic> history,
  ) {
    return {
      'individualXp': allTimeCategories['individualXp'] ?? 0,
      'groupXp': allTimeCategories['groupXp'] ?? 0,
      'mustXp': allTimeCategories['mustXp'] ?? 0,
    };
  }
  Widget _buildSummaryHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'XP Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section 2: XP Summary Cards ────────────────────────────────────────────
  Widget _buildSummaryCards(Map<String, int> categories) {
    final individualXp = categories['individualXp'] ?? 0;
    final groupXp = categories['groupXp'] ?? 0;
    final mustXp = categories['mustXp'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          // Card 1: Individual XP
          Expanded(
            child: _buildSummaryCard(
              title: 'Individual XP',
              value: individualXp,
              tag: 'HIGH',
              cardBgColor: const Color(0xFFF0F9FF),
              accentColor: const Color(0xFF0284C7),
              iconBgColor: const Color(0xFFE0F2FE),
              tagBgColor: const Color(0xFFE0F2FE),
              tagTextColor: const Color(0xFF0284C7),
            ),
          ),
          const SizedBox(width: 10),

          // Card 2: Group XP
          Expanded(
            child: _buildSummaryCard(
              title: 'Group XP',
              value: groupXp,
              tag: 'HIGH',
              cardBgColor: const Color(0xFFF0FDF4),
              accentColor: const Color(0xFF16A34A),
              iconBgColor: const Color(0xFFDCFCE7),
              tagBgColor: const Color(0xFFDCFCE7),
              tagTextColor: const Color(0xFF16A34A),
            ),
          ),
          const SizedBox(width: 10),

          // Card 3: Must XP
          Expanded(
            child: _buildSummaryCard(
              title: 'Must XP',
              value: mustXp,
              tag: 'MANDATORY',
              cardBgColor: const Color(0xFFFFF7ED),
              accentColor: const Color(0xFFEA580C),
              iconBgColor: const Color(0xFFFFEDD5),
              tagBgColor: const Color(0xFFFFEDD5),
              tagTextColor: const Color(0xFFEA580C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required int value,
    required String tag,
    required Color cardBgColor,
    required Color accentColor,
    required Color iconBgColor,
    required Color tagBgColor,
    required Color tagTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: iconBgColor.withValues(alpha: 0.8), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Category Label
          Text(
            title,
            style: TextStyle(
              color: accentColor,
              fontWeight: FontWeight.bold,
              fontSize: 11.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // XP Value
          Text(
            '$value XP',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          // Tag / Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: tagBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              tag,
              style: TextStyle(
                color: tagTextColor,
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section 3: XP Submission History Header ────────────────────────────────
  Widget _buildHistoryHeader(List<dynamic> history) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'XP Submission History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section 4: XP Submission History List ──────────────────────────────────
  Widget _buildHistoryList(List<dynamic> history) {
    if (history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history_edu_rounded, size: 54, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                'No XP logs found.\nSubmit your first activity claim!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      physics: const BouncingScrollPhysics(),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final log = history[index];
        final String activityName =
            log['activityName'] ?? log['title'] ?? 'Activity Submission';
        final int points = log['xpPoints'] ?? log['points'] ?? 0;
        final bool isPositive = points >= 0;
        final String status =
            (log['status'] ?? 'APPROVED').toString().toUpperCase();

        // Format date: e.g. 2026 08 27
        String dateStr = '';
        if (log['submittedAt'] != null) {
          try {
            final parsed = DateTime.parse(log['submittedAt'].toString());
            dateStr = DateFormat('yyyy MM dd').format(parsed);
          } catch (_) {
            dateStr = log['submittedAt']
                .toString()
                .split('T')[0]
                .replaceAll('-', ' ');
          }
        } else if (log['date'] != null) {
          dateStr = log['date'].toString().replaceAll('-', ' ');
        }

        // Status pill color
        final bool isApproved = status == 'APPROVED';
        final bool isRejected = status == 'REJECTED';
        final Color statusBg = isApproved
            ? const Color(0xFFDCFCE7)
            : isRejected
                ? const Color(0xFFFEE2E2)
                : const Color(0xFFFEF3C7);
        final Color statusColor = isApproved
            ? const Color(0xFF16A34A)
            : isRejected
                ? const Color(0xFFDC2626)
                : const Color(0xFFD97706);

        final String? approvedBy = log['approvedBy'] ??
            log['awardedBy'] ??
            log['teacherName'] ??
            log['reviewedBy'] ??
            log['teacher'];

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                _showLogDetails(log);
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                child: Row(
                  children: [
                    // Left circular trophy icon
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF5F3FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        color: Color(0xFF7C3AED),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Middle activity title & status
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activityName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                              fontSize: 13.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              if (dateStr.isNotEmpty) ...[
                                Text(
                                  dateStr,
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: statusBg,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: statusColor,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                              if (approvedBy != null &&
                                  approvedBy.toString().trim().isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '• ${approvedBy.toString()}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Right points & chevron
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isPositive ? '+$points XP' : '$points XP',
                          style: TextStyle(
                            color: isPositive
                                ? const Color(0xFF16A34A)
                                : Colors.red,
                            fontWeight: FontWeight.w800,
                            fontSize: 14.5,
                            decoration:
                                isRejected ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF64748B),
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showLogDetails(Map<String, dynamic> log) {
    final String activityName =
        log['activityName'] ?? log['title'] ?? 'Activity Submission';
    final int points = log['xpPoints'] ?? log['points'] ?? 0;
    final bool isPositive = points >= 0;
    final String status =
        (log['status'] ?? 'APPROVED').toString().toUpperCase();
    final String category = log['category'] ?? 'GENERAL';
    final String evidence = log['evidenceUrl'] ??
        log['description'] ??
        'No additional description provided.';
    final String remarks = log['remarks'] ?? log['reviewComment'] ?? '';
    final String? approvedBy = log['approvedBy'] ??
        log['awardedBy'] ??
        log['teacherName'] ??
        log['reviewedBy'] ??
        log['teacher'];

    String dateStr = '';
    if (log['submittedAt'] != null) {
      try {
        final parsed = DateTime.parse(log['submittedAt'].toString());
        dateStr = DateFormat('yyyy-MM-dd HH:mm').format(parsed);
      } catch (_) {
        dateStr = log['submittedAt'].toString();
      }
    }

    final bool isApproved = status == 'APPROVED';
    final bool isRejected = status == 'REJECTED';
    final Color statusBg = isApproved
        ? const Color(0xFFDCFCE7)
        : isRejected
            ? const Color(0xFFFEE2E2)
            : const Color(0xFFFEF3C7);
    final Color statusColor = isApproved
        ? const Color(0xFF16A34A)
        : isRejected
            ? const Color(0xFFDC2626)
            : const Color(0xFFD97706);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                  Text(
                    isPositive ? '+$points XP' : '$points XP',
                    style: TextStyle(
                      color: isPositive ? const Color(0xFF16A34A) : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                activityName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              if (dateStr.isNotEmpty)
                Text(
                  'Submitted: $dateStr',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              const Divider(height: 24),
              Text(
                'Category: $category',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4F46E5),
                ),
              ),
              if (approvedBy != null &&
                  approvedBy.toString().trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline_rounded,
                          size: 18, color: Color(0xFF4F46E5)),
                      const SizedBox(width: 8),
                      Text(
                        isApproved ? 'Awarded by: ' : 'Evaluated by: ',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          approvedBy.toString(),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                'Evidence / Notes:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                evidence,
                style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
              ),
              if (remarks.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Reviewer Remarks:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  remarks,
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF334155)),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // Section C: FAB Evidence submission modal
  void _showEvidenceSubmitSheet(XpProvider xpProvider) {
    String? selectedCategory;
    Map<String, dynamic>? selectedActivity;
    final evidenceDescController = TextEditingController();
    String? selectedFileName;
    int currentStep = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Filter activities based on the selected category and student stage
            final List<Map<String, dynamic>> allActs = [];
            for (var stage in xpProvider.stages) {
              if (stage['substages'] != null) {
                for (var sub in stage['substages']) {
                  if (sub['activities'] != null) {
                    for (var act in sub['activities']) {
                      allActs.add({
                        'name': act['activityName'],
                        'xp': act['rewardXp'],
                        'category': act['category'] ?? 'OTHER',
                        'stage': stage['displayOrder'] ?? 1,
                        'cap': act['frequency'] ?? 'Once',
                      });
                    }
                  }
                }
              }
            }

            final filteredActivities = allActs.where((act) {
              final catMatch =
                  selectedCategory == null ||
                  act['category'] == selectedCategory;
              final stageMatch = act['stage'] <= currentStage;
              return catMatch && stageMatch;
            }).toList();

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Submit Activity Evidence',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          'Step $currentStep of 4',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    // STEP 1: Select Category
                    if (currentStep == 1) ...[
                      const Text(
                        'Select Category',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        dropdownColor: Colors.white,
                        initialValue: selectedCategory,
                        hint: const Text('Choose a category'),
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: categoryConfig.keys.map((cat) {
                          return DropdownMenuItem<String>(
                            value: cat,
                            child: Text(cat),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setModalState(() {
                            selectedCategory = val;
                            selectedActivity = null; // Reset activity
                          });
                        },
                      ),
                    ],

                    // STEP 2: Select Activity
                    if (currentStep == 2) ...[
                      const Text(
                        'Select Activity',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<Map<String, dynamic>>(
                        dropdownColor: Colors.white,
                        initialValue: selectedActivity,
                        hint: const Text('Choose an activity'),
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: filteredActivities.map((act) {
                          final String details =
                              "${act['name']} (+${act['xp']} XP | ${act['cap']})";
                          return DropdownMenuItem<Map<String, dynamic>>(
                            value: act,
                            child: Text(
                              details,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setModalState(() {
                            selectedActivity = val;
                          });
                        },
                      ),
                    ],

                    // STEP 3: Submit Evidence Description & File
                    if (currentStep == 3) ...[
                      const Text(
                        'Evidence Description',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: evidenceDescController,
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'Enter evidence links or verification notes...',
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Upload File Document',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['pdf', 'jpg', 'png', 'doc'],
                          );
                          if (result != null &&
                              result.files.single.name.isNotEmpty) {
                            setModalState(() {
                              selectedFileName = result.files.single.name;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          foregroundColor: Colors.grey.shade800,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.upload_file_rounded),
                        label: Text(
                          selectedFileName ?? 'Select PDF/Photo Document',
                        ),
                      ),
                    ],

                    // STEP 4: Review and Submit
                    if (currentStep == 4) ...[
                      const Text(
                        'Claim Preview',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Activity: ${selectedActivity?['name']}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('Category: $selectedCategory'),
                            const SizedBox(height: 4),
                            Text(
                              "Points to Earn: +${selectedActivity?['xp']} XP",
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('Evidence: ${evidenceDescController.text}'),
                            if (selectedFileName != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Attachment: $selectedFileName',
                                style: const TextStyle(color: Colors.indigo),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                    // Navigation Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (currentStep > 1)
                          TextButton(
                            onPressed: () => setModalState(() => currentStep--),
                            child: const Text(
                              'Back',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          )
                        else
                          const SizedBox(),
                        ElevatedButton(
                          onPressed: () async {
                            if (currentStep == 1 && selectedCategory == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please select a category.'),
                                ),
                              );
                              return;
                            }
                            if (currentStep == 2 && selectedActivity == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please select an activity.'),
                                ),
                              );
                              return;
                            }
                            if (currentStep == 3 &&
                                evidenceDescController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please describe your evidence.',
                                  ),
                                ),
                              );
                              return;
                            }

                            if (currentStep < 4) {
                              setModalState(() => currentStep++);
                            } else {
                              // Submit
                              Navigator.pop(context);
                              final url = evidenceDescController.text.trim();
                              final success = await xpProvider.submitXpClaim(
                                regNo,
                                context.read<AuthProvider>().token!,
                                selectedCategory!,
                                selectedActivity!['name'],
                                selectedActivity!['xp'],
                                url.isNotEmpty ? url : 'Link uploaded',
                              );

                              if (success) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'XP claim submitted for approval!',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                // Reload data
                                if (!mounted) return;
                                await xpProvider.fetchSummary(
                                  regNo,
                                  context.read<AuthProvider>().token!,
                                );
                                if (!mounted) return;
                                await xpProvider.fetchHistory(
                                  regNo,
                                  context.read<AuthProvider>().token!,
                                );
                              } else {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Failed to submit claim. try again.',
                                    ),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            currentStep == 4 ? 'Submit for Approval' : 'Next',
                          ),
                        ),
                      ],
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
}

extension StringExtension on String {
  bool equalsIgnoreCase(String other) {
    return toLowerCase() == other.toLowerCase();
  }
}
