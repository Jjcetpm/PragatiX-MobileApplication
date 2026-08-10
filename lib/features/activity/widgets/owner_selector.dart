import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Department + Teacher owner selector.
// Uses DropdownButton (not DropdownButtonFormField) — validation is manual,
// shown via showError flag. Teacher list filters automatically by department.
// ─────────────────────────────────────────────────────────────────────────────

class OwnerSelector extends StatelessWidget {
  final List<dynamic> departments;
  final List<dynamic> allTeachers;
  final dynamic selectedDept;
  final dynamic selectedTeacher;
  final ValueChanged<dynamic> onDeptChanged;
  final ValueChanged<dynamic> onTeacherChanged;
  final bool showError;
  final bool showTeacher;

  static const Color _primary = Color(0xFFEA4335);
  static const Color _dark = Color(0xFF1E293B);

  const OwnerSelector({
    super.key,
    required this.departments,
    required this.allTeachers,
    required this.selectedDept,
    required this.selectedTeacher,
    required this.onDeptChanged,
    required this.onTeacherChanged,
    required this.showError,
    this.showTeacher = true,
  });

  List<dynamic> get _filteredTeachers {
    if (!showTeacher || selectedDept == null) return [];
    final deptId = selectedDept['id'];
    final deptName = (selectedDept['name'] as String).toLowerCase();
    return allTeachers.where((t) {
      final tid = t['departmentId'];
      final tname = (t['departmentName'] as String? ?? '').toLowerCase();
      return tid == deptId || tname == deptName;
    }).toList();
  }

  InputDecoration _deco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _primary, size: 20),
      filled: true,
      fillColor: Colors.grey.shade50,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTeachers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Department dropdown ──────────────────────────────────────────────
        InputDecorator(
          decoration: _deco('Department', Icons.apartment_rounded).copyWith(
            errorText: (showError && selectedDept == null)
                ? 'Department is required'
                : null,
          ),
          child: DropdownButton<dynamic>(
            value: selectedDept,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            icon: const Icon(Icons.expand_more_rounded, color: _primary),
            hint: Text(
              'Select department',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
            items: departments.map((d) {
              return DropdownMenuItem<dynamic>(
                value: d,
                child: Text(
                  d['name'].toString(),
                  style: const TextStyle(fontSize: 14, color: _dark),
                ),
              );
            }).toList(),
            onChanged: (val) {
              onDeptChanged(val);
              onTeacherChanged(null); // Clear teacher when dept changes
            },
          ),
        ),

        if (showTeacher) ...[
          const SizedBox(height: 16),

          // ── Teacher dropdown ─────────────────────────────────────────────────
          InputDecorator(
            decoration: _deco(
              'Faculty / Teacher (Optional)',
              Icons.person_outline_rounded,
            ),
            child: DropdownButton<dynamic>(
              value: selectedTeacher,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              icon: const Icon(Icons.expand_more_rounded, color: _primary),
              hint: Text(
                selectedDept == null
                    ? 'Select department first'
                    : filtered.isEmpty
                    ? 'No teachers in this department'
                    : 'Select teacher',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
              items: filtered.map((t) {
                return DropdownMenuItem<dynamic>(
                  value: t,
                  child: Text(
                    '${t["fullName"]}  (${t["username"]})',
                    style: const TextStyle(fontSize: 14, color: _dark),
                  ),
                );
              }).toList(),
              onChanged: filtered.isEmpty ? null : onTeacherChanged,
            ),
          ),
        ],
      ],
    );
  }
}
