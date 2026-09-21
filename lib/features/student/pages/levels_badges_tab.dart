import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/features/badge/providers/badge_provider.dart';
import 'package:pragatix/features/xp/providers/xp_provider.dart';
import 'package:pragatix/features/attendance/providers/attendance_provider.dart';
import 'package:pragatix/core/widgets/pragatix_loader.dart';
import 'package:pragatix/core/utils/proof_viewer_utils.dart';

class LevelsBadgesTab extends StatefulWidget {
  final VoidCallback? onBack;

  const LevelsBadgesTab({super.key, this.onBack});

  @override
  State<LevelsBadgesTab> createState() => _LevelsBadgesTabState();
}

typedef BadgesTab = LevelsBadgesTab;

class _LevelsBadgesTabState extends State<LevelsBadgesTab> {
  bool _isLoading = true;
  String _selectedTier = 'Foundation';

  final List<Map<String, dynamic>> _tierTabs = [
    {'name': 'Foundation', 'icon': Icons.settings_rounded},
    {'name': 'Achievement', 'icon': Icons.star_rounded},
    {'name': 'Excellence', 'icon': Icons.military_tech_outlined},
    {'name': 'Elite', 'icon': Icons.workspace_premium_rounded},
    {'name': 'Legacy', 'icon': Icons.energy_savings_leaf_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoading = true);

    try {
      if (mounted) {
        final bp = Provider.of<BadgeProvider>(context, listen: false);
        final xp = Provider.of<XpProvider>(context, listen: false);
        final token = context.read<AuthProvider>().token ?? '';
        if (token.isNotEmpty && token != 'debug_token') {
          await Future.wait([
            bp.fetchMyBadges(token).catchError((_) {}),
            bp.fetchMyBadgeRequests(token).catchError((_) {}),
            bp.fetchAllBadges(token).catchError((_) {}),
            xp.fetchProgression(token).catchError((_) {}),
          ]).timeout(const Duration(seconds: 8), onTimeout: () => []);
        }
      }
    } catch (e) {
      debugPrint('Error in _loadData badges: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final badgeProvider = Provider.of<BadgeProvider>(context);
    final attendanceProvider = Provider.of<AttendanceProvider>(context);

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: PragatiXLoader(fullScreen: false, message: 'Loading Badges...'),
        ),
      );
    }

    final tierBadges = badgeProvider.availableBadges
        .where((b) => (b['tier']?.toString().trim().toUpperCase()) == _selectedTier.trim().toUpperCase())
        .toList();

    final int totalCount = tierBadges.isNotEmpty ? tierBadges.length : 5;
    final int unlockedCount = tierBadges.where((b) {
      final int badgeId = b['id'] ?? 0;
      return badgeProvider.earnedBadges.any(
        (eb) => (eb['badgeId'] ?? eb['badge']?['id']) == badgeId,
      );
    }).length;

    final double progressPercent = totalCount > 0 ? (unlockedCount / totalCount) : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        color: const Color(0xFF0284C7),
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Dark Indigo Top Header with Safe Area & Tier Filter Bar
              _buildDarkHeader(attendanceProvider.currentStreak),

              // 2. Main Body with subtle upward overlap
              Transform.translate(
                offset: const Offset(0, -22),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 3. Hero Progress Card for Selected Tier
                      _buildHeroProgressCard(unlockedCount, totalCount, progressPercent),
                      const SizedBox(height: 18),

                      // 4. Badges 2-Column Grid
                      _buildBadgesGrid(tierBadges, badgeProvider),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 1. Top Dark Indigo Header with Tier Filter Bar ─────────────────────────
  Widget _buildDarkHeader(int streakCount) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title & Streak Pill Row
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      if (widget.onBack != null) {
                        widget.onBack!();
                      } else if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1.2,
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Badges',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  // Streak Pill Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Text(
                          '$streakCount',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Unlock badges and showcase your achievements',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 16),

              // Horizontal Scrollable Tier Tabs Bar
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: _tierTabs.map((tier) {
                    final isSelected = _selectedTier.toLowerCase() == tier['name'].toString().toLowerCase();
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedTier = tier['name'];
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.25),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                tier['icon'] as IconData,
                                size: 14,
                                color: isSelected ? const Color(0xFF0284C7) : Colors.white70,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                tier['name'],
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? const Color(0xFF0284C7) : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 2. Hero Progress Card ──────────────────────────────────────────────────
  Widget _buildHeroProgressCard(int unlockedCount, int totalCount, double progressPercent) {
    final int percentInt = (progressPercent * 100).toInt();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Progress Stats & Bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_selectedTier Progress',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0284C7),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$unlockedCount',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E293B),
                        height: 1.0,
                      ),
                    ),
                    Text(
                      ' / $totalCount',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Badges Unlocked',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 12),

                // Linear Progress Indicator
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progressPercent > 0 ? progressPercent : 0.001,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE0F2FE),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$percentInt% Completed',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0284C7),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Right: Sleek Shield Badge Icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE0F2FE),
              border: Border.all(
                color: const Color(0xFFBAE6FD),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.shield_rounded,
              size: 40,
              color: Color(0xFF0284C7),
            ),
          ),
        ],
      ),
    );
  }

  // ── 3. 2-Column Badges Grid ────────────────────────────────────────────────
  Widget _buildBadgesGrid(List<dynamic> tierBadges, BadgeProvider badgeProvider) {
    if (tierBadges.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFF1F5F9),
              ),
              child: const Icon(Icons.lock_outline_rounded, size: 36, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 12),
            Text(
              'No badges available in $_selectedTier',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tierBadges.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.78,
      ),
      itemBuilder: (context, index) {
        final badge = tierBadges[index];
        final int badgeId = badge['id'] ?? 0;
        final String name = badge['name'] ?? 'Unknown Badge';
        final String desc = badge['description'] ?? '';

        final bool isEarned = badgeProvider.earnedBadges.any(
          (b) => (b['badgeId'] ?? b['badge']?['id']) == badgeId,
        );
        final bool isPending = badgeProvider.myBadgeRequests.any(
          (r) => r['badgeId'] == badgeId && r['status'] == 'PENDING',
        );
        final bool isRejected = badgeProvider.myBadgeRequests.any(
          (r) => r['badgeId'] == badgeId && r['status'] == 'REJECTED',
        );

        String? proofLink;
        if (isEarned || isPending || isRejected) {
          final req = badgeProvider.myBadgeRequests.firstWhere(
            (r) => r['badgeId'] == badgeId,
            orElse: () => null,
          );
          if (req != null && req['proofLink'] != null) {
            proofLink = req['proofLink'];
          } else if (isEarned) {
            final earned = badgeProvider.earnedBadges.firstWhere(
              (b) => (b['badgeId'] ?? b['badge']?['id']) == badgeId,
              orElse: () => null,
            );
            if (earned != null && earned['evidenceUrl'] != null) {
              proofLink = earned['evidenceUrl'];
            }
          }
        }

        return InkWell(
          onTap: () => _showBadgeDetailModal(badge, isEarned, isPending, isRejected, proofLink),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isEarned ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Top-Right Status Badge Indicator (Earned or Pending only)
                if (isEarned || isPending)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isEarned
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFFEF3C7),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isEarned
                            ? Icons.check_circle_rounded
                            : Icons.access_time_filled_rounded,
                        size: 14,
                        color: isEarned
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFD97706),
                      ),
                    ),
                  ),

                // Card Main Contents
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Badge Icon
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isEarned ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9),
                          border: Border.all(
                            color: isEarned ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          isEarned ? Icons.workspace_premium_rounded : Icons.lock_outline_rounded,
                          size: 30,
                          color: isEarned ? const Color(0xFFD97706) : const Color(0xFF94A3B8),
                        ),
                      ),
                    ),

                    // Badge Name & Description
                    Column(
                      children: [
                        Text(
                          name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          desc.isNotEmpty ? desc : 'Unlock by completing activities',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),

                    // Status Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: isEarned
                            ? const Color(0xFFDCFCE7)
                            : (isPending ? const Color(0xFFFEF3C7) : const Color(0xFFE0F2FE)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isEarned
                            ? 'CLAIMED'
                            : (isPending ? 'PENDING' : 'LOCKED'),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: isEarned
                              ? const Color(0xFF16A34A)
                              : (isPending ? const Color(0xFFD97706) : const Color(0xFF0284C7)),
                          letterSpacing: 0.4,
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
    );
  }

  // ── Badge Detail & Claim Modal ─────────────────────────────────────────────
  void _showBadgeDetailModal(
    Map<String, dynamic> badge,
    bool isEarned,
    bool isPending,
    bool isRejected,
    String? proofLink,
  ) {
    final int badgeId = badge['id'] ?? 0;
    final String name = badge['name'] ?? 'Unknown Badge';
    final String desc = badge['description'] ?? 'No description';
    final String authority = badge['approvalAuthority'] ?? 'Program Management';
    final String rarity = badge['rarity'] ?? 'Common';
    final dynamic rawProof = badge['proofRequired'];
    final bool proofRequired = rawProof is bool
        ? rawProof
        : (rawProof != null &&
            (rawProof.toString().toLowerCase() == 'true' || rawProof.toString() == '1'));
    final TextEditingController proofLinkController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card with Medal Image
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isEarned ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9),
                          ),
                          child: Icon(
                            isEarned ? Icons.workspace_premium_rounded : Icons.lock_outline_rounded,
                            size: 26,
                            color: isEarned ? const Color(0xFFD97706) : const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  color: Color(0xFF1E293B),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      rarity.toUpperCase(),
                                      style: const TextStyle(
                                        color: Color(0xFF0284C7),
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: proofRequired
                                          ? Colors.orange.withValues(alpha: 0.12)
                                          : Colors.blue.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      proofRequired ? 'PROOF REQUIRED' : 'NO PROOF NEEDED',
                                      style: TextStyle(
                                        color: proofRequired ? Colors.orange.shade800 : Colors.blue.shade700,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
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
                    const SizedBox(height: 16),
                    Text(
                      desc,
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Approval Authority: $authority',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (proofLink != null && proofLink.isNotEmpty) ...[
                      const Text(
                        'Submitted Proof Link',
                        style: TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () => ProofViewerUtils.openProof(
                          context,
                          proofLink,
                          title: 'Proof Link',
                        ),
                        child: Text(
                          proofLink,
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            decoration: TextDecoration.underline,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Badge Approval Workflow (3 Steps: Claim Submitted, Evaluator Review, Badge Issued)
                    const Text(
                      'Badge Approval Workflow',
                      style: TextStyle(
                        color: Color(0xFF1E293B),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildApprovalStep(1, 'Claim Submitted', 'Student requests badge via portal', true),
                    _buildApprovalStep(2, 'Evaluator Review', 'Verifies eligibility (1-3 days)', isEarned || isPending),
                    _buildApprovalStep(3, 'Badge Issued', 'Awarded to student profile', isEarned),

                    const SizedBox(height: 20),

                    // Claim / Status Button Actions
                    if (isEarned)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Badge Earned & Verified',
                            style: TextStyle(
                              color: Color(0xFF16A34A),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    else if (isPending)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Pending Approval',
                            style: TextStyle(
                              color: Color(0xFFD97706),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    else
                      Column(
                        children: [
                          if (isRejected)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Text(
                                'Previous claim rejected. You may resubmit.',
                                style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                              ),
                            ),
                          if (proofRequired)
                            TextField(
                              controller: proofLinkController,
                              decoration: const InputDecoration(
                                labelText: 'Evidence / Proof URL',
                                hintText: 'https://...',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0284C7),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () async {
                                final proof = proofLinkController.text.trim();
                                if (proofRequired && proof.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please provide proof URL')),
                                  );
                                  return;
                                }
                                Navigator.pop(context);
                                final bp = Provider.of<BadgeProvider>(context, listen: false);
                                final token = context.read<AuthProvider>().token ?? '';
                                final res = await bp.requestBadgeWorkflow(
                                  token,
                                  badgeId,
                                  proof,
                                );
                                final bool success = res['success'] == true;
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        success ? 'Badge claim submitted!' : 'Failed to submit claim',
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: const Text(
                                'Submit Badge Claim',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
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
        );
      },
    );
  }

  Widget _buildApprovalStep(int stepNum, String title, String desc, bool isDone) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone ? const Color(0xFF10B981) : Colors.grey.shade300,
            ),
            child: Center(
              child: isDone
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : Text(
                      '$stepNum',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDone ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                  ),
                ),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
