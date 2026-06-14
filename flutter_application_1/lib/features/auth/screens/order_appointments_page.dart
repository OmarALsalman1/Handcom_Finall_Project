import 'package:flutter/material.dart';
import 'package:handcom/core/l10n/app_strings.dart';
import 'package:handcom/features/auth/screens/provider_map_screen.dart';
import 'package:provider/provider.dart'; // استيراد الـ Provider للاستماع للثيم
import 'package:handcom/features/auth/screens/provider_home_page.dart';
import 'package:handcom/shared/widgets/theme_provider.dart'; // تأكد من صحة مسار الملف في مشروعك

import 'package:handcom/services/request_service.dart';
import 'package:handcom/shared/widgets/list_error_state.dart';
import 'chats_by_provider.dart';

class OrdersAppointmentsPage extends StatefulWidget {
  const OrdersAppointmentsPage({super.key});

  @override
  State<OrdersAppointmentsPage> createState() => _OrdersAppointmentsPageState();
}

class _OrdersAppointmentsPageState extends State<OrdersAppointmentsPage> {
  static const Color primaryBlue = Color(0xFF1A3D81);
  static const Color accentOrange = Color(0xFFF58220);

  List<ServiceRequestModel> activeOrders = [];
  bool _isLoading = true;
  String? _errorCode;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final result = await RequestService.getIncomingRequests();
    if (!mounted) return;
    setState(() {
      activeOrders = result.items;
      _errorCode = result.errorCode;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final bool isDark = themeProvider.isDarkMode;

        // تهيئة الألوان المتغيرة المتناغمة مع وضع النظام
        final Color scaffoldBg = isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FB);
        final Color appBarBg = isDark ? const Color(0xFF1A1A1A) : primaryBlue;
        final Color cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final Color inputBg = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF5F5F5);
        final Color textColor = isDark ? Colors.white : Colors.black87;
        final Color subTextColor = isDark ? Colors.white60 : Colors.black54;

        return Scaffold(
          backgroundColor: scaffoldBg,
          bottomNavigationBar: _buildBottomNav(context, isDark),
          body: Column(
            children: [
              _buildHeader(context, appBarBg),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : activeOrders.isEmpty
                        ? (_errorCode != null
                            ? ListErrorState(
                                errorCode: _errorCode,
                                onRetry: _loadOrders,
                                textColor: textColor,
                              )
                            : Center(
                                child: Text(
                                  context.l10n.noIncomingOrders,
                                  style: TextStyle(
                                      color: textColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ))
                        : RefreshIndicator(
                            onRefresh: _loadOrders,
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 20),
                              itemCount: activeOrders.length,
                              itemBuilder: (context, index) {
                                final order = activeOrders[index];
                                return Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 20),
                                  child: _buildOrderCard(
                                    orderNumber: order.id.toString(),
                                    name: order.userName ??
                                        order.serviceTypeLabel(context.l10n.isAr),
                                    location: order.location,
                                    date: _formatDate(order.createdAt),
                                    status: order.statusLabel(context.l10n.isAr),
                                    cardBg: cardBg,
                                    inputBg: inputBg,
                                    textColor: textColor,
                                    subTextColor: subTextColor,
                                    isDark: isDark,
                                    index: index,
                                  ),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- الهيدر المتوافق مع الثيم ---
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
              child: Padding(
                padding: const EdgeInsets.only(left: 10),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 28),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const ProviderHomePage()),
                    );
                  },
                ),
              ),
            ),
            Center(
              child: Text(
                context.l10n.orderAppointments,
                style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- بطاقة الطلب الديناميكية بالكامل ---
  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  Widget _buildOrderCard({
    required String orderNumber,
    required String name,
    required String location,
    required String date,
    required String status,
    required Color cardBg,
    required Color inputBg,
    required Color textColor,
    required Color subTextColor,
    required bool isDark,
    required int index,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          context.l10n.orderNum(orderNumber),
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(15),
            border:
                Border.all(color: isDark ? Colors.white10 : Colors.black12),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withValues(alpha: isDark ? 0.3 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              Column(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final orderId = activeOrders[index].id;
                      final messenger = ScaffoldMessenger.of(context);
                      final ok = await RequestService.assignProvider(orderId);
                      if (!mounted) return;
                      if (ok) {
                        setState(() => activeOrders.removeAt(index));
                        messenger.showSnackBar(SnackBar(
                          content: Text(context.l10n.orderConfirmedMsg,
                              textAlign: TextAlign.center),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        ));
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const ProviderHomePage()),
                          (route) => false,
                        );
                      } else {
                        messenger.showSnackBar(const SnackBar(
                          content: Text('فشل قبول الطلب، حاول مجدداً',
                              textAlign: TextAlign.center),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ));
                      }
                    },
                    child: _buildActionButton(context.l10n.confirmBtn, accentOrange),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () async {
                      final orderId = activeOrders[index].id;
                      final messenger = ScaffoldMessenger.of(context);
                      final ok = await RequestService.declineRequest(orderId);
                      if (!mounted) return;
                      if (ok) {
                        setState(() => activeOrders.removeAt(index));
                        messenger.showSnackBar(SnackBar(
                          content: Text(context.l10n.orderCancelledMsg,
                              textAlign: TextAlign.center),
                          backgroundColor: Colors.orange,
                          behavior: SnackBarBehavior.floating,
                        ));
                      } else {
                        messenger.showSnackBar(SnackBar(
                          content: Text(context.l10n.cannotCancelMsg,
                              textAlign: TextAlign.center),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ));
                      }
                    },
                    child: _buildActionButton(
                      "إلغاء",
                      isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
                      textColor: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildInfoTag(
                      name, null, inputBg, textColor, subTextColor),
                  const SizedBox(height: 8),
                  _buildInfoTag(location, Icons.location_on_outlined,
                      inputBg, textColor, subTextColor),
                  const SizedBox(height: 8),
                  _buildInfoTag(date, Icons.calendar_month_outlined,
                      inputBg, textColor, subTextColor),
                  const SizedBox(height: 8),
                  _buildInfoTag(
                      status, Icons.info_outline, inputBg, textColor, subTextColor),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- حقول النصوص المتناسقة ---
  Widget _buildInfoTag(String text, IconData? icon, Color inputBg, Color textColor, Color subTextColor) {
    return Container(
      width: 200,
      height: 35,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 35),
            child: Text(
              text,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
          if (icon != null)
            Positioned(
              right: 12,
              child: Icon(icon, size: 18, color: subTextColor),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, {Color textColor = Colors.white}) {
    return Container(
      width: 75,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }

  // البار السفلي الموحد والخاص بمزود الخدمة (بدون كبسة الـ AI وسادة 100%)
  Widget _buildBottomNav(BuildContext context, bool isDark) {
    final Color navBg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE8E8E8);
    final Color iconColor = isDark ? Colors.white60 : Colors.grey;

    return BottomAppBar(
      elevation: 20,
      color: navBg, 
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // 1. بروفايل المزود
            IconButton(
              icon: Icon(Icons.person_outline, color: iconColor, size: 28),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ProviderHomePage()));
              },
            ),
            // 2. قائمة المحادثات للمزود
            IconButton(
              icon: Icon(Icons.chat_bubble_outline, color: iconColor, size: 26),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatsByProvider()));
              },
            ),
            // 3. خريطة وموقع المزود
            IconButton(
              icon: Icon(Icons.location_on_outlined, color: iconColor, size: 28),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ProviderMapScreen()));
              },
            ),
            // 4. الرئيسية (الهوم للمزود)
            IconButton(
              icon: Icon(Icons.home_outlined, color: iconColor, size: 28),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const ProviderHomePage()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}