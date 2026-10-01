import 'package:mantri_app/core/utils/app_dialogs.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mantri_app/core/models/app_models.dart';
import 'package:mantri_app/core/providers/locale_provider.dart';
import 'package:mantri_app/core/services/api_service.dart';
import 'package:mantri_app/core/services/firebase_service.dart';
import 'package:mantri_app/features/auth/presentation/screens/role_wrapper.dart';
import 'package:mantri_app/features/news/presentation/screens/news_screen.dart';
import 'package:mantri_app/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mantri_app/features/appointment/appointments_provider.dart';

final latestFeedProvider = FutureProvider.autoDispose<List<NewsPost>>((ref) {
  return ref.read(apiServiceProvider).getNews();
});

final socialLinksProvider = FutureProvider.autoDispose<SocialLinks?>((ref) {
  return ref.read(apiServiceProvider).getSocialLinks();
});

class UserDashboard extends ConsumerStatefulWidget {
  const UserDashboard({super.key});

  @override
  ConsumerState<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends ConsumerState<UserDashboard> {
  int _currentIndex = 1;
  late final PageController _carouselController;
  int _currentCarouselPage = 0;
  Timer? _carouselTimer;
  final int _totalBanners = 3;

  // Scroll-based greeting reveal
  bool _showGreeting = false;
  static const double _greetingScrollThreshold = 180.0;

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final shouldShow = notification.metrics.pixels > _greetingScrollThreshold;
      if (shouldShow != _showGreeting) {
        setState(() => _showGreeting = shouldShow);
      }
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _carouselController = PageController();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _carouselController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!_carouselController.hasClients) return;

      final urls = ref.read(sliderImagesProvider).valueOrNull ?? [];
      final count = urls.isEmpty ? _totalBanners : urls.length;
      if (count <= 1) return;

      int nextPage = _currentCarouselPage + 1;
      if (nextPage >= count) {
        nextPage = 0;
      }

      _carouselController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutQuart,
      );
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentCarouselPage = index;
    });
    _startAutoScroll();
  }

  @override
  Widget build(BuildContext context) {
    final saffron = const Color(0xFFDB7E20);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await AppDialogs.showExitConfirmationDialog(context);
        if (shouldExit == true && context.mounted) {
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      drawer: _buildSideDrawer(context, ref),
      body: RefreshIndicator(
        color: const Color(0xFFDB7E20),
        onRefresh: () async {
          ref.invalidate(latestFeedProvider);
          ref.invalidate(socialLinksProvider);
          // Wait briefly to allow UI to show refresh animation
          await Future.delayed(const Duration(milliseconds: 600));
        },
        child: NotificationListener<ScrollNotification>(
          onNotification: _onScrollNotification,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _buildSliverAppBar(context, ref),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 8),
                  child: _buildCarouselSection(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 24,
                            decoration: BoxDecoration(
                              color: saffron,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            AppLocalizations.of(context).howCanWeHelpYou,
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1B3B5A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      GridView.count(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.1,
                        children: [
                          _buildHelpCard(
                            context,
                            Icons.calendar_month_rounded,
                            AppLocalizations.of(context).bookAppointment,
                            Colors.teal,
                            () async {
                              final appointments = await ref.read(
                                userAppointmentsProvider.future,
                              );
                              final pendingAppt = appointments.where((a) => a.status.toLowerCase() == 'pending').firstOrNull;
                              if (pendingAppt != null) {
                                if (context.mounted) {
                                  showDialog(
                                    context: context,
                                    builder:
                                        (context) => AlertDialog(
                                          title: const Text(
                                            'Pending Appointment',
                                          ),
                                          content: const Text(
                                            'You already have a pending appointment. You can edit it before it is approved.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(context),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                context.push('/book-appointment', extra: pendingAppt);
                                              },
                                              child: const Text('Edit'),
                                            ),
                                          ],
                                        ),
                                  );
                                }
                              } else {
                                if (context.mounted)
                                  context.push('/book-appointment');
                              }
                            },
                          ),
                          _buildHelpCard(
                            context,
                            Icons.gavel_rounded,
                            AppLocalizations.of(context).postComplaint,
                            Colors.redAccent,
                            () => context.push('/book-complaint'),
                          ),
                          _buildHelpCard(
                            context,
                            Icons.reviews_rounded,
                            AppLocalizations.of(context).feedback,
                            Colors.amber.shade800,
                            () => context.push('/citizen-feedback'),
                          ),
                          _buildHelpCard(
                            context,
                            Icons.newspaper_rounded,
                            AppLocalizations.of(context).latestNews,
                            Colors.deepOrange,
                            () => context.push('/news'),
                          ),
                          _buildHelpCard(
                            context,
                            Icons.chat_rounded,
                            AppLocalizations.of(context).messageMp,
                            Colors.blue,
                            () => context.push('/send-message'),
                          ),
                          _buildHelpCard(
                            context,
                            Icons.emergency,
                            AppLocalizations.of(context).emergencyNumbers,
                            Colors.red.shade700,
                            () => context.push('/emergency-contacts'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),

                      // Latest Updates / Daily Feed
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 24,
                            decoration: BoxDecoration(
                              color: saffron,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            AppLocalizations.of(context).latestUpdates,
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1B3B5A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _LatestUpdatesFeed(),
                      const SizedBox(height: 40),
                      // Follow Us Section
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 24,
                            decoration: BoxDecoration(
                              color: saffron,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            AppLocalizations.of(context).followUs,
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1B3B5A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const _FollowUsWidget(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 0) {
            context.push('/book-appointment').then((_) {
              if (mounted) setState(() => _currentIndex = 1);
            });
          } else if (index == 2) {
            context.push('/my-requests').then((_) {
              if (mounted) setState(() => _currentIndex = 1);
            });
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: saffron,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.calendar_month),
            label: AppLocalizations.of(context).appointment,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: AppLocalizations.of(context).home,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.assignment_turned_in),
            label: AppLocalizations.of(context).trackRequest,
          ),
        ],
      ),
    ),
  );
}

  Widget _buildSideDrawer(BuildContext context, WidgetRef ref) {
    final userData = ref.watch(userDataProvider).value;
    final topPadding = MediaQuery.of(context).padding.top;

    return Drawer(
      backgroundColor: const Color(0xFFFFF8F0),
      child: Column(
        children: [
          // Header extending into status bar
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: topPadding + 16,
              bottom: 16,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFDB7E20), Color(0xFFE67E22)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  backgroundImage:
                      userData?.profileImageUrl != null
                          ? NetworkImage(userData!.profileImageUrl!)
                          : null,
                  child:
                      userData?.profileImageUrl == null
                          ? const Icon(
                            Icons.person,
                            size: 32,
                            color: Color(0xFFDB7E20),
                          )
                          : null,
                ),
                const SizedBox(height: 10),
                Text(
                  userData?.name ?? 'Citizen',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  userData?.email ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _drawerItem(
                  context,
                  Icons.account_circle_outlined,
                  AppLocalizations.of(context).myProfile,
                  () {
                    Navigator.pop(context);
                    context.push('/profile');
                  },
                ),
                _drawerItem(
                  context,
                  Icons.calendar_month_outlined,
                  AppLocalizations.of(context).bookAppointment,
                  () {
                    Navigator.pop(context);
                    context.push('/book-appointment');
                  },
                ),
                _drawerItem(
                  context,
                  Icons.gavel_rounded,
                  AppLocalizations.of(context).postComplaint,
                  () {
                    Navigator.pop(context);
                    context.push('/book-complaint');
                  },
                ),
                _drawerItem(
                  context,
                  Icons.reviews_rounded,
                  AppLocalizations.of(context).feedback,
                  () {
                    Navigator.pop(context);
                    context.push('/citizen-feedback');
                  },
                ),
                _drawerItem(
                  context,
                  Icons.assignment_turned_in_outlined,
                  AppLocalizations.of(context).myRequests,
                  () {
                    Navigator.pop(context);
                    context.push('/my-requests');
                  },
                ),
                _drawerItem(
                  context,
                  Icons.newspaper_outlined,
                  AppLocalizations.of(context).latestNews,
                  () {
                    Navigator.pop(context);
                    context.push('/news');
                  },
                ),
                _drawerItem(
                  context,
                  Icons.chat_outlined,
                  AppLocalizations.of(context).messageMp,
                  () {
                    Navigator.pop(context);
                    context.push('/send-message');
                  },
                ),
                _drawerItem(
                  context,
                  Icons.people_outline,
                  AppLocalizations.of(context).officials,
                  () {
                    Navigator.pop(context);
                    context.push('/officials');
                  },
                ),
                const SizedBox(height: 6),
                // Language Switcher
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.language,
                        color: Color(0xFFDB7E20),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppLocalizations.of(context).changeLanguage,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      _LanguageToggle(),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Divider(height: 1, thickness: 0.8),
                ),
                _drawerItem(
                  context,
                  Icons.emergency,
                  AppLocalizations.of(context).emergencyImportantNumbers,
                  () {
                    Navigator.pop(context);
                    context.push('/emergency-contacts');
                  },
                  color: Colors.red.shade700,
                  isBold: true,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Divider(height: 1, thickness: 0.8),
                ),
                // Logout Item directly in list
                ListTile(
                  leading: const Icon(
                    Icons.logout,
                    color: Colors.red,
                    size: 22,
                  ),
                  title: Text(
                    AppLocalizations.of(context).logout,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 2,
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    final shouldLogout = await AppDialogs.showLogoutConfirmationDialog(context);

                    if (shouldLogout && context.mounted) {
                      await ref.read(authServiceProvider).signOut();
                      if (context.mounted) context.go('/login');
                    }
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color? color,
    bool isBold = false,
  }) {
    final c = color ?? const Color(0xFF333333);
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFDB7E20), size: 22),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          color: c,
          fontSize: 14,
          fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      onTap: onTap,
    );
  }

  Widget _buildSliverAppBar(BuildContext context, WidgetRef ref) {
    final userData = ref.watch(userDataProvider).value;
    final fullName = userData?.name ?? 'Citizen';
    final String firstName = fullName.trim().split(' ').first;
    final String greeting = _getGreeting();

    return SliverAppBar(
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFFDB7E20),
      elevation: 0,
      leading: Builder(
        builder:
            (ctx) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
      ),
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        transitionBuilder:
            (child, animation) =>
                FadeTransition(opacity: animation, child: child),
        child:
            _showGreeting
                ? Text(
                  '$greeting, $firstName 👋',
                  key: const ValueKey('greeting'),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                )
                // Show nothing (empty) by default — no static title
                : const SizedBox.shrink(key: ValueKey('empty')),
      ),
      actions: const [SizedBox(width: 8)],
    );
  }

  Widget _buildCarouselSection() {
    final sliderImages = ref.watch(sliderImagesProvider);

    return sliderImages.when(
      data: (urls) {
        final count = urls.isEmpty ? _totalBanners : urls.length;
        return Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 185,
                  width: double.infinity,
                  child: PageView.builder(
                    controller: _carouselController,
                    onPageChanged: _onPageChanged,
                    itemCount: count,
                    itemBuilder: (context, index) {
                      if (urls.isEmpty) {
                        return _buildDefaultBanners(context)[index];
                      } else {
                        final url = urls[index];
                        if (url.startsWith('asset://')) {
                          final assetPath = url.replaceFirst('asset://', '');
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.asset(
                                assetPath,
                                fit: BoxFit.cover,
                                alignment: Alignment.topCenter,
                              ),
                            ),
                          );
                        }
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              url,
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (count > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(count, (index) {
                  final isActive = _currentCarouselPage == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: isActive ? 20 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color:
                          isActive
                              ? const Color(0xFFDB7E20)
                              : Colors.grey.shade300,
                    ),
                  );
                }),
              ),
          ],
        );
      },
      loading:
          () => const SizedBox(
            height: 185,
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFFDB7E20)),
            ),
          ),
      error: (e, _) => const SizedBox.shrink(),
    );
  }

  List<Widget> _buildDefaultBanners(BuildContext context) {
    return [
      // First banner: full-bleed image.png
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            'assets/images/image.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      ),
      // Second banner: uploaded image2.jpg
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            'assets/images/image2.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      ),
      // Third banner: uploaded image3.jpg
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            'assets/images/image3.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      ),
    ];
  }

  Widget _buildHelpCard(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 30, color: color),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1B3B5A),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 20,
                  height: 2,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Follow Us Widget
// ─────────────────────────────────────────────────────────────────────────────

class _FollowUsWidget extends ConsumerWidget {
  const _FollowUsWidget();

  Future<void> _launchUrl(String? urlString, BuildContext context) async {
    if (urlString == null || urlString.isEmpty) {
      AppDialogs.showErrorDialog(context, userMessage: 'Link not available');
      return;
    }

    final uri = Uri.tryParse(urlString);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        AppDialogs.showErrorDialog(context, userMessage: 'Could not open the link');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksAsync = ref.watch(socialLinksProvider);

    return linksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
      data: (links) {
        if (links == null) return const SizedBox.shrink();

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _SocialIcon(
              icon: Icons.facebook,
              color: Colors.blue.shade700,
              onTap: () => _launchUrl(links.facebookUrl, context),
            ),
            _SocialIcon(
              icon: FontAwesomeIcons.instagram,
              color: Colors.pink.shade500,
              onTap: () => _launchUrl(links.instagramUrl, context),
            ),
            _SocialIcon(
              icon: FontAwesomeIcons.xTwitter,
              color: Colors.black87,
              onTap: () => _launchUrl(links.xUrl, context),
            ),
          ],
        );
      },
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SocialIcon({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(10), // Reduced from 12 to make it smaller
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withAlpha((0.15 * 255).toInt()),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FaIcon(
          icon,
          size: 18,
          color: color,
        ), // Used FaIcon and reduced size from 22 to 18
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Latest Updates Feed Widget
// ─────────────────────────────────────────────────────────────────────────────

class _LatestUpdatesFeed extends ConsumerWidget {
  const _LatestUpdatesFeed();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(latestFeedProvider);

    return feedAsync.when(
      loading:
          () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32.0),
              child: CircularProgressIndicator(),
            ),
          ),
      error:
          (_, __) => Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Text(
                'Could not load updates.',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ),
          ),
      data: (posts) {
        if (posts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48.0),
              child: Column(
                children: [
                  Icon(
                    Icons.newspaper_outlined,
                    size: 56,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No updates yet.',
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade400,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return Column(
          children:
              posts
                  .map((post) => InstaFeedCard(post: post, canManage: false))
                  .toList(),
        );
      },
    );
  }
}

/// Compact toggle button for switching between English and Marathi
class _LanguageToggle extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final isMarathi = locale.languageCode == 'mr';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LangChip(
            label: 'EN',
            selected: !isMarathi,
            onTap:
                () => ref
                    .read(localeProvider.notifier)
                    .setLocale(const Locale('en')),
          ),
          _LangChip(
            label: 'मर',
            selected: isMarathi,
            onTap:
                () => ref
                    .read(localeProvider.notifier)
                    .setLocale(const Locale('mr')),
          ),
        ],
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LangChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFDB7E20) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: selected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}
