import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/activity/dialogs/manage_categories_dialog.dart';
import 'package:pragatix/features/activity/providers/activity_provider.dart';
import '../utils/validators.dart';

class ActivityBasicInformationSection extends StatelessWidget {
  final ActivityProvider? provider;
  final TextEditingController nameCtrl;
  final TextEditingController descCtrl;
  final TextEditingController displayOrderCtrl;
  final String? selectedXpCategory;
  final String selectedStatus;
  final bool submitted;
  final ValueChanged<String?> onXpCategoryChanged;
  final ValueChanged<String?> onStatusChanged;
  final bool isEdit;
  final String? selectedSubgroup;
  final ValueChanged<String?>? onSubgroupChanged;

  const ActivityBasicInformationSection({
    super.key,
    this.provider,
    required this.nameCtrl,
    required this.descCtrl,
    required this.displayOrderCtrl,
    this.selectedXpCategory,
    required this.selectedStatus,
    required this.submitted,
    required this.onXpCategoryChanged,
    required this.onStatusChanged,
    this.isEdit = false,
    this.selectedSubgroup,
    this.onSubgroupChanged,
  });

  static const Color _primary = Color(0xFF2563EB);
  static const Color _dark = Color(0xFF1E293B);
  static const Color _surface = Color(0xFFF8FAFC);

  static const List<String> _defaultCategories = [
    'Academic',
    'Skill',
    'Communication',
    'Leadership',
    'Discipline',
    'Placement',
    'Innovation',
    'Community',
    'Sports',
    'Cultural',
  ];

  InputDecoration _deco(String label, IconData icon, {bool alignHint = false}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _primary, size: 20),
      alignLabelWithHint: alignHint,
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

  void _openManageCategories(BuildContext context) async {
    final chosen = await ManageCategoriesDialog.show(
      context,
      provider: provider,
      onCategorySelected: (cat) {
        onXpCategoryChanged(cat);
      },
    );
    if (chosen != null) {
      onXpCategoryChanged(chosen);
    }
  }

  @override
  Widget build(BuildContext context) {
    ActivityProvider? activityProvider = provider;
    if (activityProvider == null) {
      try {
        activityProvider = context.watch<ActivityProvider>();
      } catch (_) {
        activityProvider = null;
      }
    }
    final List<String> activeCategories = (activityProvider != null && activityProvider.xpCategories.isNotEmpty)
        ? activityProvider.xpCategories
        : _defaultCategories;

    // Normalize or match selected value so DropdownButton never throws
    String? matchedCategoryValue;
    if (selectedXpCategory != null) {
      for (final cat in activeCategories) {
        if (cat.toLowerCase() == selectedXpCategory!.trim().toLowerCase()) {
          matchedCategoryValue = cat;
          break;
        }
      }
      // If not in the list, keep it in the dropdown list dynamically
      if (matchedCategoryValue == null && selectedXpCategory!.trim().isNotEmpty) {
        matchedCategoryValue = selectedXpCategory!.trim();
      }
    }

    final Set<String> dropdownItems = {
      ...activeCategories,
      ?matchedCategoryValue,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: nameCtrl,
          style: const TextStyle(color: _dark, fontSize: 15),
          decoration: _deco('Event Name', Icons.title_rounded),
          validator: ActivityValidators.validateName,
        ),
        const SizedBox(height: 16),

        // ── XP CATEGORY WITH MANAGE ACTION ───────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'XP Category *',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: _dark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        InputDecorator(
          decoration: _deco('Select Category', Icons.category_rounded).copyWith(
            errorText: (submitted && selectedXpCategory == null)
                ? 'XP Category is required'
                : null,
          ),
          child: DropdownButton<String>(
            dropdownColor: Colors.white,
            value: matchedCategoryValue,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            icon: const Icon(Icons.expand_more_rounded, color: _primary),
            hint: const Text(
              'Select XP Category',
              style: TextStyle(fontSize: 14),
            ),
            items: [
              ...dropdownItems.map((c) {
                return DropdownMenuItem<String>(
                  value: c,
                  child: Text(
                    c,
                    style: const TextStyle(fontSize: 14, color: _dark),
                  ),
                );
              }),
              const DropdownMenuItem<String>(
                value: '__MANAGE__',
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline_rounded, size: 16, color: _primary),
                    SizedBox(width: 8),
                    Text(
                      '+ Add / Manage Categories...',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _primary),
                    ),
                  ],
                ),
              ),
            ],
            onChanged: (val) {
              if (val == '__MANAGE__') {
                _openManageCategories(context);
              } else {
                onXpCategoryChanged(val);
              }
            },
          ),
        ),
        if (isEdit) ...[
          const SizedBox(height: 16),
          InputDecorator(
            decoration: _deco('Subgroup', Icons.group_work_rounded).copyWith(
              errorText: (submitted && selectedSubgroup == null)
                  ? 'Subgroup is required'
                  : null,
            ),
            child: DropdownButton<String>(
              dropdownColor: Colors.white,
              value: ['Must', 'Individual', 'Group'].contains(selectedSubgroup)
                  ? selectedSubgroup
                  : null,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              icon: const Icon(Icons.expand_more_rounded, color: _primary),
              hint: const Text(
                'Select Subgroup',
                style: TextStyle(fontSize: 14),
              ),
              items: {'Must', 'Individual', 'Group'}.map((s) {
                return DropdownMenuItem<String>(
                  value: s,
                  child: Text(
                    s,
                    style: const TextStyle(fontSize: 14, color: _dark),
                  ),
                );
              }).toList(),
              onChanged: onSubgroupChanged,
            ),
          ),
        ],
        const SizedBox(height: 16),
        TextFormField(
          controller: descCtrl,
          maxLines: 3,
          style: const TextStyle(color: _dark, fontSize: 15),
          decoration: _deco(
            'Description (Optional)',
            Icons.notes_rounded,
            alignHint: true,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: displayOrderCtrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: _dark, fontSize: 15),
          decoration: _deco('Display Order', Icons.sort_rounded),
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Display order is required';
            }
            if (int.tryParse(val) == null) {
              return 'Must be a valid integer';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        InputDecorator(
          decoration: _deco('Status', Icons.check_circle_outline_rounded),
          child: DropdownButton<String>(
            dropdownColor: Colors.white,
            value: ['ACTIVE', 'INACTIVE'].contains(selectedStatus) ? selectedStatus : 'ACTIVE',
            isExpanded: true,
            underline: const SizedBox.shrink(),
            icon: const Icon(Icons.expand_more_rounded, color: _primary),
            items: {'ACTIVE', 'INACTIVE'}.map((s) {
              return DropdownMenuItem<String>(
                value: s,
                child: Text(
                  s == 'ACTIVE' ? 'Active' : 'Inactive',
                  style: const TextStyle(fontSize: 14, color: _dark),
                ),
              );
            }).toList(),
            onChanged: onStatusChanged,
          ),
        ),
      ],
    );
  }
}
