import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:handcom/shared/widgets/theme_provider.dart';
import 'package:handcom/core/l10n/app_strings.dart';

class SelectLocationScreen extends StatefulWidget {
  const SelectLocationScreen({super.key});

  @override
  State<SelectLocationScreen> createState() => _SelectLocationScreenState();
}

class _SelectLocationScreenState extends State<SelectLocationScreen> {
  final Completer<GoogleMapController> _controller = Completer();

  LatLng? _pickedLocation;
  LatLng? _currentLocation;
  bool _isLoading = true;
  String _errorKey = '';
  Set<Marker> _markers = {};

  static const Color primaryBlue = Color(0xFF1A3D81);
  static const Color accentOrange = Color(0xFFF58220);

  @override
  void initState() {
    super.initState();
    _detectCurrentLocation();
  }

  Future<void> _detectCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _errorKey = '';
    });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorKey = 'service_disabled';
          _isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _errorKey = 'permission_denied';
          _isLoading = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high));
      final latLng = LatLng(position.latitude, position.longitude);

      setState(() {
        _currentLocation = latLng;
        _isLoading = false;
      });

      if (_controller.isCompleted) {
        final ctrl = await _controller.future;
        ctrl.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
      }
    } catch (e) {
      setState(() {
        _errorKey = 'error:$e';
        _isLoading = false;
      });
    }
  }

  String _localizedError(BuildContext context) {
    if (_errorKey.startsWith('error:')) {
      return context.l10n.locationDetectError(_errorKey.substring(6));
    }
    switch (_errorKey) {
      case 'service_disabled':
        return context.l10n.locationServiceDisabledShort;
      case 'permission_denied':
        return context.l10n.locationPermDeniedApp;
      default:
        return _errorKey;
    }
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _pickedLocation = position;
      _markers = {
        Marker(
          markerId: const MarkerId('picked'),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(title: context.l10n.workLocation),
        ),
      };
    });
  }

  void _useCurrentLocation() {
    if (_currentLocation == null) return;
    _onMapTap(_currentLocation!);
    _controller.future.then((ctrl) {
      ctrl.animateCamera(
          CameraUpdate.newLatLngZoom(_currentLocation!, 15));
    });
  }

  String _formatLatLng(LatLng loc) {
    return '${loc.latitude.toStringAsFixed(5)}, ${loc.longitude.toStringAsFixed(5)}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final bool isDark = themeProvider.isDarkMode;
        final Color cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final Color textColor = isDark ? Colors.white : Colors.black87;

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: cardBg,
                child: IconButton(
                  icon:
                      Icon(Icons.arrow_back_ios_new, color: textColor, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            title: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                context.l10n.locationPickerTitle,
                style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ),
            centerTitle: true,
          ),
          body: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: isDark ? accentOrange : primaryBlue,
                  ),
                )
              : _errorKey.isNotEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.location_off_rounded,
                                size: 60, color: Colors.redAccent),
                            const SizedBox(height: 16),
                            Text(
                              _localizedError(context),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryBlue),
                              onPressed: _detectCurrentLocation,
                              child: Text(context.l10n.retry,
                                  style: const TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Stack(
                      children: [
                        // ── Map ──────────────────────────────────────────────
                        GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: _currentLocation!,
                            zoom: 15,
                          ),
                          myLocationEnabled: true,
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: false,
                          markers: _markers,
                          onMapCreated: (ctrl) {
                            if (!_controller.isCompleted) {
                              _controller.complete(ctrl);
                            }
                          },
                          onTap: _onMapTap,
                        ),

                        // ── Instruction banner ───────────────────────────────
                        if (_pickedLocation == null)
                          Positioned(
                            top: 100,
                            left: 16,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xCC1E1E1E)
                                    : Colors.white.withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withValues(alpha: 0.1),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.touch_app,
                                      color: isDark
                                          ? accentOrange
                                          : primaryBlue,
                                      size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    context.l10n.workLocationHint,
                                    style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // ── My location button ───────────────────────────────
                        Positioned(
                          right: 16,
                          bottom: _pickedLocation != null ? 180 : 100,
                          child: FloatingActionButton(
                            mini: true,
                            backgroundColor: cardBg,
                            elevation: 4,
                            heroTag: 'myloc',
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            onPressed: _useCurrentLocation,
                            child: Icon(Icons.my_location,
                                color: isDark ? accentOrange : primaryBlue,
                                size: 22),
                          ),
                        ),

                        // ── Bottom confirm panel ─────────────────────────────
                        if (_pickedLocation != null)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(28),
                                  topRight: Radius.circular(28),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withValues(alpha: 0.15),
                                    blurRadius: 16,
                                    offset: const Offset(0, -4),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              context.l10n.locationSet,
                                              style: TextStyle(
                                                color: isDark
                                                    ? Colors.white60
                                                    : Colors.black54,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _formatLatLng(_pickedLocation!),
                                              style: TextStyle(
                                                color: textColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(0xFF2C2C2C)
                                              : const Color(0xFFE3EEFF),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Icon(Icons.location_on,
                                            color: isDark
                                                ? accentOrange
                                                : primaryBlue,
                                            size: 24),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryBlue,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16)),
                                        elevation: 2,
                                      ),
                                      onPressed: () {
                                        Navigator.pop(
                                            context, _pickedLocation);
                                      },
                                      child: Text(
                                        context.l10n.confirm,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                        ),
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
