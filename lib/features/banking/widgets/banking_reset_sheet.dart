import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/features/banking/providers/banking_provider.dart';
import 'package:pragatix/features/banking/models/banking_models.dart';

class BankingResetBottomSheet extends StatefulWidget {
  final BankModel bank;
  final VoidCallback onResetCompleted;
  final String initialScope;
  final int? initialTargetId;
  final String? initialTargetLabel;

  const BankingResetBottomSheet({
    super.key,
    required this.bank,
    required this.onResetCompleted,
    this.initialScope = 'ENTIRE_BANK',
    this.initialTargetId,
    this.initialTargetLabel,
  });

  @override
  State<BankingResetBottomSheet> createState() => _BankingResetBottomSheetState();
}

class _BankingResetBottomSheetState extends State<BankingResetBottomSheet> {
  late String _selectedScope;
  late final TextEditingController _targetIdController;
  final TextEditingController _reasonController = TextEditingController();
  bool _confirmed = false;

  @override
  void initState() {
    super.initState();
    _selectedScope = widget.initialScope;
    _targetIdController = TextEditingController(
      text: widget.initialTargetId != null ? widget.initialTargetId.toString() : '',
    );
  }

  @override
  void dispose() {
    _targetIdController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _handleReset() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A detailed audit reason is required for resets.'),
          backgroundColor: Color(0xFFE11D48),
        ),
      );
      return;
    }

    final token = context.read<AuthProvider>().token ?? '';
    int? targetId;
    if (_targetIdController.text.trim().isNotEmpty) {
      targetId = int.tryParse(_targetIdController.text.trim());
    }

    final success = await context.read<BankingProvider>().executeReset(
          token: token,
          bankId: widget.bank.id,
          scope: _selectedScope,
          targetId: targetId,
          reason: reason,
        );

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Current-period balances reset successfully.'),
            backgroundColor: Color(0xFF0F766E),
          ),
        );
        widget.onResetCompleted();
      } else {
        final error = context.read<BankingProvider>().adminError ?? 'Reset failed';
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
                          'Reset Banking Balances',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF991B1B),
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
                const Divider(height: 18),

                // Notice
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFECDD3)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.shield_outlined, size: 18, color: Color(0xFFE11D48)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Safe Reset Policy: Resets affect active current-period calculations only. Historical XP transactions and finalized banking records are never deleted.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF9F1239)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'SELECT RESET SCOPE',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 8),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildScopeChip('ENTIRE_BANK', 'Entire Bank'),
                    _buildScopeChip('STAGE', 'Specific Stage'),
                    _buildScopeChip('SUBGROUP', 'Specific Subgroup'),
                    _buildScopeChip('INDIVIDUAL_STUDENT', 'Single Student'),
                  ],
                ),
                const SizedBox(height: 14),

                if (_selectedScope != 'ENTIRE_BANK') ...[
                  TextField(
                    controller: _targetIdController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: _selectedScope == 'STAGE'
                          ? 'Stage ID'
                          : _selectedScope == 'SUBGROUP'
                              ? 'Subgroup ID'
                              : 'Student ID',
                      labelStyle: const TextStyle(fontSize: 12),
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
                ],

                TextField(
                  controller: _reasonController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Audit Reason *',
                    labelStyle: const TextStyle(fontSize: 12),
                    hintText: 'Explain why this balance reset is requested...',
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

                Row(
                  children: [
                    Checkbox(
                      value: _confirmed,
                      activeColor: const Color(0xFFE11D48),
                      onChanged: (val) => setState(() => _confirmed = val ?? false),
                    ),
                    const Expanded(
                      child: Text(
                        'I confirm this balance adjustment is authorized and auditable.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF475569)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: (!_confirmed || provider.executingAction)
                        ? null
                        : _handleReset,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE11D48),
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
                            'Execute Authorized Reset',
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

  Widget _buildScopeChip(String value, String label) {
    final isSelected = _selectedScope == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedScope = value;
          });
        }
      },
      selectedColor: const Color(0xFFFFE4E6),
      backgroundColor: const Color(0xFFF8FAFC),
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? const Color(0xFF9F1239) : const Color(0xFF64748B),
      ),
      side: BorderSide(
        color: isSelected ? const Color(0xFFE11D48) : const Color(0xFFE2E8F0),
      ),
    );
  }
}
