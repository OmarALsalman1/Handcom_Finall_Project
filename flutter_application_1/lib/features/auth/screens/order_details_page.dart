import 'package:flutter/material.dart';
import 'package:handcom/features/auth/screens/location_picker_page.dart';
import 'package:provider/provider.dart';
import 'package:handcom/shared/widgets/theme_provider.dart';
import 'package:handcom/services/request_service.dart';
import 'package:handcom/core/l10n/app_strings.dart';
import 'select_date_time_page.dart';
import 'home_page.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class OrderDetailsPage extends StatefulWidget {
  final int? providerId;
  final String serviceType;
  final String providerName;
  final String providerInitial;
  final double? averageRating;
  final int totalRatings;

  const OrderDetailsPage({
    super.key,
    this.providerId,
    this.serviceType = 'general',
    this.providerName = '',
    this.providerInitial = '؟',
    this.averageRating,
    this.totalRatings = 0,
  });

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  static const Color primaryBlue = Color(0xFF1A3D81);
  static const Color accentOrange = Color(0xFFF58220);

  bool isSaved = true;
  bool _isSubmitting = false;

  LatLng? _pickedLocation;
  String _locationAddress = '';
  String _selectedDateLabel = '';
  String _selectedTimeLabel = '';
  String? _scheduledForIso;


  @override
  Widget build(BuildContext context) {
    // الاستماع للتغيرات العالمية للـ Dark Mode داخل شاشة تفاصيل الطلب
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final bool isDark = themeProvider.isDarkMode;

        // تهيئة قائمة الألوان المتفاعلة ديناميكياً مع الثيم
        final Color scaffoldBg =
            isDark ? const Color(0xFF121212) : Colors.white;
        final Color appBarBg = isDark ? const Color(0xFF1A1A1A) : primaryBlue;
        final Color tagBg =
            isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF5F5F5);
        final Color textColor = isDark ? Colors.white : Colors.black87;
        final Color iconColor = isDark ? accentOrange : Colors.black87;
        final Color dividerColor = isDark ? Colors.white10 : Colors.black12;

        return Scaffold(
          backgroundColor: scaffoldBg,
          body: Column(
            children: [
              _buildHeader(context, appBarBg),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        context.l10n.workerInfo,
                        style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.grey,
                            fontSize: 14),
                      ),
                      const SizedBox(height: 10),
                      _buildWorkerInfo(textColor, isDark),
                      const SizedBox(height: 20),
                      Divider(color: dividerColor),
                      const SizedBox(height: 10),
                      _buildSectionButtonCenter(context.l10n.selectTime, () async {
                        final result = await Navigator.push<Map<String, String>>(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SelectDateTimePage()),
                        );
                        if (result != null) {
                          setState(() {
                            _selectedDateLabel = result['date'] ?? '';
                            _selectedTimeLabel = result['time'] ?? '';
                            _scheduledForIso = result['iso'];
                          });
                        }
                      }, textColor),
                      const SizedBox(height: 20),
                      _buildInfoTagRight(
                          _selectedDateLabel.isEmpty ? '—' : _selectedDateLabel,
                          Icons.calendar_month_outlined,
                          tagBg,
                          textColor,
                          iconColor),
                      const SizedBox(height: 10),
                      _buildInfoTagRight(
                          _selectedTimeLabel.isEmpty ? '—' : _selectedTimeLabel,
                          Icons.access_time,
                          tagBg, textColor, iconColor),
                      const SizedBox(height: 20),
                      Divider(color: dividerColor),
                      const SizedBox(height: 10),
                      _buildSectionButtonCenter(context.l10n.selectLocation, () async {
                        final LatLng? result = await Navigator.push<LatLng>(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LocationPickerPage()),
                        );
                        if (result != null) {
                          setState(() {
                            _pickedLocation = result;
                            _locationAddress =
                                '${result.latitude.toStringAsFixed(5)}, ${result.longitude.toStringAsFixed(5)}';
                          });
                        }
                      }, textColor),
                      const SizedBox(height: 20),
                      _buildLocationPreviewRight(textColor, isDark),
                      const SizedBox(height: 50),
                      _buildConfirmButton(context, isDark),
                      const SizedBox(height: 20),
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

  // --- الهيدر الأزرق المنحني المتوافق مع الثيم ---
  Widget _buildHeader(BuildContext context, Color appBarBg) {
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
                  icon: const Icon(Icons.arrow_back_ios,
                      color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context)),
            ),
            Center(
              child: Text(
                context.l10n.orderDetails,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- كرت معلومات الفني المطور ديناميكياً ---
  Widget _buildWorkerInfo(Color textColor, bool isDark) {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            isSaved ? Icons.bookmark : Icons.bookmark_border,
            color: isSaved
                ? Colors.orange
                : (isDark ? Colors.white60 : Colors.black),
            size: 30,
          ),
          onPressed: () => setState(() => isSaved = !isSaved),
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              widget.providerName.isNotEmpty ? widget.providerName : '—',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
            ),
            _buildRatingRow(),
          ],
        ),
        const SizedBox(width: 15),
        CircleAvatar(
          radius: 30,
          backgroundColor: isDark ? const Color(0xFF2C2C2C) : primaryBlue,
          child: Text(
            widget.providerInitial,
            style: TextStyle(
              color: isDark ? accentOrange : Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingRow() {
    final rating = widget.averageRating;
    if (rating == null || widget.totalRatings == 0) {
      return Text(
        context.l10n.isAr ? 'لا يوجد تقييم بعد' : 'No ratings yet',
        style: const TextStyle(color: Colors.grey, fontSize: 13),
      );
    }
    final filled = rating.round().clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(rating.toStringAsFixed(1),
            style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(width: 4),
        ...List.generate(5, (i) => Icon(
          Icons.star,
          color: i < filled ? accentOrange : Colors.grey,
          size: 18,
        )),
      ],
    );
  }

  // --- أزرار تبويب الأقسام الموسطة المحدثة بحواف ناعمة ---
  Widget _buildSectionButtonCenter(
      String title, VoidCallback onTap, Color textColor) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 160,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: textColor.withValues(alpha: 0.6)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
            ),
          ),
        ),
      ),
    );
  }

  // --- حقول التواقيت التفاعلية اليمينية ---
  Widget _buildInfoTagRight(String text, IconData icon, Color tagBg,
      Color textColor, Color iconColor) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: 220,
        height: 45,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
            color: tagBg, borderRadius: BorderRadius.circular(25)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              text,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                  fontSize: 14, color: textColor, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 12),
            Icon(icon, size: 20, color: iconColor),
          ],
        ),
      ),
    );
  }

  // --- معاينة الموقع والعنوان الجغرافي مدمج بها الماب الحقيقية المصغرة ---
  Widget _buildLocationPreviewRight(Color textColor, bool isDark) {
    final bool hasLocation = _pickedLocation != null;
    // Default to Amman for the map preview before a location is chosen
    final LatLng displayLatLng =
        _pickedLocation ?? const LatLng(31.9539, 35.9106);

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    hasLocation ? context.l10n.locationSet : context.l10n.locationNotSet,
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: hasLocation ? textColor : Colors.grey),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.location_on,
                      color: hasLocation ? primaryBlue : Colors.grey,
                      size: 22),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _locationAddress,
                textAlign: TextAlign.right,
                style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.grey,
                    fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 15),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 90,
            height: 70,
            decoration: BoxDecoration(
              border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black12),
            ),
            child: hasLocation
                ? GoogleMap(
                    key: ValueKey(_pickedLocation),
                    initialCameraPosition: CameraPosition(
                      target: displayLatLng,
                      zoom: 15.0,
                    ),
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: false,
                    compassEnabled: false,
                    mapToolbarEnabled: false,
                    scrollGesturesEnabled: false,
                    zoomGesturesEnabled: false,
                    tiltGesturesEnabled: false,
                    rotateGesturesEnabled: false,
                    markers: {
                      Marker(
                        markerId: const MarkerId('preview_pin'),
                        position: displayLatLng,
                      ),
                    },
                  )
                : Container(
                    color: isDark
                        ? const Color(0xFF2C2C2C)
                        : const Color(0xFFF0F0F0),
                    child: Center(
                      child: Icon(Icons.map_outlined,
                          color: isDark ? Colors.white24 : Colors.grey,
                          size: 32),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // --- زر تأكيد الطلب ---
  Widget _buildConfirmButton(BuildContext context, bool isDark) {
    return ElevatedButton(
      onPressed: _isSubmitting ? null : () => _submitOrder(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: accentOrange,
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 3,
      ),
      child: _isSubmitting
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(
              context.l10n.confirmOrder,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
    );
  }

  Future<void> _submitOrder(BuildContext context) async {
    final locationMsg = context.l10n.orderLocationRequired;
    final timeMsg = context.l10n.orderTimeRequired;
    final successMsg = context.l10n.orderSentSuccess;
    final failedMsg = context.l10n.orderSentFailed;

    if (_pickedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(locationMsg, textAlign: TextAlign.center),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    if (_scheduledForIso == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(timeMsg, textAlign: TextAlign.center),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _isSubmitting = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final result = await RequestService.createRequest(
      serviceType: widget.serviceType,
      location: _locationAddress,
      description: '',
      providerId: widget.providerId,
      scheduledFor: _scheduledForIso,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.model != null) {
      messenger.showSnackBar(SnackBar(
        content: Text(successMsg, textAlign: TextAlign.center),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ));
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage()),
        (_) => false,
      );
    } else {
      messenger.showSnackBar(SnackBar(
        content: Text(result.error ?? failedMsg, textAlign: TextAlign.center),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }
}
