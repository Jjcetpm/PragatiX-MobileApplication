// ─────────────────────────────────────────────────────────────────────────────
// Activity module – form validators.
// Static methods only. No UI code. No Flutter imports.
// ─────────────────────────────────────────────────────────────────────────────

class ActivityValidators {
  ActivityValidators._();

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Event name is required';
    }
    if (value.trim().length < 3) {
      return 'Name must be at least 3 characters';
    }
    return null;
  }

  static String? validateDescription(String? value) {
    // Description is optional – no validation required.
    return null;
  }

  static String? validateJustification(String? value) {
    // Justification is optional – no validation required.
    return null;
  }

  static String? validateFrequency(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select a frequency';
    }
    return null;
  }

  static String? validateEvidence(Set<String> selected) {
    if (selected.isEmpty) {
      return 'Select at least one evidence type';
    }
    return null;
  }

  static String? validateXp(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select an XP value';
    }
    return null;
  }

  static String? validateCap(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select a weekly cap';
    }
    return null;
  }

  static String? validateDepartment(dynamic value) {
    if (value == null) {
      return 'Department is required';
    }
    return null;
  }

  static String? validateTeacher(dynamic value) {
    if (value == null) {
      return 'Teacher selection is required';
    }
    return null;
  }
}
