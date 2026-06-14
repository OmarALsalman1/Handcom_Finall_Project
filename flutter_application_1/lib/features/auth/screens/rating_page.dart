import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:handcom/shared/widgets/theme_provider.dart';
import 'package:handcom/services/rating_service.dart';
import 'package:handcom/core/l10n/app_strings.dart';

class RatingPage extends StatefulWidget {
  final int? serviceId;
  const RatingPage({super.key, this.serviceId});

  @override
  State<RatingPage> createState() => _RatingPageState();
}

class _RatingPageState extends State<RatingPage>
    with SingleTickerProviderStateMixin {
  int selectedRating = 0;

  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool _isSubmitting = false;

  Future<void> submitRating() async {
    if (selectedRating == 0) return;

    final svcId = widget.serviceId;
    final ratingSuccess = context.l10n.ratingSuccess(selectedRating);
    final ratingFailed = context.l10n.ratingFailed;

    if (svcId == null) {
      // No serviceId provided — show local feedback only
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ratingSuccess,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final l10n = context.l10n;

    final result = await RatingService.submitRating(
      serviceId: svcId,
      ratingValue: selectedRating,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    messenger.showSnackBar(SnackBar(
      content: Text(
        result.success
            ? ratingSuccess
            : l10n.errorMessage(result.errorCode,
                fallback: result.error ?? ratingFailed),
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: result.success ? Colors.green : Colors.red,
      behavior: SnackBarBehavior.floating,
    ));

    if (result.success) navigator.pop();
  }

  // تم تمرير مظهر الدارك مود لتعديل لون النجوم غير المحددة تلقائياً
  Widget buildStar(int index, bool isDark) {
    bool isSelected = selectedRating >= index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedRating = index;
        });
      },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 250),
        scale: isSelected ? 1.15 : 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Icon(
            Icons.star_rounded,
            size: 42,
            color: isSelected
                ? Colors.orange
                : (isDark ? Colors.white24 : Colors.grey.shade300),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // الاستماع للتغيرات العالمية للـ Dark Mode داخل شاشة التقييم
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final bool isDark = themeProvider.isDarkMode;

        // تهيئة قائمة الألوان المتغيرة المتناغمة مع وضع النظام
        final Color scaffoldBg = isDark ? const Color(0xFF121212) : const Color(0xFFF4F4F4);
        final Color appBarBg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFF243C97);
        final Color cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

        return Scaffold(
          backgroundColor: scaffoldBg,
          body: SafeArea(
            child: Column(
              children: [
                /// ================= HEADER =================
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: appBarBg,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(35),
                      bottomRight: Radius.circular(35),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 10,
                        left: 10,
                        child: IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          context.l10n.ratingTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                /// ================= CONTENT =================
                Transform.translate(
                  offset: const Offset(0, -45),
                  child: ScaleTransition(
                    scale: _animation,
                    child: Column(
                      children: [
                        // PROFILE IMAGE
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                              width: 5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 55,
                            backgroundColor: isDark ? const Color(0xFF2C2C2C) : const Color(0xFF1A3D81),
                            child: const Text(
                              "م", // حرف ترحيبي كبديل للصورة الشخصية للفني
                              style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),

                        // CARD
                        Container(
                          width: MediaQuery.of(context).size.width * 0.82,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 35,
                          ),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(30),
                            border: isDark ? Border.all(color: Colors.white10, width: 0.5) : null,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                                blurRadius: 25,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // STARS
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 2,
                                children: List.generate(
                                  5,
                                  (index) => buildStar(index + 1, isDark),
                                ),
                              ),

                              const SizedBox(height: 40),

                              // BUTTON
                              SizedBox(
                                width: 180,
                                height: 58,
                                child: ElevatedButton(
                                  onPressed: _isSubmitting ? null : submitRating,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: appBarBg,
                                    foregroundColor: Colors.white,
                                    elevation: 8,
                                    shadowColor: appBarBg.withAlpha(100),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                  child: _isSubmitting
                                      ? const CircularProgressIndicator(
                                          color: Colors.white)
                                      : Text(
                                    context.l10n.sendRating,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}