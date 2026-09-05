import 'package:flutter/material.dart';
import 'package:pragatix/core/services/server_status_service.dart';
import 'package:pragatix/core/error/pages/maintenance_page.dart';
import 'package:pragatix/core/error/pages/no_internet_page.dart';

/// Root gate widget that intercepts the app view hierarchy whenever:
/// 1. Device network/internet is OFF -> Displays dedicated NoInternetPage.
/// 2. Device network is ON, but backend server is down/in maintenance -> Displays MaintenancePage.
///
/// In either offline state:
/// - Completely hides and blocks all application pages, tabs, navigation drawers, and bottom bars.
/// - Disallows back-navigation via `PopScope(canPop: false)`.
/// - Allows user to tap "Retry", which re-checks connectivity and server health.
class ServerMaintenanceGate extends StatefulWidget {
  final Widget child;
  final bool enableAutoProbe;

  const ServerMaintenanceGate({
    super.key,
    required this.child,
    this.enableAutoProbe = true,
  });

  @override
  State<ServerMaintenanceGate> createState() => _ServerMaintenanceGateState();
}

class _ServerMaintenanceGateState extends State<ServerMaintenanceGate> {
  @override
  void initState() {
    super.initState();
    if (widget.enableAutoProbe) {
      ServerStatusService.instance.checkServerHealth();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ServerStatusService.instance.isNoInternetMode,
      builder: (context, isNoInternet, _) {
        if (isNoInternet) {
          return const PopScope(
            canPop: false,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Scaffold(
                backgroundColor: Color(0xFFF8FAFC),
                body: SafeArea(
                  child: NoInternetPage(),
                ),
              ),
            ),
          );
        }

        return ValueListenableBuilder<bool>(
          valueListenable: ServerStatusService.instance.isMaintenanceMode,
          builder: (context, isMaintenance, _) {
            if (isMaintenance) {
              return const PopScope(
                canPop: false,
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Scaffold(
                    backgroundColor: Color(0xFFF8FAFC),
                    body: SafeArea(
                      child: MaintenancePage(),
                    ),
                  ),
                ),
              );
            }
            return widget.child;
          },
        );
      },
    );
  }
}
