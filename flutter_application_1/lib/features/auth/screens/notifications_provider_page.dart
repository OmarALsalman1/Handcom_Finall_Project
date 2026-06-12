import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:handcom/shared/widgets/theme_provider.dart';
import 'package:handcom/services/notification_service.dart';
import 'package:handcom/features/auth/screens/provider_map_screen.dart';
import 'package:handcom/features/auth/screens/provider_home_page.dart';
import 'package:handcom/core/l10n/app_strings.dart';
import 'chats_by_provider.dart';
import 'chat_page.dart';
import 'service_tracking_page.dart';
import 'provider_profile_page.dart';

class NotificationsProviderPage extends StatefulWidget {
  const NotificationsProviderPage({super.key});

  @override
  State<NotificationsProviderPage> createState() =>
      _NotificationsProviderPageState();
}

class _NotificationsProviderPageState
    extends State<NotificationsProviderPage> {
  static const Color primaryBlue = Color(0xFF1A3D81);
  static const Color accentOrange = Color(0xFFF58220);

  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await NotificationService.getNotifications();
    if (!mounted) return;
    setState(() {
      _notifications = list;
      _isLoading = false;
    });
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> _markAllRead() async {
    await NotificationService.markAllRead();
    if (!mounted) return;
    setState(() {
      _notifications = _notifications
          .map((n) => NotificationModel(
                id: n.id,
                type: n.type,
                title: n.title,
                body: n.body,
                isRead: true,
                createdAt: n.createdAt,
              ))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final bool isDark = themeProvider.isDarkMode;
        final Color scaffoldBg =
            isDark ? const Color(0xFF121212) : const Color(0xFFF2F2F2);
        final Color appBarBg =
            isDark ? const Color(0xFF1A1A1A) : primaryBlue;
        final Color cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final Color textColor = isDark ? Colors.white : Colors.black;
        final Color subTextColor = isDark ? Colors.white60 : Colors.grey;

        return Scaffold(
          backgroundColor: scaffoldBg,
          bottomNavigationBar: _buildBottomNav(context, isDark),
          body: Column(
            children: [
              _buildHeader(context, appBarBg),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _notifications.isEmpty
                        ? Center(
                            child: Text(context.l10n.noNotifications,
                                style: TextStyle(
                                    color: subTextColor, fontSize: 16)),
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              physics:
                                  const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              itemCount: _notifications.length,
                              itemBuilder: (context, index) {
                                final n = _notifications[index];
                                return _buildCard(n, cardBg, textColor,
                                    subTextColor, isDark);
                              },
                            ),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, Color appBarBg) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: appBarBg,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios,
                        color: Colors.white, size: 25),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Row(
                    children: [
                      Text(context.l10n.notificationsTitle,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(width: 10),
                      const Icon(Icons.notifications_none,
                          color: Colors.white, size: 30),
                    ],
                  ),
                  TextButton(
                    onPressed: _unreadCount > 0 ? _markAllRead : null,
                    child: Text(
                      context.l10n.markAllRead,
                      style: TextStyle(
                          color: _unreadCount > 0
                              ? Colors.white70
                              : Colors.white38,
                          fontSize: 12),
                    ),
                  ),
                ],
              ),
              Text(
                _unreadCount > 0
                    ? context.l10n.newNotifCount(_unreadCount)
                    : context.l10n.noNewNotifications,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openNotification(NotificationModel n) async {
    if (!n.isRead) {
      await NotificationService.markRead(n.id);
      if (mounted) {
        setState(() {
          final idx = _notifications.indexWhere((x) => x.id == n.id);
          if (idx >= 0) _notifications[idx] = n.copyWith(isRead: true);
        });
      }
    }
    if (!mounted) return;

    if (n.type == 'new_message' && n.relatedConversationId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                ChatPage(conversationId: n.relatedConversationId)),
      );
      return;
    }

    if (n.relatedRequestId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                ServiceTrackingPage(requestId: n.relatedRequestId)),
      );
    }
  }

  Widget _buildCard(NotificationModel n, Color cardBg, Color textColor,
      Color subTextColor, bool isDark) {
    return GestureDetector(
      onTap: () => _openNotification(n),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: !n.isRead
              ? Border.all(
                  color: accentOrange.withValues(alpha: 0.5), width: 1)
              : (isDark
                  ? Border.all(color: Colors.white10, width: 0.5)
                  : null),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: n.isRead ? Colors.transparent : accentOrange,
                shape: BoxShape.circle,
              ),
            ),
            const Spacer(),
            Expanded(
              flex: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(n.title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: textColor),
                      textAlign: TextAlign.right),
                  const SizedBox(height: 3),
                  Text(n.body,
                      style: TextStyle(
                          color: isDark ? Colors.white60 : subTextColor,
                          fontSize: 13),
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(n.timeAgo,
                      style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.black26,
                          fontSize: 11),
                      textAlign: TextAlign.right),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(_iconFor(n.type),
                color: isDark ? accentOrange : primaryBlue, size: 26),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'new_message':
        return Icons.chat_bubble;
      case 'new_request':
        return Icons.build;
      case 'request_accepted':
        return Icons.check_circle_outline;
      case 'request_completed':
        return Icons.task_alt;
      case 'request_cancelled':
        return Icons.cancel_outlined;
      case 'new_rating':
        return Icons.star_outline;
      default:
        return Icons.notifications_none;
    }
  }

  Widget _buildBottomNav(BuildContext context, bool isDark) {
    final Color navBg =
        isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE8E8E8);
    final Color iconColor = isDark ? Colors.white60 : Colors.grey;

    return BottomAppBar(
      elevation: 20,
      color: navBg,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(Icons.person_outline, color: iconColor, size: 28),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const ProviderProfilePage())),
            ),
            IconButton(
              icon: Icon(Icons.chat_bubble_outline, color: iconColor, size: 26),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ChatsByProvider())),
            ),
            IconButton(
              icon:
                  Icon(Icons.location_on_outlined, color: iconColor, size: 28),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ProviderMapScreen())),
            ),
            IconButton(
              icon: Icon(Icons.home_outlined, color: iconColor, size: 28),
              onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ProviderHomePage()),
                  (_) => false),
            ),
          ],
        ),
      ),
    );
  }
}
