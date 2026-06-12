import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:handcom/shared/widgets/theme_provider.dart';
import 'package:handcom/core/l10n/app_strings.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomerLocationViewPage extends StatefulWidget {
  final LatLng customerLocation;
  final String customerName;
  final String addressDetails;

  const CustomerLocationViewPage({
    super.key,
    required this.customerLocation,
    required this.customerName,
    required this.addressDetails,
  });

  @override
  State<CustomerLocationViewPage> createState() =>
      _CustomerLocationViewPageState();
}

class _CustomerLocationViewPageState extends State<CustomerLocationViewPage> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  static const Color primaryBlue = Color(0xFF1A3D81);
  static const Color accentOrange = Color(0xFFF58220);

  @override
  void initState() {
    super.initState();
    _setCustomerMarker();
  }

  // تثبيت ماركر موقع العميل على الخريطة
  void _setCustomerMarker() {
    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('customer_destination'),
          position: widget.customerLocation,
          infoWindow: InfoWindow(
            title: widget.customerName,
            snippet: widget.addressDetails,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    });
  }

  // دالة لفتح موقع العميل مباشرة في تطبيق خرائط جوجل الخارجي لتوجيه الفني بالصوت والاتجاهات
  Future<void> _openInGoogleMapsApp() async {
    final String googleMapsUrl =
        "https://www.google.com/maps/search/?api=1&query=${widget.customerLocation.latitude},${widget.customerLocation.longitude}";

    final Uri url = Uri.parse(googleMapsUrl);

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.startNavigation,
                textAlign: TextAlign.right),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final bool isDark = themeProvider.isDarkMode;

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
          appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF1A1A1A) : primaryBlue,
            title: Text(
              context.l10n.customerLocationTitle,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            centerTitle: true,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Stack(
            children: [
              // الخريطة المخصصة للفني
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: widget.customerLocation,
                  zoom: 16,
                ),
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                },
                markers: _markers,
                myLocationEnabled:
                    true, // تفعيل نقطة الفني الزرقاء الحالية على الخريطة
                myLocationButtonEnabled:
                    true, // إظهار زر البوصلة الافتراضي للرجوع لموقع الفني
                zoomControlsEnabled: false,
              ),

              // لوحة معلومات العميل السفلية مع زر التوجيه الخارجي
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
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    border: isDark ? Border.all(color: Colors.white10) : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  widget.customerName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.addressDetails,
                                  style: TextStyle(
                                    color:
                                        isDark ? Colors.white60 : Colors.grey,
                                    fontSize: 14,
                                  ),
                                  textDirection: TextDirection.rtl,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 15),
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: primaryBlue.withOpacity(0.1),
                            child: const Icon(Icons.person_pin_circle_rounded,
                                color: primaryBlue, size: 30),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // زر فتح الاتجاهات في تطبيق الخرائط الخارجي (مهم جداً للفنيين أثناء القيادة)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentOrange,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25)),
                            elevation: 2,
                          ),
                          onPressed: _openInGoogleMapsApp,
                          icon: const Icon(Icons.navigation_rounded,
                              color: Colors.white),
                          label: Text(
                            context.l10n.startNavigation,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
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
}
