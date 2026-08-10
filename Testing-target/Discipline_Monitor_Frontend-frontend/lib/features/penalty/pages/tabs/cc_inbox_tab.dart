import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/penalty/providers/penalty_provider.dart';
import 'package:pragatix/features/penalty/models/penalty_request.dart';
import 'package:intl/intl.dart';

class CcInboxTab extends StatelessWidget {
  const CcInboxTab({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Consumer<PenaltyProvider>(
            builder: (context, provider, child) {
              final pendingCount = provider.ccInbox
                  .where((r) => r.status == 'PENDING')
                  .length;
              final approvedCount = provider.ccInbox
                  .where(
                    (r) =>
                        r.status == 'APPROVED' || r.status == 'AUTO_APPROVED',
                  )
                  .length;
              final rejectedCount = provider.ccInbox
                  .where((r) => r.status == 'REJECTED')
                  .length;

              return Container(
                color: Colors.white,
                child: TabBar(
                  labelColor: Colors.blue,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.blue,
                  tabs: [
                    Tab(text: 'Pending ($pendingCount)'),
                    Tab(text: 'Approved ($approvedCount)'),
                    Tab(text: 'Rejected ($rejectedCount)'),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: Consumer<PenaltyProvider>(
              builder: (context, provider, child) {
                // If it's loading and there's no data yet, show the full spinner.
                // Otherwise, show the list so the animation can play out smoothly.
                if (provider.isLoading && provider.ccInbox.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null) {
                  return Center(
                    child: Text(
                      'Error: ${provider.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                final pending = provider.ccInbox
                    .where((r) => r.status == 'PENDING')
                    .toList();
                final approved = provider.ccInbox
                    .where(
                      (r) =>
                          r.status == 'APPROVED' || r.status == 'AUTO_APPROVED',
                    )
                    .toList();
                final rejected = provider.ccInbox
                    .where((r) => r.status == 'REJECTED')
                    .toList();

                return TabBarView(
                  children: [
                    _buildList(
                      context,
                      pending,
                      provider,
                      showButtons: true,
                      tabType: 'PENDING',
                    ),
                    _buildList(
                      context,
                      approved,
                      provider,
                      showButtons: false,
                      tabType: 'APPROVED',
                    ),
                    _buildList(
                      context,
                      rejected,
                      provider,
                      showButtons: false,
                      tabType: 'REJECTED',
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    List<PenaltyRequest> list,
    PenaltyProvider provider, {
    required bool showButtons,
    required String tabType,
  }) {
    if (list.isEmpty) {
      return const Center(child: Text('No requests found in this category.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final request = list[index];
        return AnimatedPenaltyCard(
          key: ValueKey(request.id),
          request: request,
          provider: provider,
          showButtons: showButtons,
          tabType: tabType,
        );
      },
    );
  }
}

class AnimatedPenaltyCard extends StatefulWidget {
  final PenaltyRequest request;
  final PenaltyProvider provider;
  final bool showButtons;
  final String tabType;

  const AnimatedPenaltyCard({
    super.key,
    required this.request,
    required this.provider,
    required this.showButtons,
    required this.tabType,
  });

  @override
  State<AnimatedPenaltyCard> createState() => _AnimatedPenaltyCardState();
}

class _AnimatedPenaltyCardState extends State<AnimatedPenaltyCard>
    with SingleTickerProviderStateMixin {
  bool _isDismissing = false;

  void _showRejectDialog(
    BuildContext context,
    PenaltyRequest request,
    PenaltyProvider provider,
  ) {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reject Penalty Request'),
          content: TextField(
            controller: reasonController,
            decoration: const InputDecoration(
              hintText: 'Reason for rejection',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                if (!mounted) return;
                setState(() {
                  _isDismissing = true;
                });
                // Allow animation to play
                await Future.delayed(const Duration(milliseconds: 300));

                bool success = await provider.rejectPenalty(
                  request.id,
                  reasonController.text,
                );
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Penalty Rejected')),
                  );
                } else if (!success && mounted) {
                  // Revert dismissal if failed
                  setState(() {
                    _isDismissing = false;
                  });
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'Reject',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy - hh:mm a');
    final request = widget.request;

    // Define colors and badge text based on status
    Color badgeColor;
    if (request.status == 'PENDING') {
      badgeColor = Colors.orange;
    } else if (request.status == 'APPROVED' ||
        request.status == 'AUTO_APPROVED') {
      badgeColor = Colors.green;
    } else {
      badgeColor = Colors.red;
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: _isDismissing
          ? const SizedBox(width: double.infinity, height: 0)
          : Card(
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            request.studentName ?? 'Unknown Student',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            request.status,
                            style: TextStyle(
                              color: badgeColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Register No: ${request.regNo ?? 'N/A'}'),

                    // Show full info for Pending, but hide Department/Year/Section for history to save space (as requested)
                    if (widget.tabType == 'PENDING')
                      Text(
                        'Dept: ${request.department ?? 'N/A'} | Year: ${request.year ?? 'N/A'} | Sec: ${request.section ?? 'N/A'}',
                      ),

                    const Divider(height: 24),
                    Text(
                      'Activity: ${request.penaltyActivity ?? 'Custom Penalty'}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Penalty XP: -${request.penaltyXP}',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Reason: ${request.reason ?? 'No reason provided'}',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.person, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          'By: ${request.submittedBy ?? 'Unknown'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Requested: ${request.submittedTime != null ? dateFormat.format(request.submittedTime!) : 'N/A'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),

                    if (widget.tabType == 'APPROVED') ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 14,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Approved By: ${request.approvedBy ?? 'Unknown'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Approved Date: ${request.approvalTime != null ? dateFormat.format(request.approvalTime!) : 'N/A'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (widget.tabType == 'REJECTED') ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.cancel, size: 14, color: Colors.red),
                          const SizedBox(width: 4),
                          Text(
                            'Rejected By: ${request.approvedBy ?? 'Unknown'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Rejected Date: ${request.approvalTime != null ? dateFormat.format(request.approvalTime!) : 'N/A'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      if (request.rejectedReason != null &&
                          request.rejectedReason!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Rejection Reason: ${request.rejectedReason}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],

                    if (widget.showButtons) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              _showRejectDialog(
                                context,
                                request,
                                widget.provider,
                              );
                            },
                            child: const Text(
                              'Reject',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              setState(() {
                                _isDismissing = true;
                              });
                              // Allow animation to play
                              await Future.delayed(
                                const Duration(milliseconds: 300),
                              );

                              bool success = await widget.provider
                                  .approvePenalty(request.id);
                              if (success && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Penalty Approved'),
                                  ),
                                );
                              } else if (!success && mounted) {
                                setState(() {
                                  _isDismissing = false;
                                });
                              }
                            },
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
            ),
    );
  }
}
