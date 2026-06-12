import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:handcom/core/l10n/app_strings.dart';
import 'package:handcom/shared/widgets/theme_provider.dart';
import 'package:handcom/services/auth_service.dart';
import 'login_screen.dart';
import 'provider_login_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;
  final String role; // 'service_user' or 'service_provider'

  const VerifyEmailScreen({
    super.key,
    required this.email,
    required this.role,
  });

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _otpController = TextEditingController();

  bool _isVerifying = false;
  bool _isResending = false;

  static const Color primaryBlue = Color(0xFF1A3D81);
  static const Color accentOrange = Color(0xFFF58220);
  static const int _otpTtl = 30;

  int _secondsLeft = _otpTtl;
  bool _expired = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _secondsLeft = _otpTtl;
      _expired = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          _expired = true;
          t.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isVerifying = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final result = await AuthService.verifyEmail(
      email: widget.email,
      otp: _otpController.text.trim(),
      role: widget.role,
    );

    if (!mounted) return;
    setState(() => _isVerifying = false);

    final activatedMsg = context.l10n.accountActivated;
    final expiredMsg = context.l10n.codeExpiredOrInvalid;
    if (result.success) {
      messenger.showSnackBar(SnackBar(
        content: Text(activatedMsg, textAlign: TextAlign.center),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ));
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => widget.role == 'service_user'
              ? const LoginScreen()
              : const ProviderLoginScreen(),
        ),
        (route) => false,
      );
    } else {
      messenger.showSnackBar(SnackBar(
        content: Text(
          result.error ?? expiredMsg,
          textAlign: TextAlign.center,
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _resend() async {
    setState(() => _isResending = true);
    final messenger = ScaffoldMessenger.of(context);

    final result = await AuthService.resendVerificationOtp(
      email: widget.email,
      role: widget.role,
    );

    if (!mounted) return;
    setState(() => _isResending = false);

    if (result.success) _startTimer();

    messenger.showSnackBar(SnackBar(
      content: Text(
        result.success
            ? context.l10n.codeSentSuccessTo(widget.email)
            : (result.error ?? context.l10n.resendFailed),
        textAlign: TextAlign.center,
      ),
      backgroundColor: result.success ? Colors.green : Colors.red,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final bool isDark = themeProvider.isDarkMode;
        final Color scaffoldBg =
            isDark ? const Color(0xFF121212) : const Color(0xFFF2F2F2);
        final Color appBarBg = isDark ? const Color(0xFF1A1A1A) : primaryBlue;
        final Color cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final Color inputBg =
            isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEEEEEE);
        final Color textColor = isDark ? Colors.white : Colors.black;

        return Scaffold(
          backgroundColor: scaffoldBg,
          body: SafeArea(
            child: Stack(
              children: [
                // ── Header ──────────────────────────────────────────────────
                Container(
                  height: 260,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [appBarBg, const Color(0xFF2255BB)],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        const SizedBox(height: 48),
                        const Icon(Icons.mark_email_unread_rounded,
                            color: Colors.white, size: 52),
                        const SizedBox(height: 12),
                        Text(
                          context.l10n.verifyEmailTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Card ────────────────────────────────────────────────────
                Align(
                  alignment: Alignment.topCenter,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 210),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 30),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: isDark ? 0.3 : 0.12),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Email hint
                            Text(
                              context.l10n.codeSentTo,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.black54,
                                  fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.email,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // OTP field label
                            Text(
                              context.l10n.otpLabel,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15),
                            ),
                            const SizedBox(height: 12),

                            // Countdown timer
                            Center(
                              child: _expired
                                  ? Text(
                                      context.l10n.isAr
                                          ? 'انتهت صلاحية الرمز'
                                          : 'Code expired',
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 28,
                                          height: 28,
                                          child: CircularProgressIndicator(
                                            value: _secondsLeft / _otpTtl,
                                            strokeWidth: 3,
                                            backgroundColor: isDark
                                                ? Colors.white12
                                                : Colors.black12,
                                            color: _secondsLeft <= 10
                                                ? Colors.red
                                                : accentOrange,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          '0:${_secondsLeft.toString().padLeft(2, '0')}',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: _secondsLeft <= 10
                                                ? Colors.red
                                                : (isDark
                                                    ? Colors.white
                                                    : primaryBlue),
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                            const SizedBox(height: 12),

                            // OTP input
                            TextFormField(
                              controller: _otpController,
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                                letterSpacing: 8,
                              ),
                              decoration: InputDecoration(
                                counterText: '',
                                hintText: '• • • • • •',
                                hintStyle: TextStyle(
                                  color:
                                      isDark ? Colors.white24 : Colors.black26,
                                  fontSize: 22,
                                  letterSpacing: 8,
                                ),
                                filled: true,
                                fillColor: inputBg,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return context.l10n.codeRequired;
                                }
                                if (v.trim().length != 6) {
                                  return context.l10n.otpSixDigits;
                                }
                                if (!RegExp(r'^\d+$').hasMatch(v.trim())) {
                                  return context.l10n.numbersOnly;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            // Verify button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryBlue,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(14)),
                                  elevation: 2,
                                ),
                                onPressed: (_isVerifying || _expired) ? null : _verify,
                                child: _isVerifying
                                    ? const CircularProgressIndicator(
                                        color: Colors.white)
                                    : Text(
                                        context.l10n.activateAccount,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Resend link
                            Center(
                              child: GestureDetector(
                                onTap: _isResending ? null : _resend,
                                child: _isResending
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : RichText(
                                        text: TextSpan(
                                          text: '${context.l10n.notReceived} ',
                                          style: TextStyle(
                                              color: isDark
                                                  ? Colors.white54
                                                  : Colors.black54,
                                              fontSize: 13),
                                          children: [
                                            TextSpan(
                                              text: context.l10n.resend,
                                              style: TextStyle(
                                                color: accentOrange,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Back button (on top of scroll view) ─────────────────────
                Positioned(
                  top: 0,
                  left: 0,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
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
