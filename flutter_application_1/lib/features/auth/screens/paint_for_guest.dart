import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:handcom/shared/widgets/theme_provider.dart';
import 'package:handcom/services/provider_service.dart';
import 'package:handcom/core/l10n/app_strings.dart';
import 'guest_home_screen.dart';

class Worker {
  final String name;
  final String categoryKey;
  final int experienceYears;
  final String rating;
  final String reviews;
  final String imageUrl;
  final String char;
  final String status;
  bool isSaved;

  Worker({
    required this.name,
    required this.categoryKey,
    required this.experienceYears,
    required this.rating,
    required this.reviews,
    required this.imageUrl,
    required this.char,
    required this.status,
    this.isSaved = false,
  });
}

class PaintForGuest extends StatefulWidget {
  const PaintForGuest({super.key});

  @override
  State<PaintForGuest> createState() => _PaintWorkersPageState();
}

class _PaintWorkersPageState extends State<PaintForGuest> {
  static const Color primaryBlue = Color(0xFF1A3D81);
  static const Color accentOrange = Color(0xFFF58220);

  List<Worker> workers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkers();
  }

  Future<void> _loadWorkers() async {
    final providers = await ProviderService.getProviders(category: 'painting');
    if (!mounted) return;
    setState(() {
      workers = providers
          .map((p) => Worker(
                name: p.fullName,
                categoryKey: 'painting',
                experienceYears: p.experienceYears,
                rating: p.ratingDisplay,
                reviews: p.totalRatings.toString(),
                imageUrl: '',
                char: p.initial,
                status: p.availabilityStatus,
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
            isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FD);
        final Color appBarBg =
            isDark ? const Color(0xFF1A1A1A) : const Color(0xFF1E3A8A);
        final Color cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final Color textColor = isDark ? Colors.white : const Color(0xFF1E3A8A);
        final Color placeholderBg =
            isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE3F2FD);

        return Scaffold(
          backgroundColor: scaffoldBg,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(120.0),
            child: AppBar(
              backgroundColor: appBarBg,
              centerTitle: true,
              elevation: 0,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              flexibleSpace: SafeArea(
                child: Center(
                  child: Text(
                    context.l10n.painting,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 26),
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
                      child: Text(context.l10n.noPainters,
                          style: TextStyle(color: textColor, fontSize: 16)))
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      itemCount: workers.length,
                      itemBuilder: (context, index) => _buildCard(
                          context, workers[index], cardBg, textColor,
                          placeholderBg, isDark),
                    ),
          bottomNavigationBar: _buildBottomNav(context, isDark),
        );
      },
    );
  }

  Widget _buildCard(BuildContext context, Worker w, Color cardBg,
      Color textColor, Color placeholderBg, bool isDark) {
    Color statusColor = w.status == 'available' ? Colors.green : Colors.red;
    final displayJob =
        '${context.l10n.painting} • ${context.l10n.yearsExpDisplay(w.experienceYears)}';
    return GestureDetector(
      onTap: () => GuestHomeScreen.showLoginRequiredDialog(context, isDark),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Column(
              children: [
                IconButton(
                  icon: Icon(Icons.bookmark_border,
                      color: isDark ? Colors.white60 : Colors.grey, size: 30),
                  onPressed: () =>
                      GuestHomeScreen.showLoginRequiredDialog(context, isDark),
                ),
                Row(
                  children: [
                    Text(w.rating,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isDark ? Colors.white : Colors.black)),
                    const SizedBox(width: 2),
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                  ],
                ),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(w.name,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor)),
                const SizedBox(height: 4),
                Text(displayJob,
                    style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.grey,
                        fontSize: 13)),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(context.l10n.statusFromRaw(w.status),
                      style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(width: 15),
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Container(
                  width: 75,
                  height: 75,
                  color: placeholderBg,
                  child: Center(
                      child: Text(w.char,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              fontSize: 22)))),
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
                icon: Icon(Icons.person_outline, color: iconColor, size: 28),
                onPressed: () =>
                    GuestHomeScreen.showLoginRequiredDialog(context, isDark)),
            IconButton(
                icon: Icon(Icons.chat_bubble_outline,
                    color: iconColor, size: 26),
                onPressed: () =>
                    GuestHomeScreen.showLoginRequiredDialog(context, isDark)),
            GestureDetector(
              onTap: () =>
                  GuestHomeScreen.showLoginRequiredDialog(context, isDark),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [primaryBlue, accentOrange]),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome,
                    color: Colors.white, size: 22),
              ),
            ),
            IconButton(
                icon: Icon(Icons.location_on_outlined,
                    color: iconColor, size: 28),
                onPressed: () =>
                    GuestHomeScreen.showLoginRequiredDialog(context, isDark)),
            IconButton(
                icon: Icon(Icons.home_outlined, color: iconColor, size: 28),
                onPressed: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }
}
