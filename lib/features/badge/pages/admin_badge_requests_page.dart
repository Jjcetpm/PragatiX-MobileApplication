import 'package:flutter/material.dart';
import 'package:pragatix/core/widgets/pragatix_loader.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/features/badge/providers/badge_provider.dart';
import 'package:pragatix/features/badge/models/badge_request.dart';
import 'package:pragatix/features/badge/models/badge_item.dart';
import 'package:pragatix/features/badge/pages/admin_add_edit_badge_page.dart';
import 'package:pragatix/core/utils/proof_viewer_utils.dart';
import 'package:intl/intl.dart';

class AdminBadgeRequestsPage extends StatefulWidget {
  const AdminBadgeRequestsPage({super.key});

  @override
  State<AdminBadgeRequestsPage> createState() => _AdminBadgeRequestsPageState();
}

class _AdminBadgeRequestsPageState extends State<AdminBadgeRequestsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedStatus = 'PENDING';
  String _badgeSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    final token = context.read<AuthProvider>().token;
    if (token != null) {
      context.read<BadgeProvider>().fetchAdminCCBadgeRequests(token, 'ADMIN');
      context.read<BadgeProvider>().fetchAdminBadges(token);
    }
  }


  Widget _buildHeaderActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: const Color(0xFF334155), size: 20),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final badgeProvider = context.watch<BadgeProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton.extended(
              onPressed: () => _navigateToCreateOrEdit(),
              backgroundColor: const Color(0xFF2563EB),
              elevation: 4,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'Add Badge',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : null,
      body: Stack(
        children: [
          // Background mesh subtle gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 240,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFDCE8F6),
                    Color(0xFFE8EFF9),
                    Color(0xFFF4F7FB),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Top Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 16, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              'Badge Management & Requests',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.4,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Review student submissions & badges',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildHeaderActionButton(
                        icon: Icons.refresh_rounded,
                        tooltip: 'Refresh',
                        onPressed: _loadData,
                      ),
                    ],
                  ),
                ),

                // Modern segmented TabBar
                Container(
                  margin: const EdgeInsets.fromLTRB(18, 2, 18, 10),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF64748B).withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: const Color(0xFF64748B),
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    dividerColor: Colors.transparent,
                    onTap: (_) => setState(() {}),
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Requests'),
                            if (badgeProvider.pendingAdminCCRequestsCount > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _tabController.index == 0 ? Colors.white : const Color(0xFFEF4444),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${badgeProvider.pendingAdminCCRequestsCount}',
                                  style: TextStyle(
                                    color: _tabController.index == 0 ? const Color(0xFF2563EB) : Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Tab(text: 'Manage Badges'),
                    ],
                  ),
                ),

                // Tab Views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRequestsTab(badgeProvider),
                      _buildBadgesTab(badgeProvider),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 1: BADGE REQUESTS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildRequestsTab(BadgeProvider badgeProvider) {
    final requests = badgeProvider.adminCCBadgeRequests
        .map((json) => BadgeRequest.fromJson(json))
        .where((r) => r.status == _selectedStatus)
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
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
        Expanded(
          child: badgeProvider.isLoading
              ? const Center(child: PragatiXLoader())
              : requests.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'No $_selectedStatus badge requests found.',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async => _loadData(),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: requests.length,
                        itemBuilder: (context, index) {
                          return _buildRequestCard(requests[index]);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String status, BadgeProvider badgeProvider) {
    final isSelected = _selectedStatus == status;
    final int count = badgeProvider.adminCCBadgeRequests
        .where((r) => (r['status'] ?? '').toString().toUpperCase() == status)
        .length;

    Color chipColor;
    switch (status) {
      case 'APPROVED':
        chipColor = const Color(0xFF10B981);
        break;
      case 'REJECTED':
        chipColor = const Color(0xFFEF4444);
        break;
      default:
        chipColor = const Color(0xFFF59E0B);
    }

    return ChoiceChip(
      label: Text(
        count > 0 ? '$status ($count)' : status,
        style: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF64748B),
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 12.5,
        ),
      ),
      selected: isSelected,
      selectedColor: chipColor,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? chipColor : const Color(0xFFE2E8F0),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (selected) {
        if (selected) setState(() => _selectedStatus = status);
      },
    );
  }

  Widget _buildRequestCard(BadgeRequest req) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (req.badgeIcon.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: Image.network(
                      req.badgeIcon,
                      width: 44,
                      height: 44,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.shield, size: 44, color: Colors.amber),
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(right: 12.0),
                    child: Icon(Icons.shield, size: 44, color: Colors.amber),
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
                      const SizedBox(height: 2),
                      Text(
                        '${req.studentName} (${req.regNo})',
                        style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${req.departmentName} - ${req.sectionName} (${req.academicYear})',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'Requested: ${_formatDate(req.requestedAt)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 10.0),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.link, size: 16, color: Colors.blue.shade700),
                        const SizedBox(width: 6),
                        Text(
                          'View Proof Link',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            decoration: TextDecoration.underline,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      'No proof link required/attached',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            if (req.reviewedBy != null) ...[
              const SizedBox(height: 6),
              Text(
                'Reviewed By: ${req.reviewedBy}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
              if (req.reviewedAt != null)
                Text(
                  'Reviewed At: ${_formatDate(req.reviewedAt!)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
            ],
            if (req.remarks != null && req.remarks!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Remarks: ${req.remarks}',
                style: const TextStyle(fontSize: 12, color: Colors.redAccent, fontStyle: FontStyle.italic),
              ),
            ],
            if (req.status == 'PENDING') ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _handleReject(req.id),
                    icon: const Icon(Icons.close, size: 16, color: Colors.red),
                    label: const Text('Reject', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _handleApprove(req.id),
                    icon: const Icon(Icons.check, size: 16, color: Colors.white),
                    label: const Text('Approve', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message']),
          backgroundColor: res['success'] == true ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _handleReject(int id) async {
    final token = context.read<AuthProvider>().token;
    final res = await context.read<BadgeProvider>().rejectBadgeWorkflow(
      token!,
      id,
      'ADMIN',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message']),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 2: MANAGE BADGES (MASTER LIST, ADD, EDIT, DELETE)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildBadgesTab(BadgeProvider badgeProvider) {
    final badges = badgeProvider.adminBadges.where((b) {
      if (_badgeSearchQuery.isEmpty) return true;
      final q = _badgeSearchQuery.toLowerCase();
      return b.name.toLowerCase().contains(q) ||
          b.tier.toLowerCase().contains(q) ||
          b.description.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  style: const TextStyle(color: Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    hintText: 'Search badges by name, tier...',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B)),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                    ),
                  ),
                  onChanged: (val) => setState(() => _badgeSearchQuery = val),
                ),
              ),
              const SizedBox(width: 10),
              _buildHeaderActionButton(
                icon: Icons.refresh_rounded,
                tooltip: 'Refresh',
                onPressed: () {
                  final token = context.read<AuthProvider>().token;
                  if (token != null) {
                    badgeProvider.fetchAdminBadges(token);
                  }
                },
              ),
            ],
          ),
        ),

        // Badges Count Summary
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Badges: ${badgeProvider.adminBadges.length}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              OutlinedButton.icon(
                onPressed: () => _navigateToCreateOrEdit(),
                icon: const Icon(Icons.add, size: 16, color: Color(0xFFEA4335)),
                label: const Text('+ Add New Badge', style: TextStyle(color: Color(0xFFEA4335), fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFEA4335)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),

        // Badges List
        Expanded(
          child: badgeProvider.isLoading
              ? const Center(child: PragatiXLoader())
              : badges.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.workspace_premium_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            _badgeSearchQuery.isEmpty
                                ? 'No badges created yet.\nClick "+ Add New Badge" to create one.'
                                : 'No badges matching "$_badgeSearchQuery"',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        final token = context.read<AuthProvider>().token;
                        if (token != null) {
                          await badgeProvider.fetchAdminBadges(token);
                        }
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: badges.length,
                        itemBuilder: (context, index) {
                          return _buildBadgeMasterCard(badges[index]);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildBadgeMasterCard(BadgeItem badge) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Avatar
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: badge.iconUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            badge.iconUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.workspace_premium, color: Colors.amber, size: 32),
                          ),
                        )
                      : const Icon(Icons.workspace_premium, color: Colors.amber, size: 32),
                ),
                const SizedBox(width: 14),

                // Name & Tier / Rarity
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        badge.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _buildChip(badge.tier, Colors.indigo.shade50, Colors.indigo.shade700),
                          _buildChip(badge.rarity, Colors.purple.shade50, Colors.purple.shade700),
                          // Proof Link Indicator Chip
                          badge.proofRequired
                              ? _buildChip('Proof Required', Colors.green.shade50, Colors.green.shade800, icon: Icons.verified_user_rounded)
                              : _buildChip('No Proof Needed', Colors.grey.shade100, Colors.grey.shade700, icon: Icons.link_off_rounded),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Description
            if (badge.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                badge.description,
                style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
              ),
            ],

            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.admin_panel_settings_outlined, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'Approval Authority: ${badge.approvalAuthority}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),

            const Divider(height: 20),

            // Actions (Edit & Delete to Recycle Bin)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _navigateToCreateOrEdit(badge: badge),
                  icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF1E293B)),
                  label: const Text('Edit', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF1E293B)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => _confirmDeleteBadge(badge),
                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.white),
                  label: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color bg, Color text, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: text.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: text),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NAVIGATION TO FULL SCREEN ADD / EDIT BADGE PAGE
  // ═══════════════════════════════════════════════════════════════════════════

  void _navigateToCreateOrEdit({BadgeItem? badge}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminAddEditBadgePage(badge: badge),
      ),
    );
    if (mounted && result == true) {
      final token = context.read<AuthProvider>().token;
      if (token != null) {
        context.read<BadgeProvider>().fetchAdminBadges(token);
      }
    }
  }


  // ═══════════════════════════════════════════════════════════════════════════
  // DELETE BADGE (MOVE TO RECYCLE BIN)
  // ═══════════════════════════════════════════════════════════════════════════

  void _confirmDeleteBadge(BadgeItem badge) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Move to Recycle Bin?'),
          ],
        ),
        content: Text(
          'Are you sure you want to move the badge "${badge.name}" to the Recycle Bin?\n\nYou can restore it at any time from the Recycle Bin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              final token = context.read<AuthProvider>().token;
              if (token == null) return;

              final res = await context.read<BadgeProvider>().deleteBadge(token, badge.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res['message'] ?? 'Badge moved to Recycle Bin'),
                    backgroundColor: res['success'] == true ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Move to Recycle Bin'),
          ),
        ],
      ),
    );
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
