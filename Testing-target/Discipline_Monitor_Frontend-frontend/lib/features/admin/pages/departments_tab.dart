import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:pragatix/core/utils/error_handler.dart';
import 'package:pragatix/features/admin/repository/admin_repository.dart';
import 'package:pragatix/core/di/service_locator.dart';

Future<List<dynamic>> _apiGetDepartments(String token) async {
  try {
    return await getIt<AdminRepository>().getDepartments();
  } catch (e) {
    // Fallback
    return [];
  }
}

class DepartmentsTab extends StatefulWidget {
  const DepartmentsTab({super.key});

  @override
  State<DepartmentsTab> createState() => _DepartmentsTabState();
}

class _DepartmentsTabState extends State<DepartmentsTab> {
  List<dynamic> departments = [];
  List<dynamic> filteredDepartments = [];
  bool isLoading = true;
  String searchQuery = '';

  final TextEditingController nameController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
  }

  Future<void> _fetchDepartments() async {
    try {
      final list = await _apiGetDepartments(
        context.read<AuthProvider>().token!,
      );
      if (!context.mounted) return;
      setState(() {
        departments = list;
        _filterDepartments(searchQuery);
        isLoading = false;
      });
    } catch (e) {
      if (!context.mounted) return;
      setState(() => isLoading = false);
    }
  }

  void _filterDepartments(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredDepartments = List.from(departments);
      } else {
        filteredDepartments = departments.where((dept) {
          final name = (dept['name'] ?? '').toString().toLowerCase();
          final code = (dept['code'] ?? '').toString().toLowerCase();
          return name.contains(query.toLowerCase()) ||
              code.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _addDepartment() async {
    final name = nameController.text.trim();
    final code = codeController.text.trim().toUpperCase();

    if (name.isEmpty || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name and Code are required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await getIt<AdminRepository>().addDepartment(name, code);
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Department added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      nameController.clear();
      codeController.clear();
      Navigator.pop(context);
      setState(() => isLoading = true);
      _fetchDepartments();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Department added locally (Offline mode)'),
          backgroundColor: Colors.orange,
        ),
      );
      setState(() {
        departments.add({
          'id': DateTime.now().millisecondsSinceEpoch,
          'name': name,
          'code': code,
        });
        _filterDepartments(searchQuery);
      });
      nameController.clear();
      codeController.clear();
      Navigator.pop(context);
    }
  }

  Future<void> _editDepartment(int id) async {
    final name = nameController.text.trim();
    final code = codeController.text.trim().toUpperCase();

    if (name.isEmpty || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name and Code are required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await getIt<AdminRepository>().editDepartment(id, name, code);
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Department updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      nameController.clear();
      codeController.clear();
      Navigator.pop(context);
      setState(() => isLoading = true);
      _fetchDepartments();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Updated locally (Offline mode)'),
          backgroundColor: Colors.orange,
        ),
      );
      setState(() {
        final idx = departments.indexWhere((d) => d['id'] == id);
        if (idx != -1) {
          departments[idx]['name'] = name;
          departments[idx]['code'] = code;
        }
        _filterDepartments(searchQuery);
      });
      nameController.clear();
      codeController.clear();
      Navigator.pop(context);
    }
  }

  Future<void> _deleteDepartment(int id) async {
    try {
      await getIt<AdminRepository>().deleteDepartment(id);
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Department deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() => isLoading = true);
      _fetchDepartments();
    } catch (e) {
      if (!context.mounted) return;
      ErrorHandler.showSnackBar(context, e);
    }
  }

  void _showAddDeptDialog() {
    nameController.clear();
    codeController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Add New Department',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Department Name *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(
                    labelText: 'Department Code * (e.g. IT)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.code),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: _addDepartment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showEditDeptDialog(Map<String, dynamic> dept) {
    nameController.text = dept['name'] ?? '';
    codeController.text = dept['code'] ?? '';
    final sectionNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        List<dynamic> deptSections = [];
        bool loadingSections = true;

        Future<void> fetchDeptSections(StateSetter dialogSetState) async {
          dialogSetState(() => loadingSections = true);
          try {
            final sections = await getIt<AdminRepository>()
                .getDepartmentSections(dept['id']);
            dialogSetState(() {
              deptSections = sections;
              loadingSections = false;
            });
            return;
          } catch (e) {
            debugPrint('Error fetching dept sections: $e');
          }
          dialogSetState(() => loadingSections = false);
        }

        Future<void> addSection(StateSetter dialogSetState) async {
          final secName = sectionNameController.text.trim().toUpperCase();
          if (secName.isEmpty) return;
          try {
            await getIt<AdminRepository>().addDepartmentSection(
              dept['id'],
              secName,
            );
            sectionNameController.clear();
            fetchDeptSections(dialogSetState);
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(e.toString().replaceAll('Exception: ', '')),
                backgroundColor: Colors.red,
              ),
            );
          }
        }

        Future<void> deleteSection(
          int sectionId,
          StateSetter dialogSetState,
        ) async {
          try {
            await getIt<AdminRepository>().deleteDepartmentSection(sectionId);
            fetchDeptSections(dialogSetState);
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(e.toString().replaceAll('Exception: ', '')),
                backgroundColor: Colors.red,
              ),
            );
          }
        }

        return StatefulBuilder(
          builder: (context, dialogSetState) {
            if (loadingSections && deptSections.isEmpty) {
              Future.microtask(() => fetchDeptSections(dialogSetState));
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                "Edit Department: ${dept["code"]}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DEPARTMENT DETAILS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Department Name *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: codeController,
                        decoration: const InputDecoration(
                          labelText: 'Department Code *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.code),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text(
                        'SECTIONS MANAGEMENT',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: sectionNameController,
                              decoration: const InputDecoration(
                                labelText: 'Add Section (e.g. A, B)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => addSection(dialogSetState),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E293B),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            child: const Icon(Icons.add, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      loadingSections
                          ? const Center(child: CircularProgressIndicator())
                          : (deptSections.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 8.0,
                                    ),
                                    child: Text(
                                      'No sections created yet.',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: deptSections.length,
                                    itemBuilder: (context, idx) {
                                      final sec = deptSections[idx];
                                      return ListTile(
                                        title: Text(
                                          "Section ${sec["sectionName"] ?? sec["name"] ?? ''}",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        trailing: IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                          ),
                                          onPressed: () => deleteSection(
                                            sec['id'],
                                            dialogSetState,
                                          ),
                                        ),
                                      );
                                    },
                                  )),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    _editDepartment(dept['id']);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Academic Departments',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (departments.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: searchController,
                      onChanged: _filterDepartments,
                      decoration: InputDecoration(
                        hintText: 'Search departments...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.grey,
                        ),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  searchController.clear();
                                  _filterDepartments('');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: 16,
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchDepartments,
                    color: const Color(0xFF1E293B),
                    child: filteredDepartments.isEmpty
                        ? ListView(
                            children: [
                              Container(
                                height:
                                    MediaQuery.of(context).size.height * 0.6,
                                alignment: Alignment.center,
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.blueGrey.shade50,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.folder_open_outlined,
                                        color: Colors.blueGrey.shade400,
                                        size: 80,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    const Text(
                                      '📁 No Departments Found',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'There are currently no departments.\nTap the + button to create your first department.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.blueGrey.shade500,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            itemCount: filteredDepartments.length,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            itemBuilder: (context, index) {
                              final dept = filteredDepartments[index];
                              return Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: Colors.grey.shade200,
                                    width: 1,
                                  ),
                                ),
                                margin: const EdgeInsets.only(bottom: 12),
                                color: Colors.white,
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF1E293B,
                                          ).withValues(alpha: 0.08),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.account_balance,
                                          color: Color(0xFF1E293B),
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              dept['name'] ?? '',
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1E293B),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "Code: ${dept["code"] ?? ""}",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                              color: Colors.blue,
                                              size: 22,
                                            ),
                                            onPressed: () =>
                                                _showEditDeptDialog(dept),
                                            tooltip: 'Edit Department',
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.red,
                                              size: 22,
                                            ),
                                            tooltip: 'Delete Department',
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                  ),
                                                  title: const Text(
                                                    'Delete Department',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  content: Text(
                                                    "Are you sure you want to delete department ${dept["code"]}?",
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            context,
                                                          ),
                                                      child: const Text(
                                                        'Cancel',
                                                        style: TextStyle(
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                        _deleteDepartment(
                                                          dept['id'],
                                                        );
                                                      },
                                                      child: const Text(
                                                        'Delete',
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDeptDialog,
        backgroundColor: const Color(0xFF1E293B),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
