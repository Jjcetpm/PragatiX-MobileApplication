import 'package:flutter/material.dart';
import 'package:pragatix/features/activity/utils/constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Weekly cap choice chips selector.
// ─────────────────────────────────────────────────────────────────────────────

class CapSelector extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onChanged;
  final bool showError;

  const CapSelector({
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
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: ActivityConstants.capOptions.map((opt) {
            final isSelected = selected == opt;
            return _CapChip(
              label: opt,
              selected: isSelected,
              onTap: () => onChanged(opt),
            );
          }).toList(),
        ),
        if (showError && selected == null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Please select a weekly cap.',
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

class _CapChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const Color _primary = Color(0xFFEA4335);
  static const Color _dark = Color(0xFF1E293B);

  const _CapChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _primary : Colors.white,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: selected ? _primary : Colors.grey.shade300),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _primary.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : _dark,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
