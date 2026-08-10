import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/analytics/providers/xp_analytics_provider.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import 'xp_top_performers_page.dart';
import 'xp_low_students_page.dart';
import 'xp_activity_analytics_page.dart';
import 'xp_history_page.dart';

class XpAnalyticsDashboardPage extends StatefulWidget {
  final bool isSuperAdmin;
  const XpAnalyticsDashboardPage({Key? key, this.isSuperAdmin = false}) : super(key: key);

  @override
  _XpAnalyticsDashboardPageState createState() => _XpAnalyticsDashboardPageState();
}

class _XpAnalyticsDashboardPageState extends State<XpAnalyticsDashboardPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<XpAnalyticsProvider>(context, listen: false).fetchDashboardData();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildEmptyState(String title) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            Icon(Icons.insert_chart_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No Data Available', style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 80, color: Colors.white, margin: const EdgeInsets.only(bottom: 16)),
          Row(
            children: [
              Expanded(child: Container(height: 300, color: Colors.white)),
              const SizedBox(width: 16),
              Expanded(child: Container(height: 300, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 250, color: Colors.white),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('XP Analytics Dashboard'),
        centerTitle: true,
      ),
      backgroundColor: Colors.grey[50],
      body: Consumer<XpAnalyticsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.awardVsPenalty == null) {
            return Padding(padding: const EdgeInsets.all(16.0), child: _buildSkeletonLoader());
          }
          if (provider.error != null && provider.awardVsPenalty == null) {
            return Center(child: Text('Error: ${provider.error}'));
          }

          return FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildFiltersBar(provider),
                  const SizedBox(height: 16),
                  _buildVisualizations(provider),
                  const SizedBox(height: 32),
                  const Text('Detailed Analytics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildActionCards(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFiltersBar(XpAnalyticsProvider provider) {
    int currentYear = DateTime.now().year;
    List<int> years = List.generate(5, (index) => currentYear - index);
    List<int> months = List.generate(12, (index) => index + 1);
    List<int> weeks = List.generate(5, (index) => index + 1);

    final bool hasDepartment = provider.departmentId != null;
    final bool hasSections = provider.sections.isNotEmpty;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DropdownButton<int>(
              value: provider.departmentId,
              hint: const Text('All Departments'),
              items: [
                const DropdownMenuItem<int>(value: null, child: Text('All Departments')),
                ...provider.departments.map((d) => DropdownMenuItem<int>(
                  value: d['id'],
                  child: Text(d['name']?.toString() ?? '', overflow: TextOverflow.ellipsis),
                )).toList(),
              ],
              onChanged: (val) {
                provider.onDepartmentChanged(val);
              },
            ),
            DropdownButton<int>(
              value: hasDepartment && hasSections ? provider.sectionId : null,
              hint: Text(
                !hasDepartment ? 'Select Department First' : (hasSections ? 'All Sections' : 'No Sections'),
                style: TextStyle(color: !hasDepartment || !hasSections ? Colors.grey : null),
              ),
              disabledHint: Text(!hasDepartment ? 'Select Department First' : 'No Sections'),
              items: !hasDepartment || !hasSections
                  ? null
                  : [
                      const DropdownMenuItem<int>(value: null, child: Text('All Sections')),
                      ...provider.sections.map((s) => DropdownMenuItem<int>(
                        value: s['id'],
                        child: Text(s['sectionName']?.toString() ?? '', overflow: TextOverflow.ellipsis),
                      )).toList(),
                    ],
              onChanged: !hasDepartment || !hasSections
                  ? null
                  : (val) {
                      provider.onSectionChanged(val);
                    },
            ),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Week', label: Text('Week')),
                ButtonSegment(value: 'Month', label: Text('Month')),
              ],
              selected: {provider.heatmapMode},
              onSelectionChanged: (Set<String> newSelection) {
                provider.setHeatmapFilters(mode: newSelection.first);
              },
            ),
            DropdownButton<int>(
              value: provider.heatmapYear ?? currentYear,
              hint: const Text('Year'),
              items: years.map((y) => DropdownMenuItem(value: y, child: Text(y.toString()))).toList(),
              onChanged: (y) => provider.setHeatmapFilters(year: y),
            ),
            DropdownButton<int>(
              value: provider.heatmapMonth ?? DateTime.now().month,
              hint: const Text('Month'),
              items: months.map((m) => DropdownMenuItem(value: m, child: Text(DateFormat('MMM').format(DateTime(2000, m))))).toList(),
              onChanged: (m) => provider.setHeatmapFilters(month: m),
            ),
            if (provider.heatmapMode == 'Week')
              DropdownButton<int>(
                value: provider.heatmapWeek ?? 1,
                hint: const Text('Week'),
                items: weeks.map((w) => DropdownMenuItem(value: w, child: Text('Week $w'))).toList(),
                onChanged: (w) => provider.setHeatmapFilters(week: w),
              ),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Reload Data'),
              onPressed: () => provider.fetchDashboardData(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualizations(XpAnalyticsProvider provider) {
    return LayoutBuilder(builder: (context, constraints) {
      bool isDesktop = constraints.maxWidth > 900;
      return Column(
        children: [
          if (isDesktop) Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildAwardVsPenaltyChart(provider.awardVsPenalty)),
              const SizedBox(width: 16),
              Expanded(child: _buildHeatmap(provider)),
            ],
          ) else ...[
            _buildAwardVsPenaltyChart(provider.awardVsPenalty),
            const SizedBox(height: 16),
            _buildHeatmap(provider),
          ],
          const SizedBox(height: 16),
          _buildDepartmentRanking(provider.departmentRanking),
        ],
      );
    });
  }

  Widget _buildAwardVsPenaltyChart(List<dynamic>? data) {
    if (data == null || data.isEmpty) return _buildEmptyState('Award vs Penalty');
    
    double maxVal = 0;
    for (var item in data) {
      if ((item['awardXp'] ?? 0) > maxVal) maxVal = (item['awardXp'] ?? 0).toDouble();
      if ((item['penaltyXp'] ?? 0) > maxVal) maxVal = (item['penaltyXp'] ?? 0).toDouble();
    }
    if (maxVal == 0) maxVal = 1;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Award vs Penalty (Dept)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ...data.map((item) {
              final String deptName = item['departmentName'] ?? '';
              final double award = (item['awardXp'] ?? 0).toDouble();
              final double penalty = (item['penaltyXp'] ?? 0).toDouble();
              final double net = award - penalty;

              return Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Tooltip(
                  message: '$deptName\nAward : ${award.toInt()} XP\nPenalty : ${penalty.toInt()} XP\nNet : ${net >= 0 ? '+' : ''}${net.toInt()} XP',
                  padding: const EdgeInsets.all(12),
                  textStyle: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(deptName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      // Award Bar
                      Row(
                        children: [
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return Stack(
                                  children: [
                                    Container(height: 12, decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(6))),
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 500),
                                      curve: Curves.easeOut,
                                      height: 12,
                                      width: constraints.maxWidth * (award / maxVal).clamp(0.0, 1.0),
                                      decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(6)),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(width: 50, child: Text('${award.toInt()} Award', style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Penalty Bar
                      Row(
                        children: [
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return Stack(
                                  children: [
                                    Container(height: 12, decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(6))),
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 500),
                                      curve: Curves.easeOut,
                                      height: 12,
                                      width: constraints.maxWidth * (penalty / maxVal).clamp(0.0, 1.0),
                                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(6)),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(width: 50, child: Text('${penalty.toInt()} Penalty', style: const TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold))),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatmap(XpAnalyticsProvider provider) {
    final data = provider.heatmap;
    if (data == null || data.isEmpty) return _buildEmptyState('Monthly Heatmap');
    
    final List<Color> greens = [
      Colors.grey[200]!, // 0
      const Color(0xFFC6E48B), // 1-10
      const Color(0xFF7BC96F), // 11-25
      const Color(0xFF239A3B), // 26-50
      const Color(0xFF196127), // 51-100
      const Color(0xFF0B4F1A), // 101+
    ];

    int totalXp = 0;
    int highestXp = 0;
    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;

    // We need to parse dates to correctly position them in a 7-row grid.
    // GitHub heatmap has Days of Week (Sun-Sat) on the Y axis, and Weeks on the X axis.
    Map<DateTime, Map<String, int>> dateValues = {};
    for (var d in data) {
      if (d['date'] != null) {
        try {
          DateTime dt = DateFormat('yyyy-MM-dd').parse(d['date']);
          int val = (d['xp'] ?? 0);
          int level = (d['level'] ?? 0);
          dateValues[DateTime(dt.year, dt.month, dt.day)] = {'xp': val, 'level': level};
          
          totalXp += val;
          if (val > highestXp) highestXp = val;
        } catch (e) {
          // ignore
        }
      }
    }

    Color getColor(int level) {
      if (level < 0) return greens[0];
      if (level >= greens.length) return greens.last;
      return greens[level];
    }

    // Determine grid bounds based on filter
    DateTime start = provider.startDate ?? DateTime.now().subtract(const Duration(days: 30));
    DateTime end = provider.endDate ?? DateTime.now();
    
    // Find first Sunday before or equal to start date
    DateTime gridStart = start.subtract(Duration(days: start.weekday == 7 ? 0 : start.weekday));
    int totalDays = end.difference(gridStart).inDays + 1;
    int totalCols = (totalDays / 7).ceil();
    if (totalCols == 0) totalCols = 1;
    
    // Calculate streaks
    DateTime streakCheck = start;
    while(streakCheck.isBefore(end) || streakCheck.isAtSameMomentAs(end)) {
      int val = dateValues[streakCheck]?['xp'] ?? 0;
      if (val > 0) {
        tempStreak++;
        if (tempStreak > longestStreak) longestStreak = tempStreak;
      } else {
        tempStreak = 0;
      }
      streakCheck = streakCheck.add(const Duration(days: 1));
    }
    
    // Current streak (working backwards from end)
    streakCheck = end;
    while(streakCheck.isAfter(start) || streakCheck.isAtSameMomentAs(start)) {
      if ((dateValues[streakCheck]?['xp'] ?? 0) > 0) {
        currentStreak++;
        streakCheck = streakCheck.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('XP Activity Heatmap', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Day Labels
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: const [
                      SizedBox(height: 12),
                      Text('Mon', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      SizedBox(height: 12),
                      Text('Wed', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      SizedBox(height: 12),
                      Text('Fri', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      SizedBox(height: 12),
                    ],
                  ),
                  const SizedBox(width: 8),
                  // Grid
                  SizedBox(
                    height: 120, // 7 rows * 12px + spacing
                    width: totalCols * 16.0,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      scrollDirection: Axis.horizontal,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisSpacing: 4,
                        crossAxisSpacing: 4,
                        childAspectRatio: 1,
                      ),
                      itemCount: totalCols * 7,
                      itemBuilder: (context, index) {
                        int col = index ~/ 7;
                        int row = index % 7;
                        DateTime cellDate = gridStart.add(Duration(days: (col * 7) + row));
                        
                        if (cellDate.isBefore(start) || cellDate.isAfter(end)) {
                          return const SizedBox(); // Empty space
                        }

                        Map<String, int>? dataMap = dateValues[cellDate];
                        int val = dataMap?['xp'] ?? 0;
                        int level = dataMap?['level'] ?? 0;
                        
                        return Tooltip(
                          message: '${DateFormat('MMM dd, yyyy').format(cellDate)}: $val XP',
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            decoration: BoxDecoration(
                              color: getColor(level),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('Less ', style: TextStyle(fontSize: 10, color: Colors.grey)),
                for (var color in greens)
                  Container(
                    width: 10, height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
                  ),
                const Text(' More', style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            // Stats
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildStat('Total XP', totalXp.toString()),
                _buildStat('Highest Day', highestXp.toString()),
                _buildStat('Current Streak', '$currentStreak days'),
                _buildStat('Longest Streak', '$longestStreak days'),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDepartmentRanking(List<dynamic>? data) {
    if (data == null || data.isEmpty) return _buildEmptyState('Department Ranking');
    
    double maxAvg = data.isNotEmpty ? (data[0]['averageXp'] ?? 0).toDouble() : 1;
    if (maxAvg == 0) maxAvg = 1;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Department Ranking (Avg XP)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ...data.asMap().entries.map((e) {
              final rank = e.key + 1;
              final item = e.value;
              final double avg = (item['averageXp'] ?? 0).toDouble();
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  children: [
                    SizedBox(width: 32, child: Text('#$rank', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 16))),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: Text(item['groupName'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 5,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Stack(
                            alignment: Alignment.centerLeft,
                            children: [
                              Container(
                                height: 24,
                                decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeOut,
                                width: constraints.maxWidth * (avg / maxAvg).clamp(0.0, 1.0),
                                height: 24,
                                decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(12)),
                              ),
                              Positioned(
                                right: 8,
                                child: Text(
                                  avg.toStringAsFixed(1),
                                  style: TextStyle(color: (avg / maxAvg) > 0.8 ? Colors.white : Colors.black87, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          );
                        }
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCards(BuildContext context) {
    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: MediaQuery.of(context).size.width > 600 ? 3 : 2.5,
      children: [
        _buildActionCard(
          context: context,
          title: 'Top Performers',
          subtitle: 'View highest XP',
          icon: Icons.star,
          color: Colors.orange,
          destination: const XpTopPerformersPage(),
        ),
        _buildActionCard(
          context: context,
          title: 'Low XP',
          subtitle: 'View low XP students',
          icon: Icons.warning,
          color: Colors.red,
          destination: const XpLowStudentsPage(),
        ),
        _buildActionCard(
          context: context,
          title: 'Activities',
          subtitle: 'Activity-wise XP breakdown',
          icon: Icons.local_activity,
          color: Colors.purple,
          destination: const XpActivityAnalyticsPage(),
        ),
        _buildActionCard(
          context: context,
          title: 'History',
          subtitle: 'Export detailed XP history',
          icon: Icons.history,
          color: Colors.teal,
          destination: const XpHistoryPage(),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget destination,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 110, maxHeight: 130),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => destination));
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
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
