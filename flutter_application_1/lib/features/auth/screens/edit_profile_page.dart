import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:handcom/shared/widgets/theme_provider.dart';
import 'package:handcom/providers/user_auth_provider.dart';
import 'package:handcom/services/api_service.dart';
import 'package:handcom/core/config/api_config.dart';
import 'package:handcom/core/l10n/app_strings.dart';
import 'forgot_password_email_screen.dart';
import 'worker_profile_page.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController =
      TextEditingController(text: "");
  final TextEditingController _jobController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _servicesController = TextEditingController();

  String _selectedCity = "عمان";
  final List<String> _jordanCities = [
    "عمان", "الزرقاء", "إربد", "العقبة", "المفرق", "جرش",
    "عجلون", "مأدبا", "الكرك", "الطفيلة", "معان", "البلقاء"
  ];

  final List<String> _allJobs = ["سباكة", "نجارة", "دهان", "كهرباء"];
  final List<String> _tempSelectedJobs = [];
  bool _isLoading = true;
  bool _isSaving = false;

  static const Color primaryBlue = Color(0xFF1A3D81);
  static const Color accentOrange = Color(0xFFF58220);

  static const Map<String, String> _enToAr = {
    'plumbing': 'سباكة',
    'electrical': 'كهرباء',
    'painting': 'دهان',
    'carpentry': 'نجارة',
  };
  static const Map<String, String> _arToEn = {
    'سباكة': 'plumbing',
    'كهرباء': 'electrical',
    'دهان': 'painting',
    'نجارة': 'carpentry',
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_dobController.text.isEmpty) {
      _dobController.text = context.l10n.datePlaceholder;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final response = await ApiService.get(ApiConfig.providerMe);
    if (!mounted) return;
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final fullName = (data['full_name'] ?? '') as String;
      final parts = fullName.split(' ');
      final cats = (data['service_categories'] as List? ?? [])
          .map((c) => _enToAr[c] ?? c)
          .toList();
      setState(() {
        _firstNameController.text = parts.isNotEmpty ? parts.first : '';
        _lastNameController.text =
            parts.length > 1 ? parts.sublist(1).join(' ') : '';
        _emailController.text = data['email'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _experienceController.text =
            (data['experience_years'] ?? 0).toString();
        _bioController.text = data['bio'] ?? '';
        _servicesController.text = data['services_offered'] ?? '';
        _tempSelectedJobs
          ..clear()
          ..addAll(cats.cast<String>());
        _jobController.text = _tempSelectedJobs.join(' ، ');
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final savedMsg = context.l10n.changesSaved;

    final categories = _tempSelectedJobs
        .map((j) => _arToEn[j])
        .where((c) => c != null)
        .cast<String>()
        .toList();

    final response = await ApiService.patch(ApiConfig.providerMe, {
      'full_name':
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
      'phone': _phoneController.text.trim(),
      'experience_years':
          int.tryParse(_experienceController.text.trim()) ?? 0,
      'service_categories': categories,
      'bio': _bioController.text.trim(),
      'services_offered': _servicesController.text.trim(),
    });
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      context
          .read<UserAuthProvider>()
          .setProfile(name: data['full_name'] ?? '');
      messenger.showSnackBar(SnackBar(
        content: Text(savedMsg, textAlign: TextAlign.center),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ));
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const WorkerProfilePage()),
        (route) => false,
      );
    } else {
      messenger.showSnackBar(SnackBar(
        content: Text(ApiService.extractError(response),
            textAlign: TextAlign.center),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _selectDate(BuildContext context, bool isDark) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryBlue,
              onPrimary: Colors.white,
              surface: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              onSurface: isDark ? Colors.white : Colors.black,
            ),
            dialogBackgroundColor:
                isDark ? const Color(0xFF1E1E1E) : Colors.white,
          ),
          child: Directionality(
              textDirection: TextDirection.rtl, child: child!),
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text =
            "${picked.day} / ${picked.month} / ${picked.year}";
      });
    }
  }

  void _showMultiSelectJobs(Color cardBg, Color textColor) async {
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: cardBg,
          title: Text(context.l10n.chooseProfessions,
              textAlign: TextAlign.right,
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _allJobs.map((job) {
              return CheckboxListTile(
                title: Text(job,
                    textAlign: TextAlign.right,
                    style: TextStyle(color: textColor)),
                value: _tempSelectedJobs.contains(job),
                activeColor: primaryBlue,
                checkColor: Colors.white,
                onChanged: (bool? value) {
                  setDialogState(() {
                    if (value == true) {
                      _tempSelectedJobs.add(job);
                    } else {
                      _tempSelectedJobs.remove(job);
                    }
                  });
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _jobController.text = _tempSelectedJobs.join(" ، ");
                });
                Navigator.pop(context);
              },
              child: Text(context.l10n.done,
                  style: const TextStyle(
                      color: accentOrange,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _jobController.dispose();
    _bioController.dispose();
    _experienceController.dispose();
    _servicesController.dispose();
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
            isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF0F0F0);
        final Color textColor = isDark ? Colors.white : Colors.black;
        final Color subTextColor = isDark ? Colors.white60 : Colors.black54;

        return Scaffold(
          backgroundColor: scaffoldBg,
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _buildHeader(context),
                      Transform.translate(
                        offset: const Offset(0, 20),
                        child: _buildInfoCard(
                            cardBg, inputBg, textColor, subTextColor, isDark),
                      ),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 170,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: primaryBlue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () {
                if (Navigator.canPop(context)) Navigator.pop(context);
              },
            ),
            const Spacer(),
            Text(context.l10n.editProfileTitle,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const Spacer(),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(Color cardBg, Color inputBg, Color textColor,
      Color subTextColor, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 20)
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildTextField(context.l10n.firstName, _firstNameController, inputBg,
                textColor,
                validator: (val) => val == null || val.trim().isEmpty
                    ? context.l10n.firstNameRequired
                    : null),
            _buildTextField(context.l10n.lastName, _lastNameController, inputBg,
                textColor,
                validator: (val) => val == null || val.trim().isEmpty
                    ? context.l10n.lastNameRequired
                    : null),
            _buildTextField(
                context.l10n.email, _emailController, inputBg, textColor,
                readOnly: true),
            _buildTextField(context.l10n.phone, _phoneController, inputBg, textColor,
                keyboardType: TextInputType.phone),
            _buildCityDropdownCentered(inputBg, textColor, cardBg),

            Text(context.l10n.birthdate,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: textColor)),
            const SizedBox(height: 8),
            _buildCustomSelectableField(
              text: _dobController.text,
              icon: Icons.calendar_month,
              inputBg: inputBg,
              textColor: textColor,
              onTap: () => _selectDate(context, isDark),
            ),
            const SizedBox(height: 15),
            _buildJobDropdownCentered(inputBg, textColor, cardBg),

            _buildTextField(context.l10n.yearsExp, _experienceController, inputBg,
                textColor,
                keyboardType: TextInputType.number),
            _buildTextField(context.l10n.bio, _bioController, inputBg,
                textColor,
                maxLines: 3),
            _buildTextField(context.l10n.offeredServices, _servicesController, inputBg,
                textColor,
                maxLines: 3),

            const SizedBox(height: 10),
            Text(context.l10n.editPassword,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: textColor)),
            const SizedBox(height: 10),
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
                        borderRadius: BorderRadius.circular(12))),
                child: Text(context.l10n.edit,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
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
                        borderRadius: BorderRadius.circular(12))),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(context.l10n.saveChanges,
                        style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomSelectableField(
      {required String text,
      required IconData icon,
      required Color inputBg,
      required Color textColor,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
            color: inputBg, borderRadius: BorderRadius.circular(12)),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
                alignment: Alignment.centerRight,
                child: Icon(icon, color: accentOrange, size: 22)),
            Text(text,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16,
                    color: textColor,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildCityDropdownCentered(
      Color inputBg, Color textColor, Color cardBg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(context.l10n.city,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: textColor)),
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
              icon: const Icon(Icons.arrow_drop_down, color: accentOrange),
              alignment: Alignment.centerLeft,
              style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500),
              onChanged: (String? newValue) =>
                  setState(() => _selectedCity = newValue!),
              items: _jordanCities
                  .map((v) => DropdownMenuItem<String>(
                      value: v,
                      child: Align(
                          alignment: Alignment.center,
                          child: Text(v,
                              style: TextStyle(color: textColor)))))
                  .toList(),
            ),
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget _buildJobDropdownCentered(inputBg, textColor, cardBg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(context.l10n.profession,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: textColor)),
        const SizedBox(height: 8),
        _buildCustomSelectableField(
          text: _jobController.text.isEmpty ? context.l10n.chooseProfession : _jobController.text,
          icon: Icons.arrow_drop_down,
          inputBg: inputBg,
          textColor: textColor,
          onTap: () => _showMultiSelectJobs(cardBg, textColor),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, Color inputBg,
      Color textColor,
      {int maxLines = 1,
      TextInputType keyboardType = TextInputType.text,
      bool readOnly = false,
      String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: textColor)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          readOnly: readOnly,
          validator: validator,
          textAlign: maxLines == 1 ? TextAlign.center : TextAlign.right,
          style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            filled: true,
            fillColor: inputBg,
            errorStyle: const TextStyle(height: 0.8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }
}
