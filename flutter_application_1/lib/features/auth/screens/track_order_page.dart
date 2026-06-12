import 'package:flutter/material.dart';
import 'package:handcom/core/l10n/app_strings.dart';
import 'package:handcom/features/auth/screens/ai_assistant_page.dart';
import 'package:handcom/features/auth/screens/order_tracking_page.dart';
import 'package:handcom/features/auth/screens/rating_page.dart';
import 'package:handcom/services/request_service.dart';
import 'package:provider/provider.dart';
import 'package:handcom/shared/widgets/theme_provider.dart';
import 'package:handcom/features/auth/screens/chat_page.dart';
import 'package:handcom/features/auth/screens/home_page.dart';
import 'package:handcom/services/chat_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'map_screen.dart';
import 'profile_page.dart';
import 'chat_list_screen.dart';

class TrackOrderPage extends StatefulWidget {
  final ServiceRequestModel request;

  const TrackOrderPage({super.key, required this.request});

  @override
  State<TrackOrderPage> createState() => _TrackOrderPageState();
}

class _TrackOrderPageState extends State<TrackOrderPage> {
  static const Color primaryBlue = Color(0xFF1A3D81);
  static const Color accentOrange = Color(0xFFF58220);

  late ServiceRequestModel _current;
  bool _isCancelling = false;
  bool _openingChat = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _current = widget.request;
    // If already completed on open, show rating after first frame
    if (_current.status == 'completed') {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showRatingIfNeeded());
    }
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    final updated = await RequestService.getById(_current.id);
    if (!mounted) return;
    setState(() {
      _isRefreshing = false;
      if (updated != null) _current = updated;
    });
    if (_current.status == 'completed') _showRatingIfNeeded();
  }

  void _showRatingIfNeeded() {
    if (_current.serviceId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RatingPage(serviceId: _current.serviceId)),
    );
  }

  // Parse "lat,lng" string → LatLng, returns null if not coordinates
  LatLng? _parseLocation(String? location) {
    if (location == null || location.isEmpty) return null;
    try {
      final parts = location.split(',');
      if (parts.length >= 2) {
        final lat = double.parse(parts[0].trim());
        final lng = double.parse(parts[1].trim());
        return LatLng(lat, lng);
      }
    } catch (_) {}
    return null;
  }

  String _formatDate(String? iso, bool isAr) {
    if (iso == null) return '—';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final l10n = AppStrings(isAr);
      final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final m = dt.minute.toString().padLeft(2, '0');
      final p = dt.hour >= 12 ? l10n.pm : l10n.am;
      return '${l10n.weekdays[dt.weekday % 7]} | $h:$m $p';
    } catch (_) {
      return iso;
    }
  }

  int _activeStep(String status) {
    switch (status) {
      case 'pending':
      case 'on_hold':
        return -1; // no step active — provider hasn't confirmed yet
      case 'accepted':
        return 0;
      case 'in_progress':
        return 1;
      case 'completed':
        return 2;
      default:
        return -1;
    }
  }

  Future<void> _openChat() async {
    if (_openingChat) return;
    setState(() => _openingChat = true);

    // Capture context-dependent values before the async gap
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final isAr = context.l10n.isAr;

    final conv = await ChatService.getOrCreateConversation(_current.id);

    if (!mounted) return;
    setState(() => _openingChat = false);

    if (conv == null) {
      messenger.showSnackBar(SnackBar(
        content: Text(isAr
            ? 'تعذّر فتح المحادثة، حاول مجدداً'
            : 'Could not open chat, please try again'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    navigator.push(
      MaterialPageRoute(
        builder: (_) => ChatPage(
          conversationId: conv.id,
          partnerName: _current.providerName ?? '',
          providerId: _current.serviceProviderId,
          serviceType: _current.serviceType,
        ),
      ),
    );
  }

  Future<void> _cancelOrder() async {
    if (_isCancelling) return;
    setState(() => _isCancelling = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final l10n = context.l10n;

    final ok = await RequestService.cancelRequest(_current.id);
    if (!mounted) return;
    setState(() => _isCancelling = false);

    if (ok) {
      messenger.showSnackBar(SnackBar(
        content: Text(l10n.orderCancelledMsg, textAlign: TextAlign.center),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ));
      navigator.pop();
    } else {
      messenger.showSnackBar(SnackBar(
        content: Text(l10n.cannotCancelMsg, textAlign: TextAlign.center),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final bool isDark = themeProvider.isDarkMode;
        final bool isAr = context.l10n.isAr;

        final Color scaffoldBg = isDark ? const Color(0xFF121212) : Colors.white;
        final Color appBarBg = isDark ? const Color(0xFF1A1A1A) : primaryBlue;
        final Color cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final Color alertBg = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEEF4FF);
        final Color textColor = isDark ? Colors.white : Colors.black87;
        final Color subTextColor = isDark ? Colors.white60 : Colors.grey;

        return Scaffold(
          backgroundColor: scaffoldBg,
          body: Column(
            children: [
              _buildFixedHeader(context, appBarBg, isAr),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(top: 25, bottom: 20),
                  child: _buildMainCard(
                      context, cardBg, alertBg, textColor, subTextColor, isDark, isAr),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomNav(context, isDark),
        );
      },
    );
  }

  Widget _buildFixedHeader(BuildContext context, Color appBarBg, bool isAr) {
    return Container(
      height: 160,
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
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Center(
              child: Text(
                isAr ? 'متابعة الطلب' : 'Track Order',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _isRefreshing
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: _refresh,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainCard(BuildContext context, Color cardBg, Color alertBg,
      Color textColor, Color subTextColor, bool isDark, bool isAr) {
    final step = _activeStep(_current.status);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
        border: isDark ? Border.all(color: Colors.white10, width: 0.5) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const SizedBox(height: 25),
          _buildStepper(step, textColor, isDark, isAr),
          const SizedBox(height: 25),
          _buildAlertBox(alertBg, isDark, isAr),
          const SizedBox(height: 25),
          _buildWorkerInfo(context, textColor, isDark),
          Divider(color: isDark ? Colors.white10 : Colors.black12, height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSmallTrackButton(context, isAr),
              Text(
                isAr ? 'تفاصيل الطلب' : 'Order Details',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: textColor),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildOrderDetails(textColor, subTextColor, isAr),
          const SizedBox(height: 40),
          if (['pending', 'on_hold'].contains(_current.status)) ...[
            _buildMainCancelButton(isAr),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  Widget _buildStepper(int step, Color textColor, bool isDark, bool isAr) {
    return Column(
      children: [
        // Pending banner — shown only while waiting for provider
        if (step == -1)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.hourglass_top_rounded,
                    color: Colors.orange, size: 16),
                const SizedBox(width: 6),
                Text(
                  isAr ? 'في انتظار قبول الفني' : 'Waiting for provider',
                  style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
              ],
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStepItem(
              isAr ? 'تأكيد الطلب' : 'Confirmed',
              Icons.check,
              step >= 0,
              step > 0,
              textColor,
              isDark,
            ),
            _buildLine(step >= 1, isDark),
            _buildStepItem(
              isAr ? 'بدء التنفيذ' : 'Started',
              Icons.build,
              step >= 1,
              step > 1,
              textColor,
              isDark,
            ),
            _buildLine(step >= 2, isDark),
            _buildStepItem(
              isAr ? 'الانتهاء' : 'Done',
              Icons.check_circle,
              step >= 2,
              false,
              textColor,
              isDark,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepItem(String label, IconData icon, bool isActive, bool isDone,
      Color textColor, bool isDark) {
    Color bg = isDark ? const Color(0xFF333333) : Colors.grey.shade300;
    if (isActive || isDone) bg = Colors.green;
    return Column(
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: bg,
          child: isActive
              ? Icon(icon, color: Colors.white, size: 16)
              : null,
        ),
        const SizedBox(height: 8),
        Text(label,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.bold, color: textColor)),
      ],
    );
  }

  Widget _buildLine(bool isActive, bool isDark) {
    return Container(
      width: 40,
      height: 2,
      color: isActive ? Colors.green : (isDark ? Colors.white10 : Colors.grey.shade300),
      margin: const EdgeInsets.only(bottom: 20),
    );
  }

  Widget _buildAlertBox(Color alertBg, bool isDark, bool isAr) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: alertBg, borderRadius: BorderRadius.circular(15)),
      child: Text(
        isAr
            ? 'تأكد من مطابقة بيانات الفني في التطبيق إذا وصلك'
            : 'Verify the technician\'s info in the app when they arrive',
        textAlign: TextAlign.center,
        style: TextStyle(
            color: isDark ? accentOrange : primaryBlue,
            fontSize: 12,
            fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildWorkerInfo(BuildContext context, Color textColor, bool isDark) {
    final providerName = _current.providerName ?? '—';
    final initial = providerName.isNotEmpty ? providerName.substring(0, 1) : '?';

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _openingChat
            ? const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2, color: primaryBlue),
              )
            : IconButton(
                onPressed: _openChat,
                icon: const Icon(Icons.chat_bubble_outline, color: primaryBlue, size: 28),
              ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              providerName,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
            ),
          ],
        ),
        const SizedBox(width: 15),
        CircleAvatar(
          radius: 25,
          backgroundColor: isDark ? const Color(0xFF333333) : primaryBlue,
          child: Text(
            initial,
            style: TextStyle(
                color: isDark ? accentOrange : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderDetails(Color textColor, Color subTextColor, bool isAr) {
    final r = _current;
    return Column(
      children: [
        _buildInfoRow(
          isAr ? 'العنوان' : 'Address',
          r.location,
          Icons.location_on,
          textColor,
          subTextColor,
        ),
        _buildInfoRow(
          isAr ? 'نوع الخدمة' : 'Service Type',
          r.serviceTypeLabel(isAr),
          Icons.settings,
          textColor,
          subTextColor,
        ),
        _buildInfoRow(
          isAr ? 'موعد الخدمة' : 'Date',
          _formatDate(r.createdAt, isAr),
          Icons.access_time,
          textColor,
          subTextColor,
        ),
        if (r.description.isNotEmpty)
          _buildInfoRow(
            isAr ? 'الوصف' : 'Description',
            r.description,
            Icons.notes,
            textColor,
            subTextColor,
          ),
      ],
    );
  }

  Widget _buildInfoRow(String title, String value, IconData icon,
      Color textColor, Color subTextColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(title, style: TextStyle(color: subTextColor, fontSize: 12)),
                Text(value,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: textColor),
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 15),
          Icon(icon, color: accentOrange, size: 24),
        ],
      ),
    );
  }

  Widget _buildSmallTrackButton(BuildContext context, bool isAr) {
    final latLng = _parseLocation(_current.location);
    return TextButton.icon(
      onPressed: latLng == null
          ? null
          : () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderTrackingPage(
                    orderId: _current.id.toString(),
                    customerLocation: latLng,
                    technicianInitialLocation: latLng,
                  ),
                ),
              ),
      icon: const Icon(Icons.location_searching, color: accentOrange, size: 18),
      label: Text(
        isAr ? 'تتبع الفني' : 'Track Technician',
        style: const TextStyle(
            color: accentOrange, fontSize: 14, fontWeight: FontWeight.bold),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        backgroundColor: accentOrange.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  Widget _buildMainCancelButton(bool isAr) {
    return OutlinedButton(
      onPressed: _isCancelling ? null : _cancelOrder,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red,
        side: const BorderSide(color: Colors.red, width: 1.5),
        minimumSize: const Size(double.infinity, 55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child: _isCancelling
          ? const CircularProgressIndicator(color: Colors.red)
          : Text(
              isAr ? 'إلغاء الطلب' : 'Cancel Order',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
    );
  }

  Widget _buildBottomNav(BuildContext context, bool isDark) {
    final Color navBg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE8E8E8);
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
                  MaterialPageRoute(builder: (_) => const ProfilePage())),
            ),
            IconButton(
              icon: Icon(Icons.chat_bubble_outline, color: iconColor, size: 26),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ChatListScreen())),
            ),
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AiAssistantPage())),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [primaryBlue, accentOrange]),
                    shape: BoxShape.circle),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
              ),
            ),
            IconButton(
              icon: Icon(Icons.location_on_outlined, color: iconColor, size: 28),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MapScreen())),
            ),
            IconButton(
              icon: Icon(Icons.home_outlined, color: iconColor, size: 30),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const HomePage())),
            ),
          ],
        ),
      ),
    );
  }
}
