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
            hintText: 'Search by student ID or name...',
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
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Years')),
                    ...years.map((y) {
                      final yearVal = y['yearNo']?.toString() ?? y['yearName']?.toString() ?? y['name']?.toString() ?? '';
                      final yearName = y['yearName']?.toString() ?? y['name']?.toString() ?? 'Year';
                      return DropdownMenuItem(
                        value: yearVal,
                        child: Text(yearName),
                      );
                    }),
                  ],
                  onChanged: onYearChanged,
                  isExpanded: true,
                ),
              ),
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<int?>(
                decoration: InputDecoration(
                  labelText: 'Department',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                value: selectedDepartmentId,
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Departments')),
                  ...departments.map((d) {
                    final dId = int.tryParse(d['id'].toString());
                    return DropdownMenuItem(
                      value: dId,
                      child: Text((d['name'] ?? d['code'] ?? d['deptName'] ?? d['deptCode'] ?? '').toString()),
                    );
                  }),
                ],
                onChanged: onDepartmentChanged,
                isExpanded: true,
              ),
            ),
            SizedBox(
              width: 150,
              child: DropdownButtonFormField<int?>(
                decoration: InputDecoration(
                  labelText: 'Section',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                value: selectedSectionId,
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Sections')),
                  ...sections.map((s) {
                    final sId = int.tryParse(s['id'].toString());
                    return DropdownMenuItem(
                      value: sId,
                      child: Text('Section ${s['sectionName'] ?? s['name'] ?? ''}'),
                    );
                  }),
                ],
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
