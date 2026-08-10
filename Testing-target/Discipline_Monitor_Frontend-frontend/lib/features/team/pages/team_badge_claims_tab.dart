import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/badge/providers/badge_provider.dart';
import 'package:pragatix/core/utils/proof_viewer_utils.dart';

class TeamBadgeClaimsTab extends StatefulWidget {
  const TeamBadgeClaimsTab({super.key});

  @override
  State<TeamBadgeClaimsTab> createState() => _TeamBadgeClaimsTabState();
}

class _TeamBadgeClaimsTabState extends State<TeamBadgeClaimsTab> {
  final Color primaryColor = const Color(0xFF4F46E5);
  final Color bgColor = const Color(0xFFF8FAFC);
  final Color textColor = const Color(0xFF1E293B);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BadgeProvider>(
        context,
        listen: false,
      ).fetchTeacherPendingClaims(context.read<AuthProvider>().token!);
    });
  }

  Future<void> openUrl(String url) async {
    await ProofViewerUtils.openProof(context, url, title: 'Badge Evidence');
  }

  @override
  Widget build(BuildContext context) {
    final badgeProvider = Provider.of<BadgeProvider>(context);

    if (badgeProvider.isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    final claims = badgeProvider.teacherPendingClaims;

    return Scaffold(
      backgroundColor: bgColor,
      body: claims.isEmpty
          ? Center(
              child: RefreshIndicator(
                onRefresh: () async {
                  await Provider.of<BadgeProvider>(
                    context,
                    listen: false,
                  ).fetchTeacherPendingClaims(
                    context.read<AuthProvider>().token!,
                  );
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.done_all_rounded,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No pending claims',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                await Provider.of<BadgeProvider>(
                  context,
                  listen: false,
                ).fetchTeacherPendingClaims(
                  context.read<AuthProvider>().token!,
                );
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: claims.length,
                itemBuilder: (context, index) {
                  final claim = claims[index];
                  final id = claim['id'];
                  final studentName = claim['studentName'] ?? 'Unknown Student';
                  final regNo = claim['regNo'] ?? 'ID N/A';
                  final badgeName = claim['badgeName'] ?? 'Unknown Badge';
                  final evidenceUrl = claim['evidenceUrl'];
                  final tier = claim['tier'] ?? 'Tier';

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: primaryColor.withValues(
                                  alpha: 0.1,
                                ),
                                child: Icon(Icons.person, color: primaryColor),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      studentName,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                    Text(
                                      regNo,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'PENDING',
                                  style: TextStyle(
                                    color: Colors.amber.shade800,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Text(
                            'Requested Badge:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$badgeName ($tier)',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (evidenceUrl != null &&
                              evidenceUrl.toString().isNotEmpty)
                            Row(
                              children: [
                                const Icon(
                                  Icons.link,
                                  color: Colors.blue,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: InkWell(
                                    onTap: () =>
                                        openUrl(evidenceUrl.toString()),
                                    child: Text(
                                      evidenceUrl.toString(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  badgeProvider
                                      .rejectClaim(
                                        context.read<AuthProvider>().token!,
                                        id,
                                      )
                                      .then((response) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                response['message'] ??
                                                    (response['success']
                                                        ? 'Claim rejected'
                                                        : 'Failed to reject'),
                                              ),
                                              backgroundColor:
                                                  response['success']
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
                                          );
                                        }
                                      });
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text(
                                  'Reject',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: () {
                                  badgeProvider
                                      .approveClaim(
                                        context.read<AuthProvider>().token!,
                                        id,
                                      )
                                      .then((response) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                response['message'] ??
                                                    (response['success']
                                                        ? 'Claim approved'
                                                        : 'Failed to approve'),
                                              ),
                                              backgroundColor:
                                                  response['success']
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
                                          );
                                        }
                                      });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Approve',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
    );
  }
}
