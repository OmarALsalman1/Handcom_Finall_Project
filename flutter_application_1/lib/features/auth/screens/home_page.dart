import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:handcom/core/config/api_config.dart';
import 'package:handcom/core/l10n/app_strings.dart';
import 'package:handcom/features/auth/screens/carpentry_workers_page.dart';
import 'package:handcom/features/auth/screens/chat_list_screen.dart';
import 'package:handcom/features/auth/screens/electricity_workers_page.dart';
import 'package:handcom/features/auth/screens/map_screen.dart';
import 'package:handcom/features/auth/screens/paint_workers_page.dart';
import 'package:handcom/features/auth/screens/workers_list_page.dart';
import 'package:handcom/features/auth/screens/ai_assistant_page.dart';
import 'package:handcom/providers/user_auth_provider.dart';
import 'package:handcom/services/api_service.dart';
import 'package:handcom/services/notification_service.dart';
import 'package:handcom/services/request_service.dart';
import 'track_order_page.dart';
import 'profile_page.dart';
import 'notifications_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color primaryBlue = Color(0xFF1A3D81);
  static const Color accentOrange = Color(0xFFF58220);

  List<ServiceRequestModel> _requests = [];
  bool _loadingRequests = true;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadRequests();
    _loadUnreadCount();
    _loadProfileName();
  }

  Future<void> _loadProfileName() async {
    try {
      final response = await ApiService.get(ApiConfig.userMe);
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        context.read<UserAuthProvider>().setProfile(
              name: data['full_name'] ?? '',
              email: data['email'],
              address: data['address'],
            );
      }
    } catch (_) {}
  }

  Future<void> _loadRequests() async {
    final requests = await RequestService.getMyRequests();
    if (!mounted) return;
    setState(() {
      _requests = requests;
      _loadingRequests = false;
    });
  }

  Future<void> _loadUnreadCount() async {
    final count = await NotificationModel.getUnreadCount();
    if (!mounted) return;
    setState(() => _unreadCount = count);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color scaffoldBg =
        isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FB);
    final Color cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: RefreshIndicator(
        onRefresh: _loadRequests,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(context),
              const SizedBox(height: 10),
              _buildSectionTitle(context, context.l10n.availableServices),
              _buildServicesGrid(context, cardBg),
              const SizedBox(height: 25),
              _buildSectionTitle(context, context.l10n.recentOrders),
              _buildRecentOrdersList(context, cardBg, textColor),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, isDark),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final auth = context.watch<UserAuthProvider>();
    final displayName = auth.name.isNotEmpty ? auth.name : auth.email;

    return Column(
      children: [
        // Blue top bar
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: primaryBlue,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_none,
                                color: Colors.white, size: 30),
                            onPressed: () async {
                              await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const NotificationsPage()));
                              if (mounted) _loadUnreadCount();
                            },
                          ),
                          if (_unreadCount > 0)
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ProfilePage())),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white.withAlpha(50),
                          child: Text(
                            auth.initial,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.l10n.greet(displayName),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
        // AI card — pulled up to overlap the header
        Transform.translate(
          offset: const Offset(0, -20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildAICard(context),
          ),
        ),
      ],
    );
  }

  Widget _buildAICard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const AiAssistantPage())),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [primaryBlue, accentOrange]),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(38),
                blurRadius: 10,
                offset: const Offset(0, 5))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(context.l10n.aiAssistant,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                Text(context.l10n.aiSubtitle,
                    style: const TextStyle(color: Colors.white, fontSize: 13)),
              ],
            ),
            const SizedBox(width: 15),
            const CircleAvatar(
              backgroundColor: Color(0x33FFFFFF),
              radius: 28,
              child: Icon(Icons.auto_awesome, color: Colors.white, size: 28),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(title,
            style: TextStyle(
                color: isDark ? accentOrange : primaryBlue,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildServicesGrid(BuildContext context, Color cardBg) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.8,
          children: [
            _buildServiceItem(context, context.l10n.electricity, Icons.bolt, cardBg,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ElectricityWorkersPage()))),
            _buildServiceItem(context, context.l10n.plumbing, Icons.build, cardBg,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkersListPage()))),
            _buildServiceItem(context, context.l10n.painting, Icons.format_paint, cardBg,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaintWorkersPage()))),
            _buildServiceItem(context, context.l10n.carpentry, Icons.handyman, cardBg,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CarpentryWorkersPage()))),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceItem(BuildContext context, String title, IconData icon,
      Color cardBg, VoidCallback onTap) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
                color: isDark
                    ? Colors.black.withAlpha(66)
                    : Colors.black.withAlpha(10),
                blurRadius: 6)
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                  color: accentOrange, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 10),
            Text(title,
                style: TextStyle(
                    color: isDark ? Colors.white : primaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrdersList(
      BuildContext context, Color cardBg, Color textColor) {
    if (_loadingRequests) {
      return const Padding(
        padding: EdgeInsets.all(30),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_requests.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(30),
        child: Center(
          child: Text(context.l10n.noOrders,
              style: TextStyle(
                  color: textColor.withAlpha(150), fontSize: 15)),
        ),
      );
    }

    return Column(
      children: _requests
          .take(5)
          .map((r) => _buildOrderItem(context, r, cardBg, textColor))
          .toList(),
    );
  }

  Widget _buildOrderItem(BuildContext context, ServiceRequestModel r,
      Color cardBg, Color textColor) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isAr = context.l10n.isAr;
    final String firstLetter =
        r.serviceTypeLabel(isAr).isNotEmpty ? r.serviceTypeLabel(isAr).substring(0, 1) : '?';

    Color statusColor;
    switch (r.status) {
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'accepted':
      case 'in_progress':
        statusColor = Colors.blue;
        break;
      case 'completed':
        statusColor = Colors.green;
        break;
      default:
        statusColor = Colors.grey;
    }

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
            context, MaterialPageRoute(builder: (_) => TrackOrderPage(request: r)));
        if (mounted) _loadRequests();
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: isDark
                      ? Colors.black.withAlpha(66)
                      : Colors.black.withAlpha(10),
                  blurRadius: 6)
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: primaryBlue,
                child: Text(firstLetter,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.serviceTypeLabel(isAr),
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: textColor)),
                    if (r.providerName != null)
                      Text(r.providerName!,
                          style: TextStyle(
                              color: isDark ? Colors.white60 : Colors.grey,
                              fontSize: 13)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                    color: statusColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(10)),
                child: Text(r.statusLabel(isAr),
                    style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
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
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ProfilePage())),
            ),
            IconButton(
              icon:
                  Icon(Icons.chat_bubble_outline, color: iconColor, size: 26),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ChatListScreen())),
            ),
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AiAssistantPage())),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  gradient:
                      LinearGradient(colors: [primaryBlue, accentOrange]),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
              ),
            ),
            IconButton(
              icon: Icon(Icons.location_on_outlined, color: iconColor, size: 28),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MapScreen())),
            ),
            IconButton(
              icon: Icon(Icons.home, color: isDark ? accentOrange : primaryBlue, size: 28),
              onPressed: () {
                // Already on home — scroll to top / refresh
                _loadRequests();
              },
            ),
          ],
        ),
      ),
    );
  }
}
