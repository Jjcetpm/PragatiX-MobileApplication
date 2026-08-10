import 'package:flutter/material.dart';
import '../dialogs/delete_student_dialog.dart';

class StudentList extends StatelessWidget {
  final List<dynamic> studentsList;
  final String searchQuery;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(int) onDelete;
  final ScrollController? scrollController;
  final bool isLoadingMore;
  final bool hasMore;

  const StudentList({
    super.key,
    required this.studentsList,
    required this.searchQuery,
    required this.onEdit,
    required this.onDelete,
    this.scrollController,
    this.isLoadingMore = false,
    this.hasMore = false,
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
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          );
        }

        final s = filteredList[index];
        final String sId = s['regNo'] ?? '';
        final String name = s['fullName'] ?? '';
        final String deptName = s['departmentName'] ?? s['department'] ?? 'No Department';

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFEA4335).withValues(alpha: 0.1),
              child: const Icon(Icons.person, color: Color(0xFFEA4335)),
            ),
            title: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "$sId • $deptName\nSem: ${s["semester"] ?? '1'}${s["year"] != null && s["year"].toString().isNotEmpty ? ' • Year: ${s["year"]}' : ''}${s["section"] != null && s["section"].toString().isNotEmpty ? ' • Section: ${s["section"]}' : ''}",
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                  onPressed: () => onEdit(s),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
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
            ),
          ),
        );
      },
    );
  }
}
