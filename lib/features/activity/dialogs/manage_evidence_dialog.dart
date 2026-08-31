import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/activity/models/activity_evidence_item.dart';
import 'package:pragatix/features/activity/providers/activity_provider.dart';

class ManageEvidenceDialog extends StatefulWidget {
  final ActivityProvider? provider;
  final Function(String selectedEvidence)? onEvidenceSelected;

  const ManageEvidenceDialog({super.key, this.provider, this.onEvidenceSelected});

  static Future<String?> show(
    BuildContext context, {
    ActivityProvider? provider,
    Function(String)? onEvidenceSelected,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ManageEvidenceDialog(
        provider: provider,
        onEvidenceSelected: onEvidenceSelected,
      ),
    );
  }

  @override
  State<ManageEvidenceDialog> createState() => _ManageEvidenceDialogState();
}

class _ManageEvidenceDialogState extends State<ManageEvidenceDialog> {
  final TextEditingController _newEvidenceController = TextEditingController();
  final TextEditingController _newDescController = TextEditingController();

  bool _isAdding = false;
  String? _inlineError;

  ActivityProvider get _provider {
    if (widget.provider != null) return widget.provider!;
    return context.read<ActivityProvider>();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider.loadEvidenceTypes();
    });
  }

  @override
  void dispose() {
    _newEvidenceController.dispose();
    _newDescController.dispose();
    super.dispose();
  }

  Future<void> _handleAddEvidence() async {
    final name = _newEvidenceController.text.trim();
    if (name.isEmpty) {
      setState(() => _inlineError = 'Please enter an evidence name');
      return;
    }

    setState(() {
      _isAdding = true;
      _inlineError = null;
    });

    final newItem = await _provider.createEvidenceType(
      name,
      description: _newDescController.text.trim().isNotEmpty
          ? _newDescController.text.trim()
          : null,
    );

    if (mounted) {
      setState(() => _isAdding = false);
      if (newItem != null) {
        _newEvidenceController.clear();
        _newDescController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Evidence "${newItem.name}" added successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        widget.onEvidenceSelected?.call(newItem.name);
      } else {
        setState(() {
          _inlineError = _provider.error ?? 'Failed to add evidence type';
        });
      }
    }
  }

  Future<void> _handleEditEvidence(ActivityEvidenceItem ev) async {
    final editController = TextEditingController(text: ev.name);
    final descController = TextEditingController(text: ev.description ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.edit_rounded, color: Color(0xFFEA4335), size: 22),
            SizedBox(width: 8),
            Text('Edit Evidence Type',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: editController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Evidence Name *',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEA4335),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true && editController.text.trim().isNotEmpty && mounted) {
      final updated = await _provider.updateEvidenceType(
        ev.id,
        editController.text.trim(),
        description: descController.text.trim(),
      );
      if (mounted) {
        if (updated != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Evidence updated to "${updated.name}"'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          final err = _provider.error ?? 'Update failed';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _handleDeleteEvidence(ActivityEvidenceItem ev) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.red, size: 22),
            SizedBox(width: 8),
            Text('Delete Evidence Type',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Move evidence type "${ev.name}" to Recycle Bin?\n\n'
          'You can restore it anytime from the Recycle Bin.',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Move to Bin'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final ok = await _provider.deleteEvidenceType(ev.id);
      if (mounted) {
        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Evidence "${ev.name}" moved to Recycle Bin'),
              backgroundColor: Colors.orange.shade800,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          final err = _provider.error ?? 'Failed to delete';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _provider,
      builder: (context, _) {
        final evidences = _provider.activityEvidences;

        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 6,
          backgroundColor: Colors.white,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── HEADER ──────────────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEA4335).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.fact_check_outlined,
                          color: Color(0xFFEA4335), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Manage Evidence Types',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B)),
                          ),
                          Text(
                            '${evidences.length} evidence types configured',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: Colors.grey),
                      splashRadius: 20,
                    ),
                  ],
                ),
                const Divider(height: 24),

                // ── ADD NEW EVIDENCE INPUT ──────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ADD NEW EVIDENCE TYPE',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _newEvidenceController,
                              decoration: InputDecoration(
                                hintText: 'e.g. Github PR, Lab Record',
                                hintStyle: TextStyle(
                                    fontSize: 13, color: Colors.grey.shade400),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                              onSubmitted: (_) => _handleAddEvidence(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _isAdding ? null : _handleAddEvidence,
                            icon: _isAdding
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Add'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEA4335),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                      if (_inlineError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _inlineError!,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── LIST OF EVIDENCE TYPES ──────────────────────────────────
                Expanded(
                  child: evidences.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inventory_2_outlined,
                                  size: 40, color: Colors.grey.shade300),
                              const SizedBox(height: 8),
                              Text('No evidence types configured',
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 13)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: evidences.length,
                          separatorBuilder: (_, _) =>
                              const Divider(height: 1, indent: 12, endIndent: 12),
                          itemBuilder: (context, index) {
                            final ev = evidences[index];
                            return ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              leading: CircleAvatar(
                                radius: 15,
                                backgroundColor: const Color(0xFFEA4335)
                                    .withValues(alpha: 0.1),
                                child: Text(
                                  ev.name.isNotEmpty ? ev.name[0].toUpperCase() : 'E',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFEA4335),
                                  ),
                                ),
                              ),
                              title: Text(
                                ev.name,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E293B)),
                              ),
                              subtitle: (ev.description != null &&
                                      ev.description!.isNotEmpty)
                                  ? Text(
                                      ev.description!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade500),
                                    )
                                  : null,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Quick Use / Select button
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                    ),
                                    onPressed: () {
                                      widget.onEvidenceSelected?.call(ev.name);
                                      Navigator.pop(context, ev.name);
                                    },
                                    child: const Text('Use',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFFEA4335),
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined,
                                        size: 18, color: Color(0xFF64748B)),
                                    splashRadius: 18,
                                    tooltip: 'Edit Evidence',
                                    onPressed: () => _handleEditEvidence(ev),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 18,
                                        color: Colors.redAccent),
                                    splashRadius: 18,
                                    tooltip: 'Move to Recycle Bin',
                                    onPressed: () =>
                                        _handleDeleteEvidence(ev),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),

                const Divider(height: 16),

                // ── FOOTER / INFO NOTE ──────────────────────────────────────
                Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Deleted evidence types go to Recycle Bin and can be restored.',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Done',
                          style: TextStyle(fontWeight: FontWeight.bold)),
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
}
