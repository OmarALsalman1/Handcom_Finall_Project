import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:handcom/core/l10n/app_strings.dart';
import 'package:handcom/features/auth/screens/chats_by_provider.dart';
import 'package:handcom/features/auth/screens/notifications_provider_page.dart';
import 'package:handcom/features/auth/screens/provider_map_screen.dart';
import 'dart:convert';

import 'package:handcom/core/config/api_config.dart';
import 'package:handcom/providers/user_auth_provider.dart';
import 'package:handcom/services/api_service.dart';
import 'package:handcom/services/notification_service.dart';
import 'package:handcom/services/request_service.dart';
import 'package:handcom/shared/widgets/theme_provider.dart';

import 'provider_profile_page.dart';
import 'order_appointments_page.dart';
import 'service_tracking_page.dart';

class ProviderHomePage extends StatefulWidget {
  const ProviderHomePage({super.key});

  @override
  State<ProviderHomePage> createState() => _ProviderHomePageState();
}

class _ProviderHomePageState extends State<ProviderHomePage> {
  static const Color primaryBlue = Color(0xFF1A3D81);
  static const Color accentOrange = Color(0xFFF58220);

  List<ServiceRequestModel> _orders = [];
  bool _loadingOrders = true;
  String _providerName = '';
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProviderData();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    final count = await NotificationModel.getUnreadCount();
    if (!mounted) return;
    setState(() => _unreadCount = count);
  }

  Future<void> _loadProviderData() async {
    // Fetch provider profile for the name
    try {
      final resp = await ApiService.get('${ApiConfig.baseUrl}/service-providers/me/');
      if (mounted && resp.statusCode == 200) {
        final data = jsonDecode(utf8.decode(resp.bodyBytes));
        final name = data['full_name'] as String? ?? '';
        setState(() => _providerName = name);
        context.read<UserAuthProvider>().setProfile(name: name);
      }
    } catch (_) {}

    // Fetch accepted/in-progress jobs for the home page
    final orders = await RequestService.getMyRequests();
    if (!mounted) return;
    setState(() {
      _orders = orders;
      _loadingOrders = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, UserAuthProvider>(
      builder: (context, themeProvider, auth, _) {
        final bool isDark = themeProvider.isDarkMode;

        final Color scaffoldBg =
            isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FB);
        final Color appBarBg =
            isDark ? const Color(0xFF1A1A1A) : primaryBlue;
        final Color cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final Color textColor = isDark ? Colors.white : primaryBlue;
        final Color titleColor = isDark ? Colors.white : Colors.black87;
        final Color subTextColor = isDark ? Colors.white60 : Colors.grey;

        final displayName = _providerName.isNotEmpty
            ? _providerName
            : (auth.name.isNotEmpty ? auth.name : auth.email);

        return Scaffold(
          backgroundColor: scaffoldBg,
          body: RefreshIndicator(
            onRefresh: _loadProviderData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildProviderHeader(
                      context, appBarBg, isDark, displayName, auth),
                  const SizedBox(height: 110),
                  _buildSectionTitle(context.l10n.myOrders, textColor),
                  _buildProviderOrdersList(
                      cardBg, titleColor, subTextColor, isDark),
                  const SizedBox(height: 30),
                  _buildOrdersButton(context),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          bottomNavigationBar: _buildBottomNav(context, isDark),
        );
      },
    );
  }

  Widget _buildProviderHeader(BuildContext context, Color appBarBg,
      bool isDark, String displayName, UserAuthProvider auth) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 220,
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
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
                                    builder: (_) =>
                                        const NotificationsProviderPage()),
                              );
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
                      IconButton(
                        icon: const Icon(Icons.person_outline,
                            color: Colors.white, size: 28),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ProviderProfilePage()),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 170,
          left: 30,
          right: 30,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [primaryBlue, accentOrange],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 115 : 66),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(context.l10n.welcomeProvider,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900)),
                Text(context.l10n.inHandcom,
                    style: const TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(title,
            style: TextStyle(
                color: textColor,
                fontSize: 25,
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildProviderOrdersList(Color cardBg, Color titleColor,
      Color subTextColor, bool isDark) {
    if (_loadingOrders) {
      return const Padding(
        padding: EdgeInsets.all(30),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_orders.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(30),
        child: Center(
          child: Text(context.l10n.noOrdersNow,
              style: TextStyle(color: subTextColor, fontSize: 15)),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];
        final bool isAr = context.l10n.isAr;
        return GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => ServiceTrackingPage(request: order))),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: isDark
                  ? Border.all(color: Colors.white10, width: 0.5)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 50 : 10),
                  blurRadius: 10,
                )
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.pending_actions,
                    color: Colors.orange, size: 28),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(order.serviceTypeLabel(isAr),
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: titleColor)),
                    Text(order.location,
                        style: TextStyle(
                            color: subTextColor, fontSize: 13)),
                  ],
                ),
                const SizedBox(width: 15),
                CircleAvatar(
                  radius: 25,
                  backgroundColor: isDark
                      ? const Color(0xFF2C2C2C)
                      : primaryBlue.withAlpha(25),
                  child: Text(
                    order.serviceTypeLabel(isAr).isNotEmpty
                        ? order.serviceTypeLabel(isAr).substring(0, 1)
                        : '؟',
                    style: TextStyle(
                        color: isDark ? accentOrange : primaryBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrdersButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: ElevatedButton(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const OrdersAppointmentsPage())),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 55),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30)),
          elevation: 5,
        ),
        child: Text(context.l10n.ordersBtn,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, bool isDark) {
    final Color navBg =
        isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color iconActiveColor =
        isDark ? accentOrange : primaryBlue;
    final Color iconInactiveColor =
        isDark ? Colors.white38 : Colors.grey;

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: navBg,
        border: Border(
            top: BorderSide(
                color: isDark ? Colors.white10 : Colors.black12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProviderProfilePage())),
            icon: Icon(Icons.person, size: 30, color: iconInactiveColor),
          ),
          IconButton(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ChatsByProvider())),
            icon: Icon(Icons.chat_bubble_outline,
                size: 28, color: iconInactiveColor),
          ),
          IconButton(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProviderMapScreen())),
            icon: Icon(Icons.location_on_outlined,
                size: 30, color: iconInactiveColor),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.home, size: 32, color: iconActiveColor),
          ),
        ],
      ),
    );
  }
}
