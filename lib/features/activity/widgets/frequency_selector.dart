import 'package:flutter/material.dart';
import 'package:pragatix/features/activity/utils/constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Animated frequency selector tiles.
// ─────────────────────────────────────────────────────────────────────────────

class FrequencySelector extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onChanged;
  final bool showError;

  static const List<IconData> _icons = [
    Icons.today_outlined,
    Icons.date_range_outlined,
    Icons.fact_check_outlined,
    Icons.assignment_outlined,
    Icons.schedule_outlined,
  ];

  const FrequencySelector({
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
        ...List.generate(ActivityConstants.frequencies.length, (i) {
          final label = ActivityConstants.frequencies[i];
          final icon = _icons[i];
          final isSelected = selected == label;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _FrequencyTile(
              label: label,
              icon: icon,
              isSelected: isSelected,
              onTap: () => onChanged(label),
            ),
          );
        }),
        if (showError && selected == null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Please select a frequency.',
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

class _FrequencyTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  static const Color _primary = Color(0xFFEA4335);
  static const Color _dark = Color(0xFF1E293B);

  const _FrequencyTile({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isSelected ? _primary.withValues(alpha: 0.07) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? _primary : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: _primary.withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected ? _primary : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? _primary : _dark,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w400,
                      fontSize: 14,
                    ),
                  ),
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isSelected ? 1 : 0,
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: _primary,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
