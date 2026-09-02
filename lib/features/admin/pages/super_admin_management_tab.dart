import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pragatix/core/widgets/pragatix_loader.dart';
import 'package:pragatix/features/admin/repository/admin_repository.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/core/utils/string_utils.dart';
import 'package:pragatix/core/utils/error_handler.dart';

class SuperAdminManagementTab extends StatefulWidget {
  const SuperAdminManagementTab({super.key});

  @override
  State<SuperAdminManagementTab> createState() =>
      _SuperAdminManagementTabState();
}

class _SuperAdminManagementTabState extends State<SuperAdminManagementTab> {
  final AdminRepository _repository = getIt<AdminRepository>();
  List<dynamic> _yearAdmins = [];
  List<dynamic> _yearsList = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final years = await _repository.getYears();
      final admins = await _repository.getYearAdmins();
      if (!mounted) return;
      setState(() {
        _yearsList = years;
        _yearAdmins = admins;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchYearAdmins() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final admins = await _repository.getYearAdmins();
      if (!mounted) return;
      setState(() {
        _yearAdmins = admins;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteYearAdmin(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to remove this Year Admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _repository.deleteYearAdmin(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Year Admin deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _fetchYearAdmins();
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showSnackBar(context, e);
    }
  }

  void _showAdminDialog({Map<String, dynamic>? admin}) {
    final isEditing = admin != null;
    final fullNameCtrl = TextEditingController(text: admin?['fullName'] ?? '');
    final emailCtrl = TextEditingController(text: admin?['email'] ?? '');
    final phoneCtrl = TextEditingController(text: admin?['phone'] ?? '');
    int? selectedYearId = admin?['assignedYearId'];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (pageContext) {
          return StatefulBuilder(
            builder: (context, setPageState) {
              return Scaffold(
                appBar: AppBar(
                  title: Text(
                    isEditing ? 'Assign Academic Year' : 'New Year Admin',
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: fullNameCtrl,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [
                          UpperCaseTextFormatter(),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Full Name *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        maxLength: 10,
                        decoration: const InputDecoration(
                          labelText: 'Phone',
                          hintText: 'Enter 10-digit phone number',
                          counterText: '',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        initialValue: selectedYearId,
                        decoration: const InputDecoration(
                          labelText: 'Assigned Year',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<int>(
                            value: null,
                            child: Text('Not Assigned'),
                          ),
                          ..._yearsList.map((year) {
                            return DropdownMenuItem<int>(
                              value: year['id'],
                              child: Text(year['yearName'] ?? 'Unknown Year'),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          setPageState(() {
                            selectedYearId = val;
                          });
                        },
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
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E293B),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          onPressed: () async {
                            if (fullNameCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Full Name is required'),
                                ),
                              );
                              return;
                            }

                            final rawPhone = phoneCtrl.text.trim();
                            if (rawPhone.isNotEmpty && (rawPhone.length != 10 || !RegExp(r'^\d{10}$').hasMatch(rawPhone))) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Phone number must contain exactly 10 digits'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                              return;
                            }

                            final data = <String, dynamic>{
                              'fullName': fullNameCtrl.text.trim().toUpperCase(),
                              'email': emailCtrl.text.trim().isNotEmpty ? emailCtrl.text.trim() : null,
                              'phone': rawPhone.isNotEmpty ? rawPhone : null,
                              'active': admin?['active'] ?? true,
                              'password': StringUtils.generateSecurePassword(),
                            };

                            data['assignedYearId'] = selectedYearId;

                            if (selectedYearId != null) {
                              final existingAdmins = _yearAdmins.where(
                                (a) =>
                                    a['assignedYearId'] == selectedYearId &&
                                    a['id'] != admin?['id'] &&
                                    a['active'] == true,
                              ).toList();

                              final existingAdmin =
                                  existingAdmins.isNotEmpty
                                      ? existingAdmins.first
                                      : null;

                              if (existingAdmin != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('This year is already assigned.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                            }

                            Navigator.pop(context);

                            try {
                              if (isEditing) {
                                await _repository.updateYearAdmin(
                                  admin['id'],
                                  data,
                                );
                              } else {
                                await _repository.addYearAdmin(data);
                              }
                              if (!mounted) return;
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isEditing
                                        ? 'Year Admin updated successfully'
                                        : 'Year Admin created successfully',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              _fetchYearAdmins();
                            } catch (e) {
                              if (!mounted) return;
                              ErrorHandler.showSnackBar(this.context, e);
                            }
                          },
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

  Widget _buildHeaderActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: const Color(0xFF334155), size: 20),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAdminDialog(),
        backgroundColor: const Color(0xFF2563EB),
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'New Admin',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: Stack(
        children: [
          // Background mesh subtle gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 240,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFDCE8F6),
                    Color(0xFFE8EFF9),
                    Color(0xFFF4F7FB),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Top Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 16, 12),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Super Admin Management',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.4,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Manage year admins',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildHeaderActionButton(
                        icon: Icons.refresh_rounded,
                        tooltip: 'Refresh',
                        onPressed: _fetchYearAdmins,
                      ),
                    ],
                  ),
                ),

                // Body content
                Expanded(
                  child: _isLoading
                      ? const Center(child: PragatiXLoader())
                      : _error != null
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEE2E2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Icon(
                                        Icons.error_outline_rounded,
                                        color: Color(0xFFEF4444),
                                        size: 40,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _error!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Color(0xFF0F172A),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _fetchYearAdmins,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF2563EB),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : _yearAdmins.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(18),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFDBEAFE),
                                            borderRadius: BorderRadius.circular(24),
                                          ),
                                          child: const Icon(
                                            Icons.admin_panel_settings_rounded,
                                            size: 48,
                                            color: Color(0xFF2563EB),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'No Year Admins Found',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        const Text(
                                          'Tap "+ New Admin" to assign administrators.',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: _fetchYearAdmins,
                                  color: const Color(0xFF2563EB),
                                  child: ListView.builder(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.fromLTRB(18, 6, 18, 80),
                                    itemCount: _yearAdmins.length,
                                    itemBuilder: (context, index) {
                                      final admin = _yearAdmins[index];
                                      String cleanYear = admin['assignedYearName'] ?? 'Not Assigned';
                                      final bool isAssigned = admin['assignedYearId'] != null;

                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(18),
                                          border: Border.all(
                                            color: const Color(0xFFE2E8F0),
                                            width: 1,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF64748B).withValues(alpha: 0.06),
                                              blurRadius: 14,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 48,
                                                height: 48,
                                                decoration: BoxDecoration(
                                                  gradient: const LinearGradient(
                                                    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                                                  ),
                                                  borderRadius: BorderRadius.circular(15),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: const Color(0xFF3B82F6).withValues(alpha: 0.28),
                                                      blurRadius: 10,
                                                      offset: const Offset(0, 4),
                                                    ),
                                                  ],
                                                ),
                                                child: const Icon(
                                                  Icons.admin_panel_settings_rounded,
                                                  color: Colors.white,
                                                  size: 24,
                                                ),
                                              ),
                                              const SizedBox(width: 14),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      (admin['fullName'] != null &&
                                                              admin['fullName'].toString().trim().isNotEmpty)
                                                          ? admin['fullName']
                                                          : (admin['username'] ?? ''),
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.w700,
                                                        fontSize: 16,
                                                        color: Color(0xFF0F172A),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Row(
                                                      children: [
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 3,
                                                          ),
                                                          decoration: BoxDecoration(
                                                            color: isAssigned
                                                                ? const Color(0xFFEFF6FF)
                                                                : const Color(0xFFFEF2F2),
                                                            borderRadius: BorderRadius.circular(7),
                                                            border: Border.all(
                                                              color: isAssigned
                                                                  ? const Color(0xFFBFDBFE)
                                                                  : const Color(0xFFFECACA),
                                                            ),
                                                          ),
                                                          child: Text(
                                                            cleanYear,
                                                            style: TextStyle(
                                                              fontSize: 11.5,
                                                              fontWeight: FontWeight.w600,
                                                              color: isAssigned
                                                                  ? const Color(0xFF1D4ED8)
                                                                  : const Color(0xFFDC2626),
                                                            ),
                                                          ),
                                                        ),
                                                        if (admin['email'] != null &&
                                                            admin['email'].toString().isNotEmpty) ...[
                                                          const SizedBox(width: 8),
                                                          Expanded(
                                                            child: Text(
                                                              admin['email'],
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                              style: const TextStyle(
                                                                fontSize: 12,
                                                                color: Color(0xFF64748B),
                                                              ),
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
                                                  if (!isAssigned)
                                                    TextButton(
                                                      onPressed: () => _showAdminDialog(admin: admin),
                                                      style: TextButton.styleFrom(
                                                        foregroundColor: const Color(0xFF2563EB),
                                                        textStyle: const TextStyle(
                                                          fontWeight: FontWeight.w700,
                                                          fontSize: 12.5,
                                                        ),
                                                      ),
                                                      child: const Text('Assign'),
                                                    )
                                                  else
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.edit_outlined,
                                                        color: Color(0xFF2563EB),
                                                        size: 20,
                                                      ),
                                                      onPressed: () => _showAdminDialog(admin: admin),
                                                    ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.delete_outline_rounded,
                                                      color: Color(0xFFEF4444),
                                                      size: 20,
                                                    ),
                                                    onPressed: () => _deleteYearAdmin(admin['id']),
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
          ),
        ],
      ),
    );
  }
}
