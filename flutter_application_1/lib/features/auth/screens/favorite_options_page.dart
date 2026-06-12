import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:handcom/features/auth/screens/profile_page.dart';
import 'package:handcom/shared/widgets/theme_provider.dart';
import 'package:handcom/services/api_service.dart';
import 'package:handcom/core/config/api_config.dart';
import 'package:handcom/core/l10n/app_strings.dart';
import 'home_page.dart';
import 'chat_list_screen.dart';
import 'map_screen.dart';
import 'ai_assistant_page.dart';
import 'package:handcom/features/auth/screens/worker_details_page.dart';

class _SavedProvider {
  final int providerId;
  final String name;
  final String initial;
  final String ratingDisplay;
  final String statusArabic;

  _SavedProvider({
    required this.providerId,
    required this.name,
    required this.initial,
    required this.ratingDisplay,
    required this.statusArabic,
  });

  factory _SavedProvider.fromJson(Map<String, dynamic> json) {
    final sp = json['service_provider'] ?? {};
    final name = (sp['full_name'] ?? '') as String;
    final avg = sp['average_rating'] ?? 0.0;
    final total = sp['total_ratings'] ?? 0;
    final status = sp['availability_status'] ?? 'available';
    return _SavedProvider(
      providerId: sp['service_provider_id'] ?? 0,
      name: name,
      initial: name.isNotEmpty ? name.substring(0, 1) : '؟',
      ratingDisplay: '${avg is double ? avg.toStringAsFixed(1) : avg} ($total)',
      statusArabic: status == 'available' ? 'متاح' : 'مشغول',
    );
  }
}

class FavoriteOptionsPage extends StatefulWidget {
  const FavoriteOptionsPage({super.key});

  @override
  State<FavoriteOptionsPage> createState() => _FavoriteOptionsPageState();
}

class _FavoriteOptionsPageState extends State<FavoriteOptionsPage> {
  static const Color primaryBlue = Color(0xFF1A3D81);
  static const Color accentOrange = Color(0xFFF58220);

  List<_SavedProvider> _saved = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final response = await ApiService.get(ApiConfig.savedProviders);
    if (!mounted) return;
    if (response.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final List<dynamic> data =
          decoded is Map ? (decoded['results'] ?? []) : decoded as List;
      setState(() {
        _saved = data.map((e) => _SavedProvider.fromJson(e)).toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _unsave(int providerId) async {
    setState(() {
      _saved.removeWhere((s) => s.providerId == providerId);
    });
    await ApiService.delete('${ApiConfig.savedProviders}$providerId/');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final bool isDark = themeProvider.isDarkMode;

        final Color scaffoldBg =
            isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FB);
        final Color cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final Color initialBoxBg =
            isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF0F4FC);
        final Color textColor = isDark ? Colors.white : primaryBlue;
        final Color subTextColor = isDark ? Colors.white60 : Colors.black87;

        return Scaffold(
          backgroundColor: scaffoldBg,
          bottomNavigationBar: _buildBottomNav(context, isDark),
          body: Column(
            children: [
              _buildHeader(context, isDark),
              _isLoading
                  ? const Expanded(
                      child: Center(child: CircularProgressIndicator()))
                  : _saved.isEmpty
                      ? Expanded(
                          child: Center(
                            child: Text(
                              context.l10n.noSavedOptions,
                              style: TextStyle(
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.grey,
                                  fontSize: 16),
                            ),
                          ),
                        )
                      : Expanded(
                          child: RefreshIndicator(
                            onRefresh: _loadSaved,
                            child: ListView.builder(
                              physics:
                                  const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 15),
                              itemCount: _saved.length,
                              itemBuilder: (context, index) =>
                                  _buildCard(_saved[index], cardBg,
                                      initialBoxBg, textColor,
                                      subTextColor, isDark),
                            ),
                          ),
                        ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : primaryBlue,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white, size: 22),
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (context) => const ProfilePage()),
                  (route) => false,
                ),
              ),
            ),
            Text(
              context.l10n.favoriteOptions,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(_SavedProvider sp, Color cardBg, Color initialBoxBg,
      Color textColor, Color subTextColor, bool isDark) {
    final statusColor = sp.statusArabic == 'متاح' ? Colors.green : Colors.red;

    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  WorkerDetailsPage(providerId: sp.providerId))),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
          border:
              isDark ? Border.all(color: Colors.white10, width: 0.5) : null,
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sp.ratingDisplay,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isDark ? Colors.white : Colors.black),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.star, color: Colors.amber, size: 15),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(context.l10n.removedFromFavorites,
                          textAlign: TextAlign.center),
                      duration: const Duration(seconds: 1),
                      backgroundColor: Colors.orange,
                    ));
                    _unsave(sp.providerId);
                  },
                  child: const Icon(Icons.bookmark,
                      color: Colors.orange, size: 30),
                ),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  sp.name,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? Colors.white
                          : const Color(0xFF1E3A8A)),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    sp.statusArabic == 'متاح'
                        ? (context.l10n.isAr ? 'متاح' : 'Available')
                        : (context.l10n.isAr ? 'مشغول' : 'Busy'),
                    style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                color: initialBoxBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  sp.initial,
                  style: TextStyle(
                      color: isDark ? accentOrange : primaryBlue,
                      fontSize: 26,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
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
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(Icons.person,
                  color: isDark ? accentOrange : primaryBlue, size: 30),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ProfilePage())),
            ),
            IconButton(
              icon: Icon(Icons.chat_bubble_outline,
                  color: iconColor, size: 26),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ChatListScreen())),
            ),
            GestureDetector(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AiAssistantPage())),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  gradient:
                      LinearGradient(colors: [primaryBlue, accentOrange]),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome,
                    color: Colors.white, size: 22),
              ),
            ),
            IconButton(
              icon: Icon(Icons.location_on_outlined,
                  color: iconColor, size: 28),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const MapScreen())),
            ),
            IconButton(
              icon: Icon(Icons.home_outlined, color: iconColor, size: 28),
              onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const HomePage()),
                  (route) => false),
            ),
          ],
        ),
      ),
    );
  }
}
