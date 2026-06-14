import 'dart:async';
import 'package:flutter/material.dart';
import 'package:handcom/core/l10n/app_strings.dart';
import 'package:provider/provider.dart';
import 'package:handcom/shared/widgets/theme_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import 'package:handcom/features/auth/screens/chats_by_provider.dart';
import 'package:handcom/features/auth/screens/service_tracking_page.dart';
import 'package:handcom/services/request_service.dart';
import 'package:handcom/shared/widgets/list_error_state.dart';
import 'provider_home_page.dart';
import 'provider_profile_page.dart';

class ProviderMapScreen extends StatefulWidget {
  const ProviderMapScreen({super.key});

  @override
  State<ProviderMapScreen> createState() => _ProviderMapScreenState();
}

class _ProviderMapScreenState extends State<ProviderMapScreen> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  LatLng? currentLocation;
  bool isLoading = true;
  bool _loadingOrders = true;
  String? _ordersErrorCode;
  String errorMessage = '';
  Set<Marker> _customerMarkers = {};
  List<ServiceRequestModel> _orders = [];

  static const Color primaryBlue = Color(0xFF1A3D81);
  static const Color accentOrange = Color(0xFFF58220);

  // Active statuses worth showing on the map schedule
  static const _activeStatuses = {'pending', 'accepted', 'in_progress'};

  @override
  void initState() {
    super.initState();
    _getProviderLocation();
    _loadOrders();
  }

  // ── Parse "lat,lng" string → LatLng ──────────────────────────────────────
  LatLng? _parseLocation(String? location) {
    if (location == null || location.isEmpty) return null;
    try {
      final parts = location.split(',');
      if (parts.length >= 2) {
        return LatLng(
            double.parse(parts[0].trim()), double.parse(parts[1].trim()));
      }
    } catch (_) {}
    return null;
  }

  // ── Format ISO datetime → "H:MM AM/PM" ───────────────────────────────────
  String _formatTime(String iso, bool isAr) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final h = dt.hour > 12
          ? dt.hour - 12
          : (dt.hour == 0 ? 12 : dt.hour);
      final m = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12
          ? (isAr ? 'م' : 'PM')
          : (isAr ? 'ص' : 'AM');
      return '$h:$m $period';
    } catch (_) {
      return iso;
    }
  }

  // ── Load orders from backend, filter active, sort by createdAt ───────────
  Future<void> _loadOrders() async {
    final result = await RequestService.getMyRequests();
    if (!mounted) return;

    final active = result.items
        .where((r) => _activeStatuses.contains(r.status))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt)); // earliest first

    setState(() {
      _orders = active;
      _ordersErrorCode = result.errorCode;
      _loadingOrders = false;
      if (currentLocation != null) _generateCustomerMarkers();
    });
  }

  // ── Get provider GPS location ─────────────────────────────────────────────
  Future<void> _getProviderLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          errorMessage = context.l10n.locationDisabled;
          isLoading = false;
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
          errorMessage = context.l10n.locationDenied;
          isLoading = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high));

      if (!mounted) return;
      setState(() {
        currentLocation = LatLng(position.latitude, position.longitude);
        isLoading = false;
        errorMessage = '';
        _generateCustomerMarkers();
      });

      if (_controller.isCompleted) {
        final ctrl = await _controller.future;
        ctrl.animateCamera(
            CameraUpdate.newLatLngZoom(currentLocation!, 14.5));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = context.l10n.locationError(e.toString());
        isLoading = false;
      });
    }
  }

  // ── Generate map markers from real order locations ─────────────────────
  void _generateCustomerMarkers() {
    final markers = <Marker>{};
    for (final order in _orders) {
      final latLng = _parseLocation(order.location);
      if (latLng == null) continue;
      final label = order.userName ?? order.serviceType;
      markers.add(Marker(
        markerId: MarkerId(order.id.toString()),
        position: latLng,
        infoWindow: InfoWindow(
          title: label,
          snippet: order.serviceType,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));
    }
    _customerMarkers = markers;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final bool isDark = themeProvider.isDarkMode;
        final bool isAr = context.l10n.isAr;

        final Color cardBg =
            isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final Color textColor = isDark ? Colors.white : Colors.black;
        final Color subTextColor = isDark ? Colors.white60 : Colors.black54;
        final Color sheetBarrierColor =
            isDark ? Colors.black38 : Colors.black12;

        return Scaffold(
          backgroundColor:
              isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FB),
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
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
          body: isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        isDark ? accentOrange : primaryBlue),
                  ),
                )
              : errorMessage.isNotEmpty
                  ? Center(
                      child: Text(errorMessage,
                          style:
                              const TextStyle(color: Colors.redAccent)),
                    )
                  : Stack(
                      children: [
                        // ── Map ───────────────────────────────────────────
                        GoogleMap(
                          initialCameraPosition: CameraPosition(
                              target: currentLocation!, zoom: 14.5),
                          myLocationEnabled: true,
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: false,
                          markers: _customerMarkers,
                          onMapCreated: (ctrl) {
                            if (!_controller.isCompleted) {
                              _controller.complete(ctrl);
                            }
                          },
                        ),

                        // ── My-location button ────────────────────────────
                        Positioned(
                          right: 20,
                          bottom:
                              MediaQuery.of(context).size.height * 0.38,
                          child: FloatingActionButton(
                            mini: true,
                            backgroundColor: cardBg,
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            onPressed: _getProviderLocation,
                            child: Icon(Icons.my_location,
                                color: isDark
                                    ? accentOrange
                                    : primaryBlue,
                                size: 22),
                          ),
                        ),

                        // ── Bottom sheet: today's order schedule ──────────
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: DraggableScrollableSheet(
                            initialChildSize: 0.36,
                            minChildSize: 0.18,
                            maxChildSize: 0.85,
                            builder: (context, scrollController) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(30),
                                    topRight: Radius.circular(30),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: sheetBarrierColor,
                                      blurRadius: 15,
                                      offset: const Offset(0, -3),
                                    )
                                  ],
                                ),
                                child: _loadingOrders
                                    ? const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(30),
                                          child:
                                              CircularProgressIndicator(),
                                        ),
                                      )
                                    : ListView.builder(
                                        controller: scrollController,
                                        padding:
                                            const EdgeInsets.all(20),
                                        itemCount: _orders.length + 1,
                                        itemBuilder: (context, index) {
                                          // Header row
                                          if (index == 0) {
                                            return Column(
                                              children: [
                                                Container(
                                                  width: 50,
                                                  height: 5,
                                                  decoration:
                                                      BoxDecoration(
                                                    color: isDark
                                                        ? Colors.white24
                                                        : Colors
                                                            .grey[300],
                                                    borderRadius:
                                                        BorderRadius
                                                            .circular(
                                                                10),
                                                  ),
                                                ),
                                                const SizedBox(
                                                    height: 15),
                                                Align(
                                                  alignment: Alignment
                                                      .centerRight,
                                                  child: Text(
                                                    isAr
                                                        ? 'جدول مواعيد العملاء اليوم'
                                                        : 'Today\'s Order Schedule',
                                                    style: TextStyle(
                                                      color: textColor,
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight
                                                              .bold,
                                                    ),
                                                  ),
                                                ),
                                                if (_orders.isEmpty)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets
                                                            .only(
                                                                top: 30),
                                                    child: _ordersErrorCode !=
                                                            null
                                                        ? ListErrorState(
                                                            errorCode:
                                                                _ordersErrorCode,
                                                            onRetry:
                                                                _loadOrders,
                                                            textColor:
                                                                textColor,
                                                          )
                                                        : Text(
                                                            isAr
                                                                ? 'لا توجد طلبات نشطة حالياً'
                                                                : 'No active orders',
                                                            style: TextStyle(
                                                                color:
                                                                    subTextColor,
                                                                fontSize: 15),
                                                          ),
                                                  ),
                                                const SizedBox(
                                                    height: 15),
                                              ],
                                            );
                                          }

                                          final order =
                                              _orders[index - 1];
                                          final userName =
                                              order.userName ??
                                                  order.serviceTypeLabel(
                                                      isAr);
                                          final initial = userName
                                                  .isNotEmpty
                                              ? userName.substring(0, 1)
                                              : '?';
                                          final serviceLabel =
                                              order.serviceTypeLabel(isAr);
                                          final timeLabel = _formatTime(
                                              order.createdAt, isAr);

                                          return Container(
                                            margin: const EdgeInsets
                                                .only(bottom: 12),
                                            padding:
                                                const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? const Color(
                                                      0xFF262626)
                                                  : const Color(
                                                      0xFFF8F9FB),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      20),
                                              border: Border.all(
                                                  color: isDark
                                                      ? Colors.white10
                                                      : Colors
                                                          .grey.shade200),
                                            ),
                                            child: Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 22,
                                                  backgroundColor: isDark
                                                      ? const Color(
                                                          0xFF333333)
                                                      : primaryBlue
                                                          .withValues(
                                                              alpha: 0.1),
                                                  child: Text(
                                                    initial,
                                                    style: TextStyle(
                                                      color: isDark
                                                          ? accentOrange
                                                          : primaryBlue,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        userName,
                                                        style: TextStyle(
                                                          color: textColor,
                                                          fontWeight:
                                                              FontWeight
                                                                  .bold,
                                                          fontSize: 15,
                                                        ),
                                                      ),
                                                      Text(
                                                        serviceLabel,
                                                        style: TextStyle(
                                                            color:
                                                                subTextColor,
                                                            fontSize: 12),
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                      ),
                                                      Text(
                                                        isAr
                                                            ? 'موعد الطلب: $timeLabel'
                                                            : 'Order time: $timeLabel',
                                                        style: const TextStyle(
                                                            color:
                                                                accentOrange,
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                ElevatedButton(
                                                  style: ElevatedButton
                                                      .styleFrom(
                                                    backgroundColor:
                                                        primaryBlue,
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 10,
                                                        vertical: 8),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12)),
                                                  ),
                                                  onPressed: () =>
                                                      Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          ServiceTrackingPage(
                                                              request:
                                                                  order),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    isAr
                                                        ? 'تتبع العميل'
                                                        : 'Track Client',
                                                    style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight
                                                                .bold),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
          bottomNavigationBar: _buildBottomNav(context, isDark),
        );
      },
    );
  }

  Widget _buildBottomNav(BuildContext context, bool isDark) {
    final Color navBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color iconActiveColor = isDark ? accentOrange : primaryBlue;
    final Color iconInactiveColor = isDark ? Colors.white38 : Colors.grey;

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: navBg,
        border: Border(
            top: BorderSide(
                color: isDark ? Colors.white10 : Colors.black12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(Icons.person_outline, size: 28),
            color: iconInactiveColor,
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => const ProviderProfilePage())),
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, size: 26),
            color: iconInactiveColor,
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => const ChatsByProvider())),
          ),
          IconButton(
            icon: const Icon(Icons.location_on, size: 30),
            color: iconActiveColor,
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.home_outlined, size: 30),
            color: iconInactiveColor,
            onPressed: () => Navigator.pushReplacement(context,
                MaterialPageRoute(
                    builder: (_) => const ProviderHomePage())),
          ),
        ],
      ),
    );
  }
}
