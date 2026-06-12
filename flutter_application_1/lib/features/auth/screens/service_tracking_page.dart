import 'package:flutter/material.dart';
import 'package:handcom/core/l10n/app_strings.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:handcom/features/auth/screens/chats_by_provider.dart';
import 'package:handcom/features/auth/screens/provider_map_screen.dart';
import 'package:handcom/features/auth/screens/provider_profile_page.dart';
import 'package:handcom/features/auth/screens/customer_location_view_page.dart';
import 'package:handcom/shared/widgets/theme_provider.dart';
import 'package:handcom/services/request_service.dart';
import 'provider_home_page.dart';

class ServiceTrackingPage extends StatefulWidget {
  final int? requestId;
  final ServiceRequestModel? request;

  const ServiceTrackingPage({super.key, this.requestId, this.request});

  @override
  State<ServiceTrackingPage> createState() => _ServiceTrackingPageState();
}

class _ServiceTrackingPageState extends State<ServiceTrackingPage> {
  static const Color primaryBlue = Color(0xFF1A3D81);
  static const Color accentOrange = Color(0xFFF58220);
  static const Color lightBlueBg = Color(0xFFEEF4FF);

  ServiceRequestModel? _request;
  bool _isLoading = true;
  bool _isActing = false;

  @override
  void initState() {
    super.initState();
    if (widget.request != null) {
      _request = widget.request;
      _isLoading = false;
    } else if (widget.requestId != null) {
      _loadRequest();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadRequest() async {
    final r = await RequestService.getById(widget.requestId!);
    if (!mounted) return;
    setState(() {
      _request = r;
      _isLoading = false;
    });
  }

  // Parse "lat, lng" string back to LatLng
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

  // Status → which step is active (0, 1, or 2)
  int _activeStep(String? status) {
    switch (status) {
      case 'accepted':
        return 0;
      case 'in_progress':
        return 1;
      case 'completed':
        return 2;
      default:
        return 0;
    }
  }

  Future<void> _advanceStatus() async {
    if (_request == null || _isActing) return;
    final currentStatus = _request!.status;
    final nextStatus =
        currentStatus == 'accepted' ? 'in_progress' : 'completed';

    setState(() => _isActing = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final ok = await RequestService.updateStatus(_request!.id, nextStatus);
    if (!mounted) return;
    setState(() => _isActing = false);

    if (!ok) {
      messenger.showSnackBar(SnackBar(
        content: Text(context.l10n.completeFailed, textAlign: TextAlign.center),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    // Update local state so the UI reflects the new step immediately
    setState(() {
      _request = ServiceRequestModel(
        id: _request!.id,
        serviceType: _request!.serviceType,
        location: _request!.location,
        description: _request!.description,
        status: nextStatus,
        providerName: _request!.providerName,
        userName: _request!.userName,
        createdAt: _request!.createdAt,
        serviceProviderId: _request!.serviceProviderId,
        serviceId: _request!.serviceId,
      );
    });

    if (nextStatus == 'completed') {
      messenger.showSnackBar(SnackBar(
        content: Text(context.l10n.completedSuccess, textAlign: TextAlign.center),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ));
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ProviderHomePage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final bool isDark = themeProvider.isDarkMode;
        final Color bgColor =
            isDark ? const Color(0xFF121212) : Colors.white;
        final Color cardColor =
            isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final Color textColor = isDark ? Colors.white : Colors.black87;
        final Color subTextColor = isDark ? Colors.white70 : Colors.grey;

        return Scaffold(
          backgroundColor: bgColor,
          body: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _request == null
                        ? Center(
                            child: Text(context.l10n.loadFailed,
                                style:
                                    TextStyle(color: textColor, fontSize: 16)),
                          )
                        : SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: _buildMainCard(
                                context, cardColor, textColor, subTextColor, context.l10n.isAr),
                          ),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomNav(context, isDark),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: primaryBlue,
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(40),
            bottomRight: Radius.circular(40)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Center(
                  child: Text(context.l10n.trackOrder,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainCard(BuildContext context, Color cardColor, Color textColor,
      Color subTextColor, bool isAr) {
    final l10n = AppStrings(isAr);
    final step = _activeStep(_request?.status);
    final latLng = _parseLocation(_request?.location);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildStepper(step, isAr),
          const SizedBox(height: 30),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: lightBlueBg, borderRadius: BorderRadius.circular(15)),
            child: Text(
                l10n.checkProcedures,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: primaryBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 20),
          Text(l10n.orderDetails,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: textColor)),
          const SizedBox(height: 20),

          // Location row with map button
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (latLng != null)
                InkWell(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CustomerLocationViewPage(
                                customerName:
                                    _request?.userName ?? l10n.clientLabel,
                                addressDetails:
                                    _request?.location ?? '—',
                                customerLocation: latLng,
                              ))),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                        color: accentOrange,
                        borderRadius: BorderRadius.circular(15)),
                    child: Row(children: [
                      const Icon(Icons.map_outlined,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 5),
                      Text(l10n.clientLocationBtn,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold))
                    ]),
                  ),
                ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(l10n.addressLabel,
                      style:
                          TextStyle(color: subTextColor, fontSize: 12)),
                  Text(
                    _request?.location ?? '—',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: textColor),
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              const SizedBox(width: 10),
              const Icon(Icons.location_on, color: accentOrange, size: 24),
            ],
          ),
          const SizedBox(height: 15),

          // Client name
          if (_request?.userName != null && _request!.userName!.isNotEmpty)
            _buildInfoRow(l10n.clientNameLabel, _request!.userName!,
                Icons.person_outline, textColor, subTextColor),

          // Service type
          _buildInfoRow(
              l10n.serviceTypeLabel,
              _request?.serviceTypeLabel(isAr) ?? '—',
              Icons.settings,
              textColor,
              subTextColor),

          // Date
          _buildInfoRow(
              l10n.orderDateLabel,
              _formatDate(_request?.createdAt, isAr),
              Icons.access_time,
              textColor,
              subTextColor),

          // Status
          _buildInfoRow(
              l10n.statusLabel,
              _request?.statusLabel(isAr) ?? '—',
              Icons.info_outline,
              textColor,
              subTextColor),

          const SizedBox(height: 30),

          // Action button — label and behaviour depend on current status
          if (_request?.status == 'accepted' ||
              _request?.status == 'in_progress')
            Center(
              child: ElevatedButton(
                onPressed: _isActing ? null : _advanceStatus,
                style: ElevatedButton.styleFrom(
                    backgroundColor: accentOrange,
                    minimumSize: const Size(180, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25))),
                child: _isActing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _request?.status == 'accepted'
                            ? 'بدء التنفيذ'
                            : l10n.endOrderBtn,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
              ),
            ),

          if (_request?.status == 'completed')
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.green, width: 1.5)),
                child: Text(l10n.orderCompletedBadge,
                    style: const TextStyle(
                        color: Colors.green,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepper(int activeStep, bool isAr) {
    final l10n = AppStrings(isAr);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepItem(l10n.stepConfirm, Icons.check, activeStep >= 0, activeStep > 0),
        _buildLine(activeStep >= 1),
        _buildStepItem(l10n.stepStart, Icons.build, activeStep >= 1, activeStep > 1),
        _buildLine(activeStep >= 2),
        _buildStepItem(l10n.stepDone, Icons.check_circle, activeStep >= 2, false),
      ],
    );
  }

  Widget _buildStepItem(
      String label, IconData icon, bool isActive, bool isDone) {
    Color bg = Colors.grey.shade300;
    if (isDone) bg = Colors.green;
    if (isActive && !isDone) bg = Colors.green;

    return Column(
      children: [
        CircleAvatar(
            radius: 15,
            backgroundColor: bg,
            child: isActive
                ? Icon(icon, color: Colors.white, size: 16)
                : null),
        const SizedBox(height: 8),
        Text(label,
            style: const TextStyle(
                fontSize: 9, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildLine(bool isActive) => Container(
      width: 40,
      height: 2,
      color: isActive ? Colors.green : Colors.grey.shade300,
      margin: const EdgeInsets.only(bottom: 25));

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
                Text(title,
                    style:
                        TextStyle(color: subTextColor, fontSize: 12)),
                Text(value,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: textColor),
                    textAlign: TextAlign.right),
              ],
            ),
          ),
          const SizedBox(width: 15),
          Icon(icon, color: accentOrange, size: 24),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, bool isDark) {
    final Color navBgColor =
        isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final Color iconColor = isDark ? Colors.white70 : Colors.grey;

    return Container(
      height: 80,
      decoration: BoxDecoration(
          color: navBgColor,
          border: const Border(top: BorderSide(color: Colors.black12))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
              icon: Icon(Icons.person_outline, color: iconColor, size: 28),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ProviderProfilePage()))),
          IconButton(
              icon: Icon(Icons.chat_bubble_outline,
                  color: iconColor, size: 26),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ChatsByProvider()))),
          IconButton(
              icon: Icon(Icons.location_on_outlined,
                  color: iconColor, size: 28),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ProviderMapScreen()))),
          IconButton(
              icon: Icon(Icons.home_outlined, color: iconColor, size: 28),
              onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ProviderHomePage()),
                  (route) => false)),
        ],
      ),
    );
  }
}
