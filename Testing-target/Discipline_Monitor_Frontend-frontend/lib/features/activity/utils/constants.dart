import 'package:pragatix/core/config/api_config.dart';
// ─────────────────────────────────────────────────────────────────────────────
// Activity module – shared constants.
// No Flutter imports here; this file is import-free (pure Dart).
// ─────────────────────────────────────────────────────────────────────────────

class ActivityConstants {
  ActivityConstants._();

  // ── API ──────────────────────────────────────────────────────────────────
  static const String baseUrl = '${ApiConfig.baseUrl}/api/v1/admin';

  // ── Form options ──────────────────────────────────────────────────────────
  static const List<String> frequencies = [
    'Daily',
    'Every Monday',
    'Daily → Checked Friday',
    'Daily → Weekly Log',
    'Every Period',
  ];

  static const List<String> evidenceOptions = [
    'Handwritten',
    'Soft Copy',
    'Diary / Notebook',
    'Weekly Log',
    'Direct Observation',
    'Attendance Register',
    'ERP Attendance',
    'Manual',
  ];

  static const List<String> xpOptions = [
    '20',
    '5/day',
    '10/day',
    '0 (Pass) / −40 (Fail)',
  ];

  static const List<String> capOptions = ['20/wk', '25/wk', '50/wk', 'No Cap'];
}
