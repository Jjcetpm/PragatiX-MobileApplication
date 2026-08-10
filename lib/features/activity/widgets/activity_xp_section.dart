import 'package:flutter/material.dart';

class ActivityXpSection extends StatelessWidget {
  final bool awardEnabled;
  final bool penaltyEnabled;
  final TextEditingController awardXpCtrl;
  final TextEditingController penaltyXpCtrl;
  final String selectedAwardType;
  final ValueChanged<bool> onAwardEnabledChanged;
  final ValueChanged<bool> onPenaltyEnabledChanged;
  final ValueChanged<String?> onAwardTypeChanged;

  const ActivityXpSection({
    super.key,
    required this.awardEnabled,
    required this.penaltyEnabled,
    required this.awardXpCtrl,
    required this.penaltyXpCtrl,
    required this.selectedAwardType,
    required this.onAwardEnabledChanged,
    required this.onPenaltyEnabledChanged,
    required this.onAwardTypeChanged,
  });

  static const Color _primary = Color(0xFFEA4335);
  static const Color _dark = Color(0xFF1E293B);
  static const Color _surface = Color(0xFFF8FAFC);

  InputDecoration _deco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _primary, size: 20),
      filled: true,
      fillColor: _surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'XP Configuration',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: _dark,
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          activeThumbColor: _primary,
          title: const Text(
            'Award XP',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: _dark,
            ),
          ),
          subtitle: const Text(
            'Award points when student satisfies the activity condition',
            style: TextStyle(fontSize: 12),
          ),
          value: awardEnabled,
          onChanged: onAwardEnabledChanged,
        ),
        if (awardEnabled) ...[
          const SizedBox(height: 8),
          TextFormField(
            key: const ValueKey('award_xp_field'),
            controller: awardXpCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: _dark, fontSize: 15),
            decoration: _deco(
              'Award XP Value',
              Icons.add_circle_outline_rounded,
            ),
            validator: (val) {
              if (!awardEnabled) return null;
              if (val == null || val.trim().isEmpty)
                return 'Award XP is required when enabled';
              final parsed = int.tryParse(val);
              if (penaltyEnabled) {
                if (parsed == null || parsed < 0)
                  return 'Must be a non-negative integer';
              } else {
                if (parsed == null || parsed <= 0)
                  return 'Must be a positive integer greater than zero';
              }
              return null;
            },
          ),
        ],
        const SizedBox(height: 16),
        SwitchListTile(
          activeThumbColor: _primary,
          title: const Text(
            'Penalty XP',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: _dark,
            ),
          ),
          subtitle: const Text(
            'Deduct points when student violates/fails the activity condition',
            style: TextStyle(fontSize: 12),
          ),
          value: penaltyEnabled,
          onChanged: onPenaltyEnabledChanged,
        ),
        if (penaltyEnabled) ...[
          const SizedBox(height: 8),
          TextFormField(
            key: const ValueKey('penalty_xp_field'),
            controller: penaltyXpCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: _dark, fontSize: 15),
            decoration: _deco(
              'Penalty XP Value',
              Icons.remove_circle_outline_rounded,
            ),
            validator: (val) {
              if (!penaltyEnabled) return null;
              if (val == null || val.trim().isEmpty)
                return 'Penalty XP is required when enabled';
              final parsed = int.tryParse(val);
              if (parsed == null || parsed <= 0)
                return 'Must be a positive integer greater than zero';
              return null;
            },
          ),
        ],
        if (!awardEnabled && !penaltyEnabled) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red.shade800),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'At least one toggle (Award XP or Penalty XP) must be enabled.',
                    style: TextStyle(
                      color: Colors.red.shade800,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        InputDecorator(
          decoration: _deco('Award Type', Icons.stars_rounded),
          child: DropdownButton<String>(
            dropdownColor: Colors.white,
            value: ['Fixed XP', 'Variable XP (future use)'].contains(selectedAwardType) ? selectedAwardType : 'Fixed XP',
            isExpanded: true,
            underline: const SizedBox.shrink(),
            icon: const Icon(Icons.expand_more_rounded, color: _primary),
            items: ['Fixed XP', 'Variable XP (future use)'].toSet().map((s) {
              return DropdownMenuItem<String>(
                value: s,
                child: Text(
                  s,
                  style: const TextStyle(fontSize: 14, color: _dark),
                ),
              );
            }).toList(),
            onChanged: onAwardTypeChanged,
          ),
        ),
      ],
    );
  }
}
