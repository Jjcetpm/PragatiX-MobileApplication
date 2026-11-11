import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/features/banking/providers/banking_provider.dart';
import 'package:pragatix/features/banking/models/banking_models.dart';
import 'package:pragatix/features/banking/pages/admin_bank_details_page.dart';
import 'package:pragatix/features/banking/widgets/banking_preview_sheet.dart';
import 'package:pragatix/features/banking/widgets/banking_reset_sheet.dart';

class AdminBankingDashboardPage extends StatefulWidget {
  final VoidCallback? onBack;

  const AdminBankingDashboardPage({super.key, this.onBack});

  @override
  State<AdminBankingDashboardPage> createState() => _AdminBankingDashboardPageState();
}

class _AdminBankingDashboardPageState extends State<AdminBankingDashboardPage> {
  String _statusFilter = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().token ?? '';
      if (token.isNotEmpty) {
        context.read<BankingProvider>().loadAdminDashboard(
              token,
              status: _statusFilter.isNotEmpty ? _statusFilter : null,
            );
      }
    });
  }

  void _openBankDetails(BankModel bank, {int initialTab = 0}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminBankDetailsPage(bank: bank, initialTab: initialTab),
      ),
    ).then((_) => _loadData());
  }

  void _openBankSettings(BankModel bank) {
    _openBankDetails(bank, initialTab: 2);
  }

  void _openPreviewSheet(BankModel bank) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BankingPreviewBottomSheet(
        bank: bank,
        onExecutionCompleted: _loadData,
      ),
    );
  }

  void _openResetSheet(BankModel bank) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BankingResetBottomSheet(
        bank: bank,
        onResetCompleted: _loadData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Banking Management',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 18, color: Color(0xFF0F172A)),
                onPressed: widget.onBack,
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0F766E)),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Consumer<BankingProvider>(
        builder: (context, provider, child) {
          if (provider.loadingAdmin) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF0F766E)),
            );
          }

          final stats = provider.stats;
          final banks = provider.banks;

          return RefreshIndicator(
            onRefresh: () async => _loadData(),
            color: const Color(0xFF0F766E),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildKpiGrid(stats),
                const SizedBox(height: 18),
                _buildFilterChips(),
                const SizedBox(height: 14),
                if (banks.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    alignment: Alignment.center,
                    child: const Column(
                      children: [
                        Icon(Icons.account_balance_outlined,
                            size: 40, color: Color(0xFF94A3B8)),
                        SizedBox(height: 8),
                        Text(
                          'No Banking Periods Found',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF475569)),
                        ),
                      ],
                    ),
                  )
                else
                  ...banks.map((bank) => _buildBankCard(bank)),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildKpiGrid(BankDashboardStatsModel stats) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildKpiItem(
                'Active Banks',
                '${stats.activeBanks}',
                'Total: ${stats.totalBanks}',
                const Color(0xFF0F766E),
                Icons.account_balance_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKpiItem(
                'Net XP Banked',
                '+${stats.totalNetXpBanked}',
                'Penalties: -${stats.totalXpPenalties}',
                const Color(0xFF0284C7),
                Icons.trending_up_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildKpiItem(
                'Students Banked',
                '${stats.totalStudentsBanked}',
                'In finalized snapshots',
                const Color(0xFF7C3AED),
                Icons.people_alt_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKpiItem(
                'Last Execution',
                stats.lastExecutionStatus ?? 'N/A',
                stats.lastExecutionAt != null && stats.lastExecutionAt!.length >= 10
                    ? stats.lastExecutionAt!.substring(0, 10)
                    : 'No runs yet',
                const Color(0xFFD97706),
                Icons.history_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiItem(String title, String value, String subtitle, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.4,
                ),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('', 'All Statuses'),
          const SizedBox(width: 8),
          _buildFilterChip('ACTIVE', 'Active'),
          const SizedBox(width: 8),
          _buildFilterChip('DRAFT', 'Draft'),
          const SizedBox(width: 8),
          _buildFilterChip('COMPLETED', 'Completed'),
          const SizedBox(width: 8),
          _buildFilterChip('ARCHIVED', 'Archived'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _statusFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _statusFilter = value;
          });
          _loadData();
        }
      },
      selectedColor: const Color(0xFF0F766E),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? Colors.white : const Color(0xFF64748B),
      ),
      side: BorderSide(
        color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0),
      ),
    );
  }

  Widget _buildBankCard(BankModel bank) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bank.bankName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'CODE: ${bank.bankCode}',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: bank.status == 'ACTIVE'
                      ? const Color(0xFFCCFBF1)
                      : bank.status == 'COMPLETED'
                          ? const Color(0xFFE0F2FE)
                          : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  bank.status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: bank.status == 'ACTIVE'
                        ? const Color(0xFF0F766E)
                        : bank.status == 'COMPLETED'
                            ? const Color(0xFF0369A1)
                            : const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF94A3B8)),
              const SizedBox(width: 6),
              Text(
                '${bank.startDate} → ${bank.endDate}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const Divider(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                bank.lastExecutionAt != null
                    ? 'Last run: ${bank.executionStatus ?? "DONE"}'
                    : 'Never executed',
                style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, size: 19, color: Color(0xFF4F46E5)),
                    tooltip: 'Bank Settings & Restore',
                    onPressed: () => _openBankSettings(bank),
                  ),
                  IconButton(
                    icon: const Icon(Icons.restart_alt_rounded, size: 18, color: Color(0xFFE11D48)),
                    tooltip: 'Reset Balances',
                    onPressed: () => _openResetSheet(bank),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 19, color: Color(0xFFE11D48)),
                    tooltip: 'Delete Bank (Recycle Bin)',
                    onPressed: () => _confirmDeleteBank(bank),
                  ),
                  IconButton(
                    icon: const Icon(Icons.play_circle_outline_rounded, size: 20, color: Color(0xFF0F766E)),
                    tooltip: 'Preview & Execute',
                    onPressed: () => _openPreviewSheet(bank),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF64748B)),
                    tooltip: 'View Stages & Records',
                    onPressed: () => _openBankDetails(bank),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteBank(BankModel bank) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Bank?'),
        content: Text(
          'Are you sure you want to delete "${bank.bankName}" (${bank.bankCode})?\n\nIt will be moved to the Recycle Bin and can be restored anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete to Recycle Bin'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final token = context.read<AuthProvider>().token;
      if (token == null) return;
      final success = await context.read<BankingProvider>().deleteBank(token, bank.id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Bank "${bank.bankName}" moved to Recycle Bin')),
          );
        } else {
          final err = context.read<BankingProvider>().adminError ?? 'Failed to delete bank';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}
