import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/auth/providers/auth_provider.dart';
import 'package:pragatix/features/banking/models/banking_models.dart';
import 'package:pragatix/features/banking/services/banking_service.dart';

class BankingRestoreBottomSheet extends StatefulWidget {
  final BankModel bank;
  final List<BankStageModel> stages;
  final Map<int, List<BankSubgroupModel>> subgroupsMap;
  final VoidCallback onRestoreCompleted;
  final String initialScope;
  final int? initialTargetStageId;
  final int? initialTargetSubgroupId;
  final String? initialStudentRegNo;

  const BankingRestoreBottomSheet({
    super.key,
    required this.bank,
    required this.stages,
    required this.subgroupsMap,
    required this.onRestoreCompleted,
    this.initialScope = 'ENTIRE_BANK',
    this.initialTargetStageId,
    this.initialTargetSubgroupId,
    this.initialStudentRegNo,
  });

  @override
  State<BankingRestoreBottomSheet> createState() => _BankingRestoreBottomSheetState();
}

class _BankingRestoreBottomSheetState extends State<BankingRestoreBottomSheet> {
  late String _selectedScope;
  int? _selectedStageId;
  int? _selectedSubgroupId;
  late final TextEditingController _studentRegNoController;
  final TextEditingController _reasonController = TextEditingController();

  RestorePreviewModel? _preview;
  bool _loadingPreview = false;
  bool _executing = false;
  bool _confirmed = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedScope = widget.initialScope;
    _selectedStageId = widget.initialTargetStageId;
    _selectedSubgroupId = widget.initialTargetSubgroupId;
    _studentRegNoController = TextEditingController(text: widget.initialStudentRegNo ?? '');
    _loadPreview();
  }

  @override
  void dispose() {
    _studentRegNoController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadPreview() async {
    setState(() {
      _loadingPreview = true;
      _errorMessage = null;
    });

    final token = context.read<AuthProvider>().token ?? '';
    final service = BankingService(token: token);

    try {
      final res = await service.previewRestore(
        bankId: widget.bank.id,
        scope: _selectedScope,
        targetStageId: _selectedStageId,
        targetSubgroupId: _selectedSubgroupId,
        targetStudentRegNo: _studentRegNoController.text.trim().isNotEmpty
            ? _studentRegNoController.text.trim()
            : null,
      );
      if (mounted) {
        setState(() {
          _preview = res;
          _loadingPreview = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _loadingPreview = false;
        });
      }
    }
  }

  Future<void> _handleExecuteRestore() async {
    final reason = _reasonController.text.trim();
    if (reason.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A valid audit reason is required for restoration.'),
          backgroundColor: Color(0xFFE11D48),
        ),
      );
      return;
    }

    setState(() {
      _executing = true;
      _errorMessage = null;
    });

    final token = context.read<AuthProvider>().token ?? '';
    final service = BankingService(token: token);

    try {
      await service.executeRestore(
        bankId: widget.bank.id,
        scope: _selectedScope,
        targetStageId: _selectedStageId,
        targetSubgroupId: _selectedSubgroupId,
        targetStudentRegNo: _studentRegNoController.text.trim().isNotEmpty
            ? _studentRegNoController.text.trim()
            : null,
        reason: reason,
        idempotencyKey: 'restore-mob-${widget.bank.id}-${DateTime.now().millisecondsSinceEpoch}',
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bank data restored successfully into active student balances.'),
            backgroundColor: Color(0xFF0F766E),
          ),
        );
        widget.onRestoreCompleted();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _executing = false;
        });
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
      child: SingleChildScrollView(
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
                      'Restore Banked Data',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF4338CA),
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

            // Preservation policy banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFC7D2FE)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.history_rounded, size: 18, color: Color(0xFF4F46E5)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Restoration re-activates previously banked XP back into current period balances. Finalized bank records and snapshots remain intact.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF3730A3)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Scope chips
            const Text(
              'SELECT RESTORE SCOPE',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildScopeChip('ENTIRE_BANK', 'Entire Bank'),
                _buildScopeChip('STAGE', 'By Stage'),
                _buildScopeChip('SUBGROUP', 'By Subgroup'),
                _buildScopeChip('INDIVIDUAL_STUDENT', 'Single Student'),
              ],
            ),
            const SizedBox(height: 12),

            // Scope-dependent inputs
            if (_selectedScope == 'STAGE') ...[
              DropdownButtonFormField<int>(
                initialValue: _selectedStageId,
                decoration: InputDecoration(
                  labelText: 'Select Stage to Restore',
                  labelStyle: const TextStyle(fontSize: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: widget.stages.map((stg) {
                  return DropdownMenuItem<int>(
                    value: stg.id,
                    child: Text(stg.stageName, style: const TextStyle(fontSize: 12)),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedStageId = val);
                  _loadPreview();
                },
              ),
              const SizedBox(height: 12),
            ],

            if (_selectedScope == 'SUBGROUP') ...[
              DropdownButtonFormField<int>(
                initialValue: _selectedSubgroupId,
                decoration: InputDecoration(
                  labelText: 'Select Subgroup to Restore',
                  labelStyle: const TextStyle(fontSize: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: widget.subgroupsMap.values.expand((list) => list).map((sub) {
                  return DropdownMenuItem<int>(
                    value: sub.id,
                    child: Text(sub.subgroupName, style: const TextStyle(fontSize: 12)),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedSubgroupId = val);
                  _loadPreview();
                },
              ),
              const SizedBox(height: 12),
            ],

            if (_selectedScope == 'INDIVIDUAL_STUDENT') ...[
              TextField(
                controller: _studentRegNoController,
                decoration: InputDecoration(
                  labelText: 'Student Register Number',
                  hintText: 'e.g. 21CS001',
                  labelStyle: const TextStyle(fontSize: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search_rounded, size: 18),
                    onPressed: _loadPreview,
                  ),
                ),
                onSubmitted: (_) => _loadPreview(),
              ),
              const SizedBox(height: 12),
            ],

            // Preview Section
            if (_loadingPreview)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
                ),
              )
            else if (_preview != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'RESTORATION PREVIEW',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Affected Students:', style: TextStyle(fontSize: 12, color: Color(0xFF475569))),
                        Text('${_preview!.affectedStudentCount}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('XP to Restore:', style: TextStyle(fontSize: 12, color: Color(0xFF475569))),
                        Text('+${_preview!.totalXpToRestore} XP', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF4338CA))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Transactions to Reactivate:', style: TextStyle(fontSize: 12, color: Color(0xFF475569))),
                        Text('${_preview!.transactionsToReactivateCount}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Current Period Total:', style: TextStyle(fontSize: 12, color: Color(0xFF475569))),
                        Text('${_preview!.currentPeriodTotalXp} XP → ${_preview!.expectedResultingTotalXp} XP', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F766E))),
                      ],
                    ),
                    if (_preview!.alreadyRestored) ...[
                      const Divider(height: 14),
                      Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFFD97706)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'This bank has already been restored on ${_preview!.lastRestoredAt ?? "earlier date"}. Duplicate restoration is blocked.',
                              style: const TextStyle(fontSize: 10.5, color: Color(0xFFB45309), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFECDD3)),
                ),
                child: Text(_errorMessage!, style: const TextStyle(fontSize: 11, color: Color(0xFFE11D48))),
              ),
              const SizedBox(height: 14),
            ],

            // Reason Input
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                labelText: 'Mandatory Audit Reason',
                hintText: 'e.g. Corrective restoration requested by HOD',
                labelStyle: const TextStyle(fontSize: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 12),

            // Confirmation Checkbox
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _confirmed,
              onChanged: (val) => setState(() => _confirmed = val ?? false),
              title: const Text(
                'I confirm this bank restoration operation. Reconciled XP will be immediately reflected in active student balances.',
                style: TextStyle(fontSize: 11, color: Color(0xFF334155)),
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 12),

            // Execute Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_confirmed &&
                        !_executing &&
                        _preview != null &&
                        _preview!.canRestore)
                    ? _handleExecuteRestore
                    : null,
                icon: _executing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.restore_page_rounded, size: 18, color: Colors.white),
                label: Text(
                  _executing ? 'Executing Restoration...' : 'Confirm & Restore Data',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4338CA),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScopeChip(String scope, String label) {
    final isSelected = _selectedScope == scope;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : const Color(0xFF475569),
        ),
      ),
      selected: isSelected,
      selectedColor: const Color(0xFF4338CA),
      backgroundColor: Colors.white,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedScope = scope;
            _preview = null;
          });
          _loadPreview();
        }
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: isSelected ? const Color(0xFF4338CA) : const Color(0xFFE2E8F0)),
      ),
    );
  }
}
