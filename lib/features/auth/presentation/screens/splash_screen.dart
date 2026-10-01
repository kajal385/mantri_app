import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _rotationController;
  late AnimationController _loadingController;

  // Phase 2 state and animations
  bool _showSecondPhase = false;
  late AnimationController _secondPhaseController;
  late Animation<double> _secondPhaseOpacity;
  late Animation<double> _secondPhaseScale;

  // Entrance animations (choreographed)
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<double> _uiOpacity;

  // Loading animation (0.0 to 1.0 progress fill)
  late Animation<double> _loadingProgress;

  @override
  void initState() {
    super.initState();

    // 1. Entrance Animations Controller (1.5 seconds)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );

    _uiOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    // 2. Slow majestic rotation for the background Ashoka Chakra (40s per rotation)
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();

    // 3. Loading progression controller (runs for 3 seconds)
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _loadingProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOutSine),
    );

    // 4. Phase 2 Controller (3 seconds)
    _secondPhaseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _secondPhaseOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _secondPhaseController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _secondPhaseScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _secondPhaseController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    // Start entrance animations immediately
    _entranceController.forward();

    // Start loading progress animation
    _loadingController.forward();

    // Transition to Phase 2 when progress finishes
    _loadingController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() {
            _showSecondPhase = true;
          });
          _secondPhaseController.forward();
        }
      }
    });

    // Navigate to next screen when Phase 2 finishes
    _secondPhaseController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          context.go('/language-select');
        }
      }
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _rotationController.dispose();
    _loadingController.dispose();
    _secondPhaseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Premium theme colors
    const Color bgStartColor = Color(0xFF0F172A); // Slate 900
    const Color bgEndColor = Color(0xFF05070F); // Midnight black
    const Color saffronColor = Color(0xFFFF9933); // Saffron
    const Color greenColor = Color(0xFF138808); // Green

    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;

    return Scaffold(
      backgroundColor: bgStartColor,
      body: Stack(
        children: [
          // 1. Solid deep gradient background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [bgStartColor, bgEndColor],
                ),
              ),
            ),
          ),

          // 2. Ambient glows (BJP Saffron at top-right, Green at bottom-left)
          Positioned(
            top: -screenHeight * 0.15,
            right: -screenWidth * 0.2,
            width: screenWidth * 0.9,
            height: screenWidth * 0.9,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    saffronColor.withOpacity(0.18),
                    saffronColor.withOpacity(0.04),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -screenHeight * 0.15,
            left: -screenWidth * 0.2,
            width: screenWidth * 0.9,
            height: screenWidth * 0.9,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    greenColor.withOpacity(0.15),
                    greenColor.withOpacity(0.03),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 3. Subtle Slow-Rotating Background Ashoka Chakra Watermark
          Positioned.fill(
            child: Center(
              child: RotationTransition(
                turns: _rotationController,
                child: CustomPaint(
                  size: Size(screenWidth * 0.85, screenWidth * 0.85),
                  painter: const AshokaChakraPainter(color: Colors.white10),
                ),
              ),
            ),
          ),

          // 4. Glassmorphic Radial Background Grid/Card for Logo
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 1.0, sigmaY: 1.0),
              child: Container(color: Colors.transparent),
            ),
          ),

          // 5. Main content column
          Positioned.fill(
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(height: 20),

                  // Middle Section: Logo, Title, and Tagline
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Custom emblem logo with fade & scale entry
                          AnimatedBuilder(
                            animation: _entranceController,
                            builder: (context, child) {
                              return Opacity(
                                opacity: _logoOpacity.value,
                                child: Transform.scale(
                                  scale: _logoScale.value,
                                  child: child,
                                ),
                              );
                            },
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: saffronColor.withOpacity(0.2),
                                    blurRadius: 30,
                                    spreadRadius: 2,
                                  ),
                                  BoxShadow(
                                    color: greenColor.withOpacity(0.1),
                                    blurRadius: 20,
                                    spreadRadius: -2,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 8,
                                    sigmaY: 8,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withOpacity(0.08),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.25),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: const CustomPaint(
                                      painter: OfficialLogoPainter(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 35),

                          // Title and Tagline block with staggered fade-in
                          AnimatedBuilder(
                            animation: _entranceController,
                            builder: (context, child) {
                              return Opacity(
                                opacity: _textOpacity.value,
                                child: child,
                              );
                            },
                            child: Column(
                              children: [
                                // Secure portal badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.12),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.shield_outlined,
                                        color: saffronColor,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'OFFICIAL CITIZEN PORTAL',
                                        style: GoogleFonts.outfit(
                                          color: Colors.white.withOpacity(0.85),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 2.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Main Title
                                Text(
                                  'CITIZEN SERVICES',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 34,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.8,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.3),
                                        offset: const Offset(0, 4),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Tagline
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 40.0,
                                  ),
                                  child: Text(
                                    'Connecting Citizens with Government Services',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      height: 1.4,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Section: Progress bar and Secure branding with fade-in
                  AnimatedBuilder(
                    animation: _entranceController,
                    builder: (context, child) {
                      return Opacity(opacity: _uiOpacity.value, child: child);
                    },
                    child: Column(
                      children: [
                        // Orange-Green Loading Bar
                        Container(
                          width: screenWidth * 0.65,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.05),
                              width: 0.5,
                            ),
                          ),
                          child: Stack(
                            children: [
                              AnimatedBuilder(
                                animation: _loadingProgress,
                                builder: (context, child) {
                                  return FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: _loadingProgress.value,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(3),
                                        gradient: const LinearGradient(
                                          colors: [
                                            saffronColor,
                                            greenColor,
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: saffronColor.withOpacity(
                                              0.3,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 1),
                                          ),
                                          BoxShadow(
                                            color: greenColor.withOpacity(0.2),
                                            blurRadius: 8,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Trust Badge and Security Info
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              color: Colors.white.withOpacity(0.4),
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'End-to-End Encrypted & Secure Connection',
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Phase 2 Overlay (Anup Dhotre & BJP Logo)
          if (_showSecondPhase)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _secondPhaseController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _secondPhaseOpacity.value,
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
                      child: Stack(
                        children: [
                          // Saffron and Green glows in Phase 2
                          Positioned(
                            top: -screenHeight * 0.15,
                            right: -screenWidth * 0.2,
                            width: screenWidth * 0.9,
                            height: screenWidth * 0.9,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: saffronColor.withOpacity(0.20),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -screenHeight * 0.15,
                            left: -screenWidth * 0.2,
                            width: screenWidth * 0.9,
                            height: screenWidth * 0.9,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: greenColor.withOpacity(0.15),
                              ),
                            ),
                          ),

                          // Background rotating Ashoka Chakra watermark in Phase 2
                          Positioned.fill(
                            child: Center(
                              child: RotationTransition(
                                turns: _rotationController,
                                child: CustomPaint(
                                  size: Size(
                                    screenWidth * 0.85,
                                    screenWidth * 0.85,
                                  ),
                                  painter: const AshokaChakraPainter(
                                    color: Colors.white10,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SafeArea(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const SizedBox(height: 15),

                                // BJP Logo at Top
                                Transform.scale(
                                  scale: _secondPhaseScale.value,
                                  child: Column(
                                    children: [
                                      // Container(
                                      //   width: 75,
                                      //   height: 75,
                                      //   decoration: BoxDecoration(
                                      //     shape: BoxShape.circle,
                                      //     color: Colors.white,
                                      //     // border: Border.all(
                                      //     //   color: Colors.white.withOpacity(
                                      //     //     0.3,
                                      //     //   ),
                                      //     //   width: 1.5,
                                      //     // ),
                                      //     boxShadow: [
                                      //       BoxShadow(
                                      //         color: Colors.black.withOpacity(
                                      //           0.3,
                                      //         ),
                                      //         blurRadius: 12,
                                      //         offset: const Offset(0, 4),
                                      //       ),
                                      //     ],
                                      //   ),
                                      //   child: ClipOval(
                                      //     child: Image.asset(
                                      //       'assets/images/logoo.png', // BJP Logo
                                      //       fit: BoxFit.cover,
                                      //     ),
                                      //   ),
                                      // ),
                                      /*Container(
                                        // padding: EdgeInsets.zero,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Image.asset(
                                          width: 75,
                                          height: 75,
                                          'assets/images/log1.png', // BJP Logo
                                          fit: BoxFit.cover,
                                        ),
                                      ),*/
                                      Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                        ),
                                        child: ClipOval(
                                          child: Image.asset(
                                            'assets/images/log1.png',
                                            width: 75,
                                            height: 75,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'BHARATIYA JANATA PARTY',
                                        style: GoogleFonts.outfit(
                                          color: saffronColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Anup Dhotre Portrait in Middle
                                Transform.scale(
                                  scale: _secondPhaseScale.value,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 180,
                                        height: 180,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.transparent,
                                          boxShadow: [
                                            BoxShadow(
                                              color: saffronColor.withOpacity(
                                                0.35,
                                              ),
                                              blurRadius: 25,
                                              spreadRadius: 3,
                                            ),
                                            BoxShadow(
                                              color: greenColor.withOpacity(
                                                0.25,
                                              ),
                                              blurRadius: 25,
                                              spreadRadius: -2,
                                            ),
                                          ],
                                        ),
                                        child: ClipOval(
                                          child: Image.asset(
                                            'assets/images/img.jpg', // Anup Dhotre
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        'Hon. Anup Dhotre',
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 32,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Member of Parliament (Akola Lok Sabha)',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white70,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Bottom Taglines / Decorative Orange-Green lines
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'अकोला लोकसभा मतदारसंघ',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white.withOpacity(0.6),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 25,
                                          height: 2.5,
                                          color: saffronColor,
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          width: 25,
                                          height: 2.5,
                                          color: greenColor,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 35),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// A CustomPainter that draws a detailed Ashoka Chakra as a background watermark.
class AshokaChakraPainter extends CustomPainter {
  final Color color;

  const AshokaChakraPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.015;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw the outer boundary circle
    canvas.drawCircle(center, radius, paint);

    // Draw the inner hub solid fill
    final hubFillPaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.12, hubFillPaint);

    // Draw the inner hub stroke (double rim outline)
    final hubStrokePaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.006;
    canvas.drawCircle(center, radius * 0.15, hubStrokePaint);

    // Draw the 24 spokes and 24 beads
    final spokePaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    final beadPaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    for (int i = 0; i < 24; i++) {
      final angle = (i * 2 * math.pi) / 24;

      // Draw spoke (stylized arrow/wedge pointing outwards)
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);

      final spokePath = Path();
      // Start near inner hub edge
      spokePath.moveTo(0, -radius * 0.12);
      // Curve outwards, widening slightly in the middle, then tapering at the rim
      spokePath.quadraticBezierTo(
        size.width * 0.012,
        -radius * 0.5,
        0,
        -radius + (size.width * 0.025),
      );
      spokePath.quadraticBezierTo(
        -size.width * 0.012,
        -radius * 0.5,
        0,
        -radius * 0.12,
      );
      canvas.drawPath(spokePath, spokePaint);
      canvas.restore();

      // Draw outer rim bead between each spoke
      final beadAngle = angle + (math.pi / 24);
      final beadRadius = radius - (size.width * 0.018);
      final beadX = center.dx + beadRadius * math.cos(beadAngle);
      final beadY = center.dy + beadRadius * math.sin(beadAngle);

      canvas.drawCircle(Offset(beadX, beadY), size.width * 0.009, beadPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A CustomPainter that draws the official-looking circular emblem logo.
class OfficialLogoPainter extends CustomPainter {
  const OfficialLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Concentric outer border rings (BJP theme: Saffron and Green)
    final ringWidth = size.width * 0.045;
    final outerRect = Rect.fromCircle(
      center: center,
      radius: radius - ringWidth / 2,
    );

    final accentRingPaint =
        Paint()
          ..shader = const SweepGradient(
            colors: [
              Color(0xFFFF9933), // Saffron
              Color(0xFF138808), // Green
              Color(0xFFFF9933), // Saffron (closed loop)
            ],
            stops: [0.0, 0.5, 1.0],
          ).createShader(outerRect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = ringWidth;

    canvas.drawCircle(center, radius - ringWidth / 2, accentRingPaint);

    // 2. Main white/grey clean core circular body
    final corePaint =
        Paint()
          ..color = Colors.white.withOpacity(0.96)
          ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - ringWidth, corePaint);

    // 3. Draw a gold/bronze shield shape representing official authority
    final w = size.width;
    final h = size.height;

    final shieldPaint =
        Paint()
          ..color = const Color(0xFFD4AF37) // Premium Metallic Gold
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.025;

    final shieldPath = Path();
    shieldPath.moveTo(w * 0.36, h * 0.33);
    shieldPath.quadraticBezierTo(
      w * 0.5,
      h * 0.30,
      w * 0.64,
      h * 0.33,
    ); // curved top
    shieldPath.lineTo(w * 0.64, h * 0.53);
    shieldPath.quadraticBezierTo(
      w * 0.64,
      h * 0.69,
      w * 0.5,
      h * 0.77,
    ); // right side curve to tip
    shieldPath.quadraticBezierTo(
      w * 0.36,
      h * 0.69,
      w * 0.36,
      h * 0.53,
    ); // left side curve to tip
    shieldPath.close();
    canvas.drawPath(shieldPath, shieldPaint);

    // Fill shield with a soft gradient representing progress & digital services
    final shieldFillPaint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFFF9933).withOpacity(0.12),
              const Color(0xFF138808).withOpacity(0.12),
            ],
          ).createShader(outerRect)
          ..style = PaintingStyle.fill;
    canvas.drawPath(shieldPath, shieldFillPaint);

    // 4. Central detailed Ashoka Chakra in Navy Blue inside the shield
    const Color navyColor = Color(0xFF0F2042); // Deep Navy Blue
    final chakraRadius = size.width * 0.11;
    final chakraCenter = Offset(w * 0.5, h * 0.51);

    final chakraOuterPaint =
        Paint()
          ..color = navyColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.012;
    canvas.drawCircle(chakraCenter, chakraRadius, chakraOuterPaint);

    final chakraHubPaint =
        Paint()
          ..color = navyColor
          ..style = PaintingStyle.fill;
    canvas.drawCircle(chakraCenter, chakraRadius * 0.22, chakraHubPaint);

    final spokePaint =
        Paint()
          ..color = navyColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.005;

    for (int i = 0; i < 24; i++) {
      final angle = (i * 2 * math.pi) / 24;
      final outerX = chakraCenter.dx + chakraRadius * math.cos(angle);
      final outerY = chakraCenter.dy + chakraRadius * math.sin(angle);
      canvas.drawLine(chakraCenter, Offset(outerX, outerY), spokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
