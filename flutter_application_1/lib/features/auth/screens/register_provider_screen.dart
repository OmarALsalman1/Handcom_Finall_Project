import 'package:flutter/material.dart';
import 'verify_email_screen.dart';
import 'package:provider/provider.dart';
import 'package:handcom/shared/widgets/theme_provider.dart';
import 'package:handcom/services/auth_service.dart';
import 'package:handcom/core/l10n/app_strings.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:handcom/features/auth/screens/select_location_screen.dart';

class RegisterProviderScreen extends StatefulWidget {
  const RegisterProviderScreen({super.key});

  @override
  State<RegisterProviderScreen> createState() => _RegisterProviderScreenState();
}

class _RegisterProviderScreenState extends State<RegisterProviderScreen> {
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool _isLoading = false;

  String selectedCity = "";
  List<String> selectedJobs = [];
  String birthDate = "";

  bool isLocationSelected = false;
  LatLng? _selectedLatLng;

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // الألوان الأساسية للهوية البصرية (ثابتة)
  static const Color primaryBlue = Color(0xFF1A3D81);
  static const Color accentOrange = Color(0xFFF58220);

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // استخدام Consumer للمراقبة الديناميكية لوضع الثيم العالمي
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final bool isDark = themeProvider.isDarkMode;

        // تهيئة مصفوفة الألوان المتغيرة بدون استخدام const في بداية السطر لتفادي الخطأ
        final Color scaffoldBg = isDark ? const Color(0xFF121212) : const Color(0xfff2f2f2);
        final Color appBarBg = isDark ? const Color(0xFF1A1A1A) : primaryBlue;
        final Color cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final Color inputBg = isDark ? const Color(0xFF2C2C2C) : const Color(0xffeeeeee);
        final Color textColor = isDark ? Colors.white : Colors.black87;

        return Scaffold(
          backgroundColor: scaffoldBg,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  /// HEADER
                  Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: appBarBg,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 15,
                          left: 10,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: Text(
                            context.l10n.newProviderTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// CARD
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                              blurRadius: 10,
                            )
                          ],
                          border: isDark ? Border.all(color: Colors.white10, width: 0.5) : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _title(context.l10n.firstName, textColor),
                            _input(
                              controller: _firstNameController,
                              hint: context.l10n.firstName,
                              inputBg: inputBg,
                              textColor: textColor,
                              isDark: isDark,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return context.l10n.firstNameRequired;
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 15),

                            _title(context.l10n.lastName, textColor),
                            _input(
                              controller: _lastNameController,
                              hint: context.l10n.lastName,
                              inputBg: inputBg,
                              textColor: textColor,
                              isDark: isDark,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return context.l10n.lastNameRequired;
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 15),

                            _title(context.l10n.email, textColor),
                            _input(
                              controller: _emailController,
                              hint: "example@gmail.com",
                              inputBg: inputBg,
                              textColor: textColor,
                              isDark: isDark,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return context.l10n.emailRequired;
                                }
                                final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                                if (!emailRegExp.hasMatch(value.trim())) {
                                  return context.l10n.emailInvalid;
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 15),

                            _title(context.l10n.phone, textColor),
                            _input(
                              controller: _phoneController,
                              hint: "07xxxxxxxx",
                              inputBg: inputBg,
                              textColor: textColor,
                              isDark: isDark,
                              leftAlign: true,
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return context.l10n.phoneRequired;
                                }
                                final phoneRegExp = RegExp(r'^07[789]\d{7}$');
                                if (!phoneRegExp.hasMatch(value.trim())) {
                                  return context.l10n.phoneInvalid;
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 15),

                            _title(context.l10n.profession, textColor),
                            _jobDropdown(inputBg, textColor),

                            const SizedBox(height: 15),

                            _title(context.l10n.province, textColor),
                            _cityDropdown(inputBg, textColor),

                            const SizedBox(height: 15),

                            _title(context.l10n.birthdate, textColor),
                            _datePicker(inputBg, textColor),

                            const SizedBox(height: 15),

                            _title(context.l10n.password, textColor),
                            _passwordField(inputBg, textColor),

                            const SizedBox(height: 15),

                            _title(context.l10n.confirmPassword, textColor),
                            _confirmPassword(inputBg, textColor),

                            const SizedBox(height: 15),

                            _title(context.l10n.workLocationLabel, textColor),
                            _locationPicker(inputBg, isDark),

                            const SizedBox(height: 30),

                            /// SAVE BUTTON
                            Center(
                              child: GestureDetector(
                                onTap: _isLoading
                                    ? null
                                    : () async {
                                        if (_formKey.currentState!.validate()) {
                                          if (selectedJobs.isEmpty) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                              content: Text(
                                                  context.l10n.jobRequired,
                                                  textAlign: TextAlign.right),
                                            ));
                                            return;
                                          }
                                          if (selectedCity.isEmpty) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                              content: Text(
                                                  context.l10n.provinceRequired,
                                                  textAlign: TextAlign.right),
                                            ));
                                            return;
                                          }
                                          if (birthDate.isEmpty) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                              content: Text(
                                                  context.l10n.birthdateRequired,
                                                  textAlign: TextAlign.right),
                                            ));
                                            return;
                                          }
                                          if (!isLocationSelected) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                              content: Text(
                                                  context.l10n.workLocationRequired,
                                                  textAlign: TextAlign.right),
                                            ));
                                            return;
                                          }
                                          setState(() => _isLoading = true);
                                          final navigator = Navigator.of(context);
                                          final messenger = ScaffoldMessenger.of(context);
                                          final l10n = context.l10n;
                                          final email = _emailController.text.trim();
                                          final result =
                                              await AuthService.registerProvider(
                                            firstName:
                                                _firstNameController.text,
                                            lastName: _lastNameController.text,
                                            email: email,
                                            phone: _phoneController.text,
                                            selectedJobs: selectedJobs,
                                            password: _passwordController.text,
                                          );
                                          if (!mounted) return;
                                          setState(() => _isLoading = false);
                                          if (result.success) {
                                            navigator.push(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    VerifyEmailScreen(
                                                  email: email,
                                                  role: 'service_provider',
                                                ),
                                              ),
                                            );
                                          } else {
                                            messenger.showSnackBar(SnackBar(
                                              content: Text(
                                                l10n.errorMessage(result.errorCode, fallback: result.error),
                                                textAlign: TextAlign.right,
                                              ),
                                              backgroundColor: Colors.red,
                                            ));
                                          }
                                        }
                                      },
                                child: Container(
                                  width: 160,
                                  height: 45,
                                  decoration: BoxDecoration(
                                    color: accentOrange,
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Center(
                                    child: _isLoading
                                        ? const CircularProgressIndicator(
                                            color: Colors.white)
                                        : Text(
                                            context.l10n.save,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// TITLE
  Widget _title(String text, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  /// INPUT FIELD
  Widget _input({
    String hint = "",
    bool leftAlign = false,
    TextEditingController? controller,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    required Color inputBg,
    required Color textColor,
    required bool isDark,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      textAlign: leftAlign ? TextAlign.left : TextAlign.right,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        hintText: hint,
        hintTextDirection: leftAlign ? TextDirection.ltr : TextDirection.rtl,
        hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey[400], fontSize: 14),
        filled: true,
        fillColor: inputBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        errorStyle: const TextStyle(fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      ),
    );
  }

  /// PASSWORD
  Widget _passwordField(Color inputBg, Color textColor) {
    return TextFormField(
      controller: _passwordController,
      obscureText: obscurePassword,
      textAlign: TextAlign.right,
      style: TextStyle(color: textColor),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return context.l10n.passwordRequired;
        }
        if (value.length < 6) {
          return context.l10n.passwordMin;
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: context.l10n.passwordHint,
        hintTextDirection: TextDirection.rtl,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        filled: true,
        fillColor: inputBg,
        prefixIcon: IconButton(
          icon: Icon(
            obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: () {
            setState(() {
              obscurePassword = !obscurePassword;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        errorStyle: const TextStyle(fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      ),
    );
  }

  /// CONFIRM PASSWORD
  Widget _confirmPassword(Color inputBg, Color textColor) {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: obscureConfirmPassword,
      textAlign: TextAlign.right,
      style: TextStyle(color: textColor),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return context.l10n.confirmPasswordRequired;
        }
        if (value != _passwordController.text) {
          return context.l10n.passwordMismatch;
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: context.l10n.confirmPasswordHint,
        hintTextDirection: TextDirection.rtl,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        filled: true,
        fillColor: inputBg,
        prefixIcon: IconButton(
          icon: Icon(
            obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: () {
            setState(() {
              obscureConfirmPassword = !obscureConfirmPassword;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        errorStyle: const TextStyle(fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      ),
    );
  }

  /// LOCATION PICKER
  Widget _locationPicker(Color inputBg, bool isDark) {
    return GestureDetector(
      onTap: () async {
        final LatLng? result = await Navigator.push<LatLng>(
          context,
          MaterialPageRoute(
              builder: (context) => const SelectLocationScreen()),
        );
        if (result != null) {
          setState(() {
            _selectedLatLng = result;
            isLocationSelected = true;
          });
        }
      },
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: inputBg,
          borderRadius: BorderRadius.circular(20),
          border: isLocationSelected ? Border.all(color: Colors.green, width: 1.5) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              Icons.location_on,
              color: isLocationSelected ? Colors.green : (isDark ? Colors.white60 : Colors.grey[600]),
            ),
            Text(
              isLocationSelected && _selectedLatLng != null
                  ? '${_selectedLatLng!.latitude.toStringAsFixed(4)}, ${_selectedLatLng!.longitude.toStringAsFixed(4)}'
                  : context.l10n.workLocationHint,
              style: TextStyle(
                color: isLocationSelected
                    ? Colors.green
                    : (isDark ? Colors.white60 : Colors.grey[600]),
                fontWeight:
                    isLocationSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// JOB DROPDOWN
  Widget _jobDropdown(Color inputBg, Color textColor) {
    return GestureDetector(
      onTap: () {
        _showJobs();
      },
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: inputBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(Icons.keyboard_arrow_down, color: textColor),
            Expanded(
              child: Text(
                selectedJobs.isEmpty ? context.l10n.profession : selectedJobs.join(" ، "),
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selectedJobs.isEmpty ? Colors.grey[400] : textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// CITY DROPDOWN
  Widget _cityDropdown(Color inputBg, Color textColor) {
    return GestureDetector(
      onTap: () {
        _showCities();
      },
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: inputBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(Icons.keyboard_arrow_down, color: textColor),
            Text(
              selectedCity.isEmpty
                  ? context.l10n.province
                  : context.l10n.jordanCityLabel(selectedCity),
              style: TextStyle(
                color: selectedCity.isEmpty ? Colors.grey[400] : textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// DATE PICKER
  Widget _datePicker(Color inputBg, Color textColor) {
    return GestureDetector(
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime(2000),
          firstDate: DateTime(1950),
          lastDate: DateTime.now(),
        );

        if (pickedDate != null) {
          setState(() {
            birthDate = "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
          });
        }
      },
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: inputBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(Icons.calendar_month, color: textColor),
            Text(
              birthDate.isEmpty ? context.l10n.datePlaceholder : birthDate,
              style: TextStyle(
                color: birthDate.isEmpty ? Colors.grey[400] : textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ إعادة دالة قائمة المهن الناقصة وتأمين دعمها للـ Dark Mode
  void _showJobs() {
    final l10n = context.l10n;
    List<String> jobs = [l10n.plumbing, l10n.carpentry, l10n.painting, l10n.electricity];
    final bool isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    l10n.chooseProfessions,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...jobs.map((job) {
                    return CheckboxListTile(
                      value: selectedJobs.contains(job),
                      activeColor: accentOrange,
                      checkColor: Colors.white,
                      title: Text(
                        job,
                        textAlign: TextAlign.right,
                        style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (value) {
                        setModalState(() {
                          if (value == true) {
                            selectedJobs.add(job);
                          } else {
                            selectedJobs.remove(job);
                          }
                        });
                        setState(() {});
                      },
                    );
                  }),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(l10n.done, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// ✅ إعادة دالة قائمة المحافظات الناقصة وتأمين دعمها للـ Dark Mode
  void _showCities() {
    const List<String> cities = AppStrings.jordanCitiesCanonical;
    final bool isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final l10n = context.l10n;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: ListView(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            children: cities.map((city) {
              return ListTile(
                title: Text(
                  l10n.jordanCityLabel(city),
                  textAlign: TextAlign.right,
                  style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                ),
                onTap: () {
                  setState(() {
                    selectedCity = city; // always store Arabic canonical
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}