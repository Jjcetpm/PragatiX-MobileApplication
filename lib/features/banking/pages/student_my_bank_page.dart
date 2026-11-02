import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/features/banking/providers/banking_provider.dart';
import 'package:pragatix/features/banking/models/banking_models.dart';

class StudentMyBankPage extends StatefulWidget {
  final VoidCallback? onBack;

  const StudentMyBankPage({super.key, this.onBack});

  @override
  State<StudentMyBankPage> createState() => _StudentMyBankPageState();
}

class _StudentMyBankPageState extends State<StudentMyBankPage> {
  @override
  void initState() {
    super.initState();
    _fetchSummary();
  }

  void _fetchSummary() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().token ?? '';
      if (token.isNotEmpty) {
        context.read<BankingProvider>().loadStudentSummary(token);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'My Bank',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Color(0xFF0F172A),
          ),
        ),
        centerTitle: false,
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
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0284C7)),
            onPressed: _fetchSummary,
            tooltip: 'Refresh Banking Data',
          ),
        ],
      ),
      body: Consumer<BankingProvider>(
        builder: (context, provider, child) {
          if (provider.loadingStudent) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF0D9488)),
                  SizedBox(height: 16),
                  Text(
                    'Loading Banking Summary...',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            );
          }

          if (provider.studentError != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.account_balance_outlined,
                        size: 48, color: Color(0xFF94A3B8)),
                    const SizedBox(height: 12),
                    const Text(
                      'No Active Banking Information',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider.studentError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _fetchSummary,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final summary = provider.studentSummary;
          if (summary == null || summary.bankName.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'No banking period currently configured for your academic year.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _fetchSummary(),
            color: const Color(0xFF0D9488),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              children: [
                if (provider.applicableBanks.length > 1)
                  _buildBankSelectorChips(provider),
                _buildBankHeaderCard(summary),
                const SizedBox(height: 18),
                _buildXpMetricsGrid(summary),
                const SizedBox(height: 20),
                _buildStageBreakdownSection(summary),
                const SizedBox(height: 20),
                _buildRecentTransactionsSection(summary, provider),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBankSelectorChips(BankingProvider provider) {
    final token = context.read<AuthProvider>().token ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'YOUR APPLICABLE BANKS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '${provider.applicableBanks.length} available',
                style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: provider.applicableBanks.map((b) {
                final isSelected = b.bankId == provider.selectedBankId;
                return GestureDetector(
                  onTap: () {
                    if (b.bankId != null) {
                      provider.selectStudentBank(token, b.bankId!);
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF0F766E) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0),
                        width: isSelected ? 1.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF0F766E).withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              b.bankCode,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                                color: isSelected ? const Color(0xFF99F6E4) : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : (b.bankStatus == 'ACTIVE'
                                        ? const Color(0xFFCCFBF1)
                                        : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                b.bankStatus,
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : (b.bankStatus == 'ACTIVE'
                                          ? const Color(0xFF0D9488)
                                          : const Color(0xFF475569)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          b.bankName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Banked: ${b.bankedXp} XP • Net: +${b.netCurrentPeriodXp} XP',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? const Color(0xFFCCFBF1) : const Color(0xFF0D9488),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankHeaderCard(StudentBankSummaryModel summary) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF115E59)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  summary.bankCode,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: summary.bankStatus == 'ACTIVE'
                      ? const Color(0xFF34D399)
                      : Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  summary.bankStatus,
                  style: TextStyle(
                    color: summary.bankStatus == 'ACTIVE'
                        ? const Color(0xFF064E3B)
                        : Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            summary.bankName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.date_range_rounded, size: 14, color: Colors.white70),
              const SizedBox(width: 6),
              Text(
                '${summary.startDate} → ${summary.endDate}',
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ],
          ),
          if (summary.isFinalized) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDE047).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFDE047).withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFFFDE047)),
                      SizedBox(width: 6),
                      Text(
                        'Period XP Banked & Finalized',
                        style: TextStyle(
                          color: Color(0xFFFEF08A),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (summary.bankRank != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.emoji_events_rounded, size: 14, color: Color(0xFFFDE047)),
                        const SizedBox(width: 6),
                        Text(
                          'Final Rank: #${summary.bankRank}${summary.totalBankedStudents != null ? ' of ${summary.totalBankedStudents}' : ''}',
                          style: const TextStyle(
                            color: Color(0xFFFEF08A),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildXpMetricsGrid(StudentBankSummaryModel summary) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Current Period Net',
                value: '+${summary.netCurrentPeriodXp}',
                subtitle: 'Period awards minus penalties',
                valueColor: const Color(0xFF0D9488),
                icon: Icons.trending_up_rounded,
                bgColor: const Color(0xFFF0FDFA),
                borderColor: const Color(0xFFCCFBF1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Banked XP',
                value: '${summary.bankedXp}',
                subtitle: summary.isFinalized ? 'Finalized snapshot' : 'Pending execution',
                valueColor: const Color(0xFF0284C7),
                icon: Icons.shield_rounded,
                bgColor: const Color(0xFFF0F9FF),
                borderColor: const Color(0xFFBAE6FD),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Lifetime XP',
                value: '${summary.lifetimeXp}',
                subtitle: 'Total accumulated progression',
                valueColor: const Color(0xFF7C3AED),
                icon: Icons.stars_rounded,
                bgColor: const Color(0xFFFAF5FF),
                borderColor: const Color(0xFFE9D5FF),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Awards / Penalties',
                value: '+${summary.currentPeriodAwards} / -${summary.currentPeriodPenalties}',
                subtitle: 'Active timeframe tally',
                valueColor: const Color(0xFFD97706),
                icon: Icons.swap_vert_circle_rounded,
                bgColor: const Color(0xFFFFFBEB),
                borderColor: const Color(0xFFFDE68A),
                isSplit: true,
              ),
            ),
          ],
        ),
        if (summary.bankRank != null) ...[
          const SizedBox(height: 12),
          _buildMetricCard(
            title: 'Finalized Bank Rank',
            value: '#${summary.bankRank}',
            subtitle: summary.totalBankedStudents != null
                ? 'Out of ${summary.totalBankedStudents} students in this bank'
                : 'Final rank in this bank period',
            valueColor: const Color(0xFFD97706),
            icon: Icons.emoji_events_rounded,
            bgColor: const Color(0xFFFFFBEB),
            borderColor: const Color(0xFFFDE68A),
          ),
        ],
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required Color valueColor,
    required IconData icon,
    required Color bgColor,
    required Color borderColor,
    bool isSplit = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
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
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.4,
                ),
              ),
              Icon(icon, size: 16, color: valueColor),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isSplit ? 15 : 20,
              fontWeight: FontWeight.w900,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildStageBreakdownSection(StudentBankSummaryModel summary) {
    if (summary.stageSummaries.isEmpty) {
      return const SizedBox.shrink();
    }

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
          const Row(
            children: [
              Icon(Icons.layers_rounded, size: 18, color: Color(0xFF0F766E)),
              SizedBox(width: 8),
              Text(
                'Stage-wise XP Breakdown',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...summary.stageSummaries.map((stg) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stg.stageName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          stg.stageCode,
                          style: const TextStyle(
                            fontSize: 10,
                            fontFamily: 'monospace',
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      _buildChip('+${stg.xpAwards}', const Color(0xFF0D9488), const Color(0xFFCCFBF1)),
                      const SizedBox(width: 6),
                      _buildChip('-${stg.xpPenalties}', const Color(0xFFE11D48), const Color(0xFFFFE4E6)),
                      const SizedBox(width: 6),
                      _buildChip('Net: ${stg.netXp}', const Color(0xFF0F172A), const Color(0xFFE2E8F0), isBold: true),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildChip(String text, Color textColor, Color bgColor, {bool isBold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildRecentTransactionsSection(
      StudentBankSummaryModel summary, BankingProvider provider) {
    final hasDetailedTx = provider.studentTransactions.isNotEmpty;
    final hasRecentTx = summary.recentTransactions.isNotEmpty;

    if (!hasDetailedTx && !hasRecentTx) {
      return const SizedBox.shrink();
    }

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
              const Row(
                children: [
                  Icon(Icons.history_rounded, size: 18, color: Color(0xFF0284C7)),
                  SizedBox(width: 8),
                  Text(
                    'Banking Period Transactions',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              if (provider.loadingTransactions)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0D9488)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasDetailedTx)
            ...provider.studentTransactions.map((tx) {
              final isPenalty = tx.isPenalty || tx.xpPoints < 0;
              final dateStr = tx.transactionDate.length >= 10
                  ? tx.transactionDate.substring(0, 10)
                  : tx.transactionDate;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isPenalty ? const Color(0xFFFFE4E6) : const Color(0xFFCCFBF1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPenalty ? Icons.remove_circle_outline : Icons.add_circle_outline,
                        size: 16,
                        color: isPenalty ? const Color(0xFFE11D48) : const Color(0xFF0D9488),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.activityName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                dateStr,
                                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                              ),
                              if (tx.stageName != null) ...[
                                const Text(' • ', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                                Text(
                                  tx.stageName!,
                                  style: const TextStyle(fontSize: 10, color: Color(0xFF0D9488), fontWeight: FontWeight.w600),
                                ),
                              ],
                            ],
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
            })
          else
            ...summary.recentTransactions.map((tx) {
              final isPenalty = tx.type == 'PENALTY';
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isPenalty ? const Color(0xFFFFE4E6) : const Color(0xFFCCFBF1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPenalty ? Icons.remove_circle_outline : Icons.add_circle_outline,
                        size: 16,
                        color: isPenalty ? const Color(0xFFE11D48) : const Color(0xFF0D9488),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.activityTitle,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            tx.createdAt.length >= 10 ? tx.createdAt.substring(0, 10) : tx.createdAt,
                            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      isPenalty ? '-${tx.points} XP' : '+${tx.points} XP',
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
