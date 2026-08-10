import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/core/widgets/pragatix_loader.dart';
import 'package:pragatix/features/analytics/providers/attendance_analytics_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:pragatix/core/utils/export_utils.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/core/di/service_locator.dart';

class StudentAttendanceAnalyticsPage extends StatefulWidget {
  final bool isSuperAdmin;
  
  const StudentAttendanceAnalyticsPage({Key? key, this.isSuperAdmin = false}) : super(key: key);

  @override
  _StudentAttendanceAnalyticsPageState createState() => _StudentAttendanceAnalyticsPageState();
}

class _StudentAttendanceAnalyticsPageState extends State<StudentAttendanceAnalyticsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AttendanceAnalyticsProvider>(context, listen: false).fetchDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Analytics Dashboard'),
        centerTitle: true,
        actions: [
          Consumer<AttendanceAnalyticsProvider>(
            builder: (context, provider, child) {
              return IconButton(
                icon: const Icon(Icons.download),
                tooltip: 'Export to Excel',
                onPressed: () async {
                  final url = provider.getExportUrl();
                  final token = getIt<AuthProvider>().token ?? '';
                  await ExportUtils.downloadAndOpenExcel(context, url, token);
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Existing settings...
            },
          ),
        ],
      ),
      backgroundColor: Colors.grey[100],
      body: Consumer<AttendanceAnalyticsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: PragatiXLoader(fullScreen: false, message: 'Loading Analytics...'),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchDashboardData(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.overview == null || (provider.overview!['totalStudents'] ?? 0) == 0) {
            return const Center(
              child: Text(
                'No attendance records found.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildFiltersBar(provider),
                const SizedBox(height: 16),
                _buildKPICards(provider.overview!),
                const SizedBox(height: 24),
                
                // Analytics Visualizations
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth > 800;
                    
                    if (isDesktop) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 1,
                            child: _buildDistributionChart(provider.distribution),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: _buildTrendChart(provider.trend ?? [], provider.startDate),
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          _buildDistributionChart(provider.distribution),
                          const SizedBox(height: 24),
                          _buildTrendChart(provider.trend ?? [], provider.startDate),
                        ],
                      );
                    }
                  }
                ),
                const SizedBox(height: 24),
                _buildBarChart(provider.departmentWise ?? [], 'Department-wise Attendance'),
                const SizedBox(height: 24),
                _buildBarChart(provider.sectionWise ?? [], 'Section-wise Attendance'),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth > 800;
                    if (isDesktop) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 1,
                            child: _buildTopDepartments(provider.departmentWise ?? []),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: _buildLowAttendanceAlert(provider),
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          _buildTopDepartments(provider.departmentWise ?? []),
                          const SizedBox(height: 24),
                          _buildLowAttendanceAlert(provider),
                        ],
                      );
                    }
                  }
                ),
                const SizedBox(height: 24),
                _buildSummaryTable(provider.summaryTable ?? []),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFiltersBar(AttendanceAnalyticsProvider provider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isSmall = constraints.maxWidth < 600;
            if (isSmall) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.isSuperAdmin) ...[
                    _buildAcademicYearControl(provider),
                    const SizedBox(height: 16),
                  ],
                  _buildDepartmentControl(provider),
                  const SizedBox(height: 16),
                  _buildSectionControl(provider),
                  const SizedBox(height: 16),
                  _buildDateControl(provider),
                  const SizedBox(height: 16),
                  _buildPeriodControl(provider),
                  const SizedBox(height: 16),
                  _buildResetButton(provider),
                ],
              );
            } else {
              return Column(
                children: [
                  Row(
                    children: [
                      if (widget.isSuperAdmin) ...[
                        Expanded(child: _buildAcademicYearControl(provider)),
                        const SizedBox(width: 16),
                      ],
                      Expanded(child: _buildDepartmentControl(provider)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildSectionControl(provider)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildDateControl(provider)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildPeriodControl(provider)),
                      const SizedBox(width: 16),
                      Expanded(child: Align(alignment: Alignment.centerLeft, child: _buildResetButton(provider))),
                    ],
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildFilterControlWrapper(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 4),
        child,
      ],
    );
  }

  Widget _buildAcademicYearControl(AttendanceAnalyticsProvider provider) {
    return _buildFilterControlWrapper(
      'Academic Year:',
      DropdownButton<String>(
        isExpanded: true,
        value: provider.selectedAcademicYear,
        hint: const Text('All Years'),
        items: const [
          DropdownMenuItem(value: null, child: Text('All Years')),
          DropdownMenuItem(value: '1', child: Text('First Year')),
          DropdownMenuItem(value: '2', child: Text('Second Year')),
          DropdownMenuItem(value: '3', child: Text('Third Year')),
          DropdownMenuItem(value: '4', child: Text('Fourth Year')),
        ],
        onChanged: (val) => provider.setAcademicYear(val),
      ),
    );
  }

  Widget _buildDateControl(AttendanceAnalyticsProvider provider) {
    return _buildFilterControlWrapper(
      'Date:',
      Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: provider.startDate != null ? DateTime.parse(provider.startDate!) : DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  final dateString = DateFormat('yyyy-MM-dd').format(date);
                  provider.setFilters(
                    departmentId: provider.selectedDepartmentId,
                    stageId: provider.selectedStageId,
                    sectionId: provider.selectedSectionId,
                    start: dateString,
                    end: dateString,
                    period: provider.selectedPeriod,
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(provider.startDate ?? 'Select Date', overflow: TextOverflow.ellipsis),
              ),
            ),
          ),
          if (provider.startDate != null)
            IconButton(
              icon: const Icon(Icons.clear, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                provider.setFilters(
                  departmentId: provider.selectedDepartmentId,
                  stageId: provider.selectedStageId,
                  sectionId: provider.selectedSectionId,
                  start: null,
                  end: null,
                  period: provider.selectedPeriod,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPeriodControl(AttendanceAnalyticsProvider provider) {
    return _buildFilterControlWrapper(
      'Period:',
      DropdownButton<String>(
        isExpanded: true,
        value: provider.selectedPeriod,
        hint: const Text('All Periods'),
        items: [
          const DropdownMenuItem(value: null, child: Text('All Periods')),
          ...List.generate(8, (i) => DropdownMenuItem(
            value: '${i + 1}',
            child: Text('Period ${i + 1}'),
          )),
        ],
        onChanged: (val) {
          provider.setFilters(
            departmentId: provider.selectedDepartmentId,
            stageId: provider.selectedStageId,
            sectionId: provider.selectedSectionId,
            start: provider.startDate,
            end: provider.endDate,
            period: val,
          );
        },
      ),
    );
  }

  Widget _buildDepartmentControl(AttendanceAnalyticsProvider provider) {
    return _buildFilterControlWrapper(
      'Department:',
      DropdownButton<String>(
        isExpanded: true,
        value: provider.selectedDepartmentId,
        hint: const Text('All Departments'),
        items: [
          if (widget.isSuperAdmin) const DropdownMenuItem(value: null, child: Text('All Departments')),
          ...provider.departments.map((d) => DropdownMenuItem(
            value: d['id']?.toString() ?? '',
            child: Text(d['name']?.toString() ?? '', overflow: TextOverflow.ellipsis),
          )).toList(),
        ],
        onChanged: (val) {
                provider.onDepartmentChanged(val);
              },
      ),
    );
  }

  Widget _buildSectionControl(AttendanceAnalyticsProvider provider) {
    final bool hasDepartment = provider.selectedDepartmentId != null;
    final bool hasSections = provider.sections.isNotEmpty;

    return _buildFilterControlWrapper(
      'Section:',
      DropdownButton<String>(
        isExpanded: true,
        value: hasDepartment && hasSections ? provider.selectedSectionId : null,
        hint: Text(
          !hasDepartment
              ? 'Select Department First'
              : (hasSections ? 'All Sections' : 'No Sections Available'),
          style: TextStyle(
            color: !hasDepartment || !hasSections ? Colors.grey : null,
          ),
        ),
        disabledHint: Text(
          !hasDepartment
              ? 'Select Department First'
              : 'No Sections Available',
        ),
        items: !hasDepartment || !hasSections
            ? null
            : [
                const DropdownMenuItem(value: null, child: Text('All Sections')),
                ...provider.sections.map((s) => DropdownMenuItem(
                  value: s['id']?.toString() ?? '',
                  child: Text(s['sectionName']?.toString() ?? '', overflow: TextOverflow.ellipsis),
                )).toList(),
              ],
        onChanged: !hasDepartment || !hasSections
            ? null
            : (val) {
                provider.onSectionChanged(val);
              },
      ),
    );
  }

  Widget _buildResetButton(AttendanceAnalyticsProvider provider) {
    return TextButton.icon(
      onPressed: () => provider.resetFilters(),
      icon: const Icon(Icons.refresh, color: Colors.blue),
      label: const Text('Reset Filters', style: TextStyle(color: Colors.blue)),
    );
  }

  Widget _buildKPICards(Map<String, dynamic> overview) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            children: [
              Row(
                children: [
                  _buildKPIItem('Overall %', '${(overview['overallAttendancePercentage'] ?? 0).toStringAsFixed(1)}%', Colors.blue),
                  const SizedBox(width: 12),
                  _buildKPIItem('Present Today', '${overview['presentStudents'] ?? 0}', Colors.green),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildKPIItem('Partial Absent', '${overview['partialAbsentees'] ?? 0}', Colors.orange),
                  const SizedBox(width: 12),
                  _buildKPIItem('Full Absent', '${overview['fullDayAbsentees'] ?? 0}', Colors.red),
                ],
              ),
            ],
          );
        } else {
          return Row(
            children: [
              _buildKPIItem('Overall %', '${(overview['overallAttendancePercentage'] ?? 0).toStringAsFixed(1)}%', Colors.blue),
              const SizedBox(width: 12),
              _buildKPIItem('Present Today', '${overview['presentStudents'] ?? 0}', Colors.green),
              const SizedBox(width: 12),
              _buildKPIItem('Partial Absent', '${overview['partialAbsentees'] ?? 0}', Colors.orange),
              const SizedBox(width: 12),
              _buildKPIItem('Full Absent', '${overview['fullDayAbsentees'] ?? 0}', Colors.red),
            ],
          );
        }
      },
    );
  }

  Widget _buildKPIItem(String title, String value, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 12.0),
          child: Column(
            children: [
              Text(title, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDistributionChart(Map<String, dynamic>? distribution) {
    if (distribution == null) return const SizedBox();
    final present = (distribution['presentPercentage'] ?? 0.0) as double;
    final partial = (distribution['partialAbsentPercentage'] ?? 0.0) as double;
    final absent = (distribution['fullAbsentPercentage'] ?? 0.0) as double;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Attendance Distribution', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(
                      color: Colors.green,
                      value: present,
                      title: '${present.toStringAsFixed(1)}%',
                      radius: 50,
                      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    if (partial > 0)
                      PieChartSectionData(
                        color: Colors.orange,
                        value: partial,
                        title: '${partial.toStringAsFixed(1)}%',
                        radius: 50,
                        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    if (absent > 0)
                      PieChartSectionData(
                        color: Colors.red,
                        value: absent,
                        title: '${absent.toStringAsFixed(1)}%',
                        radius: 50,
                        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(Colors.green, 'Present'),
                const SizedBox(width: 16),
                _buildLegendItem(Colors.orange, 'Partial'),
                const SizedBox(width: 16),
                _buildLegendItem(Colors.red, 'Absent'),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildTrendChart(List<dynamic> trendData, String? selectedDate) {
    if (trendData.isEmpty) return const SizedBox();

    List<FlSpot> spots = [];
    List<String> dates = [];
    List<String> rawDates = [];
    
    for (int i = 0; i < trendData.length; i++) {
      final item = trendData[i];
      final dateStr = item['date'] as String;
      final pct = (item['attendancePercentage'] as num).toDouble();
      spots.add(FlSpot(i.toDouble(), pct));
      dates.add(DateFormat('MMM dd').format(DateTime.parse(dateStr)));
      rawDates.add(dateStr);
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Attendance Trend', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < dates.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(dates[value.toInt()], style: const TextStyle(fontSize: 10)),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (dates.length - 1).toDouble(),
                  minY: 0,
                  maxY: 100,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          if (selectedDate != null && rawDates[index] == selectedDate) {
                            return FlDotCirclePainter(
                              radius: 8,
                              color: Colors.red,
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            );
                          }
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.blue,
                            strokeWidth: 1,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(List<dynamic> data, String title) {
    if (data.isEmpty) return const SizedBox();

    List<BarChartGroupData> barGroups = [];
    List<String> labels = [];

    // Sort descending
    var sortedData = List.from(data);
    sortedData.sort((a, b) => (b['attendancePercentage'] as num).compareTo(a['attendancePercentage'] as num));

    for (int i = 0; i < sortedData.length; i++) {
      final item = sortedData[i];
      labels.add(item['label'] as String);
      final pct = (item['attendancePercentage'] as num).toDouble();
      
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: pct,
              color: pct >= 75 ? Colors.blue : (pct >= 50 ? Colors.orange : Colors.red),
              width: 16,
              borderRadius: BorderRadius.circular(4),
            )
          ],
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => Colors.black87,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${labels[groupIndex]}\n${rod.toY.toStringAsFixed(1)}%',
                          const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < labels.length) {
                            String text = labels[value.toInt()];
                            if (text.length > 10) text = '${text.substring(0, 8)}..';
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Transform.rotate(
                                angle: -0.5,
                                child: Text(text, style: const TextStyle(fontSize: 10)),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: barGroups,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopDepartments(List<dynamic> deptData) {
    if (deptData.isEmpty) return const SizedBox();
    
    var sorted = List.from(deptData);
    sorted.sort((a, b) => (b['attendancePercentage'] as num).compareTo(a['attendancePercentage'] as num));
    var top5 = sorted.take(5).toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Top Attendance (Departments)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...top5.asMap().entries.map((entry) {
              int idx = entry.key;
              var data = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.blue.withOpacity(0.2),
                      child: Text('${idx + 1}', style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(data['label'] as String, style: const TextStyle(fontWeight: FontWeight.w500))),
                    Text('${(data['attendancePercentage'] as num).toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildLowAttendanceAlert(AttendanceAnalyticsProvider provider) {
    var studentData = provider.lowAttendanceStudents ?? [];
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.red),
                    const SizedBox(width: 8),
                    const Text('Low Attendance Alert', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Threshold: ', style: TextStyle(fontSize: 12)),
                    SizedBox(
                      width: 60,
                      child: DropdownButton<double>(
                        isExpanded: true,
                        value: provider.attendanceThreshold,
                        underline: const SizedBox(),
                        style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold),
                        items: [40.0, 50.0, 60.0, 70.0, 75.0, 80.0, 90.0].map((t) => DropdownMenuItem(
                          value: t,
                          child: Text('${t.toInt()}%'),
                        )).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            provider.setThreshold(val);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (studentData.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text('No students below ${provider.attendanceThreshold.toInt()}%', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              )
            else
              ...studentData.map((data) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.person, color: Colors.red, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['name'] as String, style: const TextStyle(fontWeight: FontWeight.w500)),
                            Text(data['rollNo'] as String, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Text('${(data['attendancePercentage'] as num).toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                    ],
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryTable(List<dynamic> tableData) {
    if (tableData.isEmpty) return const SizedBox();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Attendance Distribution Table', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(Colors.grey[200]),
                columns: const [
                  DataColumn(label: Text('Department', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Present', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Partial', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Absent', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Att %', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: tableData.map((row) {
                  return DataRow(
                    cells: [
                      DataCell(Text(row['departmentName'] as String)),
                      DataCell(Text('${row['totalStudents']}')),
                      DataCell(Text('${row['present']}')),
                      DataCell(Text('${row['partial']}')),
                      DataCell(Text('${row['absent']}')),
                      DataCell(Text('${(row['attendancePercentage'] as num).toStringAsFixed(1)}%')),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
