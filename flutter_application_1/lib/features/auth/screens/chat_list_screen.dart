import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:handcom/features/auth/screens/home_page.dart';
import 'package:handcom/features/auth/screens/profile_page.dart';
import 'package:handcom/shared/widgets/theme_provider.dart';
import 'package:handcom/providers/user_auth_provider.dart';
import 'package:handcom/services/chat_service.dart';
import 'package:handcom/core/l10n/app_strings.dart';
import 'chat_page.dart';
import 'ai_assistant_page.dart';
import 'map_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  static const Color primaryBlue = Color(0xFF1D3A8A);
  static const Color accentOrange = Color(0xFFF58220);

  List<ConversationModel> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    final convs = await ChatService.getMyConversations();
    if (!mounted) return;
    setState(() {
      _conversations = convs;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, UserAuthProvider>(
      builder: (context, themeProvider, auth, child) {
        final bool isDark = themeProvider.isDarkMode;

        final Color scaffoldBg =
            isDark ? const Color(0xFF121212) : const Color(0xFFF2F2F2);
        final Color appBarBg =
            isDark ? const Color(0xFF1A1A1A) : primaryBlue;
        final Color cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final Color titleColor = isDark ? Colors.white : primaryBlue;
        final Color messageColor =
            isDark ? Colors.white60 : Colors.grey.shade600;

        return Scaffold(
          backgroundColor: scaffoldBg,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(130.0),
            child: AppBar(
              backgroundColor: appBarBg,
              elevation: 0,
              automaticallyImplyLeading: false,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(35),
                  bottomRight: Radius.circular(35),
                ),
              ),
              flexibleSpace: Padding(
                padding: const EdgeInsets.only(top: 50),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white, size: 22),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        context.l10n.chatsTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _conversations.isEmpty
                  ? Center(
                      child: Text(
                        context.l10n.noChats,
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadConversations,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 10),
                        itemCount: _conversations.length,
                        itemBuilder: (context, index) {
                          final conv = _conversations[index];
                          final partnerName = auth.isProvider
                              ? conv.userName
                              : conv.providerName;
                          return _buildChatItem(
                            context: context,
                            conv: conv,
                            partnerName: partnerName.isNotEmpty
                                ? partnerName
                                : '${context.l10n.chatsTitle} #${conv.id}',
                            cardBg: cardBg,
                            titleColor: titleColor,
                            messageColor: messageColor,
                            isDark: isDark,
                          );
                        },
                      ),
                    ),
          bottomNavigationBar: _buildBottomNav(context, isDark),
        );
      },
    );
  }

  Widget _buildChatItem({
    required BuildContext context,
    required ConversationModel conv,
    required String partnerName,
    required Color cardBg,
    required Color titleColor,
    required Color messageColor,
    required bool isDark,
  }) {
    final initial =
        partnerName.isNotEmpty ? partnerName.substring(0, 1) : '؟';
    final statusColor = conv.isClosed ? Colors.grey : Colors.green;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(
            conversationId: conv.id,
            partnerName: partnerName,
          ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  conv.isClosed ? context.l10n.closedChat : context.l10n.openChat,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  partnerName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${context.l10n.chatsTitle} #${conv.id}',
                  style: TextStyle(color: messageColor, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(width: 15),
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? const Color(0xFF2C2C2C)
                    : const Color(0xFFE3EEFF),
                border: Border.all(
                    color: accentOrange.withOpacity(0.3), width: 2),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: TextStyle(
                    color: isDark ? accentOrange : primaryBlue,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
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
            const Icon(Icons.chat_bubble, color: accentOrange, size: 30),
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
                child:
                    const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
              ),
            ),
            IconButton(
              icon:
                  Icon(Icons.location_on_outlined, color: iconColor, size: 28),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const MapScreen())),
            ),
            IconButton(
              icon: Icon(Icons.home_outlined, color: iconColor, size: 28),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const HomePage())),
            ),
          ],
        ),
      ),
    );
  }
}
