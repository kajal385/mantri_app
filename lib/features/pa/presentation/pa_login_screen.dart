import 'package:mantri_app/core/utils/app_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import 'package:mantri_app/core/services/firebase_service.dart';

class PALoginScreen extends ConsumerStatefulWidget {
  const PALoginScreen({super.key});

  @override
  ConsumerState<PALoginScreen> createState() => _PALoginScreenState();
}

class _PALoginScreenState extends ConsumerState<PALoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  static const Color _navy = Color(0xFF0F2544);
  static const Color _accent = Color(0xFFFFCC00); // saffron gold accent

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final pass = _passwordCtrl.text.trim();
    if (email.isEmpty || pass.isEmpty) {
      _snack('Please enter your credentials');
      return;
    }

    // Email Validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      _snack('Please enter a valid email address');
      return;
    }

    // Password Length Validation
    if (pass.length < 6) {
      _snack('Password must be at least 6 characters long');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).signIn(email, pass);
      if (mounted) context.go('/home');
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('] ')) {
        errorMessage = errorMessage.split('] ').last;
      }
      _snack('Authentication failed: $errorMessage');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String msg) {
    AppDialogs.showErrorDialog(context, userMessage: msg);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      body: Stack(
        children: [
          // Geometric background shapes
          CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _GeoBgPainter(),
          ),

          // Back arrow
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white54, size: 20),
                onPressed: () => context.go('/home'),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 60),

                    // Official Emblem
                    _buildEmblem(),
                    const SizedBox(height: 28),

                    // Title
                    Text(
                      'STAFF PORTAL',
                      style: GoogleFonts.poppins(
                        color: _accent,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Personal Assistant\nLogin',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    Text(
                      'Office of MP Anup Dhotre',
                      style: GoogleFonts.poppins(color: Colors.white38, fontSize: 13),
                    ),
                    const SizedBox(height: 40),

                    // Login card
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        children: [
                          _buildField(
                            controller: _emailCtrl,
                            label: 'Official Email ID',
                            icon: Icons.alternate_email,
                            type: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          _buildField(
                            controller: _passwordCtrl,
                            label: 'Password',
                            icon: Icons.lock_outline,
                            obscure: _obscurePassword,
                            suffix: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: Colors.white38,
                                size: 18,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accent,
                                foregroundColor: _navy,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(color: Color(0xFF0F2544), strokeWidth: 2.5),
                                    )
                                  : Text(
                                      'SIGN IN',
                                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1.5),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Restricted access notice
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.shield_outlined, color: Colors.amber, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'This portal is restricted to authorised government staff only. Accounts are created by the Admin.',
                              style: TextStyle(color: Colors.amber.shade200, fontSize: 11, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmblem() {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.08),
        border: Border.all(color: _accent.withOpacity(0.5), width: 2),
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.account_balance, size: 38, color: _accent),
            Positioned(
              bottom: 14,
              child: Container(
                width: 34,
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.transparent, _accent, Colors.transparent]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType type = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: type,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.white38, size: 18),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withOpacity(0.07),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _accent.withOpacity(0.7), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

/// Custom painter for the geometric navy background
class _GeoBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Top-right large arc
    paint.color = const Color(0xFF1B3B5A).withOpacity(0.6);
    canvas.drawCircle(Offset(size.width + 60, -60), 200, paint);

    // Bottom-left arc
    paint.color = const Color(0xFF1B3B5A).withOpacity(0.4);
    canvas.drawCircle(Offset(-80, size.height + 40), 220, paint);

    // Diagonal accent lines
    final linePaint = Paint()
      ..color = const Color(0xFFFFCC00).withOpacity(0.06)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 6; i++) {
      canvas.drawLine(
        Offset(size.width * 0.5 + i * 50, 0),
        Offset(size.width + i * 50 - 200, size.height),
        linePaint,
      );
    }

    // Dotted grid
    final dotPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.fill;
    for (double x = 20; x < size.width; x += 40) {
      for (double y = 20; y < size.height; y += 40) {
        canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
      }
    }

    // Small rotating hexagons (decorative)
    final hexPaint = Paint()
      ..color = const Color(0xFFFFCC00).withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    _drawHexagon(canvas, Offset(size.width * 0.85, size.height * 0.25), 40, hexPaint);
    _drawHexagon(canvas, Offset(size.width * 0.1, size.height * 0.6), 30, hexPaint);
  }

  void _drawHexagon(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = math.pi / 180 * (60 * i - 30);
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_GeoBgPainter oldDelegate) => false;
}
