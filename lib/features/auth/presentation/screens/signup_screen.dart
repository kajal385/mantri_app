import 'package:mantri_app/core/utils/app_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mantri_app/core/services/firebase_service.dart';
import 'package:mantri_app/core/models/app_models.dart';
import 'package:mantri_app/core/constants/states_cities_data.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:mantri_app/core/utils/image_helper.dart';
import 'package:mantri_app/generated/app_localizations.dart';
import 'package:mantri_app/core/providers/locations_provider.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  final UserRole? initialRole;
  const SignUpScreen({super.key, this.initialRole});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _wardController = TextEditingController();
  final _dobController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _selectedState;
  String? _selectedCity;
  String? _selectedVillage;
  final _customStateController = TextEditingController();
  final _customCityController = TextEditingController();
  final _customVillageController = TextEditingController();
  late UserRole _selectedRole;
  bool _agreePolicy = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final _formKey = GlobalKey<FormState>();
  File? _profileImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole ?? UserRole.user;
  }

  final Color _saffron = const Color.fromARGB(255, 219, 126, 32);
  final Color _darkText = const Color(0xFF2E3349);
  final Color _blueDark = const Color(0xFF1B3B5A);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      final l10n = AppLocalizations.of(context);
      AppDialogs.showErrorDialog(context);
      return;
    }

    if (!_agreePolicy) {
      final l10n = AppLocalizations.of(context);
      AppDialogs.showErrorDialog(context);
      return;
    }

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final ward = _wardController.text.trim();
    final village = _selectedVillage ?? '';
    final dob = _dobController.text.trim();
    final pass = _passwordController.text.trim();

    setState(() => _isLoading = true);
    try {
      String? profileImageUrl;
      final authService = ref.read(authServiceProvider);

      // 1. Upload Profile Image if selected
      if (_profileImage != null) {
        profileImageUrl = await authService.uploadProfileImage(_profileImage!);
      }

      final stateToSave =
          _selectedState == 'Other'
              ? _customStateController.text.trim()
              : _selectedState;
      final cityToSave =
          _selectedCity == 'Other'
              ? _customCityController.text.trim()
              : _selectedCity;
      final villageToSave =
          _selectedVillage == 'Other'
              ? _customVillageController.text.trim()
              : village;

      // 2. Sign Up
      await authService.signUp(
        name,
        email,
        pass,
        _selectedRole,
        phone: phone,
        state: stateToSave,
        city: cityToSave,
        ward: ward,
        village: villageToSave,
        dob: dob.isNotEmpty ? dob : null,
        profileImageUrl: profileImageUrl,
      );
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showErrorDialog(context, technicalError: e);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (image != null) {
      final croppedFile = await ImageHelper.cropImage(File(image.path));
      if (croppedFile != null) {
        setState(() => _profileImage = croppedFile);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.initialRole == UserRole.user;
    const saffronColor = Color(0xFFFF9933);
    const greenColor = Color(0xFF128807);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Slate 900
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F172A), // Slate 900
                    Color(0xFF05070F), // Midnight Black
                  ],
                ),
              ),
            ),
          ),

          // Saffron & Green Ambient Glows
          Positioned(
            top: -100,
            right: -100,
            width: 300,
            height: 300,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: saffronColor.withOpacity(0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            width: 300,
            height: 300,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: greenColor.withOpacity(0.12),
              ),
            ),
          ),

          // Main body content
          SafeArea(child: isUser ? _buildUserSignUp() : _buildSignUp()),

          // Standard Back Arrow (layered at the end to be on top)
          Positioned(
            top: 10,
            left: 10,
            child: SafeArea(
              child: GestureDetector(
                onTap: () => context.go('/login'),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withOpacity(0.3), _blueDark.withOpacity(0.95)],
        ),
      ),
    );
  }

  Widget _buildUserSignUp() {
    final l10n = AppLocalizations.of(context);
    final langCode = Localizations.localeOf(context).languageCode;
    final customLocs = ref.watch(customLocationsProvider);
    const saffronColor = Color(0xFFFF9933);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.person_add, size: 50, color: Colors.white),
            const SizedBox(height: 15),
            Text(
              l10n.citizenRegistration,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              l10n.signUpSubtitle,
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 25),

            // Profile Image Picker
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white24,
                    backgroundImage:
                        _profileImage != null
                            ? FileImage(_profileImage!)
                            : null,
                    child:
                        _profileImage == null
                            ? const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.white60,
                            )
                            : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 20,
                        color: saffronColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(
                      l10n.fullName,
                      Icons.person_outline,
                      _nameController,
                      isDark: true,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      l10n.emailOptional,
                      Icons.mail_outline,
                      _emailController,
                      isDark: true,
                      isEmail: true,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      l10n.mobileNumber,
                      Icons.phone_android_outlined,
                      _phoneController,
                      isDark: true,
                      isMobile: true,
                    ),
                    const SizedBox(height: 16),
                    _buildDropdownField(
                      l10n.state,
                      Icons.map_outlined,
                      StatesCitiesData.allStates
                          .map(
                            (s) => MapEntry(
                              s,
                              StatesCitiesData.getLocalizedStateName(
                                s,
                                langCode,
                              ),
                            ),
                          )
                          .toList()
                        ..add(const MapEntry('Other', 'Other')),
                      _selectedState,
                      (val) {
                        setState(() {
                          _selectedState = val;
                          _selectedCity = null;
                          _selectedVillage = null;
                        });
                      },
                      isDark: true,
                      validator:
                          (val) =>
                              (val == null || val.isEmpty)
                                  ? '${l10n.state} ${l10n.isRequired}'
                                  : null,
                    ),
                    if (_selectedState == 'Other') ...[
                      const SizedBox(height: 12),
                      _buildTextField(
                        'Enter custom State',
                        Icons.map_outlined,
                        _customStateController,
                        isDark: true,
                      ),
                    ],
                    const SizedBox(height: 16),
                    _buildDropdownField(
                      l10n.city,
                      Icons.location_city_outlined,
                      (_selectedState == null || _selectedState == 'Other'
                              ? <String>[]
                              : StatesCitiesData.getCities(
                                _selectedState!,
                                customCities: customLocs.cities,
                              ))
                          .map(
                            (c) => MapEntry(
                              c,
                              StatesCitiesData.getLocalizedCityName(
                                c,
                                langCode,
                                customCities: customLocs.cities,
                              ),
                            ),
                          )
                          .toList()
                        ..add(const MapEntry('Other', 'Other')),
                      _selectedCity,
                      (val) {
                        setState(() {
                          _selectedCity = val;
                          _selectedVillage = null;
                        });
                      },
                      isDark: true,
                      validator:
                          (val) =>
                              (val == null || val.isEmpty)
                                  ? '${l10n.city} ${l10n.isRequired}'
                                  : null,
                    ),
                    if (_selectedCity == 'Other') ...[
                      const SizedBox(height: 12),
                      _buildTextField(
                        'Enter custom City',
                        Icons.location_city_outlined,
                        _customCityController,
                        isDark: true,
                      ),
                    ],
                    const SizedBox(height: 16),
                    _buildDropdownField(
                      l10n.village,
                      Icons.home_outlined,
                      (_selectedCity == null || _selectedCity == 'Other'
                              ? <String>[]
                              : StatesCitiesData.getVillages(
                                _selectedCity!,
                                customVillages: customLocs.villages,
                              ))
                          .map(
                            (v) => MapEntry(
                              v,
                              StatesCitiesData.getLocalizedVillageName(
                                v,
                                langCode,
                                customVillages: customLocs.villages,
                              ),
                            ),
                          )
                          .toList()
                        ..add(const MapEntry('Other', 'Other')),
                      _selectedVillage,
                      (val) {
                        setState(() {
                          _selectedVillage = val;
                        });
                      },
                      isDark: true,
                      validator:
                          (val) =>
                              (val == null || val.isEmpty)
                                  ? '${l10n.village} ${l10n.isRequired}'
                                  : null,
                    ),
                    if (_selectedVillage == 'Other') ...[
                      const SizedBox(height: 12),
                      _buildTextField(
                        'Enter custom Village',
                        Icons.home_outlined,
                        _customVillageController,
                        isDark: true,
                      ),
                    ],
                    const SizedBox(height: 16),
                    _buildTextField(
                      l10n.ward,
                      Icons.map_outlined,
                      _wardController,
                      isDark: true,
                      isOptional: true,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      'Date of Birth',
                      Icons.calendar_today,
                      _dobController,
                      isDark: true,
                      isOptional: true,
                      readOnly: true,
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().subtract(
                            const Duration(days: 365 * 18),
                          ), // default to 18 years ago
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            _dobController.text =
                                "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      l10n.password,
                      Icons.lock_outline,
                      _passwordController,
                      obscure: _obscurePassword,
                      onToggle:
                          () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                      isDark: true,
                      isPassword: true,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      l10n.confirmPassword,
                      Icons.lock_reset,
                      _confirmPasswordController,
                      obscure: _obscureConfirmPassword,
                      onToggle:
                          () => setState(
                            () =>
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword,
                          ),
                      isDark: true,
                      isConfirmPassword: true,
                    ),
                    const SizedBox(height: 20),
                    _buildButton(
                      _isLoading ? l10n.creatingAccount : l10n.registerButton,
                      textColor: Colors.white,
                      bgColor: saffronColor,
                      onPressed: _isLoading ? () {} : _submit,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: () => context.go('/login'),
                child: Text(
                  l10n.alreadyRegisteredSignIn,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white70,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUp() {
    final l10n = AppLocalizations.of(context);
    final langCode = Localizations.localeOf(context).languageCode;
    final customLocs = ref.watch(customLocationsProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 60),
                      Text(
                        l10n.signUpTitle,
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: _darkText,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.signUpTitleDesc,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildTextField(
                        l10n.fullName,
                        Icons.person,
                        _nameController,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        l10n.email,
                        Icons.email,
                        _emailController,
                        isEmail: true,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        l10n.mobileNumber,
                        Icons.phone_android,
                        _phoneController,
                        isMobile: true,
                      ),
                      const SizedBox(height: 16),
                      _buildDropdownField(
                        l10n.state,
                        Icons.map,
                        StatesCitiesData.allStates
                            .map(
                              (s) => MapEntry(
                                s,
                                StatesCitiesData.getLocalizedStateName(
                                  s,
                                  langCode,
                                ),
                              ),
                            )
                            .toList()
                          ..add(const MapEntry('Other', 'Other')),
                        _selectedState,
                        (val) {
                          setState(() {
                            _selectedState = val;
                            _selectedCity = null;
                            _selectedVillage = null;
                          });
                        },
                        validator:
                            (val) =>
                                (val == null || val.isEmpty)
                                    ? '${l10n.state} ${l10n.isRequired}'
                                    : null,
                      ),
                      if (_selectedState == 'Other') ...[
                        const SizedBox(height: 16),
                        _buildTextField(
                          'Enter custom State',
                          Icons.map,
                          _customStateController,
                        ),
                      ],
                      const SizedBox(height: 16),
                      _buildDropdownField(
                        l10n.city,
                        Icons.location_city,
                        (_selectedState == null || _selectedState == 'Other'
                                ? <String>[]
                                : StatesCitiesData.getCities(
                                  _selectedState!,
                                  customCities: customLocs.cities,
                                ))
                            .map(
                              (c) => MapEntry(
                                c,
                                StatesCitiesData.getLocalizedCityName(
                                  c,
                                  langCode,
                                  customCities: customLocs.cities,
                                ),
                              ),
                            )
                            .toList()
                          ..add(const MapEntry('Other', 'Other')),
                        _selectedCity,
                        (val) {
                          setState(() {
                            _selectedCity = val;
                            _selectedVillage = null;
                          });
                        },
                        validator:
                            (val) =>
                                (val == null || val.isEmpty)
                                    ? '${l10n.city} ${l10n.isRequired}'
                                    : null,
                      ),
                      if (_selectedCity == 'Other') ...[
                        const SizedBox(height: 16),
                        _buildTextField(
                          'Enter custom City',
                          Icons.location_city,
                          _customCityController,
                        ),
                      ],
                      const SizedBox(height: 16),
                      _buildDropdownField(
                        l10n.village,
                        Icons.home,
                        (_selectedCity == null || _selectedCity == 'Other'
                                ? <String>[]
                                : StatesCitiesData.getVillages(
                                  _selectedCity!,
                                  customVillages: customLocs.villages,
                                ))
                            .map(
                              (v) => MapEntry(
                                v,
                                StatesCitiesData.getLocalizedVillageName(
                                  v,
                                  langCode,
                                  customVillages: customLocs.villages,
                                ),
                              ),
                            )
                            .toList()
                          ..add(const MapEntry('Other', 'Other')),
                        _selectedVillage,
                        (val) {
                          setState(() {
                            _selectedVillage = val;
                          });
                        },
                        validator:
                            (val) =>
                                (val == null || val.isEmpty)
                                    ? '${l10n.village} ${l10n.isRequired}'
                                    : null,
                      ),
                      if (_selectedVillage == 'Other') ...[
                        const SizedBox(height: 16),
                        _buildTextField(
                          'Enter custom Village',
                          Icons.home,
                          _customVillageController,
                        ),
                      ],
                      const SizedBox(height: 16),
                      _buildTextField(
                        l10n.ward,
                        Icons.map,
                        _wardController,
                        isOptional: true,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        l10n.password,
                        Icons.vpn_key,
                        _passwordController,
                        obscure: true,
                        isPassword: true,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        l10n.confirmPassword,
                        Icons.vpn_key,
                        _confirmPasswordController,
                        obscure: true,
                        isConfirmPassword: true,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: _agreePolicy,
                              activeColor: _saffron,
                              onChanged:
                                  (val) => setState(
                                    () => _agreePolicy = val ?? true,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.agreePrivacyPolicy,
                            style: TextStyle(color: _darkText, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      _buildButton(
                        l10n.signUpTitle.toUpperCase(),
                        textColor: _darkText,
                        bgColor: Colors.white,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: GestureDetector(
                          onTap: () => context.go('/login'),
                          child: Text(
                            l10n.alreadyRegisteredSignIn,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField(
    String hint,
    IconData icon,
    TextEditingController controller, {
    bool obscure = false,
    VoidCallback? onToggle,
    bool isDark = false,
    bool isEmail = false,
    bool isMobile = false,
    bool isPassword = false,
    bool isConfirmPassword = false,
    bool isOptional = false,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      readOnly: readOnly,
      onTap: onTap,
      style: TextStyle(
        fontSize: 14,
        color: isDark ? Colors.white : Colors.black,
      ),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark ? Colors.white60 : Colors.grey.shade600,
          fontSize: 14,
        ),
        prefixIcon: Icon(
          icon,
          color: isDark ? Colors.white60 : _blueDark.withOpacity(0.6),
          size: 20,
        ),
        filled: true,
        fillColor:
            isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade100,
        suffixIcon:
            onToggle != null
                ? IconButton(
                  icon: Icon(
                    obscure ? Icons.visibility_off : Icons.visibility,
                    size: 18,
                    color: isDark ? Colors.white38 : Colors.grey,
                  ),
                  onPressed: onToggle,
                )
                : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide:
              isDark
                  ? const BorderSide(color: Colors.white10)
                  : BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide:
              isDark
                  ? const BorderSide(color: Colors.white10)
                  : BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color:
                isDark ? const Color(0xFFFF9933) : _blueDark.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        errorStyle: const TextStyle(
          fontSize: 10,
          color: Colors.redAccent,
          fontWeight: FontWeight.w500,
          height: 0.8,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
      validator: (v) {
        final l10n = AppLocalizations.of(context);
        final isCitizen = _selectedRole == UserRole.user;

        if (v == null || v.trim().isEmpty) {
          if (isEmail && isCitizen) {
            return null; // Email is optional for citizen
          }
          if (isOptional) {
            return null; // This field is optional
          }
          return '$hint ${l10n.isRequired}';
        }

        if (isEmail && v.isNotEmpty) {
          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
          if (!emailRegex.hasMatch(v.trim())) return l10n.invalidEmail;
        }
        if (isMobile && v.isNotEmpty) {
          final trimmed = v.trim();
          if (trimmed.length != 10) return l10n.phoneNumberLengthError;
          if (!RegExp(r'^\d+$').hasMatch(trimmed)) return l10n.digitsOnly;
        }
        if (isPassword) {
          if (v.trim().length < 6) return l10n.minSixCharacters;
        }
        if (isConfirmPassword) {
          if (v.trim() != _passwordController.text.trim()) {
            return l10n.passwordsDoNotMatchError;
          }
        }
        return null;
      },
    );
  }

  Widget _buildButton(
    String text, {
    required Color textColor,
    required Color bgColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildDropdownField(
    String hint,
    IconData icon,
    List<MapEntry<String, String>> items,
    String? value,
    void Function(String?) onChanged, {
    bool isDark = false,
    String? Function(String?)? validator,
  }) {
    // Only dropdown background (navyMid) and text (white) differ in dark mode
    const Color saffron = Color(0xFFFF9933);
    const Color navyMid = Color(0xFF1B3B5A);

    return DropdownButtonFormField<String>(
      value: value,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      hint: Text(
        hint,
        style: TextStyle(
          color: isDark ? Colors.white60 : Colors.grey.shade600,
          fontSize: 14,
        ),
      ),
      disabledHint:
          items.isEmpty
              ? Text(
                'No $hint available',
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                  fontSize: 14,
                ),
              )
              : null,
      style: TextStyle(
        fontSize: 14,
        color: isDark ? Colors.white : Colors.black87,
      ),
      items:
          items.isEmpty
              ? null
              : items
                  .map(
                    (entry) => DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
      onChanged: onChanged,
      dropdownColor: isDark ? navyMid : Colors.white,
      iconEnabledColor: isDark ? Colors.white60 : Colors.grey,
      decoration: InputDecoration(
        prefixIcon: Icon(
          icon,
          color: isDark ? Colors.white60 : _blueDark.withOpacity(0.6),
          size: 20,
        ),
        filled: true,
        fillColor:
            isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide:
              isDark
                  ? const BorderSide(color: Colors.white10)
                  : BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide:
              isDark
                  ? const BorderSide(color: Colors.white10)
                  : BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: isDark ? saffron : _blueDark.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        errorStyle: const TextStyle(
          fontSize: 10,
          color: Colors.redAccent,
          fontWeight: FontWeight.w500,
          height: 0.8,
        ),
      ),
      isExpanded: true,
    );
  }
}
