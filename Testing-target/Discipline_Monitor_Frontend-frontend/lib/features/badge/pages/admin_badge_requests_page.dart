import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/features/badge/providers/badge_provider.dart';
import 'package:pragatix/features/badge/models/badge_request.dart';
import 'package:pragatix/core/utils/proof_viewer_utils.dart';
import 'package:intl/intl.dart';

class AdminBadgeRequestsPage extends StatefulWidget {
  const AdminBadgeRequestsPage({super.key});

  @override
  State<AdminBadgeRequestsPage> createState() => _AdminBadgeRequestsPageState();
}

class _AdminBadgeRequestsPageState extends State<AdminBadgeRequestsPage> {
  String _selectedStatus = 'PENDING';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().token;
      if (token != null) {
        context.read<BadgeProvider>().fetchAdminCCBadgeRequests(token, 'ADMIN');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final badgeProvider = context.watch<BadgeProvider>();
    final requests = badgeProvider.adminCCBadgeRequests
        .map((json) => BadgeRequest.fromJson(json))
        .where((r) => r.status == _selectedStatus)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Badge Requests Approval',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFilterChip('PENDING'),
                const SizedBox(width: 8),
                _buildFilterChip('APPROVED'),
                const SizedBox(width: 8),
                _buildFilterChip('REJECTED'),
              ],
            ),
          ),
        ),
      ),
      body: badgeProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : requests.isEmpty
          ? const Center(child: Text('No requests found.'))
          : ListView.builder(
              itemCount: requests.length,
              itemBuilder: (context, index) {
                return _buildRequestCard(requests[index]);
              },
            ),
    );
  }

  Widget _buildFilterChip(String status) {
    final isSelected = _selectedStatus == status;
    return ChoiceChip(
      label: Text(status),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedStatus = status);
      },
    );
  }

  Widget _buildRequestCard(BadgeRequest req) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (req.badgeIcon.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Image.network(
                      req.badgeIcon,
                      width: 40,
                      height: 40,
                      errorBuilder: (_, __, ___) => const Icon(Icons.shield),
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: Icon(Icons.shield, size: 40),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        req.badgeName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${req.studentName} (${req.regNo})',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      Text(
                        '${req.departmentName} - ${req.sectionName}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Requested: ${_formatDate(req.requestedAt)}',
              style: const TextStyle(fontSize: 12),
            ),
            if (req.proofLink != null && req.proofLink!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: InkWell(
                  onTap: () => ProofViewerUtils.openProof(
                    context,
                    req.proofLink,
                    title: '${req.badgeName} Proof - ${req.studentName}',
                  ),
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.link, size: 16, color: Colors.blue),
                        SizedBox(width: 6),
                        Text(
                          'View Proof Link',
                          style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (req.reviewedBy != null) ...[
              Text(
                'Reviewed By: ${req.reviewedBy}',
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                'Reviewed At: ${_formatDate(req.reviewedAt!)}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
            if (req.status == 'PENDING') ...[
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _handleReject(req.id),
                    child: const Text(
                      'Reject',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _handleApprove(req.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text(
                      'Approve',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleApprove(int id) async {
    final token = context.read<AuthProvider>().token;
    final res = await context.read<BadgeProvider>().approveBadgeWorkflow(
      token!,
      id,
      'ADMIN',
    );
    if (mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(res['message'])));
  }

  void _handleReject(int id) async {
    final token = context.read<AuthProvider>().token;
    final res = await context.read<BadgeProvider>().rejectBadgeWorkflow(
      token!,
      id,
      'ADMIN',
    );
    if (mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(res['message'])));
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return DateFormat('MMM dd, yyyy HH:mm').format(dt);
    } catch (_) {
      return dateStr;
    }
  }
}
