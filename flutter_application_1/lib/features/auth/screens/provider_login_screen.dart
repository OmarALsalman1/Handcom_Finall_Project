import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:handcom/core/l10n/app_strings.dart';
import 'package:handcom/features/auth/screens/provider_home_page.dart';
import 'package:handcom/shared/widgets/theme_provider.dart'; // تأكد من صحة مسار ملف الـ Provider بمشروعك
import 'package:handcom/services/auth_service.dart';
import 'package:handcom/providers/user_auth_provider.dart';
import 'register_provider_screen.dart';
import 'user_type_screen.dart';
import 'forgot_password_email_screen.dart';

class ProviderLoginScreen extends StatefulWidget {
  const ProviderLoginScreen({super.key});

  @override
  State<ProviderLoginScreen> createState() => _ProviderLoginScreenState();
}

class _ProviderLoginScreenState extends State<ProviderLoginScreen> {
  bool obscurePassword = true;
  bool _isLoading = false;

  // مفتاح ذكي للتحكم في الـ Form وعمل الـ Validation
  final _formKey = GlobalKey<FormState>();

  // وحدات تحكم لقراءة النصوص من الحقول
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  static const Color primaryBlue = Color(0xFF1A3D81);
  static const Color accentOrange = Color(0xFFF58220);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // الاستماع للتغيرات العالمية للـ Dark Mode
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final bool isDark = themeProvider.isDarkMode;

        // تهيئة قائمة الألوان المتفاعلة مع النظام لضمان التناسق البصري
        final Color scaffoldBg = isDark ? const Color(0xFF121212) : const Color(0xfff2f2f2);
        final Color appBarBg = isDark ? const Color(0xFF1A1A1A) : primaryBlue;
        final Color cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final Color inputBg = isDark ? const Color(0xFF2C2C2C) : const Color(0xffeeeeee);
        final Color textColor = isDark ? Colors.white : Colors.black;

        return Scaffold(
          backgroundColor: scaffoldBg,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  /// --- الهيدر والترحيب المتوافق مع الثيم ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(top: 20, bottom: 40),
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
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const UserTypeScreen()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          context.l10n.welcome,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          context.l10n.loginToContinue,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// --- كرت الإدخال والتسجيل الديناميكي للمزود ---
                  Form(
                    key: _formKey,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? Colors.black38 : Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            context.l10n.email,
                            style: TextStyle(fontSize: 16, color: textColor, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            textAlign: TextAlign.right,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(color: textColor),
                            decoration: InputDecoration(
                              hintText: context.l10n.emailHint,
                              hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.grey),
                              filled: true,
                              fillColor: inputBg,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                              errorStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return context.l10n.emailRequired;
                              final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                              if (!emailRegExp.hasMatch(value.trim())) return context.l10n.emailInvalid;
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          Text(
                            context.l10n.password,
                            style: TextStyle(fontSize: 16, color: textColor, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            textAlign: TextAlign.right,
                            obscureText: obscurePassword,
                            style: TextStyle(color: textColor),
                            decoration: InputDecoration(
                              hintText: context.l10n.passwordHint,
                              hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.grey),
                              filled: true,
                              fillColor: inputBg,
                              prefixIcon: IconButton(
                                icon: Icon(
                                  obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: isDark ? Colors.white60 : Colors.black54,
                                ),
                                onPressed: () => setState(() => obscurePassword = !obscurePassword),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                              errorStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return context.l10n.passwordRequired;
                              if (value.length < 6) return context.l10n.passwordMin;
                              return null;
                            },
                          ),

                          const SizedBox(height: 10),

                          Align(
                            alignment: Alignment.centerLeft,
                            child: GestureDetector(
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (context) => const ForgotPasswordEmailScreen())),
                              child: Text(
                                context.l10n.forgotPassword,
                                style: TextStyle(
                                  color: isDark ? accentOrange : Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 25),

                          /// --- زر تسجيل الدخول للمزود ---
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentOrange,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              onPressed: _isLoading
                                  ? null
                                  : () async {
                                      if (!_formKey.currentState!.validate()) {
                                        return;
                                      }
                                      setState(() => _isLoading = true);

                                      // Capture before async gap
                                      final authProvider = context.read<UserAuthProvider>();
                                      final navigator = Navigator.of(context);
                                      final messenger = ScaffoldMessenger.of(context);
                                      final loginErrorMsg = context.l10n.loginError;

                                      final result =
                                          await AuthService.loginProvider(
                                        _emailController.text,
                                        _passwordController.text,
                                      );

                                      if (!mounted) return;
                                      setState(() => _isLoading = false);

                                      if (result.success) {
                                        authProvider.onLoginSuccess(
                                          role: 'service_provider',
                                          email: _emailController.text
                                              .trim(),
                                        );
                                        navigator.pushReplacement(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const ProviderHomePage(),
                                          ),
                                        );
                                      } else {
                                        messenger.showSnackBar(SnackBar(
                                          content: Text(
                                            result.error ?? loginErrorMsg,
                                            textAlign: TextAlign.right,
                                          ),
                                          backgroundColor: Colors.red,
                                        ));
                                      }
                                    },
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : Text(
                                      context.l10n.login,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 25),

                          Row(
                            children: [
                              Expanded(child: Divider(color: isDark ? Colors.white10 : Colors.black12)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Text(context.l10n.or, style: TextStyle(color: isDark ? Colors.white38 : Colors.black54)),
                              ),
                              Expanded(child: Divider(color: isDark ? Colors.white10 : Colors.black12)),
                            ],
                          ),

                          const SizedBox(height: 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const RegisterProviderScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  context.l10n.createAccount,
                                  style: TextStyle(
                                    color: isDark ? accentOrange : Colors.blue,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                ' ${context.l10n.noAccount}',
                                style: TextStyle(
                                  color: isDark ? Colors.white70 : Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}