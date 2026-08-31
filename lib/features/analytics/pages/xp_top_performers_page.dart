import 'package:flutter/material.dart';
import 'package:pragatix/core/widgets/pragatix_loader.dart';
import 'package:pragatix/features/analytics/services/xp_analytics_service.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/core/utils/error_handler.dart';

class XpTopPerformersPage extends StatefulWidget {
  const XpTopPerformersPage({Key? key}) : super(key: key);

  @override
  _XpTopPerformersPageState createState() => _XpTopPerformersPageState();
}

class _XpTopPerformersPageState extends State<XpTopPerformersPage> {
  bool _isLoading = true;
  List<dynamic> _data = [];
  String? _error;
  dynamic _rawError;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _rawError = null;
    });
    try {
      final service = getIt<XpAnalyticsService>();
      final result = await service.getTopPerformers({});
      setState(() {
        _data = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _rawError = e;
        _error = ErrorHandler.getErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Top Performers')),
      body: _isLoading 
        ? const Center(child: PragatiXLoader(fullScreen: false))
        : _error != null 
          ? ErrorHandler.buildErrorWidget(_rawError ?? _error, onRetry: _fetchData)
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Rank')),
                    DataColumn(label: Text('Student')),
                    DataColumn(label: Text('Department')),
                    DataColumn(label: Text('Section')),
                    DataColumn(label: Text('Current XP')),
                    DataColumn(label: Text('Awarded XP')),
                    DataColumn(label: Text('Penalty XP')),
                  ],
                  rows: _data.map((e) => DataRow(cells: [
                    DataCell(Text(e['rank'].toString())),
                    DataCell(Text(e['studentName'] ?? '')),
                    DataCell(Text(e['department'] ?? '')),
                    DataCell(Text(e['section'] ?? '')),
                    DataCell(Text(e['currentXp'].toString())),
                    DataCell(Text(e['awardedXp'].toString())),
                    DataCell(Text(e['penaltyXp'].toString())),
                  ])).toList(),
                ),
              ),
            ),
    );
  }
}
