import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pragatix/core/di/service_locator.dart';
import 'package:pragatix/core/widgets/pragatix_loader.dart';
import 'package:pragatix/features/admin/repository/admin_repository.dart';
import 'package:pragatix/features/student/models/student_deletion_request.dart';

class StudentDeletionRequestsPage extends StatefulWidget {
  const StudentDeletionRequestsPage({super.key});

  @override
  State<StudentDeletionRequestsPage> createState() =>
      _StudentDeletionRequestsPageState();
}

class _StudentDeletionRequestsPageState
    extends State<StudentDeletionRequestsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdminRepository _repository = getIt<AdminRepository>();
  final TextEditingController _searchController = TextEditingController();

  List<StudentDeletionRequest> _requests = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _fetchRequests();
      }
    });
    _fetchRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _currentStatusFilter() {
    switch (_tabController.index) {
      case 0:
        return 'PENDING';
      case 1:
        return 'ALL';
      case 2:
        return 'APPROVED';
      case 3:
        return 'REJECTED';
      default:
        return 'PENDING';
    }
  }

  Future<void> _fetchRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final status = _currentStatusFilter();
      final search = _searchController.text.trim();
      final results = await _repository.getStudentDeletionRequests(
        status: status,
        search: search.isNotEmpty ? search : null,
      );

      final count = await _repository.getPendingStudentDeletionRequestsCount();

      if (!mounted) return;
      setState(() {
        _requests = results;
        _pendingCount = count;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleApprove(StudentDeletionRequest request) async {
    final remarksController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626), size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Approve Deletion',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to approve deletion of ${request.studentName} (${request.registerNumber})?',
              style: const TextStyle(fontSize: 13.5, color: Color(0xFF334155), height: 1.4),
            ),
            const SizedBox(height: 10),
            const Text(
              'The student profile will be moved to the Recycle Bin following existing system retention rules.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: remarksController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Optional approval remarks...',
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Confirm Approval'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _repository.approveStudentDeletionRequest(
          request.id,
          remarks: remarksController.text.trim(),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Student ${request.registerNumber} deletion approved.'),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
        _fetchRequests();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Approval failed: ${e.toString().replaceAll('Exception:', '')}'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  Future<void> _handleReject(StudentDeletionRequest request) async {
    final remarksController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.cancel_outlined, color: Color(0xFFDC2626), size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Reject Deletion',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reject deletion for ${request.studentName} (${request.registerNumber})? The student profile will remain active.',
                style: const TextStyle(fontSize: 13.5, color: Color(0xFF334155), height: 1.4),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: remarksController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Reason for rejection (required)...',
                  hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a rejection reason';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Confirm Rejection'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _repository.rejectStudentDeletionRequest(
          request.id,
          remarks: remarksController.text.trim(),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deletion request for ${request.registerNumber} rejected.'),
            backgroundColor: const Color(0xFF2563EB),
          ),
        );
        _fetchRequests();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rejection failed: ${e.toString().replaceAll('Exception:', '')}'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Student Deletion Approvals',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Super Admin Approval Hub',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFFDC2626),
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: const Color(0xFFDC2626),
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Pending'),
                      if (_pendingCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$_pendingCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Tab(text: 'All'),
                const Tab(text: 'Approved'),
                const Tab(text: 'Rejected'),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by student name or register no...',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _fetchRequests();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                ),
              ),
              onSubmitted: (_) => _fetchRequests(),
            ),
          ),

          // Requests List
          Expanded(
            child: _isLoading
                ? const Center(child: PragatiXLoader(fullScreen: false))
                : _errorMessage != null
                    ? _buildErrorView()
                    : _requests.isEmpty
                        ? _buildEmptyView()
                        : RefreshIndicator(
                            onRefresh: _fetchRequests,
                            color: const Color(0xFFDC2626),
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: _requests.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                return _buildRequestCard(_requests[index]);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(StudentDeletionRequest req) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final formattedReqDate = req.requestedAt != null ? dateFormat.format(req.requestedAt!) : 'N/A';
    final formattedRevDate = req.reviewedAt != null ? dateFormat.format(req.reviewedAt!) : 'N/A';

    Color statusBgColor;
    Color statusTextColor;
    String statusLabel = req.status.toUpperCase();

    if (req.isPending) {
      statusBgColor = const Color(0xFFFEF3C7);
      statusTextColor = const Color(0xFFB45309);
    } else if (req.isApproved) {
      statusBgColor = const Color(0xFFDCFCE7);
      statusTextColor = const Color(0xFF15803D);
    } else {
      statusBgColor = const Color(0xFFFEE2E2);
      statusTextColor = const Color(0xFFB91C1C);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: req.isPending ? const Color(0xFFFCD34D) : const Color(0xFFE2E8F0),
          width: req.isPending ? 1.2 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Student Name + Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person_rounded, color: Color(0xFF2563EB), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      req.studentName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${req.registerNumber} • ${req.departmentName ?? 'Department'} • Year ${req.academicYear ?? 'N/A'}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: statusTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Reason Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Deletion Reason:',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  req.reason,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1E293B),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Requester Info
          Row(
            children: [
              const Icon(Icons.account_circle_outlined, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Requested by: ${req.requesterName ?? req.requestedBy} (${req.requesterRole ?? 'STAFF'}) • $formattedReqDate',
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // Reviewer Info if Reviewed
          if (!req.isPending) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: req.isApproved ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    req.isApproved ? Icons.verified_rounded : Icons.info_outline,
                    size: 14,
                    color: req.isApproved ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${req.isApproved ? 'Approved' : 'Rejected'} by ${req.reviewerName ?? req.reviewedBy ?? 'Super Admin'} on $formattedRevDate' +
                          (req.reviewerRemarks != null && req.reviewerRemarks!.isNotEmpty
                              ? ' (Remarks: ${req.reviewerRemarks})'
                              : ''),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: req.isApproved ? const Color(0xFF166534) : const Color(0xFF991B1B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Action Buttons (Pending only)
          if (req.isPending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleReject(req),
                    icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFFDC2626)),
                    label: const Text('Reject', style: TextStyle(color: Color(0xFFDC2626))),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: ElevatedButton.icon(
                    onPressed: () => _handleApprove(req),
                    icon: const Icon(Icons.delete_forever_rounded, size: 16, color: Colors.white),
                    label: const Text('Approve Deletion', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                size: 48,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Deletion Requests',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'There are no student deletion requests matching the selected filter.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFDC2626)),
            const SizedBox(height: 14),
            Text(
              _errorMessage ?? 'Failed to load requests',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: _fetchRequests,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
