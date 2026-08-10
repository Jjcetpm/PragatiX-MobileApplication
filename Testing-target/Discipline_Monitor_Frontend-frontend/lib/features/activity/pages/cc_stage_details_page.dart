import 'package:flutter/material.dart';
import 'package:pragatix/features/activity/pages/cc_activity_list_page.dart';

class CCStageDetailsPage extends StatelessWidget {
  final int stageId;
  final String stageName;
  final String stageDescription;
  final Map<String, dynamic> stageData;
  final String? academicYear;

  const CCStageDetailsPage({
    super.key,
    required this.stageId,
    required this.stageName,
    required this.stageDescription,
    required this.stageData,
    this.academicYear,
  });

  void _onCategorySelected(BuildContext context, String categoryKey, String categoryTitle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CCActivityListPage(
          stageId: stageId,
          stageName: stageName,
          categoryTitle: categoryTitle,
          subgroupFilter: categoryKey,
          academicYear: academicYear,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mustThreshold = (stageData['mustThreshold'] ?? 0).toString();
    final individualThreshold = (stageData['individualThreshold'] ?? 0).toString();
    final groupThreshold = (stageData['groupThreshold'] ?? 0).toString();

    final categories = [
      {
        'key': 'Must',
        'title': 'Mandatory (M)',
        'subtitle': 'Required activities to clear this stage',
        'threshold': mustThreshold,
        'color': const Color(0xFFEF4444),
        'icon': Icons.star_rounded,
        'badge': 'M',
      },
      {
        'key': 'Individual',
        'title': 'Individual (I)',
        'subtitle': 'Solo performance and learning tasks',
        'threshold': individualThreshold,
        'color': const Color(0xFF3B82F6),
        'icon': Icons.person_rounded,
        'badge': 'I',
      },
      {
        'key': 'Group',
        'title': 'Group (G)',
        'subtitle': 'Team and collaborative discipline events',
        'threshold': groupThreshold,
        'color': const Color(0xFF10B981),
        'icon': Icons.groups_rounded,
        'badge': 'G',
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          stageName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stage Information Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF11998E).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.workspace_premium_rounded,
                          color: Color(0xFF11998E),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stageName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            if (stageDescription.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                stageDescription,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                  ),
                  const Text(
                    'Progression Target Requirements',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _TargetSummaryPill(
                        label: 'Must',
                        value: '$mustThreshold pts',
                        color: const Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 8),
                      _TargetSummaryPill(
                        label: 'Individual',
                        value: '$individualThreshold pts',
                        color: const Color(0xFF3B82F6),
                      ),
                      const SizedBox(width: 8),
                      _TargetSummaryPill(
                        label: 'Group',
                        value: '$groupThreshold pts',
                        color: const Color(0xFF10B981),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Activity Categories (M / I / G)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),

            // Category Selection Cards
            ...categories.map((cat) {
              final catKey = cat['key'] as String;
              final catTitle = cat['title'] as String;
              final catSub = cat['subtitle'] as String;
              final catThreshold = cat['threshold'] as String;
              final color = cat['color'] as Color;
              final icon = cat['icon'] as IconData;

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _onCategorySelected(context, catKey, catTitle),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Icon(icon, color: color, size: 26),
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
                                      catTitle,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '$catThreshold pts',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: color,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  catSub,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFF94A3B8),
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _TargetSummaryPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _TargetSummaryPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
