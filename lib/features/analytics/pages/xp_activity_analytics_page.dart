import 'package:flutter/material.dart';
import 'package:pragatix/features/analytics/services/xp_analytics_service.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';

class XpActivityAnalyticsPage extends StatefulWidget {
  const XpActivityAnalyticsPage({Key? key}) : super(key: key);

  @override
  _XpActivityAnalyticsPageState createState() => _XpActivityAnalyticsPageState();
}

class _XpActivityAnalyticsPageState extends State<XpActivityAnalyticsPage> {
  bool _isLoading = true;
  List<dynamic> _allData = [];
  String? _error;
  int _limit = 10;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final service = getIt<XpAnalyticsService>();
      final result = await service.getActivityXpContribution({});
      
      // Sort descending by Net XP
      result.sort((a, b) => (b['netXp'] ?? 0).compareTo(a['netXp'] ?? 0));
      
      setState(() {
        _allData = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Widget _buildSkeletonLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(width: 100, height: 30, color: Colors.white, margin: const EdgeInsets.only(bottom: 16)),
            ],
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              margin: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insert_chart_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Data Available',
            style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activity Contribution')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? _buildSkeletonLoader()
            : _error != null
                ? Center(child: Text('Error: $_error'))
                : _allData.isEmpty
                    ? _buildEmptyState()
                    : _buildChartContent(),
      ),
    );
  }

  Widget _buildChartContent() {
    final displayData = _allData.take(_limit).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Net XP by Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            DropdownButton<int>(
              value: _limit,
              items: const [
                DropdownMenuItem(value: 10, child: Text('Top 10')),
                DropdownMenuItem(value: 20, child: Text('Top 20')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _limit = value;
                  });
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: displayData.isEmpty ? 100 : (displayData.first['netXp'] ?? 0).toDouble() * 1.2,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  tooltipMargin: 8,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final item = displayData[group.x.toInt()];
                    return BarTooltipItem(
                      '${item['activityName']}\n',
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      children: [
                        TextSpan(
                          text: 'Net XP: ${item['netXp']}\n',
                          style: const TextStyle(color: Colors.blueAccent),
                        ),
                        TextSpan(
                          text: 'Award: ${item['totalAwardXp']}\n',
                          style: const TextStyle(color: Colors.greenAccent),
                        ),
                        TextSpan(
                          text: 'Penalty: ${item['totalPenaltyXp']}',
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ],
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 && value.toInt() < displayData.length) {
                        String name = displayData[value.toInt()]['activityName'] ?? '';
                        if (name.length > 12) name = '${name.substring(0, 12)}...';
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0, right: 16.0),
                          child: Transform.rotate(
                            angle: -0.5,
                            child: Text(
                              name,
                              style: const TextStyle(fontSize: 10),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                    reservedSize: 60,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              barGroups: displayData.asMap().entries.map((e) {
                final netXp = (e.value['netXp'] ?? 0).toDouble();
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: netXp,
                      color: netXp >= 0 ? Colors.blue : Colors.red,
                      width: 20,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
