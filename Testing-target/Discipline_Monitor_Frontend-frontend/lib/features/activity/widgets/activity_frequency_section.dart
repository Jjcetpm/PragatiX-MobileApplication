import 'package:flutter/material.dart';

class ActivityFrequencySection extends StatelessWidget {
  final String selectedAwardFrequency;
  final Set<String> selectedAwardDays;
  final TextEditingController capCtrl;
  final bool submitted;
  final ValueChanged<String?> onFrequencyChanged;
  final ValueChanged<Set<String>> onDaysChanged;

  const ActivityFrequencySection({
    super.key,
    required this.selectedAwardFrequency,
    required this.selectedAwardDays,
    required this.capCtrl,
    required this.submitted,
    required this.onFrequencyChanged,
    required this.onDaysChanged,
  });

  static const Color _primary = Color(0xFFEA4335);
  static const Color _dark = Color(0xFF1E293B);
  static const Color _surface = Color(0xFFF8FAFC);

  static const List<String> _workingDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

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

  String _frequencyHint(String freq) {
    switch (freq) {
      case 'One Time':
        return 'XP is awarded only once to the student. No repetition allowed.';
      case 'Daily':
        return 'XP can be awarded once per day (resets at midnight).';
      case 'Weekly':
        return 'XP can be awarded on selected days. Cap resets every Monday.';
      case 'Monthly':
        return 'Cap resets at the start of each calendar month.';
      case 'Per Assignment':
        return 'XP is awarded for every assignment submission. No cap limit.';
      case 'Every Period':
        return 'XP can be awarded or penalized up to 8 times per day for each student.';
      case 'Manual':
        return 'XP is awarded manually by admin reset. Cap is fixed at 1.';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isWeekly = selectedAwardFrequency == 'Weekly';
    final bool isOneTimeOrManual =
        selectedAwardFrequency == 'One Time' ||
        selectedAwardFrequency == 'Manual';
    final bool isEveryPeriod = selectedAwardFrequency == 'Every Period';
    final bool isPerAssignment = selectedAwardFrequency == 'Per Assignment';

    final bool isCapDisabled =
        isOneTimeOrManual ||
        isEveryPeriod ||
        isPerAssignment;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InputDecorator(
          decoration: _deco('Award Frequency', Icons.repeat_rounded),
          child: DropdownButton<String>(
            dropdownColor: Colors.white,
            value: {
              'One Time',
              'Daily',
              'Weekly',
              'Monthly',
              'Per Assignment',
              'Every Period',
              'Week 1 (Once)',
              'Week 2 (Once)',
            }.contains(selectedAwardFrequency)
                ? selectedAwardFrequency
                : 'One Time',
            isExpanded: true,
            underline: const SizedBox.shrink(),
            icon: const Icon(Icons.expand_more_rounded, color: _primary),
            items: {
              'One Time',
              'Daily',
              'Weekly',
              'Monthly',
              'Per Assignment',
              'Every Period',
              'Week 1 (Once)',
              'Week 2 (Once)',
            }.toList().map((f) {
                  return DropdownMenuItem<String>(
                    value: f,
                    child: Text(
                      f,
                      style: const TextStyle(fontSize: 14, color: _dark),
                    ),
                  );
                }).toList(),
            onChanged: onFrequencyChanged,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _frequencyHint(selectedAwardFrequency),
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 16),
        if (isWeekly) ...[
          Container(
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: (submitted && selectedAwardDays.isEmpty)
                    ? Colors.red
                    : Colors.grey.shade300,
                width: (submitted && selectedAwardDays.isEmpty) ? 2 : 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      color: _primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Award Days',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: _dark,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => onDaysChanged(Set.from(_workingDays)),
                      child: const Text('All', style: TextStyle(fontSize: 12)),
                    ),
                    TextButton(
                      onPressed: () => onDaysChanged({}),
                      child: const Text(
                        'None',
                        style: TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _workingDays.map((day) {
                    final selected = selectedAwardDays.contains(day);
                    return FilterChip(
                      label: Text(
                        day.substring(0, 3),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : _dark,
                        ),
                      ),
                      selected: selected,
                      selectedColor: _primary,
                      checkmarkColor: Colors.white,
                      backgroundColor: Colors.grey.shade100,
                      onSelected: (val) {
                        final newSet = Set<String>.from(selectedAwardDays);
                        if (val) {
                          newSet.add(day);
                        } else {
                          newSet.remove(day);
                        }
                        onDaysChanged(newSet);
                      },
                    );
                  }).toList(),
                ),
                if (submitted && selectedAwardDays.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'At least one Award Day is required for Weekly frequency.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        AbsorbPointer(
          absorbing: isCapDisabled,
          child: Opacity(
            opacity: isCapDisabled ? 0.5 : 1.0,
            child: TextFormField(
              controller: capCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: _dark, fontSize: 15),
              decoration: _deco(
                isEveryPeriod
                    ? 'Cap (fixed at 8)'
                    : (isPerAssignment
                          ? 'Cap (Unlimited)'
                          : (isOneTimeOrManual
                                ? 'Cap (fixed at 1)'
                                : 'Cap (max awards per frequency window)')),
                Icons.bar_chart_rounded,
              ),
              validator: (val) {
                if (isCapDisabled) return null;
                if (val == null || val.trim().isEmpty) return 'Cap is required';
                final parsed = int.tryParse(val);
                if (parsed == null || parsed <= 0)
                  return 'Must be an integer greater than zero';
                return null;
              },
            ),
          ),
        ),
      ],
    );
  }
}
