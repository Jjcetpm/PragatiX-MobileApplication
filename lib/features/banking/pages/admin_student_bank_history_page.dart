import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/features/banking/models/banking_models.dart';
import 'package:pragatix/features/banking/services/banking_service.dart';

class AdminStudentBankHistoryPage extends StatefulWidget {
  final BankModel bank;
  final StudentBankingRecordModel record;

  const AdminStudentBankHistoryPage({
    super.key,
    required this.bank,
    required this.record,
  });

  @override
  State<AdminStudentBankHistoryPage> createState() => _AdminStudentBankHistoryPageState();
}

class _AdminStudentBankHistoryPageState extends State<AdminStudentBankHistoryPage> {
  StudentBankSummaryModel? _summary;
  List<StudentBankingTransactionModel> _transactions = [];
  bool _loading = true;
  String? _error;

  final String _search = '';
  String _typeFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final token = context.read<AuthProvider>().token ?? '';

    try {
      final service = BankingService(token: token);
      final results = await Future.wait([
        service.getStudentBankSummary(widget.bank.id, widget.record.studentId),
        service.getStudentBankTransactions(
          widget.bank.id,
          widget.record.studentId,
          search: _search.isNotEmpty ? _search : null,
          type: _typeFilter != 'ALL' ? _typeFilter : null,
        ),
      ]);

      if (mounted) {
        setState(() {
          _summary = results[0] as StudentBankSummaryModel;
          _transactions = results[1] as List<StudentBankingTransactionModel>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          widget.record.studentName,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: Color(0xFF0F172A),
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0D9488)),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0D9488)),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Color(0xFFEF4444)),
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildBankHeaderCard(),
                    const SizedBox(height: 16),
                    _buildStudentProfileCard(),
                    const SizedBox(height: 16),
                    _buildXpMetricsGrid(),
                    const SizedBox(height: 20),
                    _buildStageBreakdown(),
                    const SizedBox(height: 20),
                    _buildTransactionHistory(),
                    const SizedBox(height: 30),
                  ],
                ),
    );
  }

  Widget _buildBankHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFCCFBF1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_rounded, size: 20, color: Color(0xFF0F766E)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.bank.bankName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                  ),
                  Text(
                    '${widget.bank.bankCode} • ${widget.bank.startDate} to ${widget.bank.endDate}',
                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Finalized',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentProfileCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFF334155),
                radius: 18,
                child: Icon(Icons.person, color: Color(0xFF38BDF8), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.record.studentName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_summary?.bankRank != null || widget.record.bankRank != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.emoji_events_rounded, size: 12, color: Color(0xFFFDE047)),
                                const SizedBox(width: 4),
                                Text(
                                  'Rank #${_summary?.bankRank ?? widget.record.bankRank}',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFFEF08A)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      widget.record.registerNumber ?? 'ID: ${widget.record.studentId}',
                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFF334155), height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dept: ${widget.record.departmentName ?? '-'}',
                style: const TextStyle(fontSize: 11, color: Color(0xFFCBD5E1)),
              ),
              Text(
                'Year: ${widget.record.academicYear ?? '-'}',
                style: const TextStyle(fontSize: 11, color: Color(0xFFCBD5E1)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildXpMetricsGrid() {
    final awards = _summary?.currentPeriodAwards ?? widget.record.xpAwards;
    final penalties = _summary?.currentPeriodPenalties ?? widget.record.xpPenalties;
    final netBanked = _summary?.bankedXp ?? widget.record.netXpBanked;
    final lifetime = _summary?.lifetimeXp ?? widget.record.lifetimeXpSnapshot;
    final rank = _summary?.bankRank ?? widget.record.bankRank;

    return Row(
      children: [
        Expanded(
          child: _metricCard('Awards', '+$awards', const Color(0xFF0D9488), const Color(0xFFCCFBF1)),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _metricCard('Penalties', '-$penalties', const Color(0xFFE11D48), const Color(0xFFFFE4E6)),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _metricCard('Net Banked', '$netBanked', const Color(0xFF0284C7), const Color(0xFFE0F2FE)),
        ),
        if (rank != null) ...[
          const SizedBox(width: 6),
          Expanded(
            child: _metricCard('Bank Rank', '#$rank', const Color(0xFFD97706), const Color(0xFFFFFBEB)),
          ),
        ],
        const SizedBox(width: 6),
        Expanded(
          child: _metricCard('Lifetime XP', '$lifetime', const Color(0xFF7C3AED), const Color(0xFFEDE9FE)),
        ),
      ],
    );
  }

  Widget _metricCard(String label, String value, Color textCol, Color bgCol) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: textCol)),
        ],
      ),
    );
  }

  Widget _buildStageBreakdown() {
    final stages = _summary?.stageSummaries ?? [];
    if (stages.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'STAGE-WISE XP SUMMARY',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5),
          ),
          const SizedBox(height: 10),
          ...stages.map((stg) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(stg.stageName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    Text('+${stg.netXp} XP', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0D9488))),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildTransactionHistory() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'XP TRANSACTION HISTORY',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5),
              ),
              Text(
                '${_transactions.length} records',
                style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: ['ALL', 'AWARD', 'PENALTY'].map((t) {
              final isSel = _typeFilter == t;
              return GestureDetector(
                onTap: () {
                  setState(() => _typeFilter = t);
                  _loadData();
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSel ? const Color(0xFF0F766E) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    t,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isSel ? Colors.white : const Color(0xFF64748B),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          if (_transactions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('No transactions recorded for this bank.', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
              ),
            )
          else
            ..._transactions.map((tx) {
              final isPenalty = tx.isPenalty || tx.xpPoints < 0;
              final dateStr = tx.transactionDate.length >= 10 ? tx.transactionDate.substring(0, 10) : tx.transactionDate;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPenalty ? Icons.remove_circle_outline : Icons.add_circle_outline,
                      size: 16,
                      color: isPenalty ? const Color(0xFFE11D48) : const Color(0xFF0D9488),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.activityName,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                          ),
                          Text(
                            '$dateStr • ${tx.stageName ?? 'General'}',
                            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      isPenalty ? '-${tx.xpPoints.abs()} XP' : '+${tx.xpPoints} XP',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: isPenalty ? const Color(0xFFE11D48) : const Color(0xFF0D9488),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
