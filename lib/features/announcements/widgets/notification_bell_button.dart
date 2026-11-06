import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pragatix/features/announcements/pages/notifications_list_page.dart';
import 'package:pragatix/features/announcements/providers/notification_provider.dart';

class NotificationBellButton extends StatefulWidget {
  final Color iconColor;
  final double iconSize;
  final bool isDark;
  final EdgeInsetsGeometry padding;

  const NotificationBellButton({
    super.key,
    this.iconColor = const Color(0xFF1E293B),
    this.iconSize = 22,
    this.isDark = false,
    this.padding = EdgeInsets.zero,
  });

  @override
  State<NotificationBellButton> createState() => _NotificationBellButtonState();
}

class _NotificationBellButtonState extends State<NotificationBellButton> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<NotificationProvider>().fetchUnreadCount();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        final count = provider.unreadCount;
        final hasUnread = count > 0;

        return IconButton(
          padding: widget.padding,
          constraints: const BoxConstraints(),
          visualDensity: VisualDensity.compact,
          icon: Badge(
            isLabelVisible: hasUnread,
            label: Text(
              count > 99 ? '99+' : count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
            backgroundColor: const Color(0xFFEF4444), // Vibrant Red
            offset: const Offset(6, -6),
            child: Icon(
              hasUnread
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_outlined,
              color: hasUnread
                  ? (widget.isDark ? Colors.amberAccent : const Color(0xFF4F46E5))
                  : widget.iconColor,
              size: widget.iconSize,
            ),
          ),
          tooltip: hasUnread
              ? 'Notifications ($count unread)'
              : 'Notifications',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NotificationsListPage(),
              ),
            ).then((_) {
              if (mounted) {
                context.read<NotificationProvider>().fetchUnreadCount();
              }
            });
          },
        );
      },
    );
  }
}
