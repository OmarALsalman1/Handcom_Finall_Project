import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:handcom/features/auth/screens/ai_assistant_page.dart';
import 'package:handcom/features/auth/screens/home_page.dart';
import 'package:provider/provider.dart';
import 'package:handcom/shared/widgets/theme_provider.dart';
import 'package:handcom/features/auth/screens/worker_details_page.dart';
import 'package:handcom/services/provider_service.dart';
import 'package:handcom/services/api_service.dart';
import 'package:handcom/core/config/api_config.dart';
import 'package:handcom/core/l10n/app_strings.dart';
import 'profile_page.dart';
import 'chat_list_screen.dart';
import 'map_screen.dart';

class Worker {
  final int? providerId;
  final String name;
  final String categoryKey;
  final int experienceYears;
  final String rating;
  final String reviews;
  final String distance;
  final String imageUrl;
  final String char;
  final String status;
  bool isSaved;

  Worker({
    this.providerId,
    required this.name,
    required this.categoryKey,
    required this.experienceYears,
    required this.rating,
    required this.reviews,
    required this.distance,
    required this.imageUrl,
    required this.char,
    required this.status,
    this.isSaved = false,
  });
}

class CarpentryWorkersPage extends StatefulWidget {
  const CarpentryWorkersPage({super.key});

  @override
  State<CarpentryWorkersPage> createState() => _CarpentryWorkersPageState();
}

class _CarpentryWorkersPageState extends State<CarpentryWorkersPage> {
  final double appBarHeight = 120.0;

  static const Color primaryBlue = Color(0xFF1A3D81);
  static const Color accentOrange = Color(0xFFF58220);

  List<Worker> workers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkers();
  }

  Future<void> _toggleSave(Worker w) async {
    if (w.providerId == null) return;
    final willSave = !w.isSaved;
    setState(() => w.isSaved = willSave);
    final savedMsg = context.l10n.workerSaved(w.name);
    final unsavedMsg = context.l10n.workerUnsaved(w.name);
    bool success;
    if (willSave) {
      final res = await ApiService.post(
          ApiConfig.savedProvidersAdd, {'provider_id': w.providerId},
          authenticated: true);
      success = res.statusCode == 201;
    } else {
      final res = await ApiService.delete(
          '${ApiConfig.savedProviders}${w.providerId}/');
      success = res.statusCode == 204;
    }
    if (!mounted) return;
    if (!success) setState(() => w.isSaved = !willSave);
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(willSave && success ? savedMsg : unsavedMsg,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: willSave && success ? primaryBlue : Colors.grey[800],
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ));
  }

  Future<Set<int>> _fetchSavedIds() async {
    try {
      final res = await ApiService.get(ApiConfig.savedProviders);
      if (res.statusCode == 200) {
        final List data = jsonDecode(utf8.decode(res.bodyBytes));
        return data
            .map((e) => (e['service_provider']?['service_provider_id'] as int?) ?? 0)
            .where((id) => id != 0)
            .toSet();
      }
    } catch (_) {}
    return {};
  }

  Future<void> _loadWorkers() async {
    final results = await Future.wait([
      ProviderService.getProviders(category: 'نجارة'),
      _fetchSavedIds(),
    ]);
    if (!mounted) return;
    final providers = results[0] as List;
    final savedIds = results[1] as Set<int>;
    setState(() {
      workers = providers
          .map((p) => Worker(
                providerId: p.id,
                name: p.fullName,
                categoryKey: 'carpentry',
                experienceYears: p.experienceYears,
                rating: p.ratingDisplay,
                reviews: p.totalRatings.toString(),
                distance: '',
                imageUrl: '',
                char: p.initial,
                status: p.availabilityStatus,
                isSaved: savedIds.contains(p.id),
              ))
          .toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final bool isDark = themeProvider.isDarkMode;

        final Color scaffoldBg =
            isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FB);
        final Color appBarBg =
            isDark ? const Color(0xFF1A1A1A) : const Color(0xFF1E3A8A);
        final Color cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final Color textColor = isDark ? Colors.white : const Color(0xFF1E3A8A);
        final Color subTextColor = isDark ? Colors.white60 : Colors.black87;
        final Color placeholderBg =
            isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE3F2FD);

        return Scaffold(
          backgroundColor: scaffoldBg,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(appBarHeight),
            child: AppBar(
              backgroundColor: appBarBg,
              elevation: 0,
              centerTitle: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              flexibleSpace: SafeArea(
                child: Center(
                  child: Text(
                    context.l10n.carpentry,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 26,
                    ),
                  ),
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : workers.isEmpty
                  ? Center(
                      child: Text(context.l10n.noCarpenters,
                          style: TextStyle(color: textColor, fontSize: 16)))
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      itemCount: workers.length,
                      itemBuilder: (context, index) => _buildCard(
                        workers[index], cardBg, textColor,
                        subTextColor, placeholderBg, isDark,
                      ),
                    ),
          bottomNavigationBar: _buildBottomNav(context, isDark),
        );
      },
    );
  }

  // --- كرت الفني الديناميكي المتناسق مع الـ Dark Mode ---
  Widget _buildCard(
    Worker w,
    Color cardBg,
    Color textColor,
    Color subTextColor,
    Color placeholderBg,
    bool isDark,
  ) {
    final l10n = context.l10n;
    final Map<String, String> catLabels = {
      'plumbing': l10n.plumbing,
      'electrical': l10n.electricity,
      'painting': l10n.painting,
      'carpentry': l10n.carpentry,
    };
    final String displayJob =
        '${catLabels[w.categoryKey] ?? w.categoryKey} - ${l10n.yearsExpDisplay(w.experienceYears)}';
    Color statusColor = w.status == 'available' ? Colors.green : Colors.red;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => WorkerDetailsPage(providerId: w.providerId, serviceType: w.categoryKey)),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // القسم الأيسر: التقييم والمفضلة
            Column(
              children: [
                IconButton(
                  icon: Icon(
                    w.isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: Colors.orange,
                    size: 30,
                  ),
                  onPressed: () => _toggleSave(w),
                ),
                Row(
                  children: [
                    Text(
                      w.rating,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                  ],
                ),
              ],
            ),
            const Spacer(),

            // القسم الأوسط: تفاصيل الفني والحالة جنباً إلى جنب
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  w.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayJob,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.grey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // تاغ الحالة (متاح / مشغول)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        l10n.statusFromRaw(w.status),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    // الموقع والمسافة
                    Text(
                      w.distance,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: isDark ? Colors.white60 : Colors.grey,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 15),

            // القسم الأيمن: الصورة أو الحرف التعريفي الأول
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Container(
                width: 75,
                height: 75,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.grey.shade200,
                  ),
                ),
                child: w.imageUrl.isNotEmpty
                    ? Image.network(
                        w.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) =>
                            _buildPlaceholder(w.char, placeholderBg, textColor),
                      )
                    : _buildPlaceholder(w.char, placeholderBg, textColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(String char, Color placeholderBg, Color textColor) {
    return Container(
      color: placeholderBg,
      child: Center(
        child: Text(
          char,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: 22,
          ),
        ),
      ),
    );
  }

  // --- البار السفلي المتناسق بدون تظليل أو تحديد ثابت ---
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
              icon: Icon(Icons.person_outline, color: iconColor, size: 28),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              ),
            ),
            IconButton(
              icon: Icon(Icons.chat_bubble_outline, color: iconColor, size: 26),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChatListScreen(),
                  ),
                );
              },
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AiAssistantPage()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [primaryBlue, accentOrange]),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.location_on_outlined,
                color: iconColor,
                size: 28,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MapScreen()),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.home_outlined, color: iconColor, size: 28),
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const HomePage()));
              },
            ),
          ],
        ),
      ),
    );
  }
}
