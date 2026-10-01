import 'package:mantri_app/core/utils/app_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:mantri_app/core/services/firebase_service.dart';
import 'package:mantri_app/core/models/app_models.dart';
import 'package:mantri_app/core/constants/app_constants.dart';
import 'package:mantri_app/features/auth/presentation/screens/role_wrapper.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:mantri_app/core/utils/image_helper.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const Color darkBlue = Color.fromARGB(255, 219, 126, 32);
    const Color orangeAccent = Color(0xFFF57C00);
    const Color backgroundGrey = Color(0xFFF5F7FA);

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
        backgroundColor: darkBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () async {
            final shouldLogout = await AppDialogs.showLogoutConfirmationDialog(context);
            if (shouldLogout && context.mounted) {
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) context.go('/login');
            }
          },
        ),
        title: Text(
          'Admin Dashboard - MP Connect',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            tooltip: 'My Profile',
            onPressed: () => context.push('/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              final shouldLogout = await AppDialogs.showLogoutConfirmationDialog(context);
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
            _buildHeader(context, ref, darkBlue, orangeAccent),
            const SizedBox(height: 24),
            Text(
              'MP Management Control',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: darkBlue,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _buildAdminCard(
                  context,
                  Icons.business_center,
                  'Projects',
                  'Manage Dev Projects',
                  const Color(0xFF1976D2),
                  () => context.push('/project-management'),
                ),
                _buildAdminCard(
                  context,
                  Icons.newspaper,
                  'News & Updates',
                  'Post Latest Updates',
                  const Color(0xFFF57C00),
                  () => context.push('/news-management'),
                ),
                _buildAdminCard(
                  context,
                  Icons.rate_review,
                  'Citizen Feedback',
                  'Respond to Feedback',
                  const Color(0xFF388E3C),
                  () => context.push('/feedback-management'),
                ),
                _buildAdminCard(
                  context,
                  Icons.gavel,
                  'Complaints',
                  'Approve/Reject Complaints',
                  const Color(0xFFD32F2F),
                  () => context.push('/grievance-management'),
                ),
                _buildAdminCard(
                  context,
                  Icons.calendar_month,
                  'Appointments',
                  'View MP Schedule',
                  const Color(0xFF7B1FA2),
                  () => context.push('/appointment-management'),
                ),
                _buildAdminCard(
                  context,
                  Icons.event,
                  'Monitor Events',
                  'Track PA Scheduled Events',
                  const Color(0xFF00796B),
                  () => context.push('/event-management'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: darkBlue.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: darkBlue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.people_alt_outlined,
                          color: darkBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Staff Management',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            StreamBuilder<List<PAProfile>>(
                              stream:
                                  ref
                                      .watch(firestoreServiceProvider)
                                      .getPAProfiles(),
                              builder: (context, snapshot) {
                                final count = snapshot.data?.length ?? 0;
                                return Text(
                                  count == 0
                                      ? 'No PA accounts yet'
                                      : 'Total registered PA staff: $count',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/pa-staff'),
                          icon: const Icon(Icons.list_alt, size: 16),
                          label: const Text('View All PA'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: darkBlue,
                            side: const BorderSide(color: darkBlue),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => context.push('/register-pa'),
                          icon: const Icon(Icons.person_add_alt_1, size: 16),
                          label: const Text('Add New PA'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: darkBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today's Agenda",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: darkBlue,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/daily-schedule'),
                  child: const Text(
                    'Full Calendar',
                    style: TextStyle(color: orangeAccent),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDailyAgenda(ref, darkBlue),
            const SizedBox(height: 40), // Safety spacing to prevent overflow
          ],
        ),
      ),
    ),
  );
}

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    Color darkBlue,
    Color orangeAccent,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [darkBlue, orangeAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: darkBlue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/mp-profile'),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white24,
                      child: CircleAvatar(
                        radius: 33,
                        backgroundColor: Colors.white,
                        backgroundImage: ref
                            .watch(userDataProvider)
                            .when(
                              data:
                                  (user) =>
                                      user?.profileImageUrl != null
                                          ? NetworkImage(user!.profileImageUrl!)
                                          : const AssetImage(
                                                AppConstants.mpProfileImage,
                                              )
                                              as ImageProvider,
                              loading:
                                  () => const AssetImage(AppConstants.mpProfileImage),
                              error:
                                  (_, __) =>
                                      const AssetImage(AppConstants.mpProfileImage),
                            ),
                      ),
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
                              final croppedFile = await ImageHelper.cropImage(File(image.path));
                              if (croppedFile == null) return; // User cancelled crop

                              final authService = ref.read(authServiceProvider);
                              // 2. Upload Cropped Image
                              final imageUrl = await authService.uploadProfileImage(
                                croppedFile,
                              );
                              await authService.updateProfileImageUrl(imageUrl);
                              ref.invalidate(userDataProvider);
                              if (context.mounted) {
                                AppDialogs.showSuccessDialog(context, message: 'Profile photo updated!');
                              }
                            } catch (e) {
                              if (context.mounted) {
                                AppDialogs.showErrorDialog(context, userMessage: 'Upload failed:', technicalError: e);
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
                          child: Icon(Icons.camera_alt, color: darkBlue, size: 16),
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
                        'Anup Dhotre (MP)',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Admin Master Console',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View Biography',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right,
                              color: Colors.white,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditAdminProfileDialog(BuildContext context, WidgetRef ref) {
    // Method removed as it's no longer used here.
  }

  Widget _buildAdminCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF2E3349),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyAgenda(WidgetRef ref, Color darkBlue) {
    final scheduleStream = ref
        .watch(firestoreServiceProvider)
        .getDailySchedule(DateTime.now());

    return StreamBuilder<List<ScheduleItem>>(
      stream: scheduleStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Text('Error loading agenda');
        if (snapshot.connectionState == ConnectionState.waiting)
          return const LinearProgressIndicator();

        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Center(
              child: Text(
                'You have no programs listed for today.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            Color color = Colors.blue;
            if (item.type == 'Speech') color = Colors.orange;
            if (item.type == 'Appointment') color = Colors.purple;
            if (item.type == 'Event') color = Colors.teal;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                leading: Container(
                  width: 4,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                title: Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  '${item.type} • ${item.time}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right, size: 16),
                onTap: () => context.push('/daily-schedule'),
              ),
            );
          },
        );
      },
    );
  }
}
