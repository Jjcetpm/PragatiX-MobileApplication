import 'package:flutter/material.dart';

class ActivityOwnerSection extends StatelessWidget {
  final dynamic selectedSection;
  final dynamic selectedTeacher;
  final TextEditingController teacherSearchCtrl;
  final String teacherSearchQuery;
  final List<dynamic> filteredSections;
  final List<dynamic> searchedTeachers;
  final bool hasSections;
  final bool submitted;
  final dynamic initialData;
  final ValueChanged<dynamic> onSectionChanged;
  final ValueChanged<dynamic> onTeacherChanged;
  final ValueChanged<String> onTeacherSearchQueryChanged;
  final VoidCallback onClearTeacher;

  const ActivityOwnerSection({
    super.key,
    required this.selectedSection,
    required this.selectedTeacher,
    required this.teacherSearchCtrl,
    required this.teacherSearchQuery,
    required this.filteredSections,
    required this.searchedTeachers,
    required this.hasSections,
    required this.submitted,
    this.initialData,
    required this.onSectionChanged,
    required this.onTeacherChanged,
    required this.onTeacherSearchQueryChanged,
    required this.onClearTeacher,
  });

  static const Color _primary = Color(0xFFEA4335);
  static const Color _dark = Color(0xFF1E293B);
  static const Color _surface = Color(0xFFF8FAFC);

  InputDecoration _deco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _primary, size: 20),
      filled: true,
      fillColor: _surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (initialData != null &&
            initialData.assignmentSummary.isNotEmpty) ...[
          const Text(
            'Current Assignments:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: _dark,
            ),
          ),
          const SizedBox(height: 6),
          ...initialData.assignmentSummary.map((assign) {
            final secName = assign['section'] as String?;
            final teachName = assign['teacher'] as String?;
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                secName != null
                    ? 'Section $secName → $teachName'
                    : 'Assigned to → $teachName',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
        ],
        const Text(
          'New Assignment:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: _dark,
          ),
        ),
        const SizedBox(height: 10),
        const SizedBox(height: 16),
        if (hasSections) ...[
          InputDecorator(
            decoration: _deco('Section', Icons.class_outlined).copyWith(
              errorText: (submitted && selectedSection == null)
                  ? 'Section is required'
                  : null,
            ),
            child: DropdownButton<dynamic>(
              value: selectedSection != null
                  ? filteredSections.firstWhere(
                      (s) =>
                          s['id'].toString() ==
                          selectedSection['id'].toString(),
                      orElse: () => null,
                    )
                  : null,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              icon: const Icon(Icons.expand_more_rounded, color: _primary),
              hint: const Text(
                'Select section',
                style: TextStyle(fontSize: 14),
              ),
              items: filteredSections.map((s) {
                return DropdownMenuItem<dynamic>(
                  value: s,
                  child: Text(
                    s['sectionName'].toString(),
                    style: const TextStyle(fontSize: 14, color: _dark),
                  ),
                );
              }).toList(),
              onChanged: onSectionChanged,
            ),
          ),
          const SizedBox(height: 16),
        ],
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (selectedTeacher != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.blue.shade100,
                      child: const Icon(
                        Icons.person_rounded,
                        size: 16,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedTeacher['fullName']?.toString() ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: _dark,
                            ),
                          ),
                          Text(
                            '${selectedTeacher['username'] ?? ''} • ${selectedTeacher['departmentName'] ?? ''}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Colors.red,
                      ),
                      onPressed: onClearTeacher,
                      tooltip: 'Clear selection',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ],
            TextFormField(
              controller: teacherSearchCtrl,
              style: const TextStyle(color: _dark, fontSize: 14),
              decoration:
                  _deco(
                    'Search Teacher by Name/Dept',
                    Icons.search_rounded,
                  ).copyWith(
                    suffixIcon: teacherSearchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              teacherSearchCtrl.clear();
                              onTeacherSearchQueryChanged('');
                            },
                          )
                        : null,
                  ),
              onChanged: onTeacherSearchQueryChanged,
            ),
            const SizedBox(height: 8),
            Container(
              height: 320,
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Builder(
                  builder: (context) {
                    if (searchedTeachers.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No teachers found',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _dark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Try another keyword.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: searchedTeachers.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, idx) {
                        final t = searchedTeachers[idx];
                        final isSelected =
                            selectedTeacher != null &&
                            selectedTeacher['id']?.toString() ==
                                t['id']?.toString();
                        final deptName = t['departmentName'] ?? 'No Department';
                        final uName = t['username'] ?? '';
                        final fullName = t['fullName'] ?? '';

                        return Card(
                          margin: EdgeInsets.zero,
                          elevation: isSelected ? 2 : 1,
                          shadowColor: Colors.black.withValues(alpha: 0.08),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: isSelected
                                  ? Colors.blue
                                  : Colors.grey.shade200,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          color: isSelected
                              ? Colors.blue.shade50
                              : Colors.white,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => onTeacherChanged(t),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: _primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    child: const Icon(
                                      Icons.person_rounded,
                                      size: 26,
                                      color: _primary,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          fullName,
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
                                            color: _dark,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$uName • $deptName',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: Colors.green,
                                      size: 24,
                                    )
                                  else
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color: Colors.grey.shade400,
                                      size: 16,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            if (submitted && selectedTeacher == null)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 12),
                child: Text(
                  'Teacher is required',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
