import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:handcom/features/auth/screens/forgot_password_email_screen.dart';
import 'package:handcom/shared/widgets/theme_provider.dart';
import 'package:handcom/providers/user_auth_provider.dart';
import 'package:handcom/services/api_service.dart';
import 'package:handcom/core/config/api_config.dart';
import 'package:handcom/core/l10n/app_strings.dart';

class AccountInfoPage extends StatefulWidget {
  const AccountInfoPage({super.key});

  @override
  State<AccountInfoPage> createState() => _AccountInfoPageState();
}

class _AccountInfoPageState extends State<AccountInfoPage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  static const List<String> _jordanCities = AppStrings.jordanCitiesCanonical;
  String? _selectedCity;
  String selectedGender = "male";
  bool _isSaving = false;

  static const Color primaryBlue = Color(0xFF1A3D81);
  static const Color accentOrange = Color(0xFFF58220);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final response = await ApiService.get(ApiConfig.userMe);
    if (!mounted) return;
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final fullName = (data['full_name'] ?? '') as String;
      final parts = fullName.split(' ');
      setState(() {
        _firstNameController.text = parts.isNotEmpty ? parts.first : '';
        _lastNameController.text = parts.length > 1 ? parts.sublist(1).join(' ') : '';
        _emailController.text = data['email'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        final address = data['address'] ?? '';
        if (_jordanCities.contains(address)) {
          _selectedCity = address;
        } else {
          _selectedCity = _jordanCities.first;
        }
        final g = (data['gender'] ?? 'male') as String;
        selectedGender = (g == 'female') ? 'female' : 'male';
      });
    } else {
      // Fallback to provider
      final auth = context.read<UserAuthProvider>();
      final fullName = auth.name;
      final parts = fullName.split(' ');
      setState(() {
        _firstNameController.text = parts.isNotEmpty ? parts.first : '';
        _lastNameController.text = parts.length > 1 ? parts.sublist(1).join(' ') : '';
        _emailController.text = auth.email;
        _selectedCity = _jordanCities.first;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_firstNameController.text.trim().isEmpty) return;
    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final saveDone = context.l10n.saveDone;

    final response = await ApiService.patch(ApiConfig.userMe, {
      'full_name':
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
      'phone': _phoneController.text.trim(),
      'address': _selectedCity ?? '',
      'gender': selectedGender,
    });
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      context.read<UserAuthProvider>().setProfile(
            name: data['full_name'] ?? '',
            email: data['email'],
          );
      messenger.showSnackBar(SnackBar(
        content: Text(saveDone, textAlign: TextAlign.center),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ));
      navigator.pop();
    } else {
      messenger.showSnackBar(SnackBar(
        content: Text(ApiService.extractError(response),
            textAlign: TextAlign.center),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final bool isDark = themeProvider.isDarkMode;
        final Color scaffoldBg =
            isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FB);
        final Color cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final Color inputBg =
            isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEEEEEE);
        final Color textColor = isDark ? Colors.white : Colors.black;
        final Color subTextColor = isDark ? Colors.white60 : Colors.black54;

        return Scaffold(
          backgroundColor: scaffoldBg,
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildHeader(context),
                const SizedBox(height: 50),
                _buildInfoCard(cardBg, inputBg, textColor, subTextColor, isDark),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 150,
          width: double.infinity,
          decoration: const BoxDecoration(
            color: primaryBlue,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      Text(
                        context.l10n.accountInfo,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(Color cardBg, Color inputBg, Color textColor,
      Color subTextColor, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildTextField(context.l10n.firstName, _firstNameController, inputBg, textColor),
          _buildTextField(context.l10n.lastName, _lastNameController, inputBg, textColor),
          _buildTextField(context.l10n.email, _emailController, inputBg,
              textColor, readOnly: true),
          _buildTextField(context.l10n.phone, _phoneController, inputBg, textColor,
              keyboardType: TextInputType.phone),
          _buildCityDropdown(inputBg, textColor, cardBg),

          Text(context.l10n.editPassword,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const ForgotPasswordEmailScreen())),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
                fixedSize: const Size(90, 40),
              ),
              child: Text(context.l10n.edit,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),

          const SizedBox(height: 20),
          Text(context.l10n.gender,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildGenderOption('male', context.l10n.male, inputBg, subTextColor),
              const SizedBox(width: 35),
              _buildGenderOption('female', context.l10n.female, inputBg, subTextColor),
            ],
          ),
          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentOrange,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(context.l10n.save,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      Color inputBg, Color textColor,
      {TextInputType keyboardType = TextInputType.text,
      bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          textAlign: TextAlign.center,
          keyboardType: keyboardType,
          readOnly: readOnly,
          style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            filled: true,
            fillColor: inputBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget _buildCityDropdown(Color inputBg, Color textColor, Color cardBg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(context.l10n.city,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
              color: inputBg, borderRadius: BorderRadius.circular(12)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCity,
              isExpanded: true,
              dropdownColor: cardBg,
              icon: const Icon(Icons.arrow_drop_down, color: primaryBlue),
              alignment: Alignment.centerRight,
              style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500),
              onChanged: (String? newValue) =>
                  setState(() => _selectedCity = newValue),
              items: _jordanCities
                  .map((v) => DropdownMenuItem<String>(
                        value: v,
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(context.l10n.jordanCityLabel(v),
                              style: TextStyle(color: textColor)),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget _buildGenderOption(
      String value, String label, Color inputBg, Color subTextColor) {
    bool isSelected = selectedGender == value;
    return GestureDetector(
      onTap: () => setState(() => selectedGender = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryBlue : inputBg,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(label,
            style: TextStyle(
              color: isSelected ? Colors.white : subTextColor,
              fontWeight: FontWeight.bold,
            )),
      ),
    );
  }
}
