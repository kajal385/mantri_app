import 'package:mantri_app/core/utils/app_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:mantri_app/core/models/app_models.dart';
import 'package:mantri_app/core/constants/app_constants.dart';
import 'package:mantri_app/core/services/firebase_service.dart';

class PARegistrationScreen extends ConsumerStatefulWidget {
  const PARegistrationScreen({super.key});

  @override
  ConsumerState<PARegistrationScreen> createState() =>
      _PARegistrationScreenState();
}

class _PARegistrationScreenState extends ConsumerState<PARegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Controllers
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _employeeIdCtrl = TextEditingController();
  final _educationCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _idProofNumberCtrl = TextEditingController();

  // Drop-down / picker values
  String _officeLocation = 'Akola Office';
  String _idProofType = 'Aadhaar Card';
  DateTime _joiningDate = DateTime.now();

  final List<String> _officeLocations = [
    'Akola Office',
    'Mumbai Office',
    'Nagpur Office',
    'New Delhi Office',
    'Washim Office',
  ];

  final List<String> _idProofTypes = [
    'Aadhaar Card',
    'PAN Card',
    'Passport',
    'Driving License',
    'Voter ID',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _employeeIdCtrl.dispose();
    _educationCtrl.dispose();
    _addressCtrl.dispose();
    _idProofNumberCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickJoiningDate() async {
    const saffron = Color.fromARGB(255, 219, 126, 32);
    final picked = await showDatePicker(
      context: context,
      initialDate: _joiningDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder:
          (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.light(primary: saffron),
            ),
            child: child!,
          ),
    );
    if (picked != null) setState(() => _joiningDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      AppDialogs.showErrorDialog(context, userMessage: 'Please fill all mandatory fields');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final profile = PAProfile(
        uid: '',
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        employeeId: _employeeIdCtrl.text.trim(),
        education: _educationCtrl.text.trim(),
        designation: 'Personal Assistant',
        assignedTo: 'Anup Dhotre (MP)',
        officeLocation: _officeLocation,
        address: _addressCtrl.text.trim(),
        idProofType: _idProofType,
        idProofNumber: _idProofNumberCtrl.text.trim(),
        joiningDate: _joiningDate,
        createdAt: DateTime.now(),
      );

      await ref
          .read(authServiceProvider)
          .signUpPA(
            name: _nameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text.trim(),
            paProfile: profile,
          );

      if (mounted) {
        await AppDialogs.showSuccessDialog(context, message: '✅ PA account created successfully!');
        if (mounted) context.go('/pa-staff');
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showErrorDialog(context);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        final errors = data['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final messages = <String>[];
          for (final value in errors.values) {
            if (value is List) {
              messages.addAll(value.map((v) => v.toString()));
            } else {
              messages.add(value.toString());
            }
          }
          if (messages.isNotEmpty) return messages.join('\n');
        }
        final message = data['message'];
        if (message is String && message.isNotEmpty) return message;
      }
      if (e.response?.statusCode == 422) {
        return 'This email is already registered. Open Staff Management to manage the existing PA, or use a different email.';
      }
    }
    return 'Could not create PA account. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Stack(
        children: [
          // Top decorative header
          Container(
            height: 230,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color.fromARGB(255, 219, 126, 32), Color(0xFFF57C00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // AppBar area
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () => context.pop(),
                      ),
                      Expanded(
                        child: Text(
                          'Register Personal Assistant',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Official badge card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white24,
                          backgroundImage: AssetImage(AppConstants.mpProfileImage),
                        ),
                        const SizedBox(width: 14),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Authorised by Admin',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Anup Dhotre (MP)',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Designation: Personal Assistant',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'OFFICIAL',
                            style: GoogleFonts.poppins(
                              color: Colors.greenAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Form
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _sectionCard(
                            title: 'Personal Information',
                            icon: Icons.person,
                            children: [
                              _field(
                                'Full Name',
                                Icons.badge_outlined,
                                _nameCtrl,
                                required: true,
                              ),
                              _field(
                                'Email Address',
                                Icons.email_outlined,
                                _emailCtrl,
                                required: true,
                                type: TextInputType.emailAddress,
                              ),
                              _field(
                                'Mobile Number',
                                Icons.phone_outlined,
                                _phoneCtrl,
                                required: true,
                                type: TextInputType.phone,
                              ),
                              _passwordField(),
                              _confirmPasswordField(),
                              _field(
                                'Residential Address',
                                Icons.home_outlined,
                                _addressCtrl,
                                required: true,
                                maxLines: 2,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _sectionCard(
                            title: 'Professional Information',
                            icon: Icons.work_outline,
                            children: [
                              _field(
                                'PA ID',
                                Icons.pin_outlined,
                                _employeeIdCtrl,
                                required: true,
                              ),
                              _field(
                                'Education Qualification',
                                Icons.school_outlined,
                                _educationCtrl,
                                required: true,
                              ),
                              _readOnlyField(
                                'Designation',
                                'Personal Assistant',
                                Icons.assignment_ind_outlined,
                              ),
                              _readOnlyField(
                                'Assigned To',
                                'Anup Dhotre (MP)',
                                Icons.person_pin_outlined,
                              ),
                              _dropdownField(
                                'Office Location',
                                Icons.location_city_outlined,
                                _officeLocations,
                                _officeLocation,
                                (v) => setState(() => _officeLocation = v!),
                              ),
                              _datePicker(),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _sectionCard(
                            title: 'Identity Verification',
                            icon: Icons.verified_user_outlined,
                            children: [
                              _dropdownField(
                                'ID Proof Type',
                                Icons.credit_card_outlined,
                                _idProofTypes,
                                _idProofType,
                                (v) => setState(() => _idProofType = v!),
                              ),
                              _field(
                                'ID Proof Number',
                                Icons.numbers_outlined,
                                _idProofNumberCtrl,
                                required: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(255, 219, 126, 32),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 4,
                              ),
                              child:
                                  _isLoading
                                      ? const CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      )
                                      : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.person_add_alt_1),
                                          const SizedBox(width: 10),
                                          Text(
                                            'Create PA Account',
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '⚠️  Creating this account will sign you out. Please re-login as Admin.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B3B5A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF1B3B5A), size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: const Color(0xFF1B3B5A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _field(
    String label,
    IconData icon,
    TextEditingController ctrl, {
    bool required = false,
    TextInputType type = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        keyboardType: type,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.black, fontSize: 14),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: _inputDec(label, icon),
        validator: (v) {
          if (required && (v == null || v.trim().isEmpty)) {
            return '$label is required';
          }
          if (type == TextInputType.emailAddress && v != null && v.isNotEmpty) {
            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
            if (!emailRegex.hasMatch(v)) return 'Enter a valid email address';
          }
          if (type == TextInputType.phone && v != null && v.isNotEmpty) {
            if (v.length != 10)
              return 'Mobile number must be exactly 10 digits';
            if (!RegExp(r'^\d+$').hasMatch(v)) return 'Enter only digits';
          }
          return null;
        },
      ),
    );
  }

  Widget _passwordField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: _passwordCtrl,
        obscureText: _obscurePassword,
        style: const TextStyle(color: Colors.black, fontSize: 14),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: _inputDec('Password', Icons.lock_outline).copyWith(
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey,
              size: 20,
            ),
            onPressed:
                () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Password is required';
          if (v.length < 6) return 'Minimum 6 characters required';
          return null;
        },
      ),
    );
  }

  Widget _confirmPasswordField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: _confirmPasswordCtrl,
        obscureText: _obscureConfirmPassword,
        style: const TextStyle(color: Colors.black, fontSize: 14),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: _inputDec('Confirm Password', Icons.lock_reset).copyWith(
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey,
              size: 20,
            ),
            onPressed:
                () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ),
          ),
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Please confirm your password';
          if (v != _passwordCtrl.text) return 'Passwords do not match';
          return null;
        },
      ),
    );
  }

  Widget _readOnlyField(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        initialValue: value,
        readOnly: true,
        style: const TextStyle(color: Colors.grey),
        decoration: _inputDec(
          label,
          icon,
        ).copyWith(fillColor: Colors.grey.shade100),
      ),
    );
  }

  Widget _dropdownField(
    String label,
    IconData icon,
    List<String> items,
    String value,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: _inputDec(label, icon),
        items:
            items
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(e, style: const TextStyle(fontSize: 14)),
                  ),
                )
                .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _datePicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: _pickJoiningDate,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                color: Color(0xFF1B3B5A),
                size: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Joining Date',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    Text(
                      DateFormat('dd MMM yyyy').format(_joiningDate),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDec(String label, IconData icon) {
    return InputDecoration(
      hintText: label,
      hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
      prefixIcon: Icon(
        icon,
        color: const Color(0xFF1B3B5A).withOpacity(0.6),
        size: 20,
      ),
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1B3B5A), width: 1.5),
      ),
      errorStyle: const TextStyle(fontSize: 11, color: Colors.redAccent),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
