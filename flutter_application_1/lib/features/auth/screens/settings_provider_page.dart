import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:handcom/shared/widgets/theme_provider.dart';
import 'package:handcom/shared/widgets/locale_provider.dart';
import 'package:handcom/providers/user_auth_provider.dart';
import 'package:handcom/features/auth/screens/user_type_screen.dart';
import 'provider_profile_page.dart';

class SettingsProviderPage extends StatefulWidget {
  const SettingsProviderPage({super.key});

  @override
  State<SettingsProviderPage> createState() => _SettingsProviderPageState();
}

class _SettingsProviderPageState extends State<SettingsProviderPage> {
  bool isNotificationsEnabled = true;

  final Color primaryBlue = const Color(0xFF1A3D81);
  final Color accentPink = const Color(0xFFE94E77);

  @override
  Widget build(BuildContext context) {
    return Consumer3<ThemeProvider, UserAuthProvider, LocaleProvider>(
      builder: (context, themeProvider, auth, localeProvider, child) {
        final bool isDark = themeProvider.isDarkMode;
        final bool isAr = localeProvider.isArabic;
        final Color scaffoldBg =
            isDark ? const Color(0xFF121212) : const Color(0xFFF2F2F2);
        final Color cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final Color textColor = isDark ? Colors.white : Colors.black;
        final Color subTextColor = isDark ? Colors.white60 : Colors.black54;

        return Scaffold(
          backgroundColor: scaffoldBg,
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildBlueHeader(context, isAr),
                const SizedBox(height: 30),
                _buildPersonalInfoCard(auth, cardBg, textColor, subTextColor, isAr),
                const SizedBox(height: 20),
                _buildSettingsOptionsCard(
                    themeProvider, localeProvider, cardBg, textColor, isAr),
                const SizedBox(height: 20),
                _buildLogoutButton(context, auth, cardBg, isAr),
                const SizedBox(height: 50),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBlueHeader(BuildContext context, bool isAr) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: primaryBlue,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(45),
          bottomRight: Radius.circular(45),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios,
                      color: Colors.white, size: 28),
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ProviderProfilePage()),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isAr ? "الإعدادات" : "Settings",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalInfoCard(UserAuthProvider auth, Color cardBg,
      Color textColor, Color subTextColor, bool isAr) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                auth.name.isNotEmpty ? auth.name : '—',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor),
              ),
              Text(auth.email,
                  style: TextStyle(fontSize: 14, color: subTextColor)),
              Text(
                isAr ? 'مزود خدمة' : 'Service Provider',
                style: TextStyle(
                    fontSize: 13,
                    color: primaryBlue,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
                color: primaryBlue, borderRadius: BorderRadius.circular(20)),
            child: Center(
              child: Text(
                auth.initial,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 35,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsOptionsCard(ThemeProvider themeProvider,
      LocaleProvider localeProvider, Color cardBg, Color textColor, bool isAr) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        children: [
          _buildSwitchRow(
            isAr ? "الاشعارات" : "Notifications",
            Icons.notifications_none_outlined,
            isNotificationsEnabled,
            textColor,
            (val) => setState(() => isNotificationsEnabled = val),
          ),
          const Divider(height: 30, thickness: 1),
          _buildSwitchRow(
            isAr ? "الوضع الداكن" : "Dark Mode",
            Icons.dark_mode_outlined,
            themeProvider.isDarkMode,
            textColor,
            (val) => themeProvider.toggleTheme(val),
          ),
          const Divider(height: 30, thickness: 1),
          _buildLanguageRow(localeProvider, textColor, isAr),
        ],
      ),
    );
  }

  Widget _buildLanguageRow(
      LocaleProvider localeProvider, Color textColor, bool isAr) {
    return Row(
      children: [
        GestureDetector(
          onTap: localeProvider.toggleLocale,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: primaryBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryBlue.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'AR',
                  style: TextStyle(
                    fontWeight: isAr ? FontWeight.bold : FontWeight.normal,
                    color: isAr ? primaryBlue : Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text('|',
                      style: TextStyle(color: Colors.grey, fontSize: 14)),
                ),
                Text(
                  'EN',
                  style: TextStyle(
                    fontWeight: !isAr ? FontWeight.bold : FontWeight.normal,
                    color: !isAr ? primaryBlue : Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        Text(
          isAr ? 'اللغة' : 'Language',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
        ),
        const SizedBox(width: 10),
        Icon(Icons.language, color: textColor.withValues(alpha: 0.8)),
      ],
    );
  }

  Widget _buildSwitchRow(String title, IconData icon, bool value,
      Color textColor, Function(bool) onChanged) {
    return Row(
      children: [
        Switch(value: value, onChanged: onChanged, activeColor: primaryBlue),
        const Spacer(),
        Text(title,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(width: 10),
        Icon(icon, color: textColor.withValues(alpha: 0.8)),
      ],
    );
  }

  Widget _buildLogoutButton(
      BuildContext context, UserAuthProvider auth, Color cardBg, bool isAr) {
    return GestureDetector(
      onTap: () async {
        await auth.logout();
        if (!context.mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const UserTypeScreen()),
          (_) => false,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 25),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isAr ? "تسجيل الخروج" : "Log Out",
              style: const TextStyle(
                  color: Colors.red,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 15),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: accentPink.withValues(alpha: 0.15),
                  shape: BoxShape.circle),
              child: Icon(Icons.logout, color: accentPink),
            ),
          ],
        ),
      ),
    );
  }
}
