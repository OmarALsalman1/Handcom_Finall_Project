import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:handcom/shared/widgets/theme_provider.dart';
import 'package:handcom/core/l10n/app_strings.dart';

class OrderTrackingPage extends StatefulWidget {
  // بنمرر للشاشة موقع العميل وموقع الفني الابتدائي عند فتح الصفحة
  final LatLng customerLocation;
  final LatLng technicianInitialLocation;
  final String orderId;

  const OrderTrackingPage({
    super.key,
    required this.customerLocation,
    required this.technicianInitialLocation,
    required this.orderId,
  });

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  GoogleMapController? _mapController;
  late LatLng _currentTechnicianLocation;
  final Set<Marker> _markers = {};

  String _customerMarkerTitle = '';
  String _technicianMarkerTitle = '';

  // تايمر وهمي لمحاكاة حركة الفني (بتقدري تستبدليه بـ Stream جاي من Firebase أو API)
  Timer? _trackingTimer;

  static const Color primaryBlue = Color(0xFF1A3D81);
  static const Color accentOrange = Color(0xFFF58220);

  @override
  void initState() {
    super.initState();
    _currentTechnicianLocation = widget.technicianInitialLocation;
    _startLiveTrackingSimulation(); // بدء التتبع الحي
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _customerMarkerTitle = context.l10n.yourCurrentLocation;
    _technicianMarkerTitle = context.l10n.technicianOnWay;
    if (_markers.isEmpty) _initializeMarkers();
  }

  // إعداد الماركرز الافتدائية (موقع العميل وموقع الفني)
  void _initializeMarkers() {
    setState(() {
      _markers.clear();

      // 1. ماركر موقع العميل (ثابت)
      _markers.add(
        Marker(
          markerId: const MarkerId('customer_marker'),
          position: widget.customerLocation,
          infoWindow: InfoWindow(title: _customerMarkerTitle),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure), // لون أزرق للعميل
        ),
      );

      // 2. ماركر موقع الفني (متحرك)
      _markers.add(
        Marker(
          markerId: const MarkerId('technician_marker'),
          position: _currentTechnicianLocation,
          infoWindow: InfoWindow(title: _technicianMarkerTitle),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueOrange), // لون برتقالي للفني
        ),
      );
    });
  }

  // دالة تحديث موقع الفني حياً على الخريطة
  void _updateTechnicianLocation(LatLng newLocation) {
    setState(() {
      _currentTechnicianLocation = newLocation;

      // تحديث ماركر الفني فقط في الـ Set
      _markers.removeWhere((m) => m.markerId.value == 'technician_marker');
      _markers.add(
        Marker(
          markerId: const MarkerId('technician_marker'),
          position: newLocation,
          infoWindow: InfoWindow(title: _technicianMarkerTitle),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
      );
    });

    // تحريك الكاميرا بسلاسة لتواكب حركة الفني والعميل معاً إذا أردتِ
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(newLocation),
    );
  }

  // محاكاة حركة الفني (هنا بتركبي الـ Stream تبع الفايربيز تبعك)
  void _startLiveTrackingSimulation() {
    // مثال: كل 4 ثواني الفني بيقرب شوي على موقع العميل
    _trackingTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      double latStep = (widget.customerLocation.latitude -
              _currentTechnicianLocation.latitude) *
          0.1;
      double lngStep = (widget.customerLocation.longitude -
              _currentTechnicianLocation.longitude) *
          0.1;

      // إذا وصل الفني قريب جداً نوقف التتبع
      if (latStep.abs() < 0.0001 && lngStep.abs() < 0.0001) {
        _trackingTimer?.cancel();
        return;
      }

      LatLng nextPosition = LatLng(
        _currentTechnicianLocation.latitude + latStep,
        _currentTechnicianLocation.longitude + lngStep,
      );

      _updateTechnicianLocation(nextPosition);
    });
  }

  // دالة لضبط الكاميرا بحيث تظهر العميل والفني معاً في الشاشة أول ما تفتح
  void _adjustMapBounds() {
    if (_mapController == null) return;

    LatLngBounds bounds;
    if (widget.customerLocation.latitude >
        _currentTechnicianLocation.latitude) {
      bounds = LatLngBounds(
        southwest: LatLng(_currentTechnicianLocation.latitude,
            _currentTechnicianLocation.longitude),
        northeast: LatLng(widget.customerLocation.latitude,
            widget.customerLocation.longitude),
      );
    } else {
      bounds = LatLngBounds(
        southwest: LatLng(widget.customerLocation.latitude,
            widget.customerLocation.longitude),
        northeast: LatLng(_currentTechnicianLocation.latitude,
            _currentTechnicianLocation.longitude),
      );
    }

    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }

  @override
  void dispose() {
    _trackingTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : primaryBlue,
        title: Text(context.l10n.trackingTitle(widget.orderId),
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // الخريطة لعرض المواقع والتتبع
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentTechnicianLocation,
              zoom: 14,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              // عمل زووم تلقائي يجمع النقطتين معاً بعد بناء الخريطة
              Future.delayed(
                  const Duration(milliseconds: 500), _adjustMapBounds);
            },
            markers: _markers,
            myLocationEnabled:
                false, // مسكرينه لأننا بنتبع الفني والطلب مش موقع العميل الحي الحالي بالجهاز
            zoomControlsEnabled: false,
          ),

          // كرت سفلي يعرض حالة وصول الفني للعميل بشكل جميل ومتناسق مع التطبيق
          Positioned(
            bottom: 20,
            left: 15,
            right: 15,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: isDark ? Border.all(color: Colors.white10) : null,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: accentOrange.withOpacity(0.2),
                    child: const Icon(Icons.engineering_rounded,
                        color: accentOrange, size: 30),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          context.l10n.technicianComingNow,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.l10n.updatingLocationLive,
                          style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.black54,
                              fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // زر تواصل سريع مع الفني
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: isDark
                          ? const Color(0xFF2C2C2C)
                          : const Color(0xFFF1F1F1),
                    ),
                    icon: const Icon(Icons.phone_in_talk_rounded,
                        color: primaryBlue),
                    onPressed: () {
                      // كود الاتصال بالفني
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
