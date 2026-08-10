import 'package:flutter/material.dart';
import 'package:pragatix/core/widgets/pragatix_loader.dart';
import 'package:pragatix/features/analytics/services/xp_analytics_service.dart';
import 'package:pragatix/core/di/service_locator.dart';

class XpLowStudentsPage extends StatefulWidget {
  const XpLowStudentsPage({Key? key}) : super(key: key);

  @override
  _XpLowStudentsPageState createState() => _XpLowStudentsPageState();
}

class _XpLowStudentsPageState extends State<XpLowStudentsPage> {
  bool _isLoading = true;
  List<dynamic> _data = [];
  String? _error;
  double _threshold = 20.0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final service = getIt<XpAnalyticsService>();
      final result = await service.getLowXpStudents({'threshold': _threshold.toInt().toString()});
      setState(() {
        _data = result;
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
      appBar: AppBar(title: const Text('Low XP Students')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text('Threshold: '),
                Expanded(
                  child: Slider(
                    value: _threshold,
                    min: 0,
                    max: 100,
                    divisions: 20,
                    label: _threshold.round().toString(),
                    onChanged: (val) => setState(() => _threshold = val),
                    onChangeEnd: (val) => _fetchData(),
                  ),
                ),
                Text(_threshold.round().toString()),
              ],
            ),
          ),
          Expanded(
            child: _isLoading 
              ? const Center(child: PragatiXLoader(fullScreen: false))
              : _error != null 
                ? Center(child: Text('Error: $_error'))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Student')),
                          DataColumn(label: Text('Reg No')),
                          DataColumn(label: Text('Department')),
                          DataColumn(label: Text('Section')),
                          DataColumn(label: Text('Current XP')),
                          DataColumn(label: Text('Difference')),
                        ],
                        rows: _data.map((e) => DataRow(cells: [
                          DataCell(Text(e['studentName'] ?? '')),
                          DataCell(Text(e['registerNumber'] ?? '')),
                          DataCell(Text(e['department'] ?? '')),
                          DataCell(Text(e['section'] ?? '')),
                          DataCell(Text(e['currentXp'].toString())),
                          DataCell(Text(e['differenceFromThreshold'].toString(), style: const TextStyle(color: Colors.red))),
                        ])).toList(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
