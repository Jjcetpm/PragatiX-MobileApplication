import 'package:flutter/material.dart';
import 'package:pragatix/features/student/models/student_deletion_request.dart';
import 'package:intl/intl.dart';

class StudentDeletionStatusBanner extends StatelessWidget {
  final StudentDeletionRequest request;
  final bool isSuperAdmin;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onRefresh;
  final VoidCallback? onReRequest;

  const StudentDeletionStatusBanner({
    super.key,
    required this.request,
    this.isSuperAdmin = false,
    this.onApprove,
    this.onReject,
    this.onRefresh,
    this.onReRequest,
  });

  @override
  Widget build(BuildContext context) {
    if (request.isPending) {
      return _buildPendingBanner(context);
    } else if (request.isApproved) {
      return _buildApprovedBanner();
    } else {
      return _buildRejectedBanner();
    }
  }

  Widget _buildPendingBanner(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final formattedDate = request.requestedAt != null
        ? dateFormat.format(request.requestedAt!)
        : 'Recently';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pending_actions_rounded,
                  color: Color(0xFFD97706),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Deletion Request Pending Approval',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF92400E),
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE68A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'PENDING',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Requested by: ${request.requesterName ?? request.requestedBy} • $formattedDate',
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF78350F),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFDE68A).withOpacity(0.6)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reason: ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF92400E),
                  ),
                ),
                Expanded(
                  child: Text(
                    request.reason,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF451A03),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isSuperAdmin && (onApprove != null || onReject != null)) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onReject != null)
                  OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFFDC2626)),
                    label: const Text('Reject', style: TextStyle(color: Color(0xFFDC2626))),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                if (onApprove != null) ...[
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                    label: const Text('Approve Deletion', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildApprovedBanner() {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final formattedDate = request.reviewedAt != null
        ? dateFormat.format(request.reviewedAt!)
        : 'Recently';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBF7D0), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF16A34A), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Deletion Request Approved',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF15803D),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Authorized by Super Admin (${request.reviewerName ?? request.reviewedBy ?? 'Super Admin'}) on $formattedDate.',
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF166534)),
                ),
                if (request.reviewerRemarks != null && request.reviewerRemarks!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Remarks: ${request.reviewerRemarks}',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF14532D)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectedBanner() {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final formattedDate = request.reviewedAt != null
        ? dateFormat.format(request.reviewedAt!)
        : 'Recently';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cancel_outlined, color: Color(0xFFDC2626), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Deletion Request Rejected',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFB91C1C),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'PROFILE RETAINED',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF991B1B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Rejected by Super Admin (${request.reviewerName ?? request.reviewedBy ?? 'Super Admin'}) on $formattedDate.',
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF991B1B)),
                ),
                if (request.reviewerRemarks != null && request.reviewerRemarks!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Remarks: ${request.reviewerRemarks}',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF7F1D1D)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
