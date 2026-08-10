import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Activity type segmented button (Individual | Group).
// ─────────────────────────────────────────────────────────────────────────────

class TypeSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  static const Color _primary = Color(0xFFEA4335);
  static const Color _dark = Color(0xFF1E293B);

  static const List<String> _types = ['Individual', 'Group'];
  static const List<IconData> _icons = [
    Icons.person_rounded,
    Icons.group_rounded,
  ];

  const TypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_types.length, (i) {
        final type = _types[i];
        final icon = _icons[i];
        final isSelected = selected == type;
        final isFirst = i == 0;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: isFirst ? 8 : 0,
              left: isFirst ? 0 : 8,
            ),
            child: GestureDetector(
              onTap: () => onChanged(type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: isSelected ? _primary : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? _primary : Colors.grey.shade300,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: _primary.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  children: [
                    Icon(
                      icon,
                      color: isSelected ? Colors.white : Colors.grey.shade500,
                      size: 26,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      type,
                      style: TextStyle(
                        color: isSelected ? Colors.white : _dark,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
