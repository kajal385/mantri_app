import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mantri_app/core/services/firebase_service.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      final list = ref.read(sliderImagesProvider).valueOrNull ?? [];
      final urlsCount = list.isEmpty ? 3 : list.length;
      if (urlsCount <= 1) return; // Don't animate if 0 or 1 image

      if (_currentPage < urlsCount - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutQuart,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const saffron = Color(0xFFF39C12); // Gold/Orange matching the logo
    const bgColor = Color(0xFF102844); // Deep Navy background

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  // Header
                  Text(
                    'MP CONNECT',
                    style: GoogleFonts.poppins(
                      color: saffron,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hon. Anup Dhotre',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Digital Bridge to Your Representative',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Image Slider
                  Container(
                    height: 380, // Taller image as per design
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: ref.watch(sliderImagesProvider).when(
                            data: (urls) {
                              final displayUrls = urls.isEmpty
                                  ? const [
                                      'asset://assets/images/image.png',
                                      'asset://assets/images/image2.jpg',
                                      'asset://assets/images/image3.jpg',
                                    ]
                                  : urls;

                              return PageView.builder(
                                controller: _pageController,
                                onPageChanged: (int page) {
                                  setState(() {
                                    _currentPage = page;
                                  });
                                },
                                itemCount: displayUrls.length,
                                itemBuilder: (context, index) {
                                  final url = displayUrls[index];
                                  if (url.startsWith('asset://')) {
                                    return Image.asset(
                                      url.replaceFirst('asset://', ''),
                                      fit: BoxFit.cover,
                                    );
                                  }
                                  return Image.network(
                                    url,
                                    fit: BoxFit.cover, // Cover mode for full impact
                                  );
                                },
                              );
                            },
                            loading: () => const Center(
                                child: CircularProgressIndicator(color: saffron)),
                            error: (e, _) =>
                                const Center(child: Icon(Icons.error, color: Colors.red)),
                          ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Slider Indicators
                  ref.watch(sliderImagesProvider).when(
                        data: (urls) {
                          final displayUrls = urls.isEmpty
                              ? const [
                                  'asset://assets/images/image.png',
                                  'asset://assets/images/image2.jpg',
                                  'asset://assets/images/image3.jpg',
                                ]
                              : urls;
                          if (displayUrls.length <= 1) return const SizedBox.shrink();
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: displayUrls.asMap().entries.map((entry) {
                              return Container(
                                width: _currentPage == entry.key ? 22 : 8,
                                height: 6,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: _currentPage == entry.key
                                      ? saffron
                                      : Colors.white24,
                                ),
                              );
                            }).toList(),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),

                  const SizedBox(height: 40),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Select your role to continue',
                      style: TextStyle(color: Colors.white60, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Citizen Option
                  _buildRoleCard(
                    context,
                    title: 'I am a Citizen',
                    subtitle: 'Connect & report issues',
                    icon: Icons.people_alt_rounded,
                    onTap: () => context.push('/login?role=user'),
                  ),
                  const SizedBox(height: 16),

                  // PA Option
                  _buildRoleCard(
                    context,
                    title: 'Personal Assistant',
                    subtitle: 'Manage official desk',
                    icon: Icons.admin_panel_settings_rounded,
                    onTap: () => context.push('/pa-login'),
                  ),
                  const SizedBox(height: 16),

                  // Admin Option
                  _buildRoleCard(
                    context,
                    title: 'MP Admin Panel',
                    subtitle: 'Full administrative control',
                    icon: Icons.security_rounded,
                    onTap: () => context.push('/login?role=admin'),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F4F8), // Light gray/blue matching design
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: const Color(0xFFE67E22), size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF102844),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 24),
          ],
        ),
      ),
    );
  }
}
