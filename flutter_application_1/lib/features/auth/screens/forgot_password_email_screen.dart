import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:handcom/shared/widgets/theme_provider.dart';
import 'package:handcom/services/auth_service.dart';
import 'package:handcom/core/l10n/app_strings.dart';
import 'forgot_password_code_screen.dart';

class ForgotPasswordEmailScreen extends StatefulWidget {
  const ForgotPasswordEmailScreen({super.key});

  @override
  State<ForgotPasswordEmailScreen> createState() =>
      _ForgotPasswordEmailScreenState();
}

class _ForgotPasswordEmailScreenState extends State<ForgotPasswordEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  static const Color primaryBlue = Color(0xFF1A3D81);
  static const Color accentOrange = Color(0xFFF58220);

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final email = _emailController.text.trim();
    final sendError = context.l10n.sendError;

    final result = await AuthService.requestPasswordReset(email);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      navigator.push(
        MaterialPageRoute(
          builder: (context) => ForgotPasswordCodeScreen(email: email),
        ),
      );
    } else {
      messenger.showSnackBar(SnackBar(
        content: Text(result.error ?? sendError,
            textAlign: TextAlign.center),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
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
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        context.l10n.forgotPasswordTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),

                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: const EdgeInsets.only(top: 180),
                    padding: const EdgeInsets.all(20),
                    width: MediaQuery.of(context).size.width * 0.8,
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
                            context.l10n.enterEmailHint,
                            style: TextStyle(
                              fontSize: 16,
                              color: textColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _emailController,
                            textAlign: TextAlign.right,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(
                                color: textColor, fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              hintText: "A@gmail.com",
                              hintTextDirection: TextDirection.rtl,
                              hintStyle: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white38 : Colors.grey),
                              filled: true,
                              fillColor: inputBg,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return context.l10n.emailRequired;
                              }
                              final emailRegExp = RegExp(
                                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                              if (!emailRegExp.hasMatch(value.trim())) {
                                return context.l10n.emailInvalid;
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
                              onPressed: _isLoading ? null : _sendReset,
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : Text(
                                      context.l10n.send,
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
              ],
            ),
          ),
        );
      },
    );
  }
}
