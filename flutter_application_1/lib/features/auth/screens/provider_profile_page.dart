import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:handcom/features/auth/screens/chats_by_provider.dart';
import 'package:handcom/features/auth/screens/provider_map_screen.dart';
import 'package:provider/provider.dart';
import 'package:handcom/features/auth/screens/settings_provider_page.dart';
import 'package:handcom/shared/widgets/theme_provider.dart';
import 'package:handcom/providers/user_auth_provider.dart';
import 'package:handcom/services/api_service.dart';
import 'package:handcom/core/config/api_config.dart';
import 'package:handcom/core/l10n/app_strings.dart';
import 'provider_home_page.dart';
import 'worker_profile_page.dart';

class ProviderProfilePage extends StatefulWidget {
  const ProviderProfilePage({super.key});

  @override
  State<ProviderProfilePage> createState() => _ProviderProfilePageState();
}

class _ProviderProfilePageState extends State<ProviderProfilePage> {
  static const Color primaryBlue = Color(0xFF1A3D81);
  static const Color accentOrange = Color(0xFFF58220);

  String _name = '';
  String _email = '';
  String _phone = '';
  String _categoriesArabic = '';
  String _initial = '؟';
  bool _isLoading = true;
  String _availabilityStatus = 'available';
  bool _isUpdatingAvailability = false;

  static const Map<String, String> _catMap = {
    'plumbing': 'سباكة',
    'electrical': 'كهرباء',
    'painting': 'دهان',
    'carpentry': 'نجارة',
  };

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    // Pre-fill from cached auth state immediately
    final auth = context.read<UserAuthProvider>();
    if (auth.name.isNotEmpty) {
      setState(() {
        _name = auth.name;
        _initial = auth.initial;
        _email = auth.email;
      });
    }

    try {
      final response = await ApiService.get(ApiConfig.providerMe);
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final name = (data['full_name'] ?? '') as String;
        final cats = (data['service_categories'] as List? ?? [])
            .map((c) => _catMap[c] ?? c)
            .join(' ، ');
        setState(() {
          _name = name;
          _initial = name.isNotEmpty ? name.substring(0, 1) : '؟';
          _email = data['email'] ?? auth.email;
          _phone = data['phone'] ?? '';
          _categoriesArabic = cats;
          _availabilityStatus = data['availability_status'] ?? 'available';
          _isLoading = false;
        });
        auth.setProfile(name: name, email: data['email']);
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleAvailability() async {
    if (_isUpdatingAvailability) return;
    final next = _availabilityStatus == 'available' ? 'offline' : 'available';
    setState(() => _isUpdatingAvailability = true);
    try {
      final response = await ApiService.patch(
        ApiConfig.providerAvailability,
        {'availability_status': next},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() => _availabilityStatus = next);
      }
    } catch (_) {}
    if (mounted) setState(() => _isUpdatingAvailability = false);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final bool isDark = themeProvider.isDarkMode;
        final Color scaffoldBg =
            isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FB);
        final Color appBarBg =
            isDark ? const Color(0xFF1A1A1A) : primaryBlue;
        final Color cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final Color textColor = isDark ? Colors.white : primaryBlue;
        final Color subTextColor = isDark ? Colors.white60 : Colors.grey;

        return Scaffold(
          backgroundColor: scaffoldBg,
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildProfileHeader(
                    context, appBarBg, cardBg, textColor, subTextColor, isDark),
                const SizedBox(height: 120),
                _buildAvailabilityCard(context, cardBg, isDark),
                const SizedBox(height: 8),
                _buildMenuOption(
                  title: context.l10n.accountInfo,
                  subtitle: context.l10n.personalDetails,
                  icon: Icons.person_outline,
                  cardBg: cardBg,
                  textColor: textColor,
                  isDark: isDark,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const WorkerProfilePage())),
                ),
                _buildMenuOption(
                  title: context.l10n.settingsTitle,
                  icon: Icons.settings_outlined,
                  cardBg: cardBg,
                  textColor: textColor,
                  isDark: isDark,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const SettingsProviderPage())),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomNav(context, isDark),
        );
      },
    );
  }

  Widget _buildProfileHeader(BuildContext context, Color appBarBg,
      Color cardBg, Color textColor, Color subTextColor, bool isDark) {
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

        // Profile card
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
                  color: Colors.black
                      .withValues(alpha: isDark ? 0.4 : 0.15),
                  blurRadius: 40,
                  spreadRadius: 2,
                  offset: const Offset(0, 15),
                ),
              ],
              border: isDark
                  ? Border.all(color: Colors.white10, width: 0.5)
                  : null,
            ),
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _name.isNotEmpty ? _name : '—',
                            style: TextStyle(
                                color: isDark ? Colors.white : primaryBlue,
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                          ),
                          if (_email.isNotEmpty)
                            Text(_email,
                                style: TextStyle(
                                    color: subTextColor, fontSize: 14)),
                          if (_phone.isNotEmpty)
                            Text(_phone,
                                style: TextStyle(
                                    color: subTextColor, fontSize: 14)),
                          if (_categoriesArabic.isNotEmpty)
                            Text(_categoriesArabic,
                                style: const TextStyle(
                                    color: accentOrange,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(width: 20),
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: isDark
                            ? const Color(0xFF2C2C2C)
                            : primaryBlue,
                        child: Text(
                          _initial,
                          style: TextStyle(
                              color:
                                  isDark ? accentOrange : Colors.white,
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

  Widget _buildAvailabilityCard(BuildContext context, Color cardBg, bool isDark) {
    final bool isAvailable = _availabilityStatus == 'available';
    final Color statusColor = isAvailable ? Colors.green : Colors.grey;
    final String statusLabel = isAvailable ? context.l10n.availableNow : context.l10n.notAvailable;
    final String statusLabelEn = isAvailable ? 'Available' : 'Offline';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
          )
        ],
        border: isDark ? Border.all(color: Colors.white10, width: 0.5) : null,
      ),
      child: Row(
        children: [
          _isUpdatingAvailability
              ? const SizedBox(
                  width: 36,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Switch(
                  value: isAvailable,
                  onChanged: (_) => _toggleAvailability(),
                  activeThumbColor: Colors.green,
                  inactiveThumbColor: Colors.grey,
                ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Text(
                    '$statusLabel / $statusLabelEn',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                context.l10n.visibilityToClients,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white38 : Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Icon(Icons.circle_notifications_outlined,
              color: statusColor, size: 28),
        ],
      ),
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
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
          )
        ],
        border: isDark
            ? Border.all(color: Colors.white10, width: 0.5)
            : null,
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
                          color: isDark ? Colors.white : primaryBlue,
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
                  color: isDark ? accentOrange : Colors.grey[400],
                  size: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, bool isDark) {
    final Color navBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color iconActiveColor = isDark ? accentOrange : primaryBlue;
    final Color iconInactiveColor = isDark ? Colors.white38 : Colors.grey;

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
            icon: const Icon(Icons.person, size: 30),
            color: iconActiveColor,
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, size: 26),
            color: iconInactiveColor,
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (context) => const ChatsByProvider())),
          ),
          IconButton(
            icon: const Icon(Icons.location_on_outlined, size: 30),
            color: iconInactiveColor,
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (context) => const ProviderMapScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.home_outlined, size: 30),
            color: iconInactiveColor,
            onPressed: () => Navigator.pushReplacement(context,
                MaterialPageRoute(
                    builder: (context) => const ProviderHomePage())),
          ),
        ],
      ),
    );
  }
}
