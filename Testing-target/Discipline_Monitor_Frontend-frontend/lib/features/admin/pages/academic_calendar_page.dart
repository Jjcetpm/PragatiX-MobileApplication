import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/academic_calendar_service.dart';

class AcademicCalendarPage extends StatefulWidget {
  final String? initialAcademicYear;
  
  const AcademicCalendarPage({Key? key, this.initialAcademicYear}) : super(key: key);

  @override
  State<AcademicCalendarPage> createState() => _AcademicCalendarPageState();
}

class _AcademicCalendarPageState extends State<AcademicCalendarPage> {
  final AcademicCalendarService _service = AcademicCalendarService();
  bool _isLoading = false;

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  late String _selectedAcademicYear;

  Map<String, dynamic>? _academicMonth;
  
  // Flattened data for Prev, Curr, Next month
  List<dynamic> _allWeeks = [];
  List<dynamic> _allHolidays = [];
  List<dynamic> _allAlternateWorkingDays = [];

  DateTime? _pendingWeekStart;

  final List<Color> _weekColors = [
    Colors.green,
    Colors.blue,
    Colors.amber,
    Colors.purple,
    Colors.orange,
    Colors.teal,
  ];

  final List<String> _daysOfWeek = [
    'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'
  ];

  @override
  void initState() {
    super.initState();
    _selectedAcademicYear = widget.initialAcademicYear ?? 'FIRST_YEAR';
    
    // Safety Check: Never call loadCalendar for Super Admin if academic year is somehow missing
    // In our normal flow, this won't happen because they pass through CalendarYearSelectionPage
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isSuperAdmin && widget.initialAcademicYear == null) {
      // Do nothing here, wait for selection (though our UI now prevents reaching here)
      _isLoading = false;
    } else {
      _loadCalendarData();
    }
  }

  Future<void> _loadCalendarData() async {
    setState(() => _isLoading = true);
    try {
      // Optional: Pass academic year if super admin
      final auth = Provider.of<AuthProvider>(context, listen: false);
      String? academicYearParam = auth.isSuperAdmin ? _selectedAcademicYear : null;

      // Current Month
      final currData = await _service.getOrCreateMonth(_selectedMonth, _selectedYear, academicYear: academicYearParam);
      _academicMonth = currData;

      // Previous Month
      int prevMonth = _selectedMonth - 1;
      int prevYear = _selectedYear;
      if (prevMonth == 0) {
        prevMonth = 12;
        prevYear -= 1;
      }
      final prevData = await _service.getOrCreateMonth(prevMonth, prevYear, academicYear: academicYearParam);

      // Next Month
      int nextMonth = _selectedMonth + 1;
      int nextYear = _selectedYear;
      if (nextMonth == 13) {
        nextMonth = 1;
        nextYear += 1;
      }
      final nextData = await _service.getOrCreateMonth(nextMonth, nextYear, academicYear: academicYearParam);

      // Load weeks and holidays for all 3
      final weeks1 = await _service.getWeeks(prevData['id']);
      final weeks2 = await _service.getWeeks(currData['id']);
      final weeks3 = await _service.getWeeks(nextData['id']);
      
      final holidays1 = await _service.getHolidays(prevData['id']);
      final holidays2 = await _service.getHolidays(currData['id']);
      final holidays3 = await _service.getHolidays(nextData['id']);

      final awd1 = await _service.getAlternateWorkingDays(prevData['id']);
      final awd2 = await _service.getAlternateWorkingDays(currData['id']);
      final awd3 = await _service.getAlternateWorkingDays(nextData['id']);

      List<dynamic> allW = [...weeks1, ...weeks2, ...weeks3];
      List<dynamic> allH = [...holidays1, ...holidays2, ...holidays3];
      List<dynamic> allAWD = [...awd1, ...awd2, ...awd3];

      allW.sort((a, b) => DateTime.parse(a['startDate']).compareTo(DateTime.parse(b['startDate'])));
      allH.sort((a, b) => DateTime.parse(a['holidayDate']).compareTo(DateTime.parse(b['holidayDate'])));
      allAWD.sort((a, b) => DateTime.parse(a['effectiveDate']).compareTo(DateTime.parse(b['effectiveDate'])));

      setState(() {
        _allWeeks = allW;
        _allHolidays = allH;
        _allAlternateWorkingDays = allAWD;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onDateTapped(DateTime date) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return _buildBottomSheetContent(date);
      }
    );
  }

  Widget _buildBottomSheetContent(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    
    // Check if date belongs to an existing week
    dynamic existingWeek;
    for (var w in _allWeeks) {
      final s = DateTime.parse(w['startDate']);
      final e = DateTime.parse(w['endDate']);
      if ((date.isAfter(s) || date.isAtSameMomentAs(s)) && (date.isBefore(e) || date.isAtSameMomentAs(e))) {
        existingWeek = w;
        break;
      }
    }

    // Check if date is a holiday
    dynamic existingHoliday;
    try {
      existingHoliday = _allHolidays.firstWhere((h) => h['holidayDate'] == dateStr);
    } catch (_) {}

    // Check if date is an alternate working day
    dynamic existingAWD;
    try {
      existingAWD = _allAlternateWorkingDays.firstWhere((a) => a['effectiveDate'] == dateStr);
    } catch (_) {}

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selected Date: ${DateFormat('dd MMMM yyyy').format(date)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            
            if (_pendingWeekStart == null && existingWeek == null)
              ListTile(
                leading: const Icon(Icons.play_arrow, color: Colors.green),
                title: const Text('Set as Week Start'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _pendingWeekStart = date);
                },
              ),
              
            if (_pendingWeekStart != null && _pendingWeekStart == date)
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.grey),
                title: const Text('Cancel Week Start'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _pendingWeekStart = null);
                },
              ),

            if (_pendingWeekStart != null && _pendingWeekStart != date)
              ListTile(
                leading: const Icon(Icons.stop, color: Colors.red),
                title: const Text('Set as Week End'),
                onTap: () {
                  Navigator.pop(context);
                  _createWeek(_pendingWeekStart!, date);
                },
              ),

            if (existingAWD != null && existingHoliday == null)
              ListTile(
                leading: const Icon(Icons.warning, color: Colors.red),
                title: const Text('Remove Alternate Working Day to set Holiday', style: TextStyle(color: Colors.red, fontSize: 14)),
              )
            else if (existingHoliday == null)
              ListTile(
                leading: const Icon(Icons.star, color: Colors.orange),
                title: const Text('Mark as Holiday'),
                onTap: () {
                  Navigator.pop(context);
                  _createHoliday(date);
                },
              ),

            if (existingHoliday != null && existingAWD == null)
              ListTile(
                leading: const Icon(Icons.warning, color: Colors.red),
                title: const Text('Remove Holiday to set Alternate Working Day', style: TextStyle(color: Colors.red, fontSize: 14)),
              )
            else if (existingAWD == null)
              ListTile(
                leading: const Icon(Icons.swap_horiz, color: Colors.blue),
                title: const Text('Set as Alternate Working Day'),
                onTap: () {
                  Navigator.pop(context);
                  _showAlternateWorkingDayDialog(date: date);
                },
              ),

            if (existingAWD != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Alternate Working Day'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteAlternateWorkingDay(existingAWD['id']);
                },
              ),
            if (existingHoliday != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Holiday'),
                onTap: () {
                  Navigator.pop(context);
                  _removeConfiguration(null, existingHoliday, null);
                },
              ),
            if (existingWeek != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Week Configuration'),
                onTap: () {
                  Navigator.pop(context);
                  _removeConfiguration(existingWeek, null, null);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _createWeek(DateTime start, DateTime end) async {
    if (end.isBefore(start)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Week End cannot be before Week Start')));
      return;
    }
    
    // Check overlaps
    for (var w in _allWeeks) {
      final s = DateTime.parse(w['startDate']);
      final e = DateTime.parse(w['endDate']);
      if (!end.isBefore(s) && !start.isAfter(e)) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot overlap with existing configured weeks')));
         return;
      }
    }

    setState(() => _isLoading = true);
    try {
      // Determine week number based on existing weeks for the current month
      final currentMonthWeeks = _allWeeks.where((w) => w['academicMonthId'] == _academicMonth!['id']).toList();
      final weekNum = currentMonthWeeks.length + 1;

      final data = {
        'academicMonthId': _academicMonth!['id'],
        'weekNumber': weekNum,
        'startDate': DateFormat('yyyy-MM-dd').format(start),
        'endDate': DateFormat('yyyy-MM-dd').format(end),
      };

      await _service.addWeek(data);
      setState(() => _pendingWeekStart = null);
      await _loadCalendarData();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _createHoliday(DateTime date) async {
    String holidayName = 'Holiday';
    
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: const Text('Holiday Name'),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(hintText: 'Enter holiday name'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Save')),
          ],
        );
      }
    );

    if (result == null || result.trim().isEmpty) return;
    holidayName = result.trim();

    setState(() => _isLoading = true);
    try {
      final data = {
        'academicMonthId': _academicMonth!['id'],
        'holidayName': holidayName,
        'holidayDate': DateFormat('yyyy-MM-dd').format(date),
      };
      await _service.addHoliday(data);
      await _loadCalendarData();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  void _showAlternateWorkingDayDialog({DateTime? date, Map<String, dynamic>? existingAwd}) {
    String originalHoliday = existingAwd?['originalHolidayDay'] ?? 'SATURDAY';
    String workingDay = existingAwd?['workingDay'] ?? 'WEDNESDAY';
    final reasonCtrl = TextEditingController(text: existingAwd?['reason'] ?? '');
    DateTime effectiveDate = date ?? (existingAwd != null ? DateTime.parse(existingAwd['effectiveDate']) : DateTime.now());

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(existingAwd == null ? 'Add Alternate Working Day' : 'Edit Alternate Working Day'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Effective Date'),
                      subtitle: Text(DateFormat('yyyy-MM-dd').format(effectiveDate)),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: originalHoliday,
                      decoration: const InputDecoration(labelText: 'Original Holiday Day'),
                      items: _daysOfWeek.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                      onChanged: (v) {
                        if (v != null) setDialogState(() => originalHoliday = v);
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: workingDay,
                      decoration: const InputDecoration(labelText: 'Working Day'),
                      items: _daysOfWeek.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                      onChanged: (v) {
                        if (v != null) setDialogState(() => workingDay = v);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: reasonCtrl,
                      decoration: const InputDecoration(labelText: 'Reason (e.g. Saturday Compensation)'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (reasonCtrl.text.trim().isEmpty) return;
                    Navigator.pop(ctx);
                    setState(() => _isLoading = true);
                    final data = {
                      'academicMonthId': _academicMonth!['id'],
                      'effectiveDate': DateFormat('yyyy-MM-dd').format(effectiveDate),
                      'originalHolidayDay': originalHoliday,
                      'workingDay': workingDay,
                      'reason': reasonCtrl.text.trim(),
                    };
                    try {
                      if (existingAwd == null) {
                        await _service.addAlternateWorkingDay(data);
                      } else {
                        await _service.updateAlternateWorkingDay(existingAwd['id'], data);
                      }
                      await _loadCalendarData();
                    } catch (e) {
                      setState(() => _isLoading = false);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                    }
                  }, 
                  child: const Text('Save')
                ),
              ],
            );
          }
        );
      }
    );
  }

  Future<void> _removeConfiguration(dynamic week, dynamic holiday, dynamic awd) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Configuration'),
        content: const Text('Are you sure you want to remove the configurations on this date?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
        ],
      )
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      if (week != null) {
        await _service.deleteWeek(week['id']);
      }
      if (holiday != null) {
        await _service.deleteHoliday(holiday['id']);
      }
      if (awd != null) {
        await _service.deleteAlternateWorkingDay(awd['id']);
      }
      await _loadCalendarData();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _deleteAlternateWorkingDay(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Alternate Working Day'),
        content: const Text('Are you sure you want to remove this configuration?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
        ],
      )
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _service.deleteAlternateWorkingDay(id);
      await _loadCalendarData();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Academic Calendar'),
      ),
      body: Column(
        children: [
          _buildMonthSelector(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      _buildCalendarGrid(),
                      const SizedBox(height: 24),
                      _buildAlternateWorkingDaysSection(),
                      const SizedBox(height: 48),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    final List<int> years = [for (var i = 2024; i <= 2030; i++) i];
    final List<String> months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DropdownButton<int>(
                value: _selectedMonth,
                items: List.generate(12, (index) {
                  return DropdownMenuItem(
                    value: index + 1,
                    child: Text(months[index]),
                  );
                }),
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _selectedMonth = v);
                    _loadCalendarData();
                  }
                },
              ),
              const SizedBox(width: 16),
              DropdownButton<int>(
                value: _selectedYear,
                items: years.map((y) {
                  return DropdownMenuItem(value: y, child: Text(y.toString()));
                }).toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _selectedYear = v);
                    _loadCalendarData();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_selectedYear, _selectedMonth, 1);
    final daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
    
    // Sunday = 7, Monday = 1 ... Saturday = 6
    // We want Sunday to be the first column (index 0).
    int firstWeekday = firstDayOfMonth.weekday;
    int leadingEmptyDays = (firstWeekday == 7) ? 0 : firstWeekday;

    // To show trailing days of previous month
    final daysInPrevMonth = DateTime(_selectedYear, _selectedMonth, 0).day;

    // Total cells in grid
    final totalCells = leadingEmptyDays + daysInMonth;
    final trailingEmptyDays = (7 - (totalCells % 7)) % 7;
    final totalGridDays = totalCells + trailingEmptyDays;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
                  .map((d) => Text(d, style: const TextStyle(fontWeight: FontWeight.bold)))
                  .toList(),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.0,
                crossAxisSpacing: 4.0,
                mainAxisSpacing: 4.0,
              ),
              itemCount: totalGridDays,
              itemBuilder: (context, index) {
                DateTime currentDate;
                bool isCurrentMonth = true;

                if (index < leadingEmptyDays) {
                  // Previous month days
                  isCurrentMonth = false;
                  final dayNum = daysInPrevMonth - leadingEmptyDays + index + 1;
                  int prevM = _selectedMonth - 1;
                  int prevY = _selectedYear;
                  if (prevM == 0) {
                    prevM = 12;
                    prevY--;
                  }
                  currentDate = DateTime(prevY, prevM, dayNum);
                } else if (index >= leadingEmptyDays + daysInMonth) {
                  // Next month days
                  isCurrentMonth = false;
                  final dayNum = index - (leadingEmptyDays + daysInMonth) + 1;
                  int nextM = _selectedMonth + 1;
                  int nextY = _selectedYear;
                  if (nextM == 13) {
                    nextM = 1;
                    nextY++;
                  }
                  currentDate = DateTime(nextY, nextM, dayNum);
                } else {
                  // Current month days
                  final dayNum = index - leadingEmptyDays + 1;
                  currentDate = DateTime(_selectedYear, _selectedMonth, dayNum);
                }

                final dateStr = DateFormat('yyyy-MM-dd').format(currentDate);

                // Check holidays
                bool isConfiguredHoliday = _allHolidays.any((h) => h['holidayDate'] == dateStr);

                // Check Alternate Working Day
                bool isAWD = _allAlternateWorkingDays.any((a) => a['effectiveDate'] == dateStr);

                // Check Sunday default holiday
                bool isSundayHoliday = (currentDate.weekday == DateTime.sunday) && !isAWD;

                // Check weeks
                Color? cellBackgroundColor;
                for (int w = 0; w < _allWeeks.length; w++) {
                  final week = _allWeeks[w];
                  final s = DateTime.parse(week['startDate']);
                  final e = DateTime.parse(week['endDate']);
                  if ((currentDate.isAfter(s) || currentDate.isAtSameMomentAs(s)) && 
                      (currentDate.isBefore(e) || currentDate.isAtSameMomentAs(e))) {
                    cellBackgroundColor = _weekColors[w % _weekColors.length].withOpacity(0.3);
                    break;
                  }
                }

                // Apply Colors according to priority
                if (isAWD) {
                    cellBackgroundColor = Colors.purple.withOpacity(0.3);
                } else if (isConfiguredHoliday) {
                    cellBackgroundColor = Colors.red.shade900.withOpacity(0.3); // Dark Red
                } else if (isSundayHoliday) {
                    cellBackgroundColor = Colors.red.shade300.withOpacity(0.3); // Light Red
                }

                bool isSelected = _pendingWeekStart != null && currentDate.isAtSameMomentAs(_pendingWeekStart!);

                return InkWell(
                  onTap: () => _onDateTapped(currentDate),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cellBackgroundColor ?? Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isSelected 
                            ? Colors.blue 
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          currentDate.day.toString(), 
                          style: TextStyle(
                            fontSize: 16, 
                            color: isCurrentMonth ? Colors.black : Colors.grey.shade400,
                            fontWeight: isCurrentMonth ? FontWeight.normal : FontWeight.w300,
                          )
                        ),
                        if (isConfiguredHoliday || isSundayHoliday)
                          Positioned(
                            top: 2,
                            right: 2,
                            child: Icon(Icons.star, color: isConfiguredHoliday ? Colors.red.shade900 : Colors.red.shade300, size: 12),
                          ),
                        if (isAWD)
                          const Positioned(
                            bottom: 2,
                            child: Icon(Icons.circle, color: Colors.purple, size: 6),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlternateWorkingDaysSection() {
    final currentMonthAWDs = _allAlternateWorkingDays.where((a) => a['academicMonthId'] == _academicMonth?['id']).toList();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Alternate Working Days', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            if (currentMonthAWDs.isEmpty)
              const Text('No alternate working days configured for this month.')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: currentMonthAWDs.length,
                itemBuilder: (context, index) {
                  final a = currentMonthAWDs[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.event_busy, color: Colors.red, size: 16),
                                    const SizedBox(width: 4),
                                    Text(a['originalHolidayDay'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                                      child: Icon(Icons.arrow_forward, size: 16),
                                    ),
                                    const Icon(Icons.work, color: Colors.green, size: 16),
                                    const SizedBox(width: 4),
                                    Text(a['workingDay'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text('Effective Date: ${a['effectiveDate']}'),
                                Text('Reason: ${a['reason']}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.orange),
                                onPressed: () => _showAlternateWorkingDayDialog(existingAwd: a),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteAlternateWorkingDay(a['id']),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
