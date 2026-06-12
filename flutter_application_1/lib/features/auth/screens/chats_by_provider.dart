import 'package:flutter/material.dart';
import 'package:handcom/features/auth/screens/provider_map_screen.dart';
import 'package:provider/provider.dart';
import 'package:handcom/features/auth/screens/provider_home_page.dart';
import 'package:handcom/shared/widgets/theme_provider.dart';
import 'package:handcom/services/chat_service.dart';
import 'package:handcom/core/l10n/app_strings.dart';
import 'chat_page.dart';
import 'provider_profile_page.dart';

class ChatsByProvider extends StatefulWidget {
  const ChatsByProvider({super.key});

  @override
  State<ChatsByProvider> createState() => _ChatsByProviderState();
}

class _ChatsByProviderState extends State<ChatsByProvider> {
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

  String _formatTime(String iso, BuildContext context) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final m = dt.minute.toString().padLeft(2, '0');
      final p = dt.hour >= 12 ? context.l10n.pm : context.l10n.am;
      return '$h:$m $p';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
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
                            fontSize: 24),
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
                            color:
                                isDark ? Colors.white54 : Colors.grey,
                            fontSize: 16),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadConversations,
                      child: ListView.builder(
                        physics:
                            const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 10),
                        itemCount: _conversations.length,
                        itemBuilder: (context, index) {
                          final conv = _conversations[index];
                          return _buildChatItem(
                            context: context,
                            conv: conv,
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
    required Color cardBg,
    required Color titleColor,
    required Color messageColor,
    required bool isDark,
  }) {
    // Provider sees the user's (client) name
    final clientName =
        conv.userName.isNotEmpty ? conv.userName : context.l10n.clientConvNum(conv.id);
    final initial =
        clientName.isNotEmpty ? clientName.substring(0, 1) : '؟';
    final timeStr = _formatTime(conv.startedAt, context);
    final statusColor =
        conv.isClosed ? Colors.grey : Colors.green;

    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ChatPage(
                    conversationId: conv.id,
                    partnerName: clientName,
                  ))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(timeStr,
                    style: TextStyle(
                        color: isDark ? Colors.white38 : Colors.grey,
                        fontSize: 11)),
                const SizedBox(height: 6),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                      color: statusColor, shape: BoxShape.circle),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(clientName,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: titleColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(
                    conv.isClosed ? context.l10n.closedChat : context.l10n.openChat,
                    style: TextStyle(
                        color: statusColor, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? const Color(0xFF2C2C2C)
                    : const Color(0xFFE3EEFF),
                border: Border.all(
                    color: accentOrange.withValues(alpha: 0.3),
                    width: 1.5),
              ),
              child: Center(
                child: Text(initial,
                    style: TextStyle(
                        color: isDark ? accentOrange : primaryBlue,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, bool isDark) {
    final Color navBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color iconActiveColor =
        isDark ? accentOrange : primaryBlue;
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
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        const ProviderProfilePage())),
            icon: Icon(Icons.person_outline,
                size: 30, color: iconInactiveColor),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.chat_bubble,
                size: 28, color: iconActiveColor),
          ),
          IconButton(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        const ProviderMapScreen())),
            icon: Icon(Icons.location_on_outlined,
                size: 30, color: iconInactiveColor),
          ),
          IconButton(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        const ProviderHomePage())),
            icon: Icon(Icons.home_outlined,
                size: 30, color: iconInactiveColor),
          ),
        ],
      ),
    );
  }
}
