import 'package:flutter/material.dart';
import '../dialogs/delete_student_dialog.dart';

class StudentList extends StatelessWidget {
  final List<dynamic> studentsList;
  final String searchQuery;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(int) onDelete;
  final void Function(Map<String, dynamic>)? onTap;
  final ScrollController? scrollController;
  final bool isLoadingMore;
  final bool hasMore;
  final List<dynamic>? genders;
  final bool isSelectionMode;
  final Set<int> selectedIds;
  final void Function(int id)? onToggleSelect;

  const StudentList({
    super.key,
    required this.studentsList,
    required this.searchQuery,
    required this.onEdit,
    required this.onDelete,
    this.onTap,
    this.scrollController,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.genders,
    this.isSelectionMode = false,
    this.selectedIds = const {},
    this.onToggleSelect,
  });

  @override
  Widget build(BuildContext context) {
    final filteredList = searchQuery.trim().isEmpty
        ? studentsList
        : studentsList.where((s) {
            final String sId = (s['regNo'] ?? '').toString().toLowerCase();
            final String sprNo = (s['sprNo'] ?? '').toString().toLowerCase();
            final String name = (s['fullName'] ?? '').toString().toLowerCase();
            final String deptName =
                (s['departmentName'] ?? s['department'] ?? '').toString().toLowerCase();
            final String email = (s['email'] ?? '').toString().toLowerCase();
            final q = searchQuery.trim().toLowerCase();
            return sId.contains(q) ||
                sprNo.contains(q) ||
                name.contains(q) ||
                deptName.contains(q) ||
                email.contains(q);
          }).toList();

    if (filteredList.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_search_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                searchQuery.trim().isEmpty
                    ? 'No students available'
                    : 'No students found matching "$searchQuery"',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    final totalItemCount = filteredList.length + (isLoadingMore ? 1 : 0);

    return ListView.builder(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: totalItemCount,
      itemBuilder: (context, index) {
        if (index == filteredList.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
          );
        }

        final s = filteredList[index];
        final int? studentId = s['id'] is int ? s['id'] : int.tryParse(s['id'].toString());
        final bool isSelected = studentId != null && selectedIds.contains(studentId);
        final String sId = s['regNo'] ?? '';
        final String name = s['fullName'] ?? '';
        final String deptName = s['departmentName'] ?? s['department'] ?? 'No Department';

        // ── Resolve Student Gender & Gender Avatar ───────────────────────
        final dynamic rawGender = s['gender'] ?? s['genderName'] ?? (s['genderRef'] is Map ? s['genderRef']['genderName'] : null);
        String genderStr = '';
        if (rawGender is Map) {
          genderStr = (rawGender['genderName'] ?? rawGender['name'] ?? '').toString();
        } else if (rawGender != null) {
          genderStr = rawGender.toString();
        }
        genderStr = genderStr.trim().toLowerCase();

        if (genderStr.isEmpty && s['genderId'] != null && genders != null) {
          final match = genders!.firstWhere(
            (g) => g is Map && g['id'] == s['genderId'],
            orElse: () => null,
          );
          if (match != null) {
            genderStr = (match['genderName'] ?? match['name'] ?? '').toString().trim().toLowerCase();
          }
        }

        final bool isFemale = genderStr.startsWith('f') || genderStr == 'girl' || genderStr == 'woman';
        final String avatarAsset = isFemale
            ? 'assets/images/avatar_female.png'
            : 'assets/images/avatar_male.png';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
              width: isSelected ? 1.8 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? const Color(0xFF2563EB).withValues(alpha: 0.1)
                    : const Color(0xFF64748B).withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                if (isSelectionMode && studentId != null) {
                  if (onToggleSelect != null) onToggleSelect!(studentId);
                } else if (onTap != null) {
                  onTap!(Map<String, dynamic>.from(s));
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    if (isSelectionMode) ...[
                      Checkbox(
                        value: isSelected,
                        activeColor: const Color(0xFF2563EB),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                        onChanged: (_) {
                          if (studentId != null && onToggleSelect != null) {
                            onToggleSelect!(studentId);
                          }
                        },
                      ),
                      const SizedBox(width: 4),
                    ],
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isFemale ? const Color(0xFFFDF2F8) : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isFemale ? const Color(0xFFFBCFE8) : const Color(0xFFBFDBFE),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isFemale ? const Color(0xFFEC4899) : const Color(0xFF2563EB)).withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.8),
                        child: Image.asset(
                          avatarAsset,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            isFemale ? Icons.female_rounded : Icons.male_rounded,
                            color: isFemale ? const Color(0xFFDB2777) : const Color(0xFF2563EB),
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: isSelected ? const Color(0xFF1E40AF) : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            "$sId • $deptName",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Sem: ${s["semester"] ?? '1'}${s["year"] != null && s["year"].toString().isNotEmpty ? ' • Year: ${s["year"]}' : ''}${s["section"] != null && s["section"].toString().isNotEmpty ? ' • Section: ${s["section"]}' : ''}",
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isSelectionMode) ...[
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Color(0xFF2563EB), size: 20),
                        onPressed: () => onEdit(s),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => DeleteStudentDialog(
                              studentName: name,
                              onConfirmDelete: () => onDelete(s['id']),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
