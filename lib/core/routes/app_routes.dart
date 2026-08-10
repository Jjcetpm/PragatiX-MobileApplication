/// Centralized named route constants for the SPDMS application.
///
/// These are string constants only — no routing logic is changed.
/// All existing Navigator.push() calls remain intact.
///
/// Named routes are available for future adoption:
///   Navigator.pushNamed(context, AppRoutes.login)
///
/// Or to register a named-route table in MaterialApp:
///   routes: AppRoutes.table(...)
abstract final class AppRoutes {
  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String login = '/';

  // ── Admin ─────────────────────────────────────────────────────────────────
  static const String adminDashboard = '/admin/dashboard';

  // ── Teacher ───────────────────────────────────────────────────────────────
  static const String teacherDashboard = '/teacher/dashboard';

  // ── Student ───────────────────────────────────────────────────────────────
  static const String studentDashboard = '/student/dashboard';

  // ── Captain ───────────────────────────────────────────────────────────────
  static const String captainDashboard = '/captain/dashboard';

  // ── Activity ──────────────────────────────────────────────────────────────
  static const String activityList = '/activity/list';
  static const String activityCreate = '/activity/create';
  static const String activityEdit = '/activity/edit';
}
