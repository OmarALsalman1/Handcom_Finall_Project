import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:handcom/features/auth/screens/provider_map_screen.dart';
import 'package:handcom/features/auth/screens/provider_profile_page.dart';
import 'package:provider/provider.dart';
import 'package:handcom/shared/widgets/theme_provider.dart';
import 'package:handcom/providers/user_auth_provider.dart';
import 'package:handcom/services/api_service.dart';
import 'package:handcom/core/config/api_config.dart';
import 'package:handcom/core/l10n/app_strings.dart';
import 'edit_profile_page.dart';
import 'provider_home_page.dart';
import 'package:handcom/features/auth/screens/chats_by_provider.dart';

class WorkerProfilePage extends StatefulWidget {
  const WorkerProfilePage({super.key});

  @override
  State<WorkerProfilePage> createState() => _WorkerProfilePageState();
}

class _WorkerProfilePageState extends State<WorkerProfilePage> {
  static const Color primaryBlue = Color(0xFF1A3D81);
  static const Color accentOrange = Color(0xFFF58220);

  String _fullName = '';
  String _initial = '؟';
  String _phone = '';
  String _email = '';
  String _ratingDisplay = '';
  String _jobLabel = '';
  int _experienceYears = 0;
  String _bio = '';
  String _servicesOffered = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final auth = context.read<UserAuthProvider>();
    // Seed from local auth first for instant display
    setState(() {
      _fullName = auth.name;
      _initial = auth.initial;
      _email = auth.email;
    });

    final response = await ApiService.get(ApiConfig.providerMe);
    if (!mounted) return;
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final cats = (data['service_categories'] as List? ?? []);
      final catLabels = cats.map((c) {
        const m = {
          'plumbing': 'سباكة',
          'electrical': 'كهرباء',
          'painting': 'دهان',
          'carpentry': 'نجارة',
        };
        return m[c] ?? c;
      }).join(' ، ');
      final avg = (data['average_rating'] ?? 0.0);
      final total = data['total_ratings'] ?? 0;
      final name = data['full_name'] ?? auth.name;
      setState(() {
        _fullName = name;
        _initial = name.isNotEmpty ? name.substring(0, 1) : '؟';
        _phone = data['phone'] ?? '';
        _email = data['email'] ?? auth.email;
        _ratingDisplay =
            '${avg is double ? avg.toStringAsFixed(1) : avg} ($total)';
        _jobLabel = catLabels;
        _experienceYears = data['experience_years'] ?? 0;
        _bio = data['bio'] ?? '';
        _servicesOffered = data['services_offered'] ?? '';
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final bool isDark = themeProvider.isDarkMode;
        final Color scaffoldBg =
            isDark ? const Color(0xFF121212) : Colors.white;
        final Color appBarBg = isDark ? const Color(0xFF1A1A1A) : primaryBlue;
        final Color cardBg =
            isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF2F2F2);
        final Color textColor = isDark ? Colors.white : Colors.black87;
        final Color subTextColor = isDark ? Colors.white60 : Colors.black54;

        return Scaffold(
          backgroundColor: scaffoldBg,
          bottomNavigationBar: _buildBottomNav(context, isDark),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    _buildHeader(context, appBarBg),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildProfileBrief(
                                textColor, subTextColor, isDark),
                            const SizedBox(height: 20),
                            _buildInfoField(_fullName, cardBg, textColor),
                            if (_jobLabel.isNotEmpty)
                              _buildInfoField(_jobLabel, cardBg, textColor),
                            if (_phone.isNotEmpty)
                              _buildInfoField(_phone, cardBg, textColor),
                            if (_email.isNotEmpty)
                              _buildInfoField(_email, cardBg, textColor),
                            const SizedBox(height: 20),
                            _buildExperienceCard(cardBg, textColor),
                            const SizedBox(height: 30),
                            _buildEditButton(context, appBarBg),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, Color appBarBg) {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: appBarBg,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 10),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios,
                      color: Colors.white, size: 25),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            Center(
              child: Text(
                context.l10n.profileTitle,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileBrief(
      Color textColor, Color subTextColor, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const SizedBox(height: 15),
              if (_ratingDisplay.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(context.l10n.ratingLabel,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: textColor)),
                    const SizedBox(width: 5),
                    const Icon(Icons.star, color: Colors.orange, size: 18),
                  ],
                ),
                Text(_ratingDisplay,
                    style:
                        TextStyle(color: subTextColor, fontSize: 13)),
                const SizedBox(height: 12),
              ],
              Text(context.l10n.myInfoLabel,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor),
                  textAlign: TextAlign.right),
            ],
          ),
        ),
        const SizedBox(width: 15),
        Padding(
          padding: const EdgeInsets.only(top: 15),
          child: Container(
            width: 75,
            height: 75,
            decoration: BoxDecoration(
              color:
                  isDark ? const Color(0xFF2C2C2C) : primaryBlue,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withValues(alpha: isDark ? 0.3 : 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _initial,
                style: TextStyle(
                    color:
                        isDark ? accentOrange : Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoField(String text, Color cardBg, Color textColor) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
          color: cardBg, borderRadius: BorderRadius.circular(25)),
      child: Text(text,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: textColor)),
    );
  }

  Widget _buildExperienceCard(Color cardBg, Color textColor) {
    return Column(
      children: [
        // Experience & categories card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: cardBg, borderRadius: BorderRadius.circular(25)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(context.l10n.experienceAndJobs,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: textColor)),
              const SizedBox(height: 10),
              if (_jobLabel.isNotEmpty)
                ..._jobLabel.split(' ، ').map((j) => Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(j, style: TextStyle(color: textColor)),
                        const SizedBox(width: 10),
                        const Icon(Icons.check_circle,
                            color: Colors.green, size: 20),
                      ],
                    )),
              const SizedBox(height: 10),
              Text(context.l10n.yearsExpDisplay(_experienceYears),
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: textColor)),
            ],
          ),
        ),

        // Bio card
        if (_bio.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: cardBg, borderRadius: BorderRadius.circular(25)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(context.l10n.bio,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textColor)),
                const SizedBox(height: 10),
                Text(_bio,
                    textAlign: TextAlign.right,
                    style:
                        TextStyle(color: textColor, height: 1.5, fontSize: 14)),
              ],
            ),
          ),
        ],

        // Services offered card
        if (_servicesOffered.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: cardBg, borderRadius: BorderRadius.circular(25)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(context.l10n.offeredServices,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textColor)),
                const SizedBox(height: 10),
                Text(_servicesOffered,
                    textAlign: TextAlign.right,
                    style:
                        TextStyle(color: textColor, height: 1.5, fontSize: 14)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEditButton(BuildContext context, Color appBarBg) {
    return Center(
      child: ElevatedButton(
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const EditProfilePage())),
        style: ElevatedButton.styleFrom(
          backgroundColor: appBarBg,
          padding:
              const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15)),
          elevation: 2,
        ),
        child: Text(context.l10n.edit,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, bool isDark) {
    final Color navBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
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
            icon: const Icon(Icons.person, size: 30),
            color: iconInactiveColor,
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        const ProviderProfilePage())),
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, size: 28),
            color: iconInactiveColor,
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ChatsByProvider())),
          ),
          IconButton(
            icon: const Icon(Icons.location_on_outlined, size: 30),
            color: iconInactiveColor,
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        const ProviderMapScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.home_outlined, size: 30),
            color: iconInactiveColor,
            onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        const ProviderHomePage())),
          ),
        ],
      ),
    );
  }
}
