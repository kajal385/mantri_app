import 'package:mantri_app/core/utils/app_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mantri_app/core/services/firebase_service.dart';

import 'package:mantri_app/core/models/app_models.dart';
import 'package:mantri_app/core/constants/app_constants.dart';
import 'package:mantri_app/generated/app_localizations.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final UserRole? initialRole;
  const LoginScreen({super.key, this.initialRole});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController(text: '');
  final _passwordController = TextEditingController(text: '');
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();

  final Color _saffron = const Color.fromARGB(255, 219, 126, 32);
  final Color _orangeAccent = const Color(0xFFF57C00);

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();

    if (!_formKey.currentState!.validate()) {
      final l10n = AppLocalizations.of(context);
      AppDialogs.showErrorDialog(context);
      return;
    }

    try {
      await ref.read(authServiceProvider).signIn(email, pass);
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showErrorDialog(context, userMessage: 'Authentication failed:', technicalError: e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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

          // Main Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 23),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    // MP Profile Image
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 55,
                        backgroundImage:
                            ref
                                        .watch(mpProfileDataProvider)
                                        .value
                                        ?.profileImageUrl !=
                                    null
                                ? NetworkImage(
                                  ref
                                      .watch(mpProfileDataProvider)
                                      .value!
                                      .profileImageUrl!,
                                )
                                : const AssetImage(AppConstants.mpProfileImage)
                                    as ImageProvider,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.officialPortal,
                      style: GoogleFonts.outfit(
                        color: saffronColor.withOpacity(0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        // letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.mpName,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      l10n.mpDescription,
                      style: GoogleFonts.poppins(
                        color: Colors.white54,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 35),

                    // Unified Form inside Glassmorphic card
                    Container(
                      padding: const EdgeInsets.all(24),
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
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: saffronColor.withOpacity(0.85),
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    l10n.loginSubtitle,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white70,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildTextField(
                              l10n.emailOrPhone,
                              Icons.alternate_email,
                              _emailController,
                              isDark: true,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              l10n.password,
                              Icons.lock_outline,
                              _passwordController,
                              isPasswordNode: true,
                              isDark: true,
                            ),
                            const SizedBox(height: 24),
                            _buildButton(
                              l10n.loginButton,
                              textColor: Colors.white,
                              bgColor: saffronColor,
                              onPressed: _submit,
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed:
                                  () => context.push('/signup?role=user'),
                              child: Text(
                                l10n.newHereCreateAccount,
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.white70,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String hint,
    IconData icon,
    TextEditingController controller, {
    bool isPasswordNode = false,
    bool isDark = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        obscureText: isPasswordNode ? _obscurePassword : false,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: isDark ? Colors.white38 : Colors.grey.shade400,
            fontSize: 15,
          ),
          prefixIcon: Icon(
            icon,
            color: isDark ? Colors.white38 : Colors.grey.shade400,
            size: 20,
          ),
          filled: true,
          fillColor: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
          suffixIcon:
              isPasswordNode
                  ? IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey.shade400,
                    ),
                    onPressed:
                        () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                  )
                  : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide:
                isDark
                    ? const BorderSide(color: Colors.white10)
                    : BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide:
                isDark
                    ? const BorderSide(color: Colors.white10)
                    : BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFFF1C40F) : const Color(0xFF1B3B5A),
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Colors.redAccent, width: 2),
          ),
          errorStyle: const TextStyle(
            fontSize: 11,
            color: Colors.redAccent,
            fontWeight: FontWeight.w500,
            height: 0.8,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
        validator: (v) {
          final l10n = AppLocalizations.of(context);
          if (v == null || v.trim().isEmpty) return '$hint ${l10n.isRequired}';
          if (!isPasswordNode) {
            final trimmed = v.trim();
            final isDigitsOnly = RegExp(r'^\d+$').hasMatch(trimmed);
            if (isDigitsOnly) {
              if (trimmed.length != 10) {
                return l10n.phoneNumberLengthError;
              }
            } else {
              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
              if (!emailRegex.hasMatch(trimmed)) {
                return l10n.invalidEmailOrPhoneError;
              }
            }
          } else {
            if (v.trim().length < 6) return l10n.passwordMinLengthError;
          }
          return null;
        },
      ),
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
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withOpacity(0.05)
          ..strokeWidth = 1;

    const double step = 30;

    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
