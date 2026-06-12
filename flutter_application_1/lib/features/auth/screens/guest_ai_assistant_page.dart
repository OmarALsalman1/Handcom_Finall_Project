import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:handcom/shared/widgets/theme_provider.dart';
import 'package:handcom/core/l10n/app_strings.dart';
import 'guest_home_screen.dart';

class GuestAiAssistantPage extends StatefulWidget {
  const GuestAiAssistantPage({super.key});

  @override
  State<GuestAiAssistantPage> createState() => _GuestAiAssistantPageState();
}

class _GuestAiAssistantPageState extends State<GuestAiAssistantPage> {
  static const Color primaryBlue = Color(0xFF1A3D81);
  static const Color accentOrange = Color(0xFFF58220);

  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _requireLogin() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    GuestHomeScreen.showLoginRequiredDialog(context, isDark);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final bool isDark = themeProvider.isDarkMode;
        final Color scaffoldBg = isDark ? const Color(0xFF121212) : Colors.white;
        final Color appBarBg = isDark ? const Color(0xFF1A1A1A) : primaryBlue;
        final Color inputAreaBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final Color textFieldBg = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF1F1F1);
        final Color textColor = isDark ? Colors.white : Colors.black87;

        return Scaffold(
          backgroundColor: scaffoldBg,
          bottomNavigationBar: _buildBottomNav(context, isDark),
          body: Column(
            children: [
              _buildHeader(context, appBarBg),
              Expanded(
                child: ListView(
                  controller: _scroll,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  children: [
                    _buildAiBubble(context.l10n.aiWelcome, isDark, textColor),
                  ],
                ),
              ),
              _buildInputArea(inputAreaBg, textFieldBg, textColor, isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, Color appBarBg) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [appBarBg, accentOrange],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white, size: 22),
                onPressed: () => Navigator.pop(context),
              ),
              const Spacer(),
              Row(
                children: [
                  Text(
                    context.l10n.aiAssistant,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome,
                        color: Colors.white, size: 20),
                  ),
                ],
              ),
              const Spacer(),
              const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAiBubble(String text, bool isDark, Color textColor) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            margin: const EdgeInsets.only(right: 8, bottom: 10),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE3EEFF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome,
                size: 16, color: Color(0xFF1A3D81)),
          ),
          Flexible(
            child: Container(
              margin: const EdgeInsets.only(bottom: 10, right: 50),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF0F4FF),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                border: isDark ? Border.all(color: Colors.white12, width: 0.5) : null,
              ),
              child: Text(
                text,
                textAlign: TextAlign.right,
                style: TextStyle(color: textColor, fontSize: 15, height: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(
      Color inputAreaBg, Color textFieldBg, Color textColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      decoration: BoxDecoration(
        color: inputAreaBg,
        border: Border(
            top: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _buildAttachBtn(Icons.image, isDark),
            const SizedBox(width: 4),
            _buildAttachBtn(Icons.camera_alt, isDark),
            const SizedBox(width: 4),
            _buildAttachBtn(Icons.mic, isDark),
            const SizedBox(width: 6),
            Expanded(
              child: GestureDetector(
                onTap: _requireLogin,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 100),
                  decoration: BoxDecoration(
                    color: textFieldBg,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _input,
                    enabled: false,
                    maxLines: null,
                    textAlign: TextAlign.right,
                    style: TextStyle(color: textColor, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: context.l10n.typeMessage,
                      hintStyle: TextStyle(
                          color: isDark ? Colors.white38 : Colors.black38,
                          fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: _requireLogin,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  gradient:
                      LinearGradient(colors: [primaryBlue, accentOrange]),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachBtn(IconData icon, bool isDark) {
    return GestureDetector(
      onTap: _requireLogin,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF1F1F1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            size: 20,
            color: isDark ? Colors.white60 : Colors.black54),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, bool isDark) {
    final Color navBg =
        isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE8E8E8);
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
              onPressed: _requireLogin,
            ),
            IconButton(
              icon: Icon(Icons.chat_bubble_outline, color: iconColor),
              onPressed: _requireLogin,
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? accentOrange : primaryBlue,
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
            ),
            IconButton(
              icon: Icon(Icons.location_on_outlined, color: iconColor),
              onPressed: _requireLogin,
            ),
            IconButton(
              icon: Icon(Icons.home_outlined, color: iconColor, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
