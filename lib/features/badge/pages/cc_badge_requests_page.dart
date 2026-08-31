import 'package:flutter/material.dart';
import 'package:pragatix/core/widgets/pragatix_loader.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/features/badge/providers/badge_provider.dart';
import 'package:pragatix/features/badge/models/badge_request.dart';
import 'package:pragatix/core/utils/proof_viewer_utils.dart';
import 'package:intl/intl.dart';

class CCBadgeRequestsPage extends StatefulWidget {
  const CCBadgeRequestsPage({super.key});

  @override
  State<CCBadgeRequestsPage> createState() => _CCBadgeRequestsPageState();
}

class _CCBadgeRequestsPageState extends State<CCBadgeRequestsPage> {
  String _selectedStatus = 'PENDING';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().token;
      if (token != null) {
        context.read<BadgeProvider>().fetchAdminCCBadgeRequests(token, 'CC');
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
        title: const Text('Class Badge Requests (CC)'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFilterChip('PENDING', badgeProvider),
                const SizedBox(width: 8),
                _buildFilterChip('APPROVED', badgeProvider),
                const SizedBox(width: 8),
                _buildFilterChip('REJECTED', badgeProvider),
              ],
            ),
          ),
        ),
      ),
      body: badgeProvider.isLoading
          ? const Center(child: PragatiXLoader())
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

  Widget _buildFilterChip(String status, BadgeProvider badgeProvider) {
    final isSelected = _selectedStatus == status;
    final int count = badgeProvider.adminCCBadgeRequests
        .where((r) => (r['status'] ?? '').toString().toUpperCase() == status)
        .length;

    return ChoiceChip(
      label: Text(count > 0 ? '$status ($count)' : status),
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
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.shield),
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
                  onTap: () {
                    ProofViewerUtils.openProof(
                      context,
                      req.proofLink!,
                      title: '${req.badgeName} Proof - ${req.studentName}',
                    );
                  },
                  child: Text(
                    'Evidence: ${req.proofLink!}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      decoration: TextDecoration.underline,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            if (req.status == 'PENDING') ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => _handleReject(req.id),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Reject'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _handleApprove(req.id),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('Approve', style: TextStyle(color: Colors.white)),
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
    if (token == null) return;
    final res = await context.read<BadgeProvider>().approveBadgeWorkflow(token, id, 'CC');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Approved')),
      );
    }
  }

  void _handleReject(int id) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    final remarksController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Badge Request'),
        content: TextField(
          controller: remarksController,
          decoration: const InputDecoration(
            labelText: 'Remarks / Reason',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final res = await context.read<BadgeProvider>().rejectBadgeWorkflow(
                token,
                id,
                'CC',
                remarks: remarksController.text.trim(),
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(res['message'] ?? 'Rejected')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return DateFormat('MMM dd, yyyy HH:mm').format(dt);
    } catch (_) {
      return dateStr;
    }
  }
}
