import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/activity/dialogs/manage_evidence_dialog.dart';
import 'package:pragatix/features/activity/providers/activity_provider.dart';
import 'package:pragatix/features/activity/utils/constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Evidence multi-select checkbox list with dynamic options & Add Button.
// ─────────────────────────────────────────────────────────────────────────────

class EvidenceSelector extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;
  final bool showError;
  final ActivityProvider? provider;

  static const Color _primary = Color(0xFF2563EB);
  static const Color _dark = Color(0xFF1E293B);

  const EvidenceSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.showError,
    this.provider,
  });

  ActivityProvider? _resolveProvider(BuildContext context) {
    if (provider != null) return provider;
    try {
      return context.watch<ActivityProvider>();
    } catch (_) {
      try {
        return context.read<ActivityProvider>();
      } catch (_) {
        return null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveProvider = _resolveProvider(context);

    Widget buildList() {
      final dynamicOptions = (effectiveProvider?.evidenceOptions.isNotEmpty == true
              ? effectiveProvider!.evidenceOptions
              : ActivityConstants.evidenceOptions)
          .where((e) => e.toLowerCase() != 'manual')
          .toList();

      final allOptions = <String>{...dynamicOptions, ...selected}
          .where((e) => e.toLowerCase() != 'manual')
          .toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select required evidence types',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...allOptions.map((opt) {
            final checked = selected.contains(opt);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Material(
                color: checked
                    ? _primary.withValues(alpha: 0.06)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: CheckboxListTile(
                  value: checked,
                  title: Text(
                    opt,
                    style: const TextStyle(fontSize: 14, color: _dark),
                  ),
                  activeColor: _primary,
                  checkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  onChanged: (val) {
                    final next = Set<String>.from(selected);
                    if (val == true) {
                      next.add(opt);
                    } else {
                      next.remove(opt);
                    }
                    onChanged(next);
                  },
                ),
              ),
            );
          }),

          const SizedBox(height: 10),

          // ── BUTTON BELOW EVIDENCE LIST TO ADD EVIDENCE ───────────────────
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: _primary,
              side: BorderSide(
                color: _primary.withValues(alpha: 0.4),
                width: 1.2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              backgroundColor: _primary.withValues(alpha: 0.04),
              minimumSize: const Size(double.infinity, 44),
            ),
            onPressed: () {
              ManageEvidenceDialog.show(
                context,
                provider: effectiveProvider,
                onEvidenceSelected: (newEv) {
                  final next = Set<String>.from(selected)..add(newEv);
                  onChanged(next);
                },
              );
            },
            icon: const Icon(Icons.add_circle_outline_rounded,
                size: 18, color: _primary),
            label: const Text(
              '+ Add New Evidence Type',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: _primary,
              ),
            ),
          ),

          if (showError && selected.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Select at least one evidence type.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      );
    }

    if (effectiveProvider != null) {
      return ListenableBuilder(
        listenable: effectiveProvider,
        builder: (context, _) => buildList(),
      );
    }
    return buildList();
  }
}
