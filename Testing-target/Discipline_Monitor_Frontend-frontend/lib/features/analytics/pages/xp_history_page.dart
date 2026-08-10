import 'package:flutter/material.dart';
import 'package:pragatix/core/widgets/pragatix_loader.dart';
import 'package:pragatix/features/analytics/services/xp_analytics_service.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/core/utils/export_utils.dart';

class XpHistoryPage extends StatefulWidget {
  const XpHistoryPage({Key? key}) : super(key: key);

  @override
  _XpHistoryPageState createState() => _XpHistoryPageState();
}

class _XpHistoryPageState extends State<XpHistoryPage> {
  bool _isLoading = true;
  List<dynamic> _data = [];
  int _totalElements = 0;
  int _currentPage = 0;
  final int _pageSize = 20;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData({int page = 0}) async {
    setState(() => _isLoading = true);
    try {
      final service = getIt<XpAnalyticsService>();
      final result = await service.getXpHistory({
        'page': page.toString(),
        'size': _pageSize.toString(),
      });
      setState(() {
        _data = result['content'] ?? [];
        _totalElements = result['totalElements'] ?? 0;
        _currentPage = result['currentPage'] ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('XP History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () async {
              final service = getIt<XpAnalyticsService>();
              final url = service.getExportUrl({});
              final token = getIt<AuthProvider>().token ?? '';
              await ExportUtils.downloadAndOpenExcel(context, url, token);
            },
          ),
        ],
      ),
      body: _isLoading && _data.isEmpty
        ? const Center(child: PragatiXLoader(fullScreen: false))
        : _error != null && _data.isEmpty
          ? Center(child: Text('Error: $_error'))
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Date')),
                          DataColumn(label: Text('Student')),
                          DataColumn(label: Text('Reg No')),
                          DataColumn(label: Text('Dept')),
                          DataColumn(label: Text('Section')),
                          DataColumn(label: Text('Activity')),
                          DataColumn(label: Text('Award')),
                          DataColumn(label: Text('Penalty')),
                          DataColumn(label: Text('Net XP')),
                          DataColumn(label: Text('Current Total')),
                          DataColumn(label: Text('Approved By')),
                        ],
                        rows: _data.map((e) => DataRow(cells: [
                          DataCell(Text(e['date']?.substring(0, 10) ?? '')),
                          DataCell(Text(e['studentName'] ?? '')),
                          DataCell(Text(e['registerNumber'] ?? '')),
                          DataCell(Text(e['department'] ?? '')),
                          DataCell(Text(e['section'] ?? '')),
                          DataCell(Text(e['activityName'] ?? '')),
                          DataCell(Text(e['awardXp'].toString(), style: const TextStyle(color: Colors.green))),
                          DataCell(Text(e['penaltyXp'].toString(), style: const TextStyle(color: Colors.red))),
                          DataCell(Text(e['netXp'].toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(e['currentTotalXp'].toString())),
                          DataCell(Text(e['approvedBy'] ?? '')),
                        ])).toList(),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Showing ${_currentPage * _pageSize + 1} to ${(_currentPage + 1) * _pageSize} of $_totalElements'),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: _currentPage > 0 ? () => _fetchData(page: _currentPage - 1) : null,
                          ),
                          Text('Page ${_currentPage + 1}'),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: (_currentPage + 1) * _pageSize < _totalElements ? () => _fetchData(page: _currentPage + 1) : null,
                          ),
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
    );
  }
}
