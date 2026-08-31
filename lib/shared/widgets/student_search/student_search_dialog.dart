import 'package:flutter/material.dart';
import 'package:pragatix/core/widgets/pragatix_loader.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/shared/providers/student_search_provider.dart';
import 'package:pragatix/shared/widgets/student_search/student_tile.dart';

class StudentSearchDialog extends StatefulWidget {
  final bool unassignedOnly;
  final String? year;
  final dynamic departmentId;
  final String? departmentName;
  final dynamic sectionId;
  final String? sectionName;

  const StudentSearchDialog({
    super.key,
    this.unassignedOnly = false,
    this.year,
    this.departmentId,
    this.departmentName,
    this.sectionId,
    this.sectionName,
  });

  @override
  State<StudentSearchDialog> createState() => _StudentSearchDialogState();
}

class _StudentSearchDialogState extends State<StudentSearchDialog> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final token = context.read<AuthProvider>().token;
      if (token != null) {
        final provider = context.read<StudentSearchProvider>();
        await provider.fetchStudents(
          token,
          forceRefresh: true,
          year: widget.year,
          departmentId: widget.departmentId,
          sectionId: widget.sectionId,
          unassignedOnly: widget.unassignedOnly,
        );
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _triggerSearch(String val) {
    context.read<StudentSearchProvider>().searchStudents(
      val,
      unassignedOnly: widget.unassignedOnly,
      year: widget.year,
      departmentId: widget.departmentId,
      sectionId: widget.sectionId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Column(
            children: [
              _buildHeader(),
              _buildClassScopeBadge(),
              _buildSearchBar(),
              Expanded(
                child: Consumer<StudentSearchProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading) {
                      return const Center(child: PragatiXLoader());
                    }

                    if (provider.error.isNotEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            provider.error,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    final students = provider.filteredStudents;
                    if (students.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF1F5F9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person_search_rounded,
                                  size: 40,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No Eligible Students Found',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No unassigned students found in the selected class (${widget.year ?? "Year"} • ${widget.departmentName ?? "Department"}${widget.sectionName != null && widget.sectionName!.isNotEmpty ? " • Section ${widget.sectionName}" : ""}).',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final student = students[index];
                        return StudentTile(
                          student: student,
                          onTap: () {
                            Navigator.pop(context, student);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 16, right: 8, bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Select Student',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildClassScopeBadge() {
    if (widget.year == null && widget.departmentName == null && widget.departmentId == null) {
      return const SizedBox.shrink();
    }

    final List<String> scopeParts = [];
    if (widget.year != null && widget.year!.isNotEmpty) {
      scopeParts.add('Year: ${widget.year}');
    }
    if (widget.departmentName != null && widget.departmentName!.isNotEmpty) {
      scopeParts.add(widget.departmentName!);
    } else if (widget.departmentId != null) {
      scopeParts.add('Dept #${widget.departmentId}');
    }
    if (widget.sectionName != null && widget.sectionName!.isNotEmpty) {
      scopeParts.add('Section ${widget.sectionName}');
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_alt_rounded, size: 16, color: Color(0xFF2563EB)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              scopeParts.join(' • '),
              style: const TextStyle(
                color: Color(0xFF1E40AF),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchCtrl,
        onChanged: _triggerSearch,
        decoration: InputDecoration(
          hintText: 'Search by Name, Reg No, SPR No...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchCtrl.clear();
                    _triggerSearch('');
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Theme.of(context).cardColor,
        ),
      ),
    );
  }
}
