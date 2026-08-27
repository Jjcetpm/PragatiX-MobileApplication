import 'package:flutter/material.dart';

class StudentFilterPanel extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String>? onSearchSubmitted;
  final bool isSuperAdmin;
  
  final List<dynamic> years;
  final List<dynamic> departments;
  final List<dynamic> sections;
  
  final String? selectedYear;
  final int? selectedDepartmentId;
  final int? selectedSectionId;
  
  final ValueChanged<String?> onYearChanged;
  final ValueChanged<int?> onDepartmentChanged;
  final ValueChanged<int?> onSectionChanged;
  final VoidCallback onReset;

  const StudentFilterPanel({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    this.onSearchSubmitted,
    required this.isSuperAdmin,
    required this.years,
    required this.departments,
    required this.sections,
    required this.selectedYear,
    required this.selectedDepartmentId,
    required this.selectedSectionId,
    required this.onYearChanged,
    required this.onDepartmentChanged,
    required this.onSectionChanged,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: 'Search by Register Number or name...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: onSearchChanged,
          onSubmitted: onSearchSubmitted,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (isSuperAdmin)
              SizedBox(
                width: 150,
                child: DropdownButtonFormField<String?>(
                  decoration: InputDecoration(
                    labelText: 'Academic Year',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  value: selectedYear,
                  items: () {
                    final seenYears = <String>{};
                    final items = <DropdownMenuItem<String?>>[
                      const DropdownMenuItem(value: null, child: Text('All Years')),
                    ];
                    for (final y in years) {
                      String yearVal;
                      String yearName;
                      if (y is String) {
                        yearVal = y;
                        yearName = y.split('_').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}' : '').join(' ');
                      } else {
                        yearVal = y['yearNo']?.toString() ?? y['yearName']?.toString() ?? y['name']?.toString() ?? '';
                        yearName = y['yearName']?.toString() ?? y['year_name']?.toString() ?? y['name']?.toString() ?? (y['yearNo'] != null ? 'Year ${y['yearNo']}' : 'Year');
                      }
                      if (yearVal.isNotEmpty && !seenYears.contains(yearVal)) {
                        seenYears.add(yearVal);
                        items.add(DropdownMenuItem(
                          value: yearVal,
                          child: Text(yearName, overflow: TextOverflow.ellipsis, maxLines: 1),
                        ));
                      }
                    }
                    return items;
                  }(),
                  onChanged: onYearChanged,
                  isExpanded: true,
                ),
              ),
            SizedBox(
              width: 190,
              child: DropdownButtonFormField<int?>(
                decoration: InputDecoration(
                  labelText: 'Department',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                value: selectedDepartmentId,
                selectedItemBuilder: (BuildContext context) {
                  final list = <Widget>[
                    const Text('All Departments', overflow: TextOverflow.ellipsis, maxLines: 1),
                  ];
                  final seenDepts = <int>{};
                  for (final d in departments) {
                    final dId = int.tryParse(d['id']?.toString() ?? '');
                    if (dId != null && !seenDepts.contains(dId)) {
                      seenDepts.add(dId);
                      final name = (d['name'] ?? d['deptName'] ?? d['code'] ?? d['deptCode'] ?? '').toString();
                      list.add(Text(name, overflow: TextOverflow.ellipsis, maxLines: 1));
                    }
                  }
                  return list;
                },
                items: () {
                  final seenDepts = <int>{};
                  final items = <DropdownMenuItem<int?>>[
                    const DropdownMenuItem(value: null, child: Text('All Departments')),
                  ];
                  for (final d in departments) {
                    final dId = int.tryParse(d['id']?.toString() ?? '');
                    if (dId != null && !seenDepts.contains(dId)) {
                      seenDepts.add(dId);
                      final name = (d['name'] ?? d['deptName'] ?? d['code'] ?? d['deptCode'] ?? '').toString();
                      items.add(DropdownMenuItem(
                        value: dId,
                        child: Text(
                          name,
                          softWrap: true,
                          maxLines: 2,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ));
                    }
                  }
                  return items;
                }(),
                onChanged: onDepartmentChanged,
                isExpanded: true,
              ),
            ),
            SizedBox(
              width: 160,
              child: DropdownButtonFormField<int?>(
                decoration: InputDecoration(
                  labelText: 'Section',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                value: selectedSectionId,
                items: () {
                  final seenSecs = <int>{};
                  final items = <DropdownMenuItem<int?>>[
                    const DropdownMenuItem(value: null, child: Text('All Sections')),
                  ];
                  for (final s in sections) {
                    final sId = int.tryParse(s['id']?.toString() ?? '');
                    if (sId != null && !seenSecs.contains(sId)) {
                      seenSecs.add(sId);
                      items.add(DropdownMenuItem(
                        value: sId,
                        child: Text(
                          'Section ${s['sectionName'] ?? s['name'] ?? ''}',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ));
                    }
                  }
                  return items;
                }(),
                onChanged: onSectionChanged,
                isExpanded: true,
              ),
            ),
            TextButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reset Filters'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
