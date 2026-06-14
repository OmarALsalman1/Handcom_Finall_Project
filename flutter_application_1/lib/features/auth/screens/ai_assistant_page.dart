import 'dart:io';
import 'package:flutter/material.dart';
import 'package:handcom/core/l10n/app_strings.dart';
import 'package:provider/provider.dart';
import 'package:handcom/shared/widgets/theme_provider.dart';
import 'package:handcom/services/ai_service.dart';
import 'package:handcom/features/auth/screens/home_page.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import 'profile_page.dart';
import 'chat_list_screen.dart';
import 'map_screen.dart';
import 'select_location_screen.dart';

// ─── Message models ───────────────────────────────────────────────────────────

abstract class _Msg {}

class _UserMsg extends _Msg {
  final String text;
  _UserMsg(this.text);
}

class _AiMsg extends _Msg {
  final String text;
  final List<AiProviderSuggestion> providers;
  final int? conversationId;
  _AiMsg(this.text, {this.providers = const [], this.conversationId});
}

class _TypingMsg extends _Msg {}

// ─── Page ─────────────────────────────────────────────────────────────────────

class AiAssistantPage extends StatefulWidget {
  const AiAssistantPage({super.key});

  @override
  State<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends State<AiAssistantPage> {
  static const Color primaryBlue = Color(0xFF1A3D81);
  static const Color accentOrange = Color(0xFFF58220);

  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _recorder = AudioRecorder();

  final List<_Msg> _messages = [];
  int? _activeConversationId;
  bool _isRecording = false;
  File? _pendingImage;
  String? _pendingAudio;

  bool _welcomeAdded = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_welcomeAdded) {
      _welcomeAdded = true;
      _messages.add(_AiMsg(context.l10n.aiWelcome));
    }
  }

  Future<void> _requestPermissions() async {
    await [Permission.microphone, Permission.camera].request();
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    _recorder.dispose();
    super.dispose();
  }

  // ── Send message ────────────────────────────────────────────────────────────

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty && _pendingImage == null && _pendingAudio == null) return;

    _input.clear();
    final image = _pendingImage;
    final audio = _pendingAudio;
    setState(() {
      _pendingImage = null;
      _pendingAudio = null;
      if (text.isNotEmpty) _messages.add(_UserMsg(text));
      if (image != null) _messages.add(_UserMsg(context.l10n.isAr ? '📷 صورة' : '📷 Image'));
      if (audio != null) _messages.add(_UserMsg(context.l10n.isAr ? '🎙️ رسالة صوتية' : '🎙️ Voice note'));
      _messages.add(_TypingMsg());
    });
    _scrollToBottom();

    final l10n = context.l10n;
    final lang = l10n.isAr ? 'ar' : 'en';
    final response = await AiService.sendMessage(
      text: text.isNotEmpty ? text : null,
      image: image,
      voice: audio != null ? File(audio) : null,
      conversationId: _activeConversationId,
      lang: lang,
    );

    if (!mounted) return;
    setState(() {
      _messages.removeWhere((m) => m is _TypingMsg);
      if (response.success) {
        _activeConversationId = response.conversationId;
        _messages.add(_AiMsg(
          response.aiMessage ?? (l10n.isAr ? 'فهمت مشكلتك، دعني أساعدك.' : 'Got it, let me help you.'),
          providers: response.providers,
          conversationId: response.conversationId,
        ));
      } else {
        _messages.add(_AiMsg(
            l10n.errorMessage(response.errorCode, fallback: response.error)));
      }
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Attachments ─────────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(
          source: ImageSource.gallery, imageQuality: 80);
      if (picked != null && mounted) {
        setState(() => _pendingImage = File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.l10n.galleryError),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _pickCamera() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) status = await Permission.camera.request();
    if (!mounted) return;
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.l10n.cameraPermission),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    try {
      final picked = await _picker.pickImage(
          source: ImageSource.camera, imageQuality: 80);
      if (picked != null && mounted) {
        setState(() => _pendingImage = File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.l10n.cameraError),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      try {
        final path = await _recorder.stop();
        if (!mounted) return;
        setState(() {
          _isRecording = false;
          _pendingAudio = path;
        });
      } catch (e) {
        if (mounted) setState(() => _isRecording = false);
      }
      return;
    }

    // Check / request microphone permission
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
    }
    if (!mounted) return;
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.l10n.micPermission),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    // Start recording
    try {
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/ai_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(), path: path);
      if (!mounted) return;
      setState(() => _isRecording = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.l10n.isAr ? 'تعذّر تشغيل الميكروفون: $e' : 'Microphone error: $e'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  // ── Request provider dialog ─────────────────────────────────────────────────

  void _showRequestDialog(
      AiProviderSuggestion provider, int? conversationId, bool isDark) async {
    // Open the map picker — user taps to place a pin, confirms with the button
    final LatLng? pickedLocation = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(builder: (_) => const SelectLocationScreen()),
    );

    if (!mounted) return;
    if (pickedLocation == null) return; // user cancelled

    final location =
        '${pickedLocation.latitude.toStringAsFixed(5)}, ${pickedLocation.longitude.toStringAsFixed(5)}';

    _submitRequest(provider, location, conversationId);
  }

  Future<void> _submitRequest(
      AiProviderSuggestion provider, String location, int? convId) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;

    setState(() => _messages.add(_TypingMsg()));
    _scrollToBottom();

    ({bool success, String? error, String? errorCode}) result =
        (success: false, error: null, errorCode: null);
    if (convId != null) {
      result = await AiService.createRequestFromChat(
        conversationId: convId,
        location: location,
        providerId: provider.id,
      );
    }

    if (!mounted) return;
    setState(() => _messages.removeWhere((m) => m is _TypingMsg));

    if (result.success) {
      setState(() {
        _messages.add(_AiMsg(context.l10n.requestSentSuccess));
      });
      _scrollToBottom();
    } else {
      messenger.showSnackBar(SnackBar(
        content: Text(l10n.errorMessage(result.errorCode, fallback: result.error),
            textAlign: TextAlign.center),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final bool isDark = themeProvider.isDarkMode;
        final Color scaffoldBg =
            isDark ? const Color(0xFF121212) : Colors.white;
        final Color appBarBg =
            isDark ? const Color(0xFF1A1A1A) : primaryBlue;
        final Color inputAreaBg =
            isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final Color textFieldBg =
            isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF1F1F1);
        final Color textColor = isDark ? Colors.white : Colors.black87;

        return Scaffold(
          backgroundColor: scaffoldBg,
          bottomNavigationBar: _buildBottomNav(context, isDark),
          body: Column(
            children: [
              _buildHeader(context, appBarBg),
              Expanded(
                child: ListView.builder(
                  controller: _scroll,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  itemCount: _messages.length,
                  itemBuilder: (context, i) => _buildMessage(
                      _messages[i], isDark, textColor),
                ),
              ),
              _buildInputArea(
                  inputAreaBg, textFieldBg, textColor, isDark),
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
          colors: [appBarBg, const Color(0xFFF58220)],
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

  Widget _buildMessage(_Msg msg, bool isDark, Color textColor) {
    if (msg is _TypingMsg) return _buildTyping(isDark);
    if (msg is _UserMsg) return _buildUserBubble(msg.text, isDark);
    if (msg is _AiMsg) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAiBubble(msg.text, isDark, textColor),
          if (msg.providers.isNotEmpty)
            ...msg.providers.map((p) => _buildProviderCard(
                p, msg.conversationId, isDark, textColor)),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildUserBubble(String text, bool isDark) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10, left: 50),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A3D81) : primaryBlue,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.right,
          style: const TextStyle(
              color: Colors.white, fontSize: 15, height: 1.4),
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
              color: isDark
                  ? const Color(0xFF2C2C2C)
                  : const Color(0xFFE3EEFF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome,
                size: 16, color: Color(0xFF1A3D81)),
          ),
          Flexible(
            child: Container(
              margin: const EdgeInsets.only(bottom: 10, right: 50),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E1E1E)
                    : const Color(0xFFF0F4FF),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                border: isDark
                    ? Border.all(color: Colors.white12, width: 0.5)
                    : null,
              ),
              child: Text(
                text,
                textAlign: TextAlign.right,
                style: TextStyle(
                    color: textColor, fontSize: 15, height: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTyping(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF0F4FF),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.l10n.typing,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(width: 8),
            SizedBox(
              width: 30,
              child: LinearProgressIndicator(
                color: const Color(0xFF1A3D81),
                backgroundColor: Colors.grey.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderCard(AiProviderSuggestion p, int? conversationId,
      bool isDark, Color textColor) {
    final statusColor = p.availabilityStatus == 'available'
        ? Colors.green
        : Colors.orange;
    return Container(
      margin: const EdgeInsets.only(bottom: 10, right: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFD0DFF8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Action button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentOrange,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onPressed: () =>
                _showRequestDialog(p, conversationId, isDark),
            child: Text(context.l10n.requestLabel,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const Spacer(),
          // Provider info (RTL)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                p.name,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? Colors.white
                        : const Color(0xFF1E3A8A)),
              ),
              const SizedBox(height: 4),
              Text(
                '${p.categoriesLabel(context.l10n.isAr)} • ${context.l10n.yearsExpDisplay(p.experienceYears)}',
                style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.grey[600]),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(context.l10n.statusFromRaw(p.availabilityStatus),
                        style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11)),
                  ),
                  const SizedBox(width: 10),
                  if (p.averageRating != null) ...[
                    Text(p.ratingDisplay,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.black87)),
                    const SizedBox(width: 3),
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF2C2C2C)
                  : const Color(0xFFE3EEFF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                p.initial,
                style: const TextStyle(
                    color: Color(0xFF1A3D81),
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(Color inputAreaBg, Color textFieldBg,
      Color textColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      decoration: BoxDecoration(
        color: inputAreaBg,
        border: Border(
            top: BorderSide(
                color: isDark ? Colors.white10 : Colors.black12)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pending attachments preview
            if (_pendingImage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(_pendingImage!,
                          height: 80, width: 80, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _pendingImage = null),
                        child: Container(
                          decoration: const BoxDecoration(
                              color: Colors.red, shape: BoxShape.circle),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_pendingAudio != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2C2C2C)
                      : const Color(0xFFE3EEFF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () =>
                          setState(() => _pendingAudio = null),
                      child: const Icon(Icons.close,
                          color: Colors.red, size: 18),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.mic,
                        color: Color(0xFF1A3D81), size: 18),
                    const SizedBox(width: 6),
                    Text(context.l10n.isAr ? 'تسجيل صوتي جاهز' : 'Voice note ready',
                        style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),

            // Input row
            Row(
              children: [
                // Attachment buttons
                _buildAttachBtn(
                    Icons.image,
                    isDark,
                    _pickImage),
                const SizedBox(width: 4),
                _buildAttachBtn(
                    Icons.camera_alt,
                    isDark,
                    _pickCamera),
                const SizedBox(width: 4),
                _buildAttachBtn(
                    _isRecording ? Icons.stop : Icons.mic,
                    isDark,
                    _toggleRecording,
                    color: _isRecording ? Colors.red : null),
                const SizedBox(width: 6),

                // Text field
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 100),
                    decoration: BoxDecoration(
                      color: textFieldBg,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _input,
                      maxLines: null,
                      textAlign: TextAlign.right,
                      style: TextStyle(color: textColor, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: context.l10n.typeMessage,
                        hintStyle: TextStyle(
                            color: isDark
                                ? Colors.white38
                                : Colors.black38,
                            fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Send button
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          colors: [primaryBlue, accentOrange]),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachBtn(IconData icon, bool isDark, VoidCallback onTap,
      {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF2C2C2C)
              : const Color(0xFFF1F1F1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            size: 20,
            color: color ??
                (isDark ? Colors.white60 : Colors.black54)),
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
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ProfilePage())),
            ),
            IconButton(
              icon: Icon(Icons.chat_bubble_outline, color: iconColor, size: 26),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ChatListScreen())),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? accentOrange : primaryBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome,
                  color: Colors.white, size: 22),
            ),
            IconButton(
              icon:
                  Icon(Icons.location_on_outlined, color: iconColor, size: 28),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MapScreen())),
            ),
            IconButton(
              icon: Icon(Icons.home_outlined, color: iconColor, size: 32),
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
