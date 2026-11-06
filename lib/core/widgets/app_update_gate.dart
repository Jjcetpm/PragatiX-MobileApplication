import 'package:flutter/material.dart';
import 'package:pragatix/core/services/app_version_service.dart';
import 'package:pragatix/core/error/pages/force_update_page.dart';

/// Intercepts the application hierarchy whenever a mandatory app update is required.
///
/// If the student's app version or build number is lower than the minimum required
/// by the institution, this gate completely hides all application pages, tabs,
/// and features, showing the ForceUpdatePage until the student updates their app.
class AppUpdateGate extends StatefulWidget {
  final Widget child;
  final bool autoCheckOnStart;

  const AppUpdateGate({
    super.key,
    required this.child,
    this.autoCheckOnStart = true,
  });

  @override
  State<AppUpdateGate> createState() => _AppUpdateGateState();
}

class _AppUpdateGateState extends State<AppUpdateGate> {
  @override
  void initState() {
    super.initState();
    if (widget.autoCheckOnStart) {
      AppVersionService.instance.checkAppVersion();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppVersionService.instance.isUpdateRequired,
      builder: (context, isRequired, _) {
        if (isRequired) {
          return const Directionality(
            textDirection: TextDirection.ltr,
            child: ForceUpdatePage(),
          );
        }
        return widget.child;
      },
    );
  }
}

