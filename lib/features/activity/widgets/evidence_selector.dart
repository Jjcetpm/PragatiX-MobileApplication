import 'package:flutter/material.dart';
import 'package:pragatix/features/activity/utils/constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Evidence multi-select checkbox list.
// ─────────────────────────────────────────────────────────────────────────────

class EvidenceSelector extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;
  final bool showError;

  static const Color _primary = Color(0xFFEA4335);
  static const Color _dark = Color(0xFF1E293B);

  const EvidenceSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.showError,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...ActivityConstants.evidenceOptions.map((opt) {
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
        if (showError && selected.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
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
}
