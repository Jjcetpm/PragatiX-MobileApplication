import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/features/banking/providers/banking_provider.dart';
import 'package:pragatix/features/banking/models/banking_models.dart';

class BankingPreviewBottomSheet extends StatefulWidget {
  final BankModel bank;
  final VoidCallback onExecutionCompleted;

  const BankingPreviewBottomSheet({
    super.key,
    required this.bank,
    required this.onExecutionCompleted,
  });

  @override
  State<BankingPreviewBottomSheet> createState() => _BankingPreviewBottomSheetState();
}

class _BankingPreviewBottomSheetState extends State<BankingPreviewBottomSheet> {
  final TextEditingController _notesController = TextEditingController();
  bool _confirmed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().token ?? '';
      if (token.isNotEmpty) {
        context.read<BankingProvider>().loadPreview(token, widget.bank.id);
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _handleExecute() async {
    final token = context.read<AuthProvider>().token ?? '';
    final success = await context.read<BankingProvider>().executeBanking(
          token,
          widget.bank.id,
          notes: _notesController.text.trim(),
        );

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Banking executed and snapshotted successfully!'),
            backgroundColor: Color(0xFF0F766E),
          ),
        );
        widget.onExecutionCompleted();
      } else {
        final error = context.read<BankingProvider>().adminError ?? 'Execution failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: const Color(0xFFE11D48)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Consumer<BankingProvider>(
        builder: (context, provider, child) {
          if (provider.loadingPreview) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 40.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF0F766E)),
                  SizedBox(height: 16),
                  Text(
                    'Calculating preview against live XP records...',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            );
          }

          if (provider.previewError != null) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: Color(0xFFE11D48), size: 40),
                  const SizedBox(height: 12),
                  Text(
                    provider.previewError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                  ),
                ],
              ),
            );
          }

          final preview = provider.preview;
          if (preview == null) return const SizedBox.shrink();

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Execute Banking Snapshot',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '${widget.bank.bankName} (${widget.bank.bankCode})',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 20),

                // Overlap Warning
                if (preview.hasOverlappingBanks)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            size: 18, color: Color(0xFFD97706)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Warning: Overlaps detected with: ${preview.overlappingBankNames.join(', ')}. Each transaction is safely attributed only once.',
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF92400E)),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Preview Metrics Grid
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      _buildRow('Applicable Students', '${preview.eligibleStudentsCount} students'),
                      const Divider(height: 12),
                      _buildRow('Total XP Awards', '+${preview.totalXpAwards}', color: const Color(0xFF0D9488)),
                      const Divider(height: 12),
                      _buildRow('Total XP Penalties', '-${preview.totalXpPenalties}', color: const Color(0xFFE11D48)),
                      const Divider(height: 12),
                      _buildRow('Net Eligible XP', '+${preview.totalNetXp}', isBold: true, color: const Color(0xFF0F766E)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Audit Notes
                TextField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    hintText: 'Execution notes (e.g. End of Semester run)...',
                    hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 12),

                // Confirmation Checkbox
                Row(
                  children: [
                    Checkbox(
                      value: _confirmed,
                      activeColor: const Color(0xFF0F766E),
                      onChanged: (val) => setState(() => _confirmed = val ?? false),
                    ),
                    const Expanded(
                      child: Text(
                        'I confirm this banking calculation is verified and authorized.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF475569)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Execute Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: (!_confirmed || provider.executingAction)
                        ? null
                        : _handleExecute,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      disabledBackgroundColor: const Color(0xFF94A3B8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: provider.executingAction
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Execute Banking & Lock Records',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRow(String label, String value, {Color? color, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 14 : 12,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
            color: color ?? const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
