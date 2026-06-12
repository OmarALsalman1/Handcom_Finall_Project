import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:handcom/features/auth/screens/reset_password_screen.dart';
import 'package:handcom/shared/widgets/theme_provider.dart';
import 'package:handcom/core/l10n/app_strings.dart';

class ForgotPasswordCodeScreen extends StatefulWidget {
  final String email;

  const ForgotPasswordCodeScreen({super.key, required this.email});

  @override
  State<ForgotPasswordCodeScreen> createState() =>
      _ForgotPasswordCodeScreenState();
}

class _ForgotPasswordCodeScreenState extends State<ForgotPasswordCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();

  static const Color primaryBlue = Color(0xFF1A3D81);
  static const Color accentOrange = Color(0xFFF58220);

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _next() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResetPasswordScreen(
          email: widget.email,
          otp: _codeController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final bool isDark = themeProvider.isDarkMode;

        final Color scaffoldBg =
            isDark ? const Color(0xFF121212) : const Color(0xfff2f2f2);
        final Color appBarBg = isDark ? const Color(0xFF1A1A1A) : primaryBlue;
        final Color cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final Color inputBg =
            isDark ? const Color(0xFF2C2C2C) : const Color(0xffeeeeee);
        final Color textColor = isDark ? Colors.white : Colors.black;

        return Scaffold(
          backgroundColor: scaffoldBg,
          body: SafeArea(
            child: Stack(
              children: [
                Container(
                  height: 240,
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 40, bottom: 100),
                  decoration: BoxDecoration(
                    color: appBarBg,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      context.l10n.forgotPasswordTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                Align(
                  alignment: Alignment.topCenter,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 180),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 35),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? Colors.black38 : Colors.black26,
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              context.l10n.enterVerifyCode,
                              style: TextStyle(
                                  fontSize: 16,
                                  color: textColor,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _codeController,
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  letterSpacing: 2),
                              decoration: InputDecoration(
                                hintText: "- - - -",
                                hintStyle: TextStyle(
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.black38),
                                filled: true,
                                fillColor: inputBg,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return context.l10n.codeRequired;
                                }
                                if (!RegExp(r'^\d+$').hasMatch(value.trim())) {
                                  return context.l10n.codeDigitsOnly;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accentOrange,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  elevation: 2,
                                ),
                                onPressed: _next,
                                child: Text(
                                  context.l10n.confirm,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topLeft,
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
