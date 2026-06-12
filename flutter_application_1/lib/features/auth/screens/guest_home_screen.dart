import 'package:flutter/material.dart';
import 'package:handcom/features/auth/screens/carpentry_for_guest.dart';
import 'package:handcom/features/auth/screens/electricity_for_guest.dart';
import 'package:handcom/features/auth/screens/paint_for_guest.dart';
import 'package:handcom/features/auth/screens/plumbing_for_guest.dart';
import 'package:provider/provider.dart'; // استيراد الـ Provider للاستماع للثيم العام
import 'package:handcom/shared/widgets/theme_provider.dart'; // تأكد من صحة مسار ملف الـ Provider بمشروعك
import 'package:handcom/core/l10n/app_strings.dart';
import 'login_screen.dart';

// ✅ 1. استيراد ملفات شاشات العمال الحقيقية والكاملة الخاصة بمشروعكِ لربط الـ GridView

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Handcom App',
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF8F9FB),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212),
          ),
          home: const GuestHomeScreen(),
        );
      },
    );
  }
}

class GuestHomeScreen extends StatelessWidget {
  const GuestHomeScreen({super.key});

  static const Color primaryBlue = Color(0xFF1A3D81);
  static const Color accentOrange = Color(0xFFF58220);

  // ✅ دالة التنبيه العالمية الثابتة (Static) لتستدعيها من داخل صفحات العمال الحقيقية
  static void showLoginRequiredDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            context.l10n.loginRequired,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          content: Text(
            context.l10n.loginRequiredMsg,
            textAlign: TextAlign.center,
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 15),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                context.l10n.cancel,
                style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: Text(
                context.l10n.loginNow,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color scaffoldBg = isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FB);
    final Color appBarBg = isDark ? const Color(0xFF1A1A1A) : primaryBlue;
    final Color cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 25, bottom: 60), 
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
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const LoginScreen()),
                              );
                            },
                            style: TextButton.styleFrom(
                              minimumSize: Size.zero,
                              padding: EdgeInsets.zero,
                            ),
                            child: Text(
                              context.l10n.login,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          const SizedBox(height: 5), 
                          Text(
                            context.l10n.guestWelcome,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),

                Positioned(
                  bottom: -30,
                  left: 20,
                  right: 20,
                  child: GestureDetector(
                    onTap: () => showLoginRequiredDialog(context, isDark),
                    child: _buildAICard(context, isDark),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 50),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  context.l10n.availableServices,
                  style: TextStyle(
                    color: isDark ? accentOrange : primaryBlue,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 15,
                  crossAxisSpacing: 15,
                  childAspectRatio: 1.8,
                  children: [
                    // ✅ 2. تم ربط الأزرار بالصفحات الحقيقية للمشروع لفتح قوائم العمال الفعلية كزائر
                    _buildServiceCard(context, context.l10n.electricity, Icons.bolt, cardBg, isDark, const ElectricityForGuest()),
                    _buildServiceCard(context, context.l10n.plumbing, Icons.build, cardBg, isDark, const PlumbingForGuest()),
                    _buildServiceCard(context, context.l10n.painting, Icons.format_paint, cardBg, isDark, const PaintForGuest()),
                    _buildServiceCard(context, context.l10n.carpentry, Icons.handyman, cardBg, isDark, const CarpentryForGuest()),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  context.l10n.recentOrders,
                  style: TextStyle(
                    color: isDark ? accentOrange : primaryBlue,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Text(
                  context.l10n.noResults,
                  style: TextStyle(
                    color: isDark ? Colors.redAccent : Colors.red,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomAppBar(context, isDark),
    );
  }

  Widget _buildAICard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryBlue, accentOrange],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black45 : Colors.black26,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                context.l10n.aiAssistant,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                context.l10n.aiSubtitle,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
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
    );
  }

  Widget _buildServiceCard(
    BuildContext context,
    String title,
    IconData icon,
    Color cardBg,
    bool isDark,
    Widget targetPage,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => targetPage),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: isDark ? Colors.black26 : Colors.black12, blurRadius: 10)],
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(color: isDark ? Colors.white : primaryBlue, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: accentOrange, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAppBar(BuildContext context, bool isDark) {
    final Color navBg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE8E8E8);
    final Color iconColor = isDark ? Colors.white60 : Colors.black87;

    return BottomAppBar(
      color: navBg, 
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(Icons.person_outline, color: iconColor),
              onPressed: () => showLoginRequiredDialog(context, isDark),
            ),
            IconButton(
              icon: Icon(Icons.chat_bubble_outline, color: iconColor),
              onPressed: () => showLoginRequiredDialog(context, isDark),
            ),
            GestureDetector(
              onTap: () => showLoginRequiredDialog(context, isDark),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [primaryBlue, accentOrange]),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, color: Color(0xFFFFFFFF)),
              ),
            ),
            IconButton(
              icon: Icon(Icons.location_on_outlined, color: iconColor),
              onPressed: () => showLoginRequiredDialog(context, isDark),
            ),
            IconButton(
              icon: Icon(Icons.home, color: isDark ? accentOrange : primaryBlue, size: 28),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}