import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:handcom/features/auth/screens/ai_assistant_page.dart';
import 'package:handcom/features/auth/screens/map_screen.dart';
import 'package:handcom/features/auth/screens/settings_user_page.dart';
import 'package:handcom/providers/user_auth_provider.dart';
import 'package:handcom/services/api_service.dart';
import 'package:handcom/core/config/api_config.dart';
import 'package:handcom/core/l10n/app_strings.dart';
import 'package:handcom/shared/widgets/theme_provider.dart';

import 'home_page.dart';
import 'favorite_options_page.dart';
import 'account_info_page.dart';
import 'chat_list_screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const Color primaryBlue = Color(0xFF1A3D81);
  static const Color accentOrange = Color(0xFFF58220);

  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final response = await ApiService.get('${ApiConfig.baseUrl}/users/me/');
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
    if (mounted) setState(() => _loadingProfile = false);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, UserAuthProvider>(
      builder: (context, themeProvider, auth, child) {
        final bool isDark = themeProvider.isDarkMode;
        final Color scaffoldBg =
            isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FB);
        final Color appBarBg =
            isDark ? const Color(0xFF1A1A1A) : primaryBlue;
        final Color cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final Color textColor = isDark ? Colors.white : primaryBlue;

        return Scaffold(
          backgroundColor: scaffoldBg,
          bottomNavigationBar: _buildBottomNav(context, isDark),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildProfileHeader(
                    context, auth, appBarBg, cardBg, textColor, isDark),
                const SizedBox(height: 120),
                _buildMenuOption(
                  title: context.l10n.accountInfo,
                  subtitle: context.l10n.personalDetails,
                  icon: Icons.person_outline,
                  cardBg: cardBg,
                  textColor: textColor,
                  isDark: isDark,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AccountInfoPage())),
                ),
                _buildMenuOption(
                  title: context.l10n.settingsTitle,
                  icon: Icons.settings_outlined,
                  cardBg: cardBg,
                  textColor: textColor,
                  isDark: isDark,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SettingsUserPage())),
                ),
                _buildMenuOption(
                  title: context.l10n.favoriteOptions,
                  icon: Icons.bookmark_outline,
                  cardBg: cardBg,
                  textColor: textColor,
                  isDark: isDark,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const FavoriteOptionsPage())),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserAuthProvider auth,
      Color appBarBg, Color cardBg, Color textColor, bool isDark) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 240,
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
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white, size: 24),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(context.l10n.profileTitle,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold)),
                          Text(context.l10n.manageAccount,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 170,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 100 : 30),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                  spreadRadius: 2,
                )
              ],
              border: isDark
                  ? Border.all(color: Colors.white10, width: 0.5)
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _loadingProfile
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            auth.name.isNotEmpty ? auth.name : auth.email,
                            style: TextStyle(
                                color: isDark ? Colors.white : primaryBlue,
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(auth.email,
                              style: TextStyle(
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.grey,
                                  fontSize: 14)),
                        ],
                      ),
                const SizedBox(width: 20),
                CircleAvatar(
                  radius: 35,
                  backgroundColor:
                      isDark ? const Color(0xFF2C2C2C) : primaryBlue,
                  child: Text(
                    auth.initial,
                    style: TextStyle(
                        color: isDark ? accentOrange : Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuOption({
    required String title,
    String? subtitle,
    required IconData icon,
    required Color cardBg,
    required Color textColor,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(isDark ? 50 : 8), blurRadius: 10)
        ],
        border:
            isDark ? Border.all(color: Colors.white10, width: 0.5) : null,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.arrow_back_ios,
                  color: isDark ? Colors.white38 : Colors.grey, size: 16),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: textColor,
                          fontSize: 17,
                          fontWeight: FontWeight.bold)),
                  if (subtitle != null)
                    Text(subtitle,
                        style: TextStyle(
                            color: isDark ? Colors.white60 : Colors.grey,
                            fontSize: 12)),
                ],
              ),
              const SizedBox(width: 15),
              Icon(icon,
                  color: isDark ? accentOrange : Colors.grey[400], size: 28),
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
              icon: Icon(Icons.person, color: accentOrange, size: 32),
              onPressed: () {},
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
                    shape: BoxShape.circle),
                child: const Icon(Icons.auto_awesome,
                    color: Colors.white, size: 22),
              ),
            ),
            IconButton(
              icon: Icon(Icons.location_on_outlined, color: iconColor, size: 28),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MapScreen())),
            ),
            IconButton(
              icon: Icon(Icons.home_outlined, color: iconColor, size: 28),
              onPressed: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const HomePage())),
            ),
          ],
        ),
      ),
    );
  }
}
