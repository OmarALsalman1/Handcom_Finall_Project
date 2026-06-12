import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:handcom/shared/widgets/theme_provider.dart';
import 'package:handcom/services/provider_service.dart';
import 'package:handcom/core/l10n/app_strings.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'worker_details_page.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();

  LatLng? _currentLocation;
  bool _isLoading = true;
  String _errorMessage = '';

  List<ProviderModel> _providers = [];
  Set<Marker> _markers = {};

  static const Color primaryBlue = Color(0xFF1A3D81);
  static const Color accentOrange = Color(0xFFF58220);

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _detectLocation();
    await _loadProviders();
  }

  Future<void> _detectLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted) return;
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = context.l10n.locationDisabled;
          _isLoading = false;
        });
        return;
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (!mounted) return;
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = context.l10n.locationPermDenied;
          _isLoading = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high));

      if (!mounted) return;
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = context.l10n.locationError(e.toString());
        _isLoading = false;
      });
    }
  }

  Future<void> _loadProviders() async {
    final providers = await ProviderService.getProviders(
      userLat: _currentLocation?.latitude,
      userLng: _currentLocation?.longitude,
    );
    if (!mounted) return;

    final markers = <Marker>{};

    for (int i = 0; i < providers.length; i++) {
      final p = providers[i];
      // Use real stored coordinates; fall back to a small spread if missing
      final LatLng pos;
      if (p.latitude != null && p.longitude != null) {
        pos = LatLng(p.latitude!, p.longitude!);
      } else {
        final base = _currentLocation ?? const LatLng(31.9539, 35.9106);
        final lat = base.latitude + 0.008 * (i % 3 + 1) * (i.isEven ? 1 : -1);
        final lng = base.longitude + 0.008 * ((i + 1) % 3 + 1) * (i % 3 == 0 ? 1 : -1);
        pos = LatLng(lat, lng);
      }

      markers.add(Marker(
        markerId: MarkerId('provider_${p.id}'),
        position: pos,
        infoWindow: InfoWindow(
          title: p.fullName,
          snippet: p.categoriesLabel(context.l10n.isAr),
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          p.availabilityStatus == 'available'
              ? BitmapDescriptor.hueOrange
              : BitmapDescriptor.hueAzure,
        ),
        onTap: () => _openProvider(p),
      ));
    }

    setState(() {
      _providers = providers;
      _markers = markers;
      _isLoading = false;
    });

    if (_currentLocation != null && _controller.isCompleted) {
      final ctrl = await _controller.future;
      ctrl.animateCamera(
          CameraUpdate.newLatLngZoom(_currentLocation!, 14));
    }
  }

  void _openProvider(ProviderModel p) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => WorkerDetailsPage(providerId: p.id)),
    );
  }

  Future<void> _goToMyLocation() async {
    if (_currentLocation == null) return;
    final ctrl = await _controller.future;
    ctrl.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation!, 14.5));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final bool isDark = themeProvider.isDarkMode;
        final Color cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final Color textColor = isDark ? Colors.white : Colors.black;
        final Color subTextColor = isDark ? Colors.white60 : Colors.black54;

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
                  icon: Icon(Icons.arrow_back_ios_new,
                      color: textColor, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
          body: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: isDark ? accentOrange : primaryBlue,
                  ),
                )
              : _errorMessage.isNotEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.location_off_rounded,
                                size: 60, color: Colors.redAccent),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage,
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
                              onPressed: () {
                                setState(() {
                                  _isLoading = true;
                                  _errorMessage = '';
                                });
                                _init();
                              },
                              child: Text(context.l10n.retry,
                                  style: const TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Stack(
                      children: [
                        GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: _currentLocation!,
                            zoom: 14,
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
                        ),

                        // My-location FAB
                        Positioned(
                          right: 16,
                          bottom: MediaQuery.of(context).size.height * 0.38,
                          child: FloatingActionButton(
                            mini: true,
                            backgroundColor: cardBg,
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            onPressed: _goToMyLocation,
                            child: Icon(Icons.my_location,
                                color: isDark ? accentOrange : primaryBlue,
                                size: 22),
                          ),
                        ),

                        // Bottom sheet — real providers
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: DraggableScrollableSheet(
                            initialChildSize: 0.35,
                            minChildSize: 0.12,
                            maxChildSize: 0.85,
                            builder: (context, scrollCtrl) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(30),
                                    topRight: Radius.circular(30),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                          alpha: isDark ? 0.3 : 0.1),
                                      blurRadius: 15,
                                      offset: const Offset(0, -3),
                                    ),
                                  ],
                                ),
                                child: _providers.isEmpty
                                    ? ListView(
                                        controller: scrollCtrl,
                                        padding: const EdgeInsets.all(20),
                                        children: [
                                          _buildDragHandle(isDark),
                                          const SizedBox(height: 30),
                                          Center(
                                            child: Text(
                                              context.l10n.noProviders,
                                              style: TextStyle(
                                                  color: isDark
                                                      ? Colors.white54
                                                      : Colors.grey,
                                                  fontSize: 15),
                                            ),
                                          ),
                                        ],
                                      )
                                    : ListView(
                                        controller: scrollCtrl,
                                        padding: const EdgeInsets.all(20),
                                        children: [
                                          _buildDragHandle(isDark),
                                          const SizedBox(height: 10),
                                          Text(
                                            context.l10n.availableProviders(_providers.length),
                                            style: TextStyle(
                                              color: textColor,
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          ..._providers.map((p) =>
                                              _buildProviderCard(
                                                  p, isDark, textColor,
                                                  subTextColor, cardBg)),
                                        ],
                                      ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
        );
      },
    );
  }

  Widget _buildDragHandle(bool isDark) {
    return Center(
      child: Container(
        width: 50,
        height: 5,
        decoration: BoxDecoration(
          color: isDark ? Colors.white24 : Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildProviderCard(ProviderModel p, bool isDark, Color textColor,
      Color subTextColor, Color cardBg) {
    final statusColor =
        p.availabilityStatus == 'available' ? Colors.green : Colors.orange;

    return GestureDetector(
      onTap: () => _openProvider(p),
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(
              color: isDark ? Colors.white10 : Colors.grey.shade100),
        ),
        color: isDark ? const Color(0xFF262626) : const Color(0xFFF8F9FB),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: isDark
                    ? const Color(0xFF2C2C2C)
                    : const Color(0xFFE3F2FD),
                child: Text(
                  p.initial,
                  style: TextStyle(
                    color: isDark ? accentOrange : primaryBlue,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.fullName,
                      style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p.categoriesLabel(context.l10n.isAr),
                      style:
                          TextStyle(color: subTextColor, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (p.averageRating != null) ...[
                          const Icon(Icons.star,
                              color: Colors.amber, size: 15),
                          const SizedBox(width: 3),
                          Text(
                            p.ratingDisplay,
                            style: TextStyle(
                                color: textColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            p.statusArabic,
                            style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 14,
                  color: isDark ? Colors.white30 : Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

extension on ProviderModel {
  String categoriesLabel(bool isAr) {
    const ar = {
      'plumbing': 'سباكة',
      'electrical': 'كهرباء',
      'painting': 'دهان',
      'carpentry': 'نجارة',
    };
    const en = {
      'plumbing': 'Plumbing',
      'electrical': 'Electrical',
      'painting': 'Painting',
      'carpentry': 'Carpentry',
    };
    final map = isAr ? ar : en;
    return serviceCategories.map((c) => map[c] ?? c).join(isAr ? ' ، ' : ', ');
  }
}
