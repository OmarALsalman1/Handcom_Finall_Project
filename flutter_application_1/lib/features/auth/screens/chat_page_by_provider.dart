import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // استيراد الـ Provider للاستماع للثيم
import 'package:image_picker/image_picker.dart'; 
import 'package:handcom/shared/widgets/theme_provider.dart'; // تأكد من صحة مسار الملف في مشروعك
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart'; // استيراد بكج مشغل الصوت الجديد

class ChatPageByProvider extends StatefulWidget {
  const ChatPageByProvider({super.key});

  @override
  State<ChatPageByProvider> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPageByProvider> {
  static const Color primaryBlue = Color(0xFF1A3D81);
  final Color accentOrange = const Color(0xFFF58220);

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isRecording = false;
  bool _isTextEmpty = true;
  String? _currentlyPlayingPath; // لمتابعة الفويس الشغال حالياً

  final List<Map<String, dynamic>> _messages = [
    {
      "text": "السلام عليكم  لقد وصلت",
      "time": "10:15 ص",
      "isMe": false,
      "isImage": false,
      "isVoice": false,
    },
    {
      "text": "وعليكم السلام، حسنًا", 
      "time": "10:16 ص", 
      "isMe": true,
      "isImage": false,
      "isVoice": false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      setState(() {
        _isTextEmpty = _messageController.text.trim().isEmpty;
      });
    });
  }

  String _getFormattedTime() {
    final int hour = DateTime.now().hour;
    final int minute = DateTime.now().minute;
    final String period = hour >= 12 ? "م" : "ص";
    final int formattedHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final String formattedMinute = minute < 10 ? "0$minute" : "$minute";
    return "$formattedHour:$formattedMinute $period";
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      setState(() {
        _messages.add({
          "text": _messageController.text.trim(),
          "time": _getFormattedTime(),
          "isMe": true,
          "isImage": false,
          "isVoice": false,
        });
      });
      _messageController.clear();
      _scrollToBottom();
    }
  }

  Future<void> _startVoiceRecord() async {
    try {
      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) return;

      final dir = await getTemporaryDirectory();
      final filePath = "${dir.path}/chat_voice_${DateTime.now().millisecondsSinceEpoch}.m4a";

      await _audioRecorder.start(
        const RecordConfig(),
        path: filePath,
      );

      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      debugPrint("Record Start Error: $e");
    }
  }

  Future<void> _stopAndSendVoiceRecord() async {
    try {
      if (!_isRecording) return;
      
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
      });

      if (path != null) {
        setState(() {
          _messages.add({
            "text": "🎙️ رسالة صوتية",
            "voicePath": path,
            "time": _getFormattedTime(),
            "isMe": true,
            "isImage": false,
            "isVoice": true,
          });
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint("Record Stop Error: $e");
      setState(() {
        _isRecording = false;
      });
    }
  }

  Future<void> _playVoiceMessage(String path) async {
    try {
      if (_currentlyPlayingPath == path) {
        await _audioPlayer.stop();
        setState(() {
          _currentlyPlayingPath = null;
        });
      } else {
        await _audioPlayer.play(DeviceFileSource(path));
        setState(() {
          _currentlyPlayingPath = path;
        });

        _audioPlayer.onPlayerComplete.listen((event) {
          setState(() {
            _currentlyPlayingPath = null;
          });
        });
      }
    } catch (e) {
      debugPrint("Audio Play Error: $e");
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _messages.add({
          "imagePath": image.path,
          "time": _getFormattedTime(),
          "isMe": true,
          "isImage": true,
          "isVoice": false,
        });
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose(); 
    super.dispose();
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
        final Color textColor = isDark ? Colors.white : Colors.black;

        final Color myBubbleColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF1F1F1);
        final Color otherBubbleColor = isDark ? const Color(0xFF1A3D81).withOpacity(0.4) : const Color(0xFFB4C1D9);
        final Color otherBubbleTextColor = isDark ? Colors.white : Colors.black;

        return Scaffold(
          backgroundColor: scaffoldBg,
          appBar: _buildCustomAppBar(context, appBarBg, isDark),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    return _buildMessageBubble(msg, myBubbleColor, otherBubbleColor, textColor, otherBubbleTextColor, isDark);
                  },
                ),
              ),
              _buildInputArea(inputAreaBg, textFieldBg, textColor, isDark),
            ],
          ),
        );
      },
    );
  }

  // --- ✅ تم تعديل الـ AppBar وإزالة زر "الطلب" ليتسع الهيدر ويصبح متناسقاً ---
  PreferredSizeWidget _buildCustomAppBar(BuildContext context, Color appBarBg, bool isDark) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(90),
      child: AppBar(
        backgroundColor: appBarBg,
        elevation: 0,
        automaticallyImplyLeading: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
        ),
        flexibleSpace: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 22),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      "لين سربل",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "متصل الآن",
                      style: TextStyle(color: isDark ? Colors.greenAccent : Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  radius: 22,
                  backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade400,
                  child: const Icon(Icons.person, color: Colors.white, size: 25),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, Color myBubbleColor, Color otherBubbleColor, Color myTextColor, Color otherTextColor, bool isDark) {
    bool isMe = msg['isMe'] ?? false;
    bool isImage = msg['isImage'] ?? false;
    bool isVoice = msg['isVoice'] ?? false;
    String? voicePath = msg['voicePath'];

    bool isPlaying = isVoice && _currentlyPlayingPath == voicePath;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 250),
        decoration: BoxDecoration(
          color: isMe ? myBubbleColor : otherBubbleColor,
          borderRadius: BorderRadius.circular(15),
          border: isDark ? Border.all(color: Colors.white10, width: 0.5) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (isImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(File(msg['imagePath'])),
              )
            else if (isVoice && voicePath != null)
              GestureDetector(
                onTap: () => _playVoiceMessage(voicePath),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPlaying ? Icons.stop_circle_rounded : Icons.play_arrow_rounded, 
                      color: isMe ? (isDark ? accentOrange : primaryBlue) : otherTextColor, 
                      size: 26
                    ),
                    const SizedBox(width: 5),
                    Container(width: 100, height: 3, color: isMe ? Colors.grey.shade400 : Colors.white70),
                    const SizedBox(width: 8),
                    Icon(Icons.mic, color: isMe ? (isDark ? Colors.white60 : Colors.black54) : otherTextColor, size: 16),
                  ],
                ),
              )
            else
              Text(
                msg['text'],
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  color: isMe ? (isDark ? Colors.white : Colors.black) : otherTextColor,
                ),
                textAlign: TextAlign.right,
              ),
            const SizedBox(height: 4),
            Text(
              msg['time'],
              style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(Color inputAreaBg, Color textFieldBg, Color textColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      color: inputAreaBg,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.link, color: isDark ? Colors.white60 : Colors.black54, size: 28),
              onPressed: _pickImage,
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Container(
                height: 45,
                decoration: BoxDecoration(
                  color: textFieldBg,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        textAlign: TextAlign.right,
                        style: TextStyle(color: textColor, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: _isRecording ? "جاري تسجيل فويس..." : "...اكتب رسالتك",
                          hintStyle: TextStyle(color: _isRecording ? Colors.red : (isDark ? Colors.white38 : Colors.black38), fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            _isTextEmpty
                ? GestureDetector(
                    onLongPressStart: (_) async {
                      await _startVoiceRecord();
                    },
                    onLongPressEnd: (_) async {
                      await _stopAndSendVoiceRecord();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _isRecording ? Colors.red : (isDark ? const Color(0xFF2C2C2C) : const Color(0xFFB4C1D9)), 
                        shape: BoxShape.circle,
                        border: isDark ? Border.all(color: Colors.white10) : null,
                      ),
                      child: Icon(
                        _isRecording ? Icons.stop : Icons.mic, 
                        color: _isRecording ? Colors.white : primaryBlue, 
                        size: 23
                      ),
                    ),
                  )
                : GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFB4C1D9), 
                        shape: BoxShape.circle,
                        border: isDark ? Border.all(color: Colors.white10) : null,
                      ),
                      child: const Icon(
                        Icons.send_rounded, 
                        color: primaryBlue, 
                        size: 23
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}