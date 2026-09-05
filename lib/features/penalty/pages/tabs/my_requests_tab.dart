import 'package:flutter/material.dart';
import 'package:pragatix/core/widgets/pragatix_loader.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/penalty/providers/penalty_provider.dart';
import 'package:pragatix/features/penalty/models/penalty_request.dart';
import 'package:intl/intl.dart';

class MyRequestsTab extends StatelessWidget {
  const MyRequestsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PenaltyProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: PragatiXLoader());
        }

        if (provider.error != null) {
          return Center(
            child: Text(
              'Error: ${provider.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (provider.myRequests.isEmpty) {
          return const Center(
            child: Text('You have not submitted any penalty requests.'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.myRequests.length,
          itemBuilder: (context, index) {
            final request = provider.myRequests[index];
            return _buildPenaltyCard(context, request);
          },
        );
      },
    );
  }

  Widget _buildPenaltyCard(BuildContext context, PenaltyRequest request) {
    final dateFormat = DateFormat('MMM dd, yyyy - hh:mm a');

    Color statusColor;
    switch (request.status) {
      case 'APPROVED':
        statusColor = Colors.green;
        break;
      case 'REJECTED':
        statusColor = Colors.red;
        break;
      case 'AUTO_APPROVED':
        statusColor = Colors.blue;
        break;
      case 'PENDING':
      default:
        statusColor = Colors.orange;
        break;
    }

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    request.status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Register No: ${request.regNo ?? 'N/A'}',
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF475569),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 5),
            _buildClassHierarchyRow(request),
            if (request.ccName != null &&
                request.ccName!.trim().isNotEmpty &&
                request.ccName!.trim().toUpperCase() != 'N/A') ...[
              const SizedBox(height: 5),
              Row(
                children: [
                  const Icon(Icons.person_pin_rounded, size: 15, color: Color(0xFF2563EB)),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      'CC: ${request.ccName}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF1D4ED8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const Divider(height: 22),
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
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Requested: ${request.submittedTime != null ? dateFormat.format(request.submittedTime!) : 'N/A'}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            if (request.status != 'PENDING') ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    request.status == 'REJECTED'
                        ? Icons.cancel
                        : Icons.check_circle,
                    size: 14,
                    color: statusColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Reviewed By: ${request.approvedBy ?? 'System'}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Reviewed At: ${request.approvalTime != null ? dateFormat.format(request.approvalTime!) : 'N/A'}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              if (request.status == 'REJECTED' &&
                  request.rejectedReason != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Reason: ${request.rejectedReason}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildClassHierarchyRow(PenaltyRequest request) {
    final List<String> parts = [];

    final yearStr = _formatYear(request.year);
    if (yearStr.isNotEmpty) parts.add(yearStr);

    if (request.department != null &&
        request.department!.trim().isNotEmpty &&
        request.department!.trim().toUpperCase() != 'N/A') {
      parts.add(request.department!.trim());
    }

    if (request.section != null &&
        request.section!.trim().isNotEmpty &&
        request.section!.trim().toUpperCase() != 'N/A' &&
        request.section!.trim().toUpperCase() != 'NULL') {
      final sec = request.section!.trim();
      parts.add(sec.toUpperCase().startsWith('SECTION') ? sec : 'Sec: $sec');
    }

    if (parts.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        const Icon(Icons.school_outlined, size: 15, color: Color(0xFF64748B)),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            parts.join(' • '),
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF334155),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _formatYear(String? year) {
    if (year == null || year.trim().isEmpty || year.trim().toUpperCase() == 'N/A') return '';
    final clean = year.trim().toUpperCase();
    if (clean == '1' || clean.contains('FIRST') || clean == 'I' || clean.contains('1ST')) return '1st Year';
    if (clean == '2' || clean.contains('SECOND') || clean == 'II' || clean.contains('2ND')) return '2nd Year';
    if (clean == '3' || clean.contains('THIRD') || clean == 'III' || clean.contains('3RD')) return '3rd Year';
    if (clean == '4' || clean.contains('FOURTH') || clean == 'IV' || clean.contains('4TH')) return '4th Year';
    return year.trim();
  }
}
