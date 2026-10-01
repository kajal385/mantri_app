import 'package:mantri_app/core/utils/app_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:mantri_app/core/services/firebase_service.dart';
import 'package:mantri_app/core/models/app_models.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:mantri_app/core/utils/image_helper.dart';
import 'package:intl/intl.dart';
import 'package:mantri_app/features/auth/presentation/screens/role_wrapper.dart';
import 'package:mantri_app/features/appointment/appointments_provider.dart';
import 'package:mantri_app/features/pa/pa_providers.dart';
import 'package:mantri_app/core/services/api_service.dart';

final paProfileProvider = FutureProvider<PAProfile?>((ref) async {
  final authUser = await ref.watch(authStateProvider.future);
  if (authUser == null) return null;
  return ref.read(apiServiceProvider).getPAProfile(authUser.uid);
});

final todayScheduleProvider = FutureProvider<List<ScheduleItem>>((ref) async {
  final now = DateTime.now();
  return ref
      .read(apiServiceProvider)
      .getSchedules(
        start: DateTime(now.year, now.month, now.day),
        end: DateTime(now.year, now.month, now.day, 23, 59, 59),
      );
});

class PADashboard extends ConsumerWidget {
  const PADashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const saffron = Color.fromARGB(255, 219, 126, 32);
    const orangeAccent = Color(0xFFF57C00);
    const backgroundGrey = Color(0xFFF5F7FA);

    final paProfile = ref.watch(paProfileProvider);

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
        backgroundColor: backgroundGrey,
        appBar: AppBar(
          backgroundColor: saffron,
          foregroundColor: Colors.white,
          title: Text(
            'PA Management Portal',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.person),
              tooltip: 'My Profile',
              onPressed: () => context.push('/profile'),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                final shouldLogout =
                    await AppDialogs.showLogoutConfirmationDialog(context);
                if (shouldLogout && context.mounted) {
                  await ref.read(authServiceProvider).signOut();
                  if (context.mounted) context.go('/login');
                }
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              paProfile.when(
                data:
                    (profile) => _buildPAHeader(
                      context,
                      ref,
                      profile,
                      saffron,
                      orangeAccent,
                    ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Text('Error loading profile: $e'),
              ),
              const SizedBox(height: 24),

              // Stats Section
              _buildStatsSection(context, ref, saffron),
              const SizedBox(height: 24),

              Text(
                'Administrative Controls',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: saffron,
                ),
              ),
              const SizedBox(height: 16),
              _buildActionGrid(context, ref),
              const SizedBox(height: 32),

              // Events Management Tabs
              DefaultTabController(
                length: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hon. Anup Dhotre Engagement Tracker',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: saffron,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TabBar(
                      isScrollable: true,
                      labelColor: saffron,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: saffron,
                      tabs: const [
                        Tab(text: "Today's Agenda"),
                        Tab(text: 'Upcoming'),
                        Tab(text: 'Past (Archive)'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 350,
                      child: TabBarView(
                        children: [
                          _EventTimelineStream(type: 'today', color: saffron),
                          _EventTimelineStream(
                            type: 'upcoming',
                            color: saffron,
                          ),
                          _EventTimelineStream(type: 'past', color: saffron),
                        ],
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
    );
  }

  Widget _buildPAHeader(
    BuildContext context,
    WidgetRef ref,
    PAProfile? profile,
    Color saffron,
    Color orangeAccent,
  ) {
    if (profile == null) return const SizedBox.shrink();

    return InkWell(
      onTap: () => _showProfileDialog(context, ref, profile),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [saffron, orangeAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: saffron.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white24,
                      backgroundImage:
                          profile.profileImageUrl != null
                              ? NetworkImage(profile.profileImageUrl!)
                              : null,
                      child:
                          profile.profileImageUrl == null
                              ? const Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.white,
                              )
                              : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () async {
                          final picker = ImagePicker();
                          final image = await picker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 50,
                          );
                          if (image != null) {
                            try {
                              // 1. Crop Image
                              final croppedFile = await ImageHelper.cropImage(
                                File(image.path),
                              );
                              if (croppedFile == null)
                                return; // User cancelled crop

                              final authService = ref.read(authServiceProvider);
                              // 2. Upload Cropped Image
                              final imageUrl = await authService
                                  .uploadProfileImage(croppedFile);
                              await authService.updateProfileImageUrl(imageUrl);

                              // Refresh profile data
                              ref.invalidate(userDataProvider);
                              ref.invalidate(paProfileProvider);

                              if (context.mounted) {
                                AppDialogs.showSuccessDialog(
                                  context,
                                  message: 'Profile photo updated!',
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                AppDialogs.showErrorDialog(
                                  context,
                                  userMessage: 'Upload failed:',
                                  technicalError: e,
                                );
                              }
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            color: saffron,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        profile.designation,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'ID: ${profile.employeeId}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white70),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: Colors.white24),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _headerInfoItem(Icons.phone, profile.phone),
                _headerInfoItem(Icons.location_on, profile.officeLocation),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white70),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 11)),
      ],
    );
  }

  Widget _buildStatsSection(
    BuildContext context,
    WidgetRef ref,
    Color saffron,
  ) {
    final todayScheduleAsync = ref.watch(todayScheduleProvider);
    final appointmentsAsync = ref.watch(appointmentsProvider);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Pending Appointments Card
          Expanded(
            child: appointmentsAsync.when(
              loading:
                  () => _statCard(
                    'Pending Appointments',
                    '...',
                    Icons.calendar_month,
                    Colors.purple,
                    () => context.push('/appointment-management'),
                  ),
              error:
                  (err, stack) => _statCard(
                    'Pending Appointments',
                    '00',
                    Icons.calendar_month,
                    Colors.purple,
                    () => context.push('/appointment-management'),
                  ),
              data: (appts) {
                final count = appts.where((a) => a.status == 'pending').length;
                return _statCard(
                  'Pending Appointments',
                  count.toString().padLeft(2, '0'),
                  Icons.calendar_month,
                  Colors.purple,
                  () => context.push('/appointment-management'),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          // Pending Daily Events Card
          Expanded(
            child: todayScheduleAsync.when(
              loading:
                  () => _statCard(
                    'Pending Daily Scheduled Events',
                    '...',
                    Icons.pending_actions,
                    Colors.orange,
                    () => context.push('/daily-schedule'),
                  ),
              error:
                  (e, s) => _statCard(
                    'Pending Daily Scheduled Events',
                    '00',
                    Icons.pending_actions,
                    Colors.orange,
                    () => context.push('/daily-schedule'),
                  ),
              data: (items) {
                final pending =
                    items.where((item) => item.status == 'pending').length;
                return _statCard(
                  'Pending Daily Scheduled Events',
                  pending.toString().padLeft(2, '0'),
                  Icons.pending_actions,
                  Colors.orange,
                  () => context.push('/daily-schedule'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    String label,
    String value,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        height: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context, WidgetRef ref) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _actionItem(
          context,
          Icons.inbox,
          'Unified Inbox',
          Colors.teal,
          '/unified-inbox',
        ),
        _actionItem(
          context,
          Icons.dashboard_customize,
          'Daily Briefing',
          Colors.deepPurple,
          '/daily-briefing',
        ),

        _actionItem(
          context,
          Icons.speaker_notes,
          'Meeting Notes',
          Colors.amber.shade900,
          '/meeting-notes',
        ),
        _actionItem(
          context,
          Icons.monetization_on,
          'Donation Mgmt',
          Colors.green.shade800,
          '/donations',
        ),
        _actionItem(
          context,
          Icons.event_available,
          'Availability Mgmt',
          Colors.blue.shade800,
          '/pa-availability',
        ),
        _actionItem(
          context,
          Icons.calendar_month,
          'Appointments',
          Colors.purple,
          '/appointment-management',
        ),
        _actionItem(
          context,
          Icons.dynamic_feed_rounded,
          'Daily Feed',
          Colors.orange,
          '/news-feed-management',
        ),
        _actionItem(
          context,
          Icons.rate_review,
          'Feedback',
          Colors.green,
          '/feedback-management',
        ),
        _actionItem(
          context,
          Icons.list_alt,
          'Manage Issues',
          Colors.teal.shade700,
          '/manage-issues',
        ),
        _actionItem(
          context,
          Icons.folder_special,
          'Feedback Projects',
          Colors.deepOrange.shade600,
          '/manage-feedback-projects',
        ),
        _actionItem(
          context,
          Icons.gavel,
          'Grievances',
          Colors.red,
          '/grievance-management',
        ),
        _actionItem(
          context,
          Icons.schedule,
          'Daily Agenda',
          Colors.indigo,
          '/daily-schedule',
        ),
        _actionItem(
          context,
          Icons.share,
          'Social Links',
          Colors.blue,
          '/social-links-management',
        ),
        _actionItem(
          context,
          Icons.emergency,
          'Emergency Numbers',
          Colors.red.shade700,
          '/emergency-contacts-management',
        ),
        _actionItem(
          context,
          Icons.account_balance,
          'Officials Mgmt',
          Colors.cyan.shade700,
          '/officials-management',
        ),
        _actionItem(
          context,
          Icons.person_pin,
          'MP Biography',
          Colors.brown,
          '/mp-profile',
        ),
        _actionItem(
          context,
          Icons.photo_library,
          'Manage Slider',
          Colors.orange.shade800,
          '/manage-slider',
        ),
      ],
    );
  }

  Widget _actionItem(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
    dynamic action,
  ) {
    return InkWell(
      onTap: () {
        if (action is String) {
          context.push(action);
        } else if (action is VoidCallback) {
          action();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileDialog(
    BuildContext context,
    WidgetRef ref,
    PAProfile? profile,
  ) {
    if (profile == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.9,
            maxChildSize: 0.95,
            minChildSize: 0.5,
            builder:
                (_, scrollController) => Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(24),
                    children: [
                      Center(
                        child: Container(
                          width: 50,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      Text(
                        'Professional PA Profile',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color.fromARGB(255, 219, 126, 32),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Add Photo Picker in Dialog
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.white,
                              backgroundImage:
                                  profile.profileImageUrl != null
                                      ? NetworkImage(profile.profileImageUrl!)
                                      : null,
                              child:
                                  profile.profileImageUrl == null
                                      ? const Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Colors.grey,
                                      )
                                      : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () async {
                                  final picker = ImagePicker();
                                  final image = await picker.pickImage(
                                    source: ImageSource.gallery,
                                    imageQuality: 50,
                                  );
                                  if (image != null) {
                                    try {
                                      // 1. Crop Image
                                      final croppedFile =
                                          await ImageHelper.cropImage(
                                            File(image.path),
                                          );
                                      if (croppedFile == null)
                                        return; // User cancelled crop

                                      final authService = ref.read(
                                        authServiceProvider,
                                      );
                                      // 2. Upload Cropped Image
                                      final imageUrl = await authService
                                          .uploadProfileImage(croppedFile);
                                      await authService.updateProfileImageUrl(
                                        imageUrl,
                                      );

                                      // Refresh profile data
                                      ref.invalidate(userDataProvider);
                                      ref.invalidate(paProfileProvider);

                                      if (context.mounted) {
                                        Navigator.pop(context); // Close dialog
                                        AppDialogs.showSuccessDialog(
                                          context,
                                          message: 'Profile photo updated!',
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        AppDialogs.showErrorDialog(
                                          context,
                                          userMessage: 'Upload failed:',
                                          technicalError: e,
                                        );
                                      }
                                    }
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Color.fromARGB(255, 219, 126, 32),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      _profileSection('Basic Information', [
                        _profileDetail(Icons.person, 'Full Name', profile.name),
                        _profileDetail(
                          Icons.badge,
                          'Employee ID',
                          profile.employeeId,
                        ),
                        _profileDetail(
                          Icons.work,
                          'Designation',
                          profile.designation,
                        ),
                        _profileDetail(
                          Icons.email,
                          'Email Address',
                          profile.email,
                        ),
                        _profileDetail(
                          Icons.phone,
                          'Phone Number',
                          profile.phone,
                        ),
                      ]),

                      const SizedBox(height: 24),
                      _profileSection('Education & Role', [
                        _profileDetail(
                          Icons.school,
                          'Qualification',
                          profile.education,
                        ),
                        _profileDetail(
                          Icons.assignment_ind,
                          'Assigned To',
                          profile.assignedTo,
                        ),
                        _profileDetail(
                          Icons.calendar_today,
                          'Joining Date',
                          DateFormat('dd MMM yyyy').format(profile.joiningDate),
                        ),
                      ]),

                      const SizedBox(height: 24),
                      _profileSection('Office & Location', [
                        _profileDetail(
                          Icons.location_city,
                          'Office Location',
                          profile.officeLocation,
                        ),
                        _profileDetail(
                          Icons.home,
                          'Residential Address',
                          profile.address,
                        ),
                      ]),

                      const SizedBox(height: 24),
                      _profileSection('Identification', [
                        _profileDetail(
                          Icons.verified_user,
                          'ID Proof Type',
                          profile.idProofType,
                        ),
                        _profileDetail(
                          Icons.numbers,
                          'ID Number',
                          profile.idProofNumber,
                        ),
                      ]),

                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            219,
                            126,
                            32,
                          ),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text('Close Profile'),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
          ),
    );
  }

  Widget _profileSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _profileDetail(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 219, 126, 32).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: const Color.fromARGB(255, 219, 126, 32),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EventTimelineStream extends ConsumerStatefulWidget {
  final String type;
  final Color color;
  const _EventTimelineStream({required this.type, required this.color});

  @override
  ConsumerState<_EventTimelineStream> createState() =>
      _EventTimelineStreamState();
}

class _EventTimelineStreamState extends ConsumerState<_EventTimelineStream> {
  List<ScheduleItem>? _items;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    Stream<List<ScheduleItem>> stream;
    if (widget.type == 'today') {
      stream = ref.read(firestoreServiceProvider).getDailySchedule(now);
    } else if (widget.type == 'upcoming') {
      stream = ref
          .read(firestoreServiceProvider)
          .getScheduleRange(todayEnd, now.add(const Duration(days: 30)));
    } else {
      stream = ref
          .read(firestoreServiceProvider)
          .getScheduleRange(
            now.subtract(const Duration(days: 30)),
            todayStart.subtract(const Duration(seconds: 1)),
          );
    }

    try {
      final items = await stream.first;
      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _items = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final items = _items ?? [];
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note, color: Colors.grey.shade300, size: 48),
            const SizedBox(height: 8),
            Text(
              'No ${widget.type} events found',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final dateStr = DateFormat('MMM dd').format(item.date);

        Color typeColor;
        IconData typeIcon;
        switch (item.type) {
          case 'Speech':
            typeColor = Colors.orange;
            typeIcon = Icons.record_voice_over;
            break;
          case 'Appointment':
            typeColor = Colors.purple;
            typeIcon = Icons.people;
            break;
          case 'Event':
            typeColor = Colors.teal;
            typeIcon = Icons.campaign;
            break;
          default:
            typeColor = Colors.blue;
            typeIcon = Icons.event_note;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(typeIcon, color: typeColor),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                _buildStatusChip(item.status),
              ],
            ),
            subtitle: Text(
              '$dateStr • ${item.time} • ${item.location ?? 'TBA'}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: IconButton(
              icon: Icon(
                item.status == 'attended'
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: item.status == 'attended' ? Colors.green : Colors.grey,
              ),
              onPressed: () async {
                final oldStatus = item.status;
                final newStatus =
                    oldStatus == 'attended' ? 'pending' : 'attended';

                // Optimistically update UI
                setState(() {
                  _items![index] = item.copyWith(status: newStatus);
                });

                try {
                  await ref
                      .read(firestoreServiceProvider)
                      .updateScheduleStatus(item.id, newStatus);

                  // Optionally refresh dashboard stats in background
                  ref.invalidate(todayScheduleProvider);
                } catch (e) {
                  // Revert on failure
                  if (mounted) {
                    setState(() {
                      _items![index] = item.copyWith(status: oldStatus);
                    });
                    AppDialogs.showErrorDialog(
                      context,
                      userMessage: 'Failed to update status:',
                      technicalError: e,
                    );
                  }
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    final isAttended = status == 'attended';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color:
            isAttended
                ? Colors.green.withOpacity(0.1)
                : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        isAttended ? 'Attended' : 'Pending',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isAttended ? Colors.green : Colors.orange,
        ),
      ),
    );
  }
}
