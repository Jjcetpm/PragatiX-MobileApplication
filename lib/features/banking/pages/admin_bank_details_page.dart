import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/features/banking/models/banking_models.dart';
import 'package:pragatix/features/banking/services/banking_service.dart';
import 'package:pragatix/features/banking/widgets/banking_preview_sheet.dart';
import 'package:pragatix/features/banking/widgets/banking_reset_sheet.dart';
import 'package:pragatix/features/banking/widgets/banking_restore_sheet.dart';
import 'package:pragatix/features/banking/pages/admin_student_bank_history_page.dart';

class AdminBankDetailsPage extends StatefulWidget {
  final BankModel bank;
  final int initialTab;

  const AdminBankDetailsPage({
    super.key,
    required this.bank,
    this.initialTab = 0,
  });

  @override
  State<AdminBankDetailsPage> createState() => _AdminBankDetailsPageState();
}

class _AdminBankDetailsPageState extends State<AdminBankDetailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late BankModel _bank;

  List<BankStageModel> _stages = [];
  Map<int, List<BankSubgroupModel>> _subgroupsMap = {};
  List<StudentBankingRecordModel> _records = [];
  BankSettingsModel? _bankSettings;
  List<ResetHistoryModel> _resetHistories = [];
  List<RestoreHistoryModel> _restoreHistories = [];
  bool _showRestoreHistory = false;
  bool _loading = true;

  final TextEditingController _studentResetRegNoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _bank = widget.bank;
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 2),
    );
    _loadDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _studentResetRegNoController.dispose();
    super.dispose();
  }

  Future<void> _loadDetails() async {
    setState(() => _loading = true);
    final token = context.read<AuthProvider>().token ?? '';

    try {
      final service = BankingService(token: token);
      final refreshedBank = await service.getBankById(_bank.id);
      final stages = await service.getStages(_bank.id);

      final Map<int, List<BankSubgroupModel>> subMap = {};
      for (final stg in stages) {
        try {
          final subs = await service.getSubgroups(_bank.id, stg.id);
          subMap[stg.id] = subs;
        } catch (_) {
          subMap[stg.id] = [];
        }
      }

      final records = await service.getStudentRecords(_bank.id, size: 5000);

      BankSettingsModel? settings;
      try {
        settings = await service.getBankSettings(_bank.id);
      } catch (_) {}

      List<ResetHistoryModel> resetHistories = [];
      try {
        resetHistories = await service.getResetHistory(_bank.id);
      } catch (_) {}

      List<RestoreHistoryModel> restoreHistories = [];
      try {
        restoreHistories = await service.getRestoreHistory(_bank.id);
      } catch (_) {}

      if (mounted) {
        setState(() {
          _bank = refreshedBank;
          _stages = stages;
          _subgroupsMap = subMap;
          _records = records;
          _bankSettings = settings;
          _resetHistories = resetHistories;
          _restoreHistories = restoreHistories;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _openPreviewSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BankingPreviewBottomSheet(
        bank: _bank,
        onExecutionCompleted: _loadDetails,
      ),
    );
  }

  void _openResetSheet({
    String initialScope = 'ENTIRE_BANK',
    int? initialTargetId,
    String? initialTargetLabel,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BankingResetBottomSheet(
        bank: _bank,
        initialScope: initialScope,
        initialTargetId: initialTargetId,
        initialTargetLabel: initialTargetLabel,
        onResetCompleted: _loadDetails,
      ),
    );
  }

  void _openRestoreSheet({
    String initialScope = 'ENTIRE_BANK',
    int? initialTargetStageId,
    int? initialTargetSubgroupId,
    String? initialStudentRegNo,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BankingRestoreBottomSheet(
        bank: _bank,
        stages: _stages,
        subgroupsMap: _subgroupsMap,
        initialScope: initialScope,
        initialTargetStageId: initialTargetStageId,
        initialTargetSubgroupId: initialTargetSubgroupId,
        initialStudentRegNo: initialStudentRegNo,
        onRestoreCompleted: _loadDetails,
      ),
    );
  }

  Future<void> _confirmDeleteBank() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Bank?'),
        content: Text(
          'Are you sure you want to delete "${_bank.bankName}" (${_bank.bankCode})?\n\nIt will be moved to the Recycle Bin and can be restored anytime.',
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
      final success = await context.read<BankingProvider>().deleteBank(token, _bank.id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Bank "${_bank.bankName}" moved to Recycle Bin')),
          );
          Navigator.pop(context, true);
        } else {
          final err = context.read<BankingProvider>().adminError ?? 'Failed to delete bank';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _bank.bankName,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFE11D48)),
            tooltip: 'Delete Bank (Recycle Bin)',
            onPressed: _confirmDeleteBank,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0F766E)),
            onPressed: _loadDetails,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF0F766E),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF0F766E),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(text: 'Stages (${_stages.length})'),
            Tab(text: 'Records (${_records.length})'),
            const Tab(text: 'Settings & Restore'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0F766E)),
            )
          : Column(
              children: [
                _buildBankInfoBanner(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildStagesTab(),
                      _buildRecordsTab(),
                      _buildSettingsTab(),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openResetSheet(),
                  icon: const Icon(Icons.restart_alt_rounded, size: 16, color: Color(0xFFE11D48)),
                  label: const Text('Reset', style: TextStyle(color: Color(0xFFE11D48), fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFECDD3)),
                    backgroundColor: const Color(0xFFFFF1F2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openRestoreSheet(),
                  icon: const Icon(Icons.restore_page_rounded, size: 16, color: Color(0xFF4F46E5)),
                  label: const Text('Restore', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFC7D2FE)),
                    backgroundColor: const Color(0xFFEEF2FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _openPreviewSheet,
                  icon: const Icon(Icons.play_circle_filled_rounded, size: 18, color: Colors.white),
                  label: const Text('Preview & Execute', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBankInfoBanner() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CODE: ${_bank.bankCode}',
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _bank.status == 'ACTIVE' ? const Color(0xFFCCFBF1) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _bank.status,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: _bank.status == 'ACTIVE' ? const Color(0xFF0F766E) : const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${_bank.startDate} → ${_bank.endDate}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          if (_bank.description != null && _bank.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _bank.description!,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStagesTab() {
    if (_stages.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'No stages configured inside this bank yet.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _stages.length,
      itemBuilder: (context, index) {
        final stg = _stages[index];
        final subs = _subgroupsMap[stg.id] ?? [];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFCCFBF1),
              radius: 16,
              child: Icon(Icons.layers_rounded, size: 16, color: Color(0xFF0F766E)),
            ),
            title: Text(
              stg.stageName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
            ),
            subtitle: Text(
              '${stg.stageCode} | ${stg.startDate} → ${stg.endDate}',
              style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
            ),
            trailing: InkWell(
              onTap: () => _openResetSheet(
                initialScope: 'STAGE',
                initialTargetId: stg.id,
                initialTargetLabel: stg.stageName,
              ),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFECDD3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.restart_alt_rounded, size: 13, color: Color(0xFFE11D48)),
                    SizedBox(width: 4),
                    Text('Reset Stage', style: TextStyle(fontSize: 10, color: Color(0xFFE11D48), fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 12),
                    Text(
                      'SUBGROUPS (${subs.length})',
                      style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 6),
                    if (subs.isEmpty)
                      const Text('No subgroups in this stage.', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8)))
                    else
                      ...subs.map((sub) => Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFF1F5F9)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.hub_outlined, size: 14, color: Color(0xFF0D9488)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        sub.subgroupName,
                                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                      ),
                                      Text(
                                        sub.subgroupCode,
                                        style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                ),
                                InkWell(
                                  onTap: () => _openResetSheet(
                                    initialScope: 'SUBGROUP',
                                    initialTargetId: sub.id,
                                    initialTargetLabel: sub.subgroupName,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF1F2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFFECDD3)),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.restart_alt_rounded, size: 11, color: Color(0xFFE11D48)),
                                        SizedBox(width: 4),
                                        Text('Reset', style: TextStyle(fontSize: 9.5, color: Color(0xFFE11D48), fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecordsTab() {
    if (_records.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'No finalized student records found. Execute banking to create an immutable snapshot.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _records.length,
      itemBuilder: (context, index) {
        final rec = _records[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminStudentBankHistoryPage(
                      bank: _bank,
                      record: rec,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                rec.studentName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                            ],
                          ),
                          Text(
                            '${rec.registerNumber ?? rec.studentId} • ${rec.departmentName ?? ''}',
                            style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '+${rec.netXpBanked} XP',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF0F766E)),
                        ),
                        Text(
                          'Lifetime: ${rec.lifetimeXpSnapshot}',
                          style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsTab() {
    final settings = _bankSettings;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: General Settings
          _buildSettingsCard(
            title: '1. General Settings & Metrics',
            subtitle: 'Overview of banking status, snapshot metrics, and reset/restore state.',
            icon: Icons.settings_outlined,
            color: const Color(0xFF4338CA),
            child: Column(
              children: [
                _buildMetricRow('Bank Code & Name', '${_bank.bankCode} • ${_bank.bankName}'),
                _buildMetricRow('Banking Period', '${_bank.startDate} → ${_bank.endDate}'),
                _buildMetricRow('Bank Status', _bank.status),
                _buildMetricRow('Last Execution', _bank.lastExecutionAt ?? 'Never executed'),
                _buildMetricRow(
                  'Last Reset Status',
                  _bank.lastResetAt != null
                      ? '${_bank.lastResetStatus ?? "SUCCESS"} by ${_bank.lastResetBy ?? "Admin"} at ${_bank.lastResetAt}'
                      : 'Never Reset',
                ),
                _buildMetricRow(
                  'Last Restore Status',
                  _bank.lastRestoredAt != null
                      ? '${_bank.lastRestoredStatus ?? "RESTORED"} by ${_bank.lastRestoredBy ?? "Admin"} at ${_bank.lastRestoredAt}'
                      : 'Never Restored',
                ),
                const Divider(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatBox(
                        'Students Banked',
                        '${settings?.totalStudentsBanked ?? _records.length}',
                        const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatBox(
                        'Total Awards',
                        '+${settings?.totalXpBanked ?? 0} XP',
                        const Color(0xFF0F766E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatBox(
                        'Total Penalties',
                        '-${settings?.totalPenaltiesBanked ?? 0} XP',
                        const Color(0xFFE11D48),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatBox(
                        'Net Banked XP',
                        '+${settings?.netXpBanked ?? 0} XP',
                        const Color(0xFF4338CA),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Section 2: Overall XP Reset
          _buildSettingsCard(
            title: '2. Overall XP Reset',
            subtitle: 'Zero applicable current-period XP for all students in this bank.',
            icon: Icons.restart_alt_rounded,
            color: const Color(0xFFE11D48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Clears active student balances for this period to 0. Banked snapshots and historical records remain fully preserved.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openResetSheet(initialScope: 'ENTIRE_BANK'),
                    icon: const Icon(Icons.restart_alt_rounded, size: 16, color: Colors.white),
                    label: const Text('Execute Overall XP Reset', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE11D48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Section 3: Stage Points Reset
          _buildSettingsCard(
            title: '3. Stage Points Reset',
            subtitle: 'Reset current-period XP for a specific stage and recalculate its subgroups.',
            icon: Icons.layers_rounded,
            color: const Color(0xFF0D9488),
            child: _stages.isEmpty
                ? const Text('No stages found in this bank.', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)))
                : Column(
                    children: _stages.map((stg) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(stg.stageName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  Text(stg.stageCode, style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFF64748B))),
                                ],
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _openResetSheet(
                                initialScope: 'STAGE',
                                initialTargetId: stg.id,
                                initialTargetLabel: stg.stageName,
                              ),
                              icon: const Icon(Icons.restart_alt_rounded, size: 14, color: Color(0xFFE11D48)),
                              label: const Text('Reset Stage', style: TextStyle(fontSize: 10, color: Color(0xFFE11D48), fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFFECDD3)),
                                backgroundColor: const Color(0xFFFFF1F2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 16),

          // Section 4: Subgroup Points Reset
          _buildSettingsCard(
            title: '4. Subgroup Points Reset',
            subtitle: 'Reset points for a single subgroup while preserving the bank snapshot.',
            icon: Icons.hub_outlined,
            color: const Color(0xFF0284C7),
            child: _subgroupsMap.values.expand((e) => e).isEmpty
                ? const Text('No subgroups found in this bank.', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)))
                : Column(
                    children: _subgroupsMap.values.expand((e) => e).map((sub) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(sub.subgroupName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  Text(sub.subgroupCode, style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFF64748B))),
                                ],
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _openResetSheet(
                                initialScope: 'SUBGROUP',
                                initialTargetId: sub.id,
                                initialTargetLabel: sub.subgroupName,
                              ),
                              icon: const Icon(Icons.restart_alt_rounded, size: 14, color: Color(0xFFE11D48)),
                              label: const Text('Reset Subgroup', style: TextStyle(fontSize: 10, color: Color(0xFFE11D48), fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFFECDD3)),
                                backgroundColor: const Color(0xFFFFF1F2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 16),

          // Section 5: Student XP Reset
          _buildSettingsCard(
            title: '5. Student XP Reset',
            subtitle: 'Reset current period XP for an individual student by register number.',
            icon: Icons.person_outline_rounded,
            color: const Color(0xFFD97706),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _studentResetRegNoController,
                  decoration: InputDecoration(
                    labelText: 'Student Register Number',
                    hintText: 'e.g. 21CS001',
                    labelStyle: const TextStyle(fontSize: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final regNo = _studentResetRegNoController.text.trim();
                      if (regNo.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid student register number.'),
                            backgroundColor: Color(0xFFE11D48),
                          ),
                        );
                        return;
                      }
                      _openResetSheet(
                        initialScope: 'INDIVIDUAL_STUDENT',
                        initialTargetLabel: regNo,
                      );
                    },
                    icon: const Icon(Icons.restart_alt_rounded, size: 16, color: Colors.white),
                    label: const Text('Reset Student Balances', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Section 6: Restore Bank Data
          _buildSettingsCard(
            title: '6. Restore Bank Data',
            subtitle: 'Restore previously banked XP back into current period balances safely.',
            icon: Icons.restore_page_rounded,
            color: const Color(0xFF4338CA),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reconciles banked transactions and updates current student balances with server-side duplicate prevention and idempotency.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openRestoreSheet(),
                    icon: const Icon(Icons.restore_page_rounded, size: 16, color: Colors.white),
                    label: const Text('Configure & Preview Restore', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4338CA),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Sections 7 & 8: Reset & Restore History
          _buildSettingsCard(
            title: '7 & 8. Reset and Restore History',
            subtitle: 'Full auditable history of balance resets and data restorations for this bank.',
            icon: Icons.history_rounded,
            color: const Color(0xFF475569),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: Text('7. Reset History (${_resetHistories.length})', style: const TextStyle(fontSize: 11)),
                        selected: !_showRestoreHistory,
                        selectedColor: const Color(0xFFE2E8F0),
                        onSelected: (val) {
                          if (val) setState(() => _showRestoreHistory = false);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: Text('8. Restore History (${_restoreHistories.length})', style: const TextStyle(fontSize: 11)),
                        selected: _showRestoreHistory,
                        selectedColor: const Color(0xFFC7D2FE),
                        onSelected: (val) {
                          if (val) setState(() => _showRestoreHistory = true);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (!_showRestoreHistory) ...[
                  if (_resetHistories.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('No reset operations logged for this bank.', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                    )
                  else
                    ..._resetHistories.map((rst) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFECDD3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(rst.scope, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF991B1B))),
                                Text(rst.resetAt, style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text('Reason: ${rst.reason}', style: const TextStyle(fontSize: 11, color: Color(0xFF1E293B))),
                            Text('Executed by: ${rst.resetByName} • Students: ${rst.affectedStudentCount}', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                          ],
                        ),
                      );
                    }),
                ] else ...[
                  if (_restoreHistories.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('No restore operations logged for this bank.', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                    )
                  else
                    ..._restoreHistories.map((rst) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFC7D2FE)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(rst.scope, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF3730A3))),
                                Text(rst.createdAt, style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text('Restored XP: +${rst.totalXpRestored} XP', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4338CA))),
                            Text('Reason: ${rst.reason}', style: const TextStyle(fontSize: 11, color: Color(0xFF1E293B))),
                            Text('Executed by: ${rst.executedByName ?? rst.executedByUsername ?? "Admin"} • Students: ${rst.affectedStudentCount}', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                          ],
                        ),
                      );
                    }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.1),
                radius: 14,
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A))),
                    Text(subtitle, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}
