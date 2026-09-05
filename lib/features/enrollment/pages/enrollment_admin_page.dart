import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/features/enrollment/models/enrollment_model.dart';
import 'package:pragatix/features/enrollment/repository/enrollment_repository.dart';
import 'package:pragatix/core/utils/string_utils.dart';
import 'package:pragatix/core/utils/export_utils.dart';

class EnrollmentAdminPage extends StatefulWidget {
  const EnrollmentAdminPage({super.key});

  @override
  State<EnrollmentAdminPage> createState() => _EnrollmentAdminPageState();
}

class _EnrollmentAdminPageState extends State<EnrollmentAdminPage> with SingleTickerProviderStateMixin {
  final EnrollmentRepository _enrollmentRepository = getIt<EnrollmentRepository>();

  late TabController _tabController;
  bool _isEnrollmentEnabled = false;
  bool _isTogglingStatus = false;
  bool _isLoadingLookups = true;

  // Filters
  List<dynamic> _departments = [];
  int? _selectedDeptId;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Pending Tab State
  List<EnrollmentItem> _pendingItems = [];
  bool _isLoadingPending = true;
  int _pendingTotal = 0;
  int _pendingPage = 0;

  // Enrolled Tab State
  List<EnrollmentItem> _enrolledItems = [];
  bool _isLoadingEnrolled = true;
  int _enrolledTotal = 0;
  int _enrolledPage = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoadingLookups = true);
    try {
      final status = await _enrollmentRepository.getAdminStatus();
      _isEnrollmentEnabled = status;
    } catch (e) {
      debugPrint('Status error: $e');
    }

    try {
      final depts = await _enrollmentRepository.getEnrollmentDepartments();
      _departments = depts;
    } catch (e) {
      debugPrint('Enrollment depts error: $e');
      try {
        final pubDepts = await _enrollmentRepository.getPendingDepartments();
        _departments = pubDepts;
      } catch (pubErr) {
        debugPrint('Public depts error: $pubErr');
      }
    }

    if (mounted) {
      setState(() => _isLoadingLookups = false);
      _fetchPending();
      _fetchEnrolled();
    }
  }

  Future<void> _toggleEnrollmentStatus(bool newVal) async {
    setState(() => _isTogglingStatus = true);
    try {
      await _enrollmentRepository.updateStatus(newVal);
      if (!mounted) return;
      setState(() {
        _isEnrollmentEnabled = newVal;
        _isTogglingStatus = false;
      });
      _showSnackBar(
        newVal ? 'Enrollment is now ON. Students can self-enroll.' : 'Enrollment is now OFF.',
        isError: false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isTogglingStatus = false);
      _showSnackBar('Failed to update status: $e', isError: true);
    }
  }

  Future<void> _fetchPending() async {
    setState(() => _isLoadingPending = true);
    try {
      final res = await _enrollmentRepository.getPendingList(
        page: _pendingPage,
        size: 50,
        search: _searchQuery,
        departmentId: _selectedDeptId,
      );
      if (!mounted) return;
      setState(() {
        _pendingItems = res['items'] as List<EnrollmentItem>;
        _pendingTotal = res['totalElements'] as int;
        _isLoadingPending = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingPending = false);
      _showSnackBar('Failed to load pending enrollments: $e', isError: true);
    }
  }

  Future<void> _fetchEnrolled() async {
    setState(() => _isLoadingEnrolled = true);
    try {
      final res = await _enrollmentRepository.getEnrolledList(
        page: _enrolledPage,
        size: 50,
        search: _searchQuery,
        departmentId: _selectedDeptId,
      );
      if (!mounted) return;
      setState(() {
        _enrolledItems = res['items'] as List<EnrollmentItem>;
        _enrolledTotal = res['totalElements'] as int;
        _isLoadingEnrolled = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingEnrolled = false);
      _showSnackBar('Failed to load enrolled list: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  // ==========================================
  // BULK IMPORT & TEMPLATE DOWNLOAD
  // ==========================================

  Future<void> _downloadTemplate() async {
    try {
      final bytes = await _enrollmentRepository.downloadTemplate();

      if (kIsWeb) {
        _showSnackBar('Template downloaded successfully.');
        return;
      }

      await ExportUtils.saveBytesAndOpen(
        context,
        bytes,
        'Student_Enrollment_Template.xlsx',
        successMessage: 'Template downloaded successfully!',
      );
    } catch (e) {
      _showSnackBar('Error downloading template: $e', isError: true);
    }
  }

  void _showBulkImportDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BulkImportModal(
        onDownloadTemplate: _downloadTemplate,
        onImportSuccess: () {
          _fetchPending();
          _fetchEnrolled();
        },
      ),
    );
  }

  void _showAddSingleStudentDialog() {
    final depts = _departments.whereType<PendingDepartment>().toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SingleStudentModal(
        departments: depts,
        onSuccess: () {
          _fetchPending();
          _fetchEnrolled();
        },
      ),
    );
  }

  void _showEditStudentDialog(EnrollmentItem item) {
    final depts = _departments.whereType<PendingDepartment>().toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditStudentModal(
        item: item,
        departments: depts,
        onSuccess: () {
          _fetchPending();
          _fetchEnrolled();
        },
      ),
    );
  }

  void _showEnrolledStudentDetailsDialog(EnrollmentItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EnrolledStudentDetailsModal(
        item: item,
        onDelete: () => _deleteStudentDirect(item),
      ),
    );
  }

  Future<void> _deleteStudentDirect(EnrollmentItem item) async {
    final isEnrolled = item.status.toUpperCase() == 'ENROLLED';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.delete_outline_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Move to Recycle Bin?'),
          ],
        ),
        content: Text(
          isEnrolled
              ? 'Are you sure you want to delete enrolled student "${item.fullName}" (Reg: ${item.enrolledStudentRegNo ?? 'N/A'})?\n\nThis will move the student to the Recycle Bin. You can restore or permanently delete them from the Recycle Bin.'
              : 'Are you sure you want to remove "${item.fullName}" from the pending enrollment list?\n\nThis will move the record to the Recycle Bin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Move to Recycle Bin'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _enrollmentRepository.deleteEnrollment(item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${item.fullName}" moved to Recycle Bin.'),
          backgroundColor: Colors.green,
        ),
      );
      _fetchPending();
      _fetchEnrolled();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const primaryColor = Color(0xFF2563EB);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text(
          'Student Enrollment',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Refresh',
            onPressed: () {
              _fetchPending();
              _fetchEnrolled();
            },
          ),
          IconButton(
            icon: const Icon(Icons.file_upload_outlined, color: Colors.white),
            tooltip: 'Bulk Import',
            onPressed: _showBulkImportDialog,
          ),
        ],
      ),
      body: _isLoadingLookups
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
          // ── Status Banner ──────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isEnrollmentEnabled
                    ? const Color(0xFF86EFAC)
                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isEnrollmentEnabled
                        ? const Color(0xFFDCFCE7)
                        : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isEnrollmentEnabled ? Icons.how_to_reg_rounded : Icons.lock_outline_rounded,
                    color: _isEnrollmentEnabled ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Enrollment Status: ',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _isEnrollmentEnabled
                                  ? const Color(0xFFDCFCE7)
                                  : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _isEnrollmentEnabled ? 'ON' : 'OFF',
                              style: TextStyle(
                                color: _isEnrollmentEnabled
                                    ? const Color(0xFF16A34A)
                                    : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isEnrollmentEnabled
                            ? 'Students can self-enroll on Login page.'
                            : 'Self-enrollment is currently closed.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                _isTogglingStatus
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : Switch.adaptive(
                        value: _isEnrollmentEnabled,
                        activeColor: const Color(0xFF16A34A),
                        onChanged: _toggleEnrollmentStatus,
                      ),
              ],
            ),
          ),

          // ── Search & Filter Controls ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search student...',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF64748B)),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _pendingPage = 0;
                                  _enrolledPage = 0;
                                });
                                _fetchPending();
                                _fetchEnrolled();
                              },
                            )
                          : null,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                      ),
                    ),
                    onSubmitted: (val) {
                      setState(() {
                        _searchQuery = val.trim();
                        _pendingPage = 0;
                        _enrolledPage = 0;
                      });
                      _fetchPending();
                      _fetchEnrolled();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedDeptId,
                        hint: const Text('All Depts', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF64748B)),
                        items: [
                          const DropdownMenuItem<int>(
                            value: null,
                            child: Text('All Depts', style: TextStyle(fontSize: 13)),
                          ),
                          ..._departments.map((d) {
                            final int id = d is PendingDepartment ? d.id : (d['id'] as int);
                            final String code = d is PendingDepartment
                                ? (d.deptCode.isNotEmpty ? d.deptCode : d.name)
                                : (d['deptCode'] ?? d['code'] ?? d['name'] ?? '');
                            return DropdownMenuItem<int>(
                              value: id,
                              child: Text(code, style: const TextStyle(fontSize: 13)),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedDeptId = val;
                            _pendingPage = 0;
                            _enrolledPage = 0;
                          });
                          _fetchPending();
                          _fetchEnrolled();
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Tabs ───────────────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.all(3),
              labelColor: Colors.white,
              unselectedLabelColor: isDark ? Colors.white60 : const Color(0xFF64748B),
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: [
                Tab(text: 'Pending ($_pendingTotal)'),
                Tab(text: 'Enrolled ($_enrolledTotal)'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Tab Views ──────────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPendingTab(isDark, primaryColor),
                _buildEnrolledTab(isDark, primaryColor),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'add_single_student_btn',
            onPressed: _showAddSingleStudentDialog,
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            icon: const Icon(Icons.person_add_rounded, color: Color(0xFF2563EB)),
            label: const Text(
              'Add Student',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          FloatingActionButton.extended(
            heroTag: 'bulk_import_students_btn',
            onPressed: _showBulkImportDialog,
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            icon: const Icon(Icons.file_upload_rounded, color: Colors.white),
            label: const Text(
              'Bulk Import',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: PENDING LIST
  // ==========================================

  Widget _buildPendingTab(bool isDark, Color primaryColor) {
    if (_isLoadingPending) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pendingItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 54, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'No Pending Enrollments',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              'Use "Bulk Import" to upload student enrollment records.',
              style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchPending,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: _pendingItems.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = _pendingItems[index];
          return Card(
            elevation: 0,
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showEditStudentDialog(item),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF475569) : const Color(0xFFDBEAFE),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        item.fullName.isNotEmpty ? item.fullName.substring(0, 1).toUpperCase() : 'S',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.fullName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFFDE68A)),
                                ),
                                child: const Text(
                                  'PENDING',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFD97706),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.edit_outlined,
                                size: 18,
                                color: isDark ? Colors.white70 : const Color(0xFF2563EB),
                              ),
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () => _deleteStudentDirect(item),
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Icon(
                                    Icons.delete_outline_rounded,
                                    size: 18,
                                    color: Colors.red.shade400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.school_outlined, size: 14, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                              const SizedBox(width: 4),
                              Text(
                                item.deptCode.isNotEmpty ? item.deptCode : item.departmentName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(Icons.phone_locked_outlined, size: 14, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                              const SizedBox(width: 4),
                              Text(
                                item.maskedMobile,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                ),
                              ),
                              const Spacer(),
                              if (item.gender.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item.gender,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // TAB 2: ENROLLED LIST
  // ==========================================

  Widget _buildEnrolledTab(bool isDark, Color primaryColor) {
    if (_isLoadingEnrolled) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_enrolledItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.how_to_reg_outlined, size: 54, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'No Enrolled Students',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              'Students who complete enrollment will appear here.',
              style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchEnrolled,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: _enrolledItems.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = _enrolledItems[index];
          return Card(
            elevation: 0,
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showEnrolledStudentDetailsDialog(item),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF475569) : const Color(0xFFDCFCE7),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.check_rounded,
                        size: 22,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.fullName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFBBF7D0)),
                                ),
                                child: const Text(
                                  'ENROLLED',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF16A34A),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.info_outline_rounded,
                                size: 18,
                                color: isDark ? Colors.white70 : const Color(0xFF2563EB),
                              ),
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () => _deleteStudentDirect(item),
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Icon(
                                    Icons.delete_outline_rounded,
                                    size: 18,
                                    color: Colors.red.shade400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.school_outlined, size: 14, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                              const SizedBox(width: 4),
                              Text(
                                item.deptCode.isNotEmpty ? item.deptCode : item.departmentName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                ),
                              ),
                              if (item.enrolledStudentRegNo != null) ...[
                                const SizedBox(width: 12),
                                Icon(Icons.badge_outlined, size: 14, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                                const SizedBox(width: 4),
                                Text(
                                  'Reg: ${item.enrolledStudentRegNo}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (item.enrolledAt != null) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.access_time_rounded, size: 14, color: isDark ? Colors.white54 : const Color(0xFF94A3B8)),
                                const SizedBox(width: 4),
                                Text(
                                  'Enrolled: ${item.enrolledAt!.substring(0, 10)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ==========================================
// SINGLE STUDENT ENROLLMENT MODAL SHEET
// ==========================================

class _SingleStudentModal extends StatefulWidget {
  final List<PendingDepartment> departments;
  final VoidCallback onSuccess;

  const _SingleStudentModal({
    required this.departments,
    required this.onSuccess,
  });

  @override
  State<_SingleStudentModal> createState() => _SingleStudentModalState();
}

class _SingleStudentModalState extends State<_SingleStudentModal> {
  final EnrollmentRepository _repository = getIt<EnrollmentRepository>();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  String _selectedGender = 'Male';
  int? _selectedDepartmentId;
  bool _isLoading = false;
  bool _isLoadingDepts = false;
  String? _errorMessage;
  List<PendingDepartment> _depts = [];

  @override
  void initState() {
    super.initState();
    _depts = List.from(widget.departments);
    if (_depts.isNotEmpty) {
      _selectedDepartmentId = _depts.first.id;
    } else {
      _fetchDepartments();
    }
  }

  Future<void> _fetchDepartments() async {
    setState(() => _isLoadingDepts = true);
    try {
      final list = await _repository.getEnrollmentDepartments();
      if (!mounted) return;
      setState(() {
        _depts = list;
        if (_selectedDepartmentId == null && _depts.isNotEmpty) {
          _selectedDepartmentId = _depts.first.id;
        }
        _isLoadingDepts = false;
      });
    } catch (_) {
      try {
        final pubList = await _repository.getPendingDepartments();
        if (!mounted) return;
        setState(() {
          _depts = pubList;
          if (_selectedDepartmentId == null && _depts.isNotEmpty) {
            _selectedDepartmentId = _depts.first.id;
          }
          _isLoadingDepts = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoadingDepts = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDepartmentId == null) {
      setState(() => _errorMessage = 'Please select a department.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _repository.addSingleEnrollment(
        fullName: _nameController.text.trim().toUpperCase(),
        gender: _selectedGender,
        email: _emailController.text.trim(),
        mobile: _mobileController.text.trim(),
        departmentId: _selectedDepartmentId!,
      );
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Student "${_nameController.text.trim()}" added to pending enrollment list.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const primaryColor = Color(0xFF2563EB);

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.person_add_rounded, color: primaryColor, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Add Student to Enrollment',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: _isLoading ? null : () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 4),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter student details to add them to the pending self-enrollment list.',
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),

                    // Full Name
                    TextFormField(
                      controller: _nameController,
                      enabled: !_isLoading,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        UpperCaseTextFormatter(),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Full Name *',
                        hintText: 'e.g. ARUN KUMAR',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Full name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Gender Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Gender *',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        prefixIcon: const Icon(Icons.wc_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(value: 'Female', child: Text('Female')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: _isLoading ? null : (v) => setState(() => _selectedGender = v ?? 'Male'),
                    ),
                    const SizedBox(height: 14),

                    // Mobile Number
                    TextFormField(
                      controller: _mobileController,
                      enabled: !_isLoading,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Mobile Number *',
                        hintText: '10 digits',
                        counterText: '',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        prefixIcon: const Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Mobile is required';
                        }
                        if (val.trim().length != 10) {
                          return '10-digit number required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Email Address
                    TextFormField(
                      controller: _emailController,
                      enabled: !_isLoading,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email Address *',
                        hintText: 'e.g. arun@gmail.com',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Email is required';
                        }
                        if (!val.contains('@') || !val.contains('.')) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Department Dropdown
                    _isLoadingDepts
                        ? const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
                        : DropdownButtonFormField<int>(
                            value: _depts.any((d) => d.id == _selectedDepartmentId)
                                ? _selectedDepartmentId
                                : (_depts.isNotEmpty ? _depts.first.id : null),
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Department (9 Approved) *',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              prefixIcon: const Icon(Icons.school_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
                            ),
                            items: _depts.map((d) {
                              final code = d.deptCode.isNotEmpty ? d.deptCode : d.name;
                              return DropdownMenuItem<int>(
                                value: d.id,
                                child: Text(
                                  '$code - ${d.name}',
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: _isLoading ? null : (v) => setState(() => _selectedDepartmentId = v),
                            validator: (val) => val == null ? 'Department is required' : null,
                          ),
                    const SizedBox(height: 20),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                        ),
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.person_add_rounded),
                        label: Text(
                          _isLoading ? 'Adding Student...' : 'Add Student to Enrollment',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                    // Error Message
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red.shade900, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// EDIT STUDENT ENROLLMENT MODAL SHEET
// ==========================================

class _EditStudentModal extends StatefulWidget {
  final EnrollmentItem item;
  final List<PendingDepartment> departments;
  final VoidCallback onSuccess;

  const _EditStudentModal({
    required this.item,
    required this.departments,
    required this.onSuccess,
  });

  @override
  State<_EditStudentModal> createState() => _EditStudentModalState();
}

class _EditStudentModalState extends State<_EditStudentModal> {
  final EnrollmentRepository _repository = getIt<EnrollmentRepository>();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _mobileController;
  late String _selectedGender;
  int? _selectedDepartmentId;
  bool _isLoading = false;
  bool _isDeleting = false;
  bool _isLoadingDepts = false;
  String? _errorMessage;
  List<PendingDepartment> _depts = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.fullName);
    _emailController = TextEditingController(text: widget.item.email);
    _mobileController = TextEditingController(text: widget.item.mobile);

    const validGenders = ['Male', 'Female', 'Other'];
    _selectedGender = validGenders.contains(widget.item.gender) ? widget.item.gender : 'Male';

    _depts = List.from(widget.departments);
    _selectedDepartmentId = widget.item.departmentId;
    if (_selectedDepartmentId == null && _depts.isNotEmpty) {
      _selectedDepartmentId = _depts.first.id;
    }
    if (_depts.isEmpty) {
      _fetchDepartments();
    }
  }

  Future<void> _fetchDepartments() async {
    setState(() => _isLoadingDepts = true);
    try {
      final list = await _repository.getEnrollmentDepartments();
      if (!mounted) return;
      setState(() {
        _depts = list;
        if (_selectedDepartmentId == null && _depts.isNotEmpty) {
          _selectedDepartmentId = _depts.first.id;
        }
        _isLoadingDepts = false;
      });
    } catch (_) {
      try {
        final pubList = await _repository.getPendingDepartments();
        if (!mounted) return;
        setState(() {
          _depts = pubList;
          if (_selectedDepartmentId == null && _depts.isNotEmpty) {
            _selectedDepartmentId = _depts.first.id;
          }
          _isLoadingDepts = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoadingDepts = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDepartmentId == null) {
      setState(() => _errorMessage = 'Please select a department.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _repository.updateEnrollment(
        widget.item.id,
        fullName: _nameController.text.trim().toUpperCase(),
        gender: _selectedGender,
        email: _emailController.text.trim(),
        mobile: _mobileController.text.trim(),
        departmentId: _selectedDepartmentId!,
      );
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Student "${_nameController.text.trim()}" updated successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Student?'),
        content: Text('Are you sure you want to remove "${widget.item.fullName}" from the pending enrollment list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isDeleting = true;
      _errorMessage = null;
    });

    try {
      await _repository.deleteEnrollment(widget.item.id);
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Student "${widget.item.fullName}" removed from pending enrollment list.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const primaryColor = Color(0xFF2563EB);

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.edit_note_rounded, color: primaryColor, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Edit Student Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: (_isLoading || _isDeleting) ? null : () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 4),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Modify student details in the pending self-enrollment list.',
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),

                    // Full Name
                    TextFormField(
                      controller: _nameController,
                      enabled: !_isLoading && !_isDeleting,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                        UpperCaseTextFormatter(),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Full Name *',
                        hintText: 'e.g. ARUN KUMAR',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Full name is required';
                        }
                        if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(val.trim())) {
                          return 'Full name must contain letters and spaces only';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Gender Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _selectedGender,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Gender *',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        prefixIcon: const Icon(Icons.wc_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(value: 'Female', child: Text('Female')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (_isLoading || _isDeleting)
                          ? null
                          : (v) => setState(() => _selectedGender = v ?? 'Male'),
                    ),
                    const SizedBox(height: 14),

                    // Mobile Number
                    TextFormField(
                      controller: _mobileController,
                      enabled: !_isLoading && !_isDeleting,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Mobile Number *',
                        hintText: '10 digits',
                        counterText: '',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        prefixIcon: const Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Mobile is required';
                        }
                        if (val.trim().length != 10) {
                          return '10-digit number required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Email Address
                    TextFormField(
                      controller: _emailController,
                      enabled: !_isLoading && !_isDeleting,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email Address *',
                        hintText: 'e.g. arun@gmail.com',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Email is required';
                        }
                        if (!val.contains('@') || !val.contains('.')) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    // Department Dropdown
                    _isLoadingDepts
                        ? const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
                        : DropdownButtonFormField<int>(
                            value: _depts.any((d) => d.id == _selectedDepartmentId)
                                ? _selectedDepartmentId
                                : (_depts.isNotEmpty ? _depts.first.id : null),
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Department (9 Approved) *',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              prefixIcon: const Icon(Icons.school_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
                            ),
                            items: _depts.map((d) {
                              final code = d.deptCode.isNotEmpty ? d.deptCode : d.name;
                              return DropdownMenuItem<int>(
                                value: d.id,
                                child: Text(
                                  '$code - ${d.name}',
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (_isLoading || _isDeleting)
                                ? null
                                : (v) => setState(() => _selectedDepartmentId = v),
                            validator: (val) => val == null ? 'Department is required' : null,
                          ),
                    const SizedBox(height: 24),

                    // Action Buttons Row (Delete + Save)
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: (_isLoading || _isDeleting) ? null : _delete,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: BorderSide(color: Colors.red.shade300),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              icon: _isDeleting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(color: Colors.red, strokeWidth: 2),
                                    )
                                  : const Icon(Icons.delete_outline_rounded, size: 20),
                              label: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: (_isLoading || _isDeleting) ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 2,
                              ),
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Icon(Icons.save_rounded, size: 20),
                              label: Text(
                                _isLoading ? 'Saving...' : 'Save Changes',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Error Message
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red.shade900, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// ENROLLED STUDENT DETAILS MODAL SHEET
// ==========================================

class _EnrolledStudentDetailsModal extends StatelessWidget {
  final EnrollmentItem item;
  final VoidCallback? onDelete;

  const _EnrolledStudentDetailsModal({
    required this.item,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.verified_user_rounded, color: Colors.green, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Enrolled Student Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: [
                _buildInfoTile('Full Name', item.fullName, Icons.person_outline_rounded, isDark),
                _buildInfoTile('Register No', item.enrolledStudentRegNo ?? 'Assigned on enrollment', Icons.badge_outlined, isDark),
                _buildInfoTile('Department', '${item.deptCode} - ${item.departmentName}', Icons.school_outlined, isDark),
                _buildInfoTile('Gender', item.gender.isNotEmpty ? item.gender : 'Not specified', Icons.wc_rounded, isDark),
                _buildInfoTile('Mobile', item.maskedMobile, Icons.phone_outlined, isDark),
                _buildInfoTile('Status', 'ENROLLED', Icons.check_circle_outline_rounded, isDark, isGreen: true),
                if (item.enrolledAt != null)
                  _buildInfoTile('Enrolled On', item.enrolledAt!, Icons.calendar_today_outlined, isDark),
              ],
            ),
          ),
          if (onDelete != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onDelete!();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red.shade300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                label: const Text(
                  'Move to Recycle Bin',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon, bool isDark, {bool isGreen = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF475569) : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: isGreen ? Colors.green : Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey.shade600)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isGreen ? Colors.green.shade700 : (isDark ? Colors.white : Colors.black87),
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

// ==========================================
// BULK IMPORT MODAL SHEET
// ==========================================

class _BulkImportModal extends StatefulWidget {
  final Future<void> Function() onDownloadTemplate;
  final VoidCallback onImportSuccess;

  const _BulkImportModal({
    required this.onDownloadTemplate,
    required this.onImportSuccess,
  });

  @override
  State<_BulkImportModal> createState() => _BulkImportModalState();
}

class _BulkImportModalState extends State<_BulkImportModal> {
  final EnrollmentRepository _repository = getIt<EnrollmentRepository>();

  PlatformFile? _pickedFile;
  bool _isUploading = false;
  bool _isDownloadingTemplate = false;
  EnrollmentImportResult? _importResult;
  String? _errorMessage;

  double _progressValue = 0.0;
  String _statusMessage = 'Preparing file...';
  Timer? _progressTimer;

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  Future<void> _pickFile() async {
    if (_isUploading) return;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _pickedFile = result.files.first;
          _errorMessage = null;
          _importResult = null;
          _progressValue = 0.0;
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to pick file: $e');
    }
  }

  Future<void> _uploadFile() async {
    if (_isUploading) return;
    if (_pickedFile == null || _pickedFile!.bytes == null) {
      setState(() => _errorMessage = 'Please select a valid Excel file.');
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
      _importResult = null;
      _progressValue = 0.15;
      _statusMessage = 'Preparing and uploading Excel file...';
    });

    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 350), (timer) {
      if (!mounted || !_isUploading) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_progressValue < 0.35) {
          _progressValue += 0.06;
          _statusMessage = 'Uploading Excel data...';
        } else if (_progressValue < 0.65) {
          _progressValue += 0.04;
          _statusMessage = 'Validating student records & checking duplicates...';
        } else if (_progressValue < 0.88) {
          _progressValue += 0.02;
          _statusMessage = 'Persisting enrollment records...';
        }
      });
    });

    try {
      final result = await _repository.importExcel(
        _pickedFile!.bytes!,
        _pickedFile!.name,
      );
      _progressTimer?.cancel();
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _progressValue = 1.0;
        _statusMessage = 'Import completed successfully!';
        _importResult = result;
      });
      widget.onImportSuccess();
    } catch (e) {
      _progressTimer?.cancel();
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _progressValue = 0.0;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const primaryColor = Color(0xFF2563EB);

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Bulk Import Students',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: _isUploading ? null : () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 8),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step 1: Download Template
                  const Text('Step 1: Download 6-Column Template', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    'Template strictly contains: Sl.No., Name, Gender, Email, Mobile, Branch.',
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey.shade600),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: (_isDownloadingTemplate || _isUploading)
                          ? null
                          : () async {
                              setState(() => _isDownloadingTemplate = true);
                              await widget.onDownloadTemplate();
                              if (mounted) setState(() => _isDownloadingTemplate = false);
                            },
                      icon: _isDownloadingTemplate
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.download_rounded),
                      label: const Text('Download Excel Template (.xlsx)'),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Step 2: Select File
                  const Text('Step 2: Select Excel File', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: _isUploading ? null : _pickFile,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _pickedFile != null ? primaryColor : (isDark ? const Color(0xFF475569) : Colors.grey.shade300),
                          width: _pickedFile != null ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _pickedFile != null ? Icons.file_present_rounded : Icons.cloud_upload_outlined,
                            size: 38,
                            color: _pickedFile != null ? primaryColor : Colors.grey,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _pickedFile != null ? _pickedFile!.name : 'Click to select XLSX file',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _pickedFile != null ? primaryColor : (isDark ? Colors.white : Colors.black87),
                            ),
                          ),
                          if (_pickedFile != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${(_pickedFile!.size / 1024).toStringAsFixed(1)} KB',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Upload Button
                  if (_pickedFile != null && !_isUploading)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _uploadFile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.upload_file_rounded),
                        label: const Text(
                          'Upload & Import',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                  // Progress & Loading Indicator State
                  if (_isUploading)
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: primaryColor.withOpacity(0.35)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Importing Students...',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${(_progressValue * 100).toInt()}%',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: _progressValue,
                              minHeight: 8,
                              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade300,
                              valueColor: const AlwaysStoppedAnimation<Color>(primaryColor),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _statusMessage,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Please do not close this window.',
                            style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),

                  // Error Banner
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Import Failed',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 13),
                                ),
                                const SizedBox(height: 2),
                                Text(_errorMessage!, style: TextStyle(color: Colors.red.shade900, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Import Result Summary
                  if (_importResult != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isDark ? const Color(0xFF475569) : Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                _importResult!.importedCount > 0
                                    ? 'Import completed successfully'
                                    : 'Import finished with errors',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              _buildMetricChip('Total Rows', _importResult!.totalRows.toString(), Colors.blue),
                              const SizedBox(width: 8),
                              _buildMetricChip('Imported', _importResult!.importedCount.toString(), Colors.green),
                              const SizedBox(width: 8),
                              _buildMetricChip('Skipped', _importResult!.skippedCount.toString(), Colors.red),
                            ],
                          ),
                          if (_importResult!.errors.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Text('Row-level Errors / Skipped Items:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 8),
                            Container(
                              constraints: const BoxConstraints(maxHeight: 180),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: _importResult!.errors.length,
                                itemBuilder: (_, idx) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Text(
                                    '• ${_importResult!.errors[idx]}',
                                    style: const TextStyle(fontSize: 12, color: Colors.redAccent),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(String label, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(count, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
            Text(label, style: TextStyle(fontSize: 10, color: color)),
          ],
        ),
      ),
    );
  }
}
