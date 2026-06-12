import 'package:flutter/material.dart';
import 'package:handcom/core/l10n/app_strings.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:handcom/shared/widgets/theme_provider.dart';

class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({super.key});

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  GoogleMapController? _mapController;
  LatLng _selectedLocation =
      const LatLng(31.9522, 35.9150); // موقع افتراضي (عمان مثلاً)
  bool _isLoading = true;
  final Set<Marker> _markers = {};

  static const Color primaryBlue = Color(0xFF1A3D81);

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  // دالة طلب الإذن وتحديد موقع المستخدم الحالي عند فتح الصفحة
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showErrorSnackBar("الرجاء تفعيل خدمات الموقع (GPS) في الجهاز");
      setState(() => _isLoading = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showErrorSnackBar("تم رفض إذن الوصول للموقع");
        setState(() => _isLoading = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showErrorSnackBar("إذن الموقع مرفوض بشكل دائم من إعدادات الجهاز");
      setState(() => _isLoading = false);
      return;
    }

    // جلب الموقع الحالي
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      _updateLocation(LatLng(position.latitude, position.longitude));
    } catch (e) {
      debugPrint("Error getting location: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // تحديث النقطة المحددة والماركر على الخريطة
  void _updateLocation(LatLng location) {
    setState(() {
      _selectedLocation = location;
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('selected_pos'),
          position: location,
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueOrange), // ماركر برتقالي متناسق مع الهوية
        ),
      );
    });

    // تحريك الكاميرا للموقع الجديد
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(location, 16),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, textAlign: TextAlign.right)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : primaryBlue,
        title: Text(context.l10n.locationPickerTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : Stack(
              children: [
                // الخريطة
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _selectedLocation,
                    zoom: 15,
                  ),
                  onMapCreated: (controller) => _mapController = controller,
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled:
                      false, // سنصنع زر مخصص ليكون شكله أجمل
                  onTap: (LatLng location) {
                    _updateLocation(
                        location); // السماح للمستخدم بتغيير الموقع عند الضغط على أي مكان بالخريطة
                  },
                ),

                // زر إعادة التوجيه للموقع الحالي للمستخدم (أعلى اليمين أو اليسار)
                Positioned(
                  bottom: 100,
                  right: 20,
                  child: FloatingActionButton(
                    backgroundColor:
                        isDark ? const Color(0xFF2C2C2C) : Colors.white,
                    mini: true,
                    onPressed: _determinePosition,
                    child: Icon(Icons.my_location,
                        color: isDark ? Colors.white : primaryBlue),
                  ),
                ),

                // زر تأكيد وإرسال الموقع في الأسفل
                Positioned(
                  bottom: 30,
                  left: 20,
                  right: 20,
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isDark ? const Color(0xFF2C2C2C) : primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                          side: isDark
                              ? const BorderSide(color: Colors.white10)
                              : BorderSide.none,
                        ),
                      ),
                      onPressed: () {
                        // إرجاع الموقع المختار (LatLng) إلى الشاشة السابقة عند الضغط على الزر
                        Navigator.pop(context, _selectedLocation);
                      },
                      child: const Text(
                        "إرسال الموقع الحالي",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
