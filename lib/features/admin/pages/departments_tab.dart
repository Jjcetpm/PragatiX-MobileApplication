import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/core/widgets/pragatix_loader.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:pragatix/core/utils/error_handler.dart';
import 'package:pragatix/features/admin/repository/admin_repository.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/features/admin/providers/department_provider.dart' as import_provider;

Future<List<dynamic>> _apiGetDepartments(String token) async {
  try {
    return await getIt<AdminRepository>().getDepartments(all: true);
  } catch (e) {
    return [];
  }
}

class DepartmentsTab extends StatefulWidget {
  const DepartmentsTab({super.key});

  @override
  State<DepartmentsTab> createState() => _DepartmentsTabState();
}

class _DepartmentsTabState extends State<DepartmentsTab> {
  String searchQuery = '';
  
  bool _supportsSections = false;
  String _departmentType = 'MAIN';

  final TextEditingController nameController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<import_provider.DepartmentProvider>().fetchDepartments();
    });
  }

  List<dynamic> _getFilteredDepartments(List<dynamic> departments) {
    if (searchQuery.isEmpty) return departments;
    return departments.where((dept) {
      final name = (dept['name'] ?? '').toString().toLowerCase();
      final code = (dept['code'] ?? '').toString().toLowerCase();
      final type = (dept['departmentType'] ?? dept['type'] ?? '').toString().toLowerCase();
      return name.contains(searchQuery.toLowerCase()) ||
          code.contains(searchQuery.toLowerCase()) ||
          type.contains(searchQuery.toLowerCase());
    }).toList();
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
      await getIt<AdminRepository>().addDepartment(
        name,
        code,
        _departmentType == 'SUB' ? false : _supportsSections,
        departmentType: _departmentType,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Department added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      nameController.clear();
      codeController.clear();
      _supportsSections = false;
      _departmentType = 'MAIN';
      Navigator.pop(context);
      context.read<import_provider.DepartmentProvider>().fetchDepartments();
    } catch (e) {
      if (!context.mounted) return;
      ErrorHandler.showSnackBar(context, e);
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
      await getIt<AdminRepository>().editDepartment(
        id,
        name,
        code,
        _departmentType == 'SUB' ? false : _supportsSections,
        departmentType: _departmentType,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Department updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      nameController.clear();
      codeController.clear();
      _supportsSections = false;
      _departmentType = 'MAIN';
      Navigator.pop(context);
      context.read<import_provider.DepartmentProvider>().fetchDepartments();
    } catch (e) {
      if (!context.mounted) return;
      ErrorHandler.showSnackBar(context, e);
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
      context.read<import_provider.DepartmentProvider>().fetchDepartments();
    } catch (e) {
      if (!context.mounted) return;
      ErrorHandler.showSnackBar(context, e);
    }
  }

  void _showAddDeptDialog() {
    nameController.clear();
    codeController.clear();
    _supportsSections = true;
    _departmentType = 'MAIN';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (pageContext) => Scaffold(
          appBar: AppBar(
            title: const Text(
              'Add New Department',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            backgroundColor: const Color(0xFF1E293B),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                const SizedBox(height: 16),
                StatefulBuilder(
                  builder: (context, setDialogState) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<String>(
                          value: _departmentType,
                          decoration: const InputDecoration(
                            labelText: 'Department Type *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.category),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'MAIN',
                              child: Text('MAIN (Engineering / Academic)'),
                            ),
                            DropdownMenuItem(
                              value: 'SUB',
                              child: Text('SUB (Language / Basic Science)'),
                            ),
                          ],
                          onChanged: (val) {
                            final newType = val ?? 'MAIN';
                            setDialogState(() {
                              _departmentType = newType;
                              if (newType == 'SUB') {
                                _supportsSections = false;
                              } else {
                                _supportsSections = true;
                              }
                            });
                            setState(() {
                              _departmentType = newType;
                              if (newType == 'SUB') {
                                _supportsSections = false;
                              } else {
                                _supportsSections = true;
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        if (_departmentType == 'MAIN')
                          SwitchListTile(
                            title: const Text('Supports Sections?'),
                            subtitle: const Text(
                              'Enable if this department will have sections (A, B, C, etc.)',
                              style: TextStyle(fontSize: 12),
                            ),
                            value: _supportsSections,
                            onChanged: (val) {
                              setDialogState(() => _supportsSections = val);
                              setState(() => _supportsSections = val);
                            },
                            contentPadding: EdgeInsets.zero,
                            activeColor: const Color(0xFF1E293B),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.purple.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.info_outline, color: Colors.purple, size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'SUB departments do not support sections.',
                                    style: TextStyle(fontSize: 12, color: Colors.purple, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  }
                ),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(pageContext),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _addDepartment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Add',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditDeptDialog(Map<String, dynamic> dept) {
    nameController.text = dept['name'] ?? '';
    codeController.text = dept['code'] ?? '';
    _departmentType = (dept['departmentType'] ?? dept['type'] ?? 'MAIN').toString();
    _supportsSections = dept['supportsSections'] == true && _departmentType == 'MAIN';
    final sectionNameController = TextEditingController();
    List<dynamic> deptSections = [];
    bool loadingSections = true;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (pageContext) {
          return StatefulBuilder(
            builder: (context, setPageState) {
              Future<void> fetchDeptSections() async {
                if (_departmentType == 'SUB') {
                  setPageState(() => loadingSections = false);
                  return;
                }
                setPageState(() => loadingSections = true);
                try {
                  final sections = await getIt<AdminRepository>()
                      .getDepartmentSections(dept['id']);
                  setPageState(() {
                    deptSections = sections;
                    loadingSections = false;
                  });
                } catch (e) {
                  debugPrint('Error fetching dept sections: $e');
                  setPageState(() => loadingSections = false);
                }
              }

              Future<void> addSection() async {
                final secName =
                    sectionNameController.text.trim().toUpperCase();
                if (secName.isEmpty) return;
                try {
                  await getIt<AdminRepository>().addDepartmentSection(
                    dept['id'],
                    secName,
                  );
                  sectionNameController.clear();
                  fetchDeptSections();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text(
                        e.toString().replaceAll('Exception: ', ''),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }

              Future<void> deleteSection(int sectionId) async {
                try {
                  await getIt<AdminRepository>()
                      .deleteDepartmentSection(sectionId);
                  fetchDeptSections();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text(
                        e.toString().replaceAll('Exception: ', ''),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }

              if (loadingSections && deptSections.isEmpty && _departmentType == 'MAIN') {
                Future.microtask(fetchDeptSections);
              }

              return Scaffold(
                appBar: AppBar(
                  title: Text(
                    'Edit Department: ${dept["code"]}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: const Color(0xFF1E293B),
                  iconTheme: const IconThemeData(color: Colors.white),
                ),
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
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
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _departmentType,
                        decoration: const InputDecoration(
                          labelText: 'Department Type *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'MAIN',
                            child: Text('MAIN (Engineering / Academic)'),
                          ),
                          DropdownMenuItem(
                            value: 'SUB',
                            child: Text('SUB (Language / Basic Science)'),
                          ),
                        ],
                        onChanged: (val) {
                          final newType = val ?? 'MAIN';
                          setPageState(() {
                            _departmentType = newType;
                            if (newType == 'SUB') {
                              _supportsSections = false;
                            }
                          });
                          setState(() {
                            _departmentType = newType;
                            if (newType == 'SUB') {
                              _supportsSections = false;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      if (_departmentType == 'MAIN') ...[
                        StatefulBuilder(
                          builder: (context, setDialogState) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SwitchListTile(
                                  title: const Text('Supports Sections?'),
                                  subtitle: const Text(
                                    'Enable if this department will have sections (A, B, C, etc.)',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  value: _supportsSections,
                                  onChanged: (val) {
                                    setDialogState(() => _supportsSections = val);
                                    setState(() => _supportsSections = val);
                                  },
                                  contentPadding: EdgeInsets.zero,
                                  activeColor: const Color(0xFF1E293B),
                                ),
                                if (_supportsSections) ...[
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
                                        onPressed: addSection,
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
                                      ? const Center(child: PragatiXLoader())
                                      : deptSections.isEmpty
                                      ? const Padding(
                                          padding: EdgeInsets.symmetric(vertical: 8.0),
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
                                          physics: const NeverScrollableScrollPhysics(),
                                          itemCount: deptSections.length,
                                          itemBuilder: (context, idx) {
                                            final sec = deptSections[idx];
                                            return ListTile(
                                              title: Text(
                                                'Section ${sec["sectionName"] ?? sec["name"] ?? ""}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              trailing: IconButton(
                                                icon: const Icon(
                                                  Icons.delete_outline,
                                                  color: Colors.red,
                                                ),
                                                onPressed: () => deleteSection(sec['id']),
                                              ),
                                            );
                                          },
                                        ),
                                ],
                              ],
                            );
                          }
                        ),
                      ] else ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.info_outline, color: Colors.purple, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'SUB departments do not support sections.',
                                  style: TextStyle(fontSize: 12, color: Colors.purple, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                bottomNavigationBar: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () => _editDepartment(dept['id']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E293B),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: const Text(
                            'Save',
                            style: TextStyle(color: Colors.white),
                          ),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final departmentProvider = context.watch<import_provider.DepartmentProvider>();
    final departments = departmentProvider.departments;
    final filteredDepartments = _getFilteredDepartments(departments);
    final isLoading = departmentProvider.isLoading;

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
      body: isLoading && departments.isEmpty
          ? const Center(child: PragatiXLoader())
          : Column(
              children: [
                if (departmentProvider.error != null)
                  Container(
                    width: double.infinity,
                    color: Colors.red.shade100,
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      departmentProvider.error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (departments.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: searchController,
                      onChanged: (val) => setState(() => searchQuery = val),
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
                                  setState(() => searchQuery = '');
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
                    onRefresh: () => context.read<import_provider.DepartmentProvider>().fetchDepartments(),
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
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    dept['name'] ?? '',
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF1E293B),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: ((dept['departmentType'] ?? dept['type']) == 'SUB')
                                                        ? Colors.purple.withValues(alpha: 0.12)
                                                        : Colors.blue.withValues(alpha: 0.12),
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(
                                                      color: ((dept['departmentType'] ?? dept['type']) == 'SUB')
                                                          ? Colors.purple.shade300
                                                          : Colors.blue.shade300,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    ((dept['departmentType'] ?? dept['type']) == 'SUB') ? 'SUB' : 'MAIN',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: ((dept['departmentType'] ?? dept['type']) == 'SUB')
                                                          ? Colors.purple.shade800
                                                          : Colors.blue.shade800,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Text(
                                                  'Code: ${dept["code"] ?? ""}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                if (dept['supportsSections'] == true) ...[
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    '• Sections Enabled',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.green.shade700,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ],
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
                                                builder: (context) =>
                                                    AlertDialog(
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
                                                        'Are you sure you want to delete department ${dept["code"]}?',
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
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                          ),
                                                        ),
                                                        TextButton(
                                                          onPressed: () {
                                                            Navigator.pop(
                                                              context,
                                                            );
                                                            _deleteDepartment(
                                                              dept['id'],
                                                            );
                                                          },
                                                          child: const Text(
                                                            'Delete',
                                                            style: TextStyle(
                                                              color: Colors.red,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
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
