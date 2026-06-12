import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:handcom/shared/widgets/theme_provider.dart';
import 'package:handcom/shared/widgets/locale_provider.dart';
import 'package:handcom/core/l10n/app_strings.dart';
import 'login_screen.dart';
import 'provider_login_screen.dart';

class UserTypeScreen extends StatelessWidget {
  const UserTypeScreen({super.key});

  static const Color primaryBlue = Color(0xFF1A3D81);
  static const Color accentOrange = Color(0xFFF58220);

  @override
  Widget build(BuildContext context) {
    // الاستماع للتغيرات العالمية للـ Dark Mode داخل شاشة تحديد نوع الحساب
    return Consumer2<ThemeProvider, LocaleProvider>(
      builder: (context, themeProvider, localeProvider, child) {
        final bool isDark = themeProvider.isDarkMode;
        final bool isAr = localeProvider.isArabic;

        final Color scaffoldBg =
            isDark ? const Color(0xFF121212) : const Color(0xfff2f2f2);
        final Color providerButtonBg =
            isDark ? const Color(0xFF1E1E1E) : primaryBlue;

        return Scaffold(
          backgroundColor: scaffoldBg,
          body: SafeArea(
            child: Column(
              children: [
                // ── Language toggle pinned to top-right ───────────────────
                SizedBox(
                  height: 200,
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: GestureDetector(
                        onTap: localeProvider.toggleLocale,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E1E1E)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withValues(alpha: isDark ? 0.3 : 0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.language,
                                  color: primaryBlue, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'AR',
                                style: TextStyle(
                                  fontWeight: isAr
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isAr ? primaryBlue : Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4),
                                child: Text('|',
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 13)),
                              ),
                              Text(
                                'EN',
                                style: TextStyle(
                                  fontWeight: !isAr
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: !isAr ? primaryBlue : Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // اللوجو الخاص بالتطبيق
                Image.asset(
                  "assets/images/e4e88ada-3646-4357-8652-af49c92d55a4-removebg-preview.png",
                  height: 240,
                ),

                const SizedBox(
                    height: 70), // رفعنا الأزرار لفوق لتعطي مظهر منسق

                // --- زر المستخدم ---
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    height: 65,
                    decoration: BoxDecoration(
                      color: accentOrange,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 20),
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        Text(
                          context.l10n.user,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(right: 20),
                          child: Icon(Icons.arrow_forward_ios, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 35),

                // --- زر مزود الخدمة ---
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProviderLoginScreen(),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    height: 65,
                    decoration: BoxDecoration(
                      color: providerButtonBg,
                      borderRadius: BorderRadius.circular(15),
                      border: isDark
                          ? Border.all(color: Colors.white10, width: 0.5)
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 20),
                          child: Icon(Icons.handyman, color: Colors.white),
                        ),
                        Text(
                          context.l10n.serviceProviderBtn,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(right: 20),
                          child: Icon(Icons.arrow_forward_ios, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
