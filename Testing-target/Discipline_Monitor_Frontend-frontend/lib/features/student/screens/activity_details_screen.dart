import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/activity/providers/activity_completion_provider.dart';

class ActivityDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> activity;

  const ActivityDetailsScreen({Key? key, required this.activity})
    : super(key: key);

  @override
  State<ActivityDetailsScreen> createState() => _ActivityDetailsScreenState();
}

class _ActivityDetailsScreenState extends State<ActivityDetailsScreen> {
  final _reasonCtrl = TextEditingController();
  final _proofUrlCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActivityCompletionProvider>().loadMyRequests();
    });
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _proofUrlCtrl.dispose();
    super.dispose();
  }

  void _showRequestCompletionDialog(int activityId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request Activity'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Reason / Remarks',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _proofUrlCtrl,
              decoration: const InputDecoration(
                labelText: 'Proof URL (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isSubmitting = true);
              final success = await context
                  .read<ActivityCompletionProvider>()
                  .submitRequest(
                    activityId,
                    reason: _reasonCtrl.text.trim(),
                    proofUrl: _proofUrlCtrl.text.trim(),
                  );
              setState(() => _isSubmitting = false);

              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Activity Request Submitted Successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  final err = context.read<ActivityCompletionProvider>().error;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(err ?? 'Failed to submit request'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activity = widget.activity;
    final String name = activity['activityName'] ?? 'Activity Details';
    final String description =
        activity['description'] ?? 'No description provided.';
    final int rewardXp = activity['rewardXp'] ?? 0;
    final int awardedXp = activity['awardedXp'] ?? 0;
    final String status = activity['status'] ?? 'PENDING';
    final bool isCompleted = status == 'COMPLETED';

    final String facultyName = activity['facultyName'] ?? 'Unassigned';
    final String frequency = activity['frequency'] ?? 'N/A';

    // evidence could be a List or a String in some backend setups, assuming List
    final dynamic evidenceRaw = activity['evidence'];
    List<String> evidence = evidenceRaw is List
        ? evidenceRaw.map((e) => e.toString()).toList()
        : (evidenceRaw != null && evidenceRaw.toString().isNotEmpty
              ? [evidenceRaw.toString()]
              : []);
              
    final manualEvidenceName = activity['manualEvidenceName']?.toString();
    if (manualEvidenceName != null && manualEvidenceName.isNotEmpty) {
      evidence = evidence.map((e) => e == 'Manual' ? manualEvidenceName : e).toList();
    }

    final bool allowStudentRequest = activity['allowStudentRequest'] == true;
    final int activityId = activity['activityId'] ?? activity['id'] ?? 0;

    return Consumer<ActivityCompletionProvider>(
      builder: (context, provider, _) {
        final existingRequest = provider.getMyRequestForActivity(activityId);
        final String reqStatus = existingRequest?.status.toUpperCase() ?? '';

        final bool hasCompleted = isCompleted || reqStatus == 'APPROVED';
        final bool isPending = reqStatus == 'PENDING';
        final bool isRejected = reqStatus == 'REJECTED';

        final bool buttonEnabled = !hasCompleted && !isPending && !_isSubmitting;
        final String buttonText = hasCompleted
            ? 'Completed'
            : (isPending ? 'Request Pending' : 'Request Activity');

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text(
              'Activity Details',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Colors.green.withOpacity(0.1)
                        : Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isCompleted
                          ? Colors.green.shade300
                          : Colors.amber.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCompleted ? Icons.check_circle : Icons.pending,
                        size: 16,
                        color: isCompleted
                            ? Colors.green.shade700
                            : Colors.amber.shade700,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        status,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isCompleted
                              ? Colors.green.shade700
                              : Colors.amber.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Name & Description
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 24),

                // Details Grid
                const Text(
                  'Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 16),

                _InfoRow(
                  icon: Icons.star_rounded,
                  title: 'Reward',
                  value: '$rewardXp XP',
                  iconColor: Colors.amber,
                ),
                const SizedBox(height: 16),
                _InfoRow(
                  icon: Icons.military_tech_rounded,
                  title: 'Awarded',
                  value: '$awardedXp XP',
                  iconColor: Colors.blue,
                ),
                const SizedBox(height: 16),
                _InfoRow(
                  icon: Icons.person_rounded,
                  title: 'Faculty / Owner',
                  value: facultyName,
                  iconColor: Colors.purple,
                ),
                const SizedBox(height: 16),
                _InfoRow(
                  icon: Icons.repeat_rounded,
                  title: 'Frequency',
                  value: frequency,
                  iconColor: Colors.teal,
                ),

                const SizedBox(height: 32),

                // Evidence Section
                if (evidence.isNotEmpty) ...[
                  const Text(
                    'Required Evidence',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: evidence
                        .map(
                          (e) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.attachment,
                                  size: 16,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  e,
                                  style: TextStyle(
                                    color: Colors.grey.shade800,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          bottomNavigationBar: allowStudentRequest
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasCompleted)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.lock, color: Colors.green),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Completed ✓',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else ...[
                          if (isRejected && existingRequest != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Previous request rejected: ${existingRequest.rejectedReason ?? "No reason provided"}',
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: !buttonEnabled
                                    ? Colors.grey
                                    : const Color(0xFFEA4335),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: buttonEnabled
                                  ? () => _showRequestCompletionDialog(
                                        activityId,
                                      )
                                  : null,
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Text(
                                      buttonText,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color iconColor;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
