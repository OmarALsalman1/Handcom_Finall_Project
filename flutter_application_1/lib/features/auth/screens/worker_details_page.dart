import 'package:flutter/material.dart';
import 'package:handcom/features/auth/screens/ai_assistant_page.dart';
import 'package:provider/provider.dart';
import 'package:handcom/shared/widgets/theme_provider.dart';
import 'package:handcom/features/auth/screens/chat_page.dart';
import 'package:handcom/features/auth/screens/home_page.dart';
import 'package:handcom/features/auth/screens/order_details_page.dart';
import 'package:handcom/services/provider_service.dart';
import 'package:handcom/services/chat_service.dart';
import 'package:handcom/core/l10n/app_strings.dart';
import 'map_screen.dart';
import 'profile_page.dart';
import 'chat_list_screen.dart';

class WorkerDetailsPage extends StatefulWidget {
  final int? providerId;
  final String? serviceType;

  const WorkerDetailsPage({super.key, this.providerId, this.serviceType});

  @override
  State<WorkerDetailsPage> createState() => _WorkerDetailsPageState();
}

class _WorkerDetailsPageState extends State<WorkerDetailsPage> {
  static const Color primaryBlue = Color(0xFF1A3D81);
  static const Color accentOrange = Color(0xFFF58220);

  ProviderModel? _provider;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.providerId != null) {
      _loadProvider();
    } else {
      setState(() => _isLoading = false);
    }
  }

  String get _resolvedServiceType =>
      widget.serviceType ??
      (_provider!.serviceCategories.isNotEmpty
          ? _provider!.serviceCategories.first
          : 'plumbing');

  Future<void> _loadProvider() async {
    final provider =
        await ProviderService.getProviderById(widget.providerId!);
    if (!mounted) return;
    setState(() {
      _provider = provider;
      _isLoading = false;
    });
  }

  Future<void> _startChat() async {
    if (_provider == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final chatError = context.l10n.chatError;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    // Start a direct conversation — no order required
    final conv = await ChatService.startDirectChat(_provider!.id);
    if (!mounted) return;
    navigator.pop(); // close loading dialog

    if (conv == null) {
      messenger.showSnackBar(SnackBar(
        content: Text(chatError, textAlign: TextAlign.center),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    navigator.push(MaterialPageRoute(
      builder: (_) => ChatPage(
        conversationId: conv.id,
        partnerName: _provider!.fullName,
        providerId: _provider!.id,
        serviceType: _resolvedServiceType,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final bool isDark = themeProvider.isDarkMode;
        final Color scaffoldBg =
            isDark ? const Color(0xFF121212) : Colors.white;
        final Color appBarBg =
            isDark ? const Color(0xFF1A1A1A) : primaryBlue;
        final Color fieldBg =
            isDark ? const Color(0xFF1E1E1E) : const Color(0xFFEFEFEF);
        final Color textColor = isDark ? Colors.white : Colors.black87;
        final Color subTextColor = isDark ? Colors.white60 : Colors.black54;

        return Scaffold(
          backgroundColor: scaffoldBg,
          bottomNavigationBar: _buildBottomNav(context, isDark),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Container(
                            height: 150,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: appBarBg,
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(30),
                                bottomRight: Radius.circular(30),
                              ),
                            ),
                            child: SafeArea(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.arrow_back_ios,
                                          color: Colors.white),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                    Text(
                                      context.l10n.workerInfo,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 48),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -45,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF121212)
                                        : Colors.white,
                                    width: 4),
                              ),
                              child: CircleAvatar(
                                radius: 40,
                                backgroundColor:
                                    isDark ? const Color(0xFF2C2C2C) : primaryBlue,
                                child: Text(
                                  _provider?.initial ?? '؟',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 55),

                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 25),
                        child: Column(
                          children: [
                            _buildInfoField(
                                _provider?.fullName ?? '—', fieldBg, textColor),
                            _buildRatingField(fieldBg, _provider),
                            if (_provider != null)
                              _buildInfoField(
                                  _provider!.serviceCategories
                                      .map((c) {
                                        const m = {
                                          'plumbing': 'سباكة',
                                          'electrical': 'كهرباء',
                                          'painting': 'دهان',
                                          'carpentry': 'نجارة',
                                        };
                                        return m[c] ?? c;
                                      })
                                      .join(' ، '),
                                  fieldBg,
                                  textColor),
                            if (_provider?.phone != null &&
                                _provider!.phone.isNotEmpty)
                              _buildInfoField(
                                  _provider!.phone, fieldBg, textColor),
                            const SizedBox(height: 20),
                            _buildSectionCard(
                              title: context.l10n.experienceAndJobs,
                              fieldBg: fieldBg,
                              textColor: textColor,
                              child: Column(
                                children: [
                                  if (_provider != null)
                                    ..._provider!.serviceCategories
                                        .map((c) {
                                      const m = {
                                        'plumbing': 'سباكة',
                                        'electrical': 'كهرباء',
                                        'painting': 'دهان',
                                        'carpentry': 'نجارة',
                                      };
                                      return _buildServiceItem(
                                          m[c] ?? c, textColor);
                                    }),
                                  Divider(
                                      color: isDark
                                          ? Colors.white10
                                          : Colors.black12),
                                  Text(
                                    context.l10n.yearsExpDisplay(_provider?.experienceYears ?? 0),
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: textColor),
                                  ),
                                ],
                              ),
                            ),
                            _buildSectionCard(
                              title: context.l10n.availabilityLabel,
                              fieldBg: fieldBg,
                              textColor: textColor,
                              child: Text(
                                _provider != null
                                    ? context.l10n.statusFromRaw(_provider!.availabilityStatus)
                                    : '—',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    height: 1.5,
                                    color: subTextColor,
                                    fontSize: 15),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildActionBtn(context.l10n.chatAction, accentOrange,
                                      _provider == null ? null : _startChat),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: _buildActionBtn(
                                      context.l10n.requestAction,
                                      _provider != null
                                          ? accentOrange
                                          : Colors.grey,
                                      _provider == null
                                          ? null
                                          : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              OrderDetailsPage(
                                                providerId: _provider!.id,
                                                providerName: _provider!.fullName,
                                                providerInitial: _provider!.initial,
                                                serviceType: _resolvedServiceType,
                                                averageRating: _provider!.averageRating,
                                                totalRatings: _provider!.totalRatings,
                                              )),
                                    );
                                  }),
                                ),
                              ],
                            ),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildInfoField(String text, Color fieldBg, Color textColor) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
          color: fieldBg, borderRadius: BorderRadius.circular(15)),
      child: Text(text,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontWeight: FontWeight.bold, color: textColor, fontSize: 16)),
    );
  }

  Widget _buildRatingField(Color fieldBg, ProviderModel? provider) {
    final rating = provider?.averageRating ?? 0.0;
    final stars = rating.round().clamp(0, 5);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
          color: fieldBg, borderRadius: BorderRadius.circular(15)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            provider?.ratingDisplay ?? '—',
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(width: 6),
          ...List.generate(
              stars,
              (i) => const Icon(Icons.star, color: Colors.orange, size: 22)),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
      {required String title,
      required Widget child,
      required Color fieldBg,
      required Color textColor}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: fieldBg, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildServiceItem(String name, Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(name,
            style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w500)),
        const SizedBox(width: 10),
        const Icon(Icons.check_circle, color: Colors.green, size: 20),
      ],
    );
  }

  Widget _buildActionBtn(
      String label, Color color, VoidCallback? onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25)),
        elevation: 2,
      ),
      onPressed: onTap,
      child: Text(label,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold)),
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
                  MaterialPageRoute(builder: (context) => const ProfilePage())),
            ),
            IconButton(
              icon:
                  Icon(Icons.chat_bubble_outline, color: iconColor, size: 26),
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
                  gradient: LinearGradient(
                      colors: [primaryBlue, accentOrange]),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome,
                    color: Colors.white, size: 22),
              ),
            ),
            IconButton(
              icon: Icon(Icons.location_on_outlined, color: iconColor, size: 28),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const MapScreen())),
            ),
            IconButton(
              icon: Icon(Icons.home_outlined,
                  color: isDark ? accentOrange : primaryBlue, size: 30),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const HomePage())),
            ),
          ],
        ),
      ),
    );
  }
}
