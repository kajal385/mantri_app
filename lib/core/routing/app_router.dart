import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mantri_app/features/auth/presentation/screens/login_screen.dart';
import 'package:mantri_app/features/auth/presentation/screens/language_selection_screen.dart';
import 'package:mantri_app/features/auth/presentation/screens/signup_screen.dart';
import 'package:mantri_app/features/auth/presentation/screens/role_wrapper.dart';
import 'package:mantri_app/features/user/presentation/profile_screen.dart';
import 'package:mantri_app/features/appointment/presentation/screens/appointment_booking_screen.dart';
import 'package:mantri_app/core/models/app_models.dart';
import 'package:mantri_app/features/appointment/presentation/screens/appointment_management_screen.dart';
import 'package:mantri_app/features/user/presentation/my_requests_screen.dart';
import 'package:mantri_app/features/events/presentation/screens/event_management_screen.dart';
import 'package:mantri_app/features/news/presentation/screens/news_screen.dart';
import 'package:mantri_app/features/projects/presentation/screens/projects_screen.dart';
import 'package:mantri_app/features/complaints/presentation/screens/complaint_booking_screen.dart';
import 'package:mantri_app/features/complaints/presentation/screens/grievance_management_screen.dart';
import 'package:mantri_app/features/feedback/presentation/screens/citizen_feedback_screen.dart';
import 'package:mantri_app/features/feedback/presentation/screens/feedback_management_screen.dart';
import 'package:mantri_app/features/admin/presentation/mp_profile_screen.dart';
import 'package:mantri_app/features/admin/presentation/schedule_management_screen.dart';
import 'package:mantri_app/features/admin/presentation/pa_registration_screen.dart';
import 'package:mantri_app/features/admin/presentation/pa_staff_list_screen.dart';
import 'package:mantri_app/features/pa/presentation/pa_login_screen.dart';
import 'package:mantri_app/features/pa/presentation/unified_inbox_screen.dart';
import 'package:mantri_app/features/admin/presentation/screens/manage_issues_screen.dart';
import 'package:mantri_app/features/admin/presentation/screens/manage_feedback_projects_screen.dart';

import 'package:mantri_app/features/pa/presentation/meeting_notes_screen.dart';
import 'package:mantri_app/features/pa/presentation/donation_management_screen.dart';
import 'package:mantri_app/features/pa/presentation/daily_briefing_screen.dart';
import 'package:mantri_app/features/pa/presentation/pa_availability_screen.dart';
import 'package:mantri_app/features/user/presentation/send_message_screen.dart';
import 'package:mantri_app/features/news/presentation/screens/news_post_management_screen.dart';
import 'package:mantri_app/features/pa/presentation/screens/social_links_management_screen.dart';
import 'package:mantri_app/features/admin/presentation/slider_management_screen.dart';
import 'package:mantri_app/features/emergency/presentation/emergency_contacts_screen.dart';
import 'package:mantri_app/features/emergency/presentation/emergency_contacts_management_screen.dart';
import 'package:mantri_app/features/officials/presentation/officials_screen.dart';
import 'package:mantri_app/features/officials/presentation/officials_management_screen.dart';
import 'package:mantri_app/features/pa/presentation/manage_locations_screen.dart';

import 'package:mantri_app/core/services/firebase_service.dart';

import 'package:mantri_app/features/auth/presentation/screens/splash_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final laravelUser = ref.read(laravelUserProvider);

      final bool isLoggedIn = laravelUser != null;

      final isAuthPage =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/pa-login' ||
          state.matchedLocation == '/register-pa' ||
          state.matchedLocation == '/home' ||
          state.matchedLocation == '/splash' ||
          state.matchedLocation == '/language-select';

      if (!isLoggedIn) {
        return isAuthPage ? null : '/login';
      }

      if ((isAuthPage &&
              state.matchedLocation != '/register-pa' &&
              state.matchedLocation != '/splash') ||
          state.matchedLocation == '/auth-check') {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/language-select',
        builder: (context, state) => const LanguageSelectionScreen(),
      ),
      GoRoute(
        path: '/auth-check',
        builder: (context, state) => const RoleWrapper(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) {
          final roleStr = state.uri.queryParameters['role'];
          final role = UserRole.values.firstWhere(
            (e) => e.name == roleStr,
            orElse: () => UserRole.user,
          );
          return LoginScreen(initialRole: role);
        },
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) {
          final roleStr = state.uri.queryParameters['role'];
          final role = UserRole.values.firstWhere(
            (e) => e.name == roleStr,
            orElse: () => UserRole.user,
          );
          return SignUpScreen(initialRole: role);
        },
      ),
      GoRoute(path: '/home', builder: (context, state) => const RoleWrapper()),
      GoRoute(
        path: '/mp-profile',
        builder: (context, state) => const MPProfileScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/my-requests',
        builder: (context, state) => const MyRequestsScreen(),
      ),
      GoRoute(
        path: '/book-appointment',
        builder: (context, state) {
          final extra = state.extra;
          final appointment = extra is Appointment ? extra : null;
          return AppointmentBookingScreen(existingAppointment: appointment);
        },
      ),
      GoRoute(
        path: '/appointment-management',
        builder: (context, state) => const AppointmentManagementScreen(),
      ),
      GoRoute(
        path: '/event-management',
        builder: (context, state) => const EventManagementScreen(),
      ),
      GoRoute(
        path: '/news-management',
        builder: (context, state) => const NewsScreen(),
      ),
      GoRoute(path: '/news', builder: (context, state) => const NewsScreen()),
      GoRoute(
        // Deep-link route: /news?postId=xxx  — opened when user taps a shared link
        path: '/news-post',
        builder: (context, state) {
          final postId = state.uri.queryParameters['postId'];
          return NewsScreen(initialPostId: postId);
        },
      ),
      GoRoute(
        path: '/project-management',
        builder: (context, state) => const ProjectsScreen(),
      ),
      GoRoute(
        path: '/projects',
        builder: (context, state) => const ProjectsScreen(),
      ),
      GoRoute(
        path: '/book-complaint',
        builder: (context, state) => const ComplaintBookingScreen(),
      ),
      GoRoute(
        path: '/citizen-feedback',
        builder: (context, state) => const CitizenFeedbackScreen(),
      ),
      GoRoute(
        path: '/feedback-management',
        builder: (context, state) => const FeedbackManagementScreen(),
      ),
      GoRoute(
        path: '/grievance-management',
        builder: (context, state) => const GrievanceManagementScreen(),
      ),
      GoRoute(
        path: '/manage-appointments',
        builder: (context, state) => const AppointmentManagementScreen(),
      ),
      GoRoute(
        path: '/manage-events',
        builder: (context, state) => const EventManagementScreen(),
      ),
      GoRoute(
        path: '/daily-schedule',
        builder: (context, state) => const ScheduleManagementScreen(),
      ),
      GoRoute(
        path: '/register-pa',
        builder: (context, state) => const PARegistrationScreen(),
      ),
      GoRoute(
        path: '/pa-staff',
        builder: (context, state) => const PAStaffListScreen(),
      ),
      GoRoute(
        path: '/pa-login',
        builder: (context, state) => const PALoginScreen(),
      ),
      GoRoute(
        path: '/manage-slider',
        builder: (context, state) => const SliderManagementScreen(),
      ),
      GoRoute(
        path: '/unified-inbox',
        builder: (context, state) => const UnifiedInboxScreen(),
      ),

      GoRoute(
        path: '/meeting-notes',
        builder: (context, state) => const MeetingNotesScreen(),
      ),
      GoRoute(
        path: '/donations',
        builder: (context, state) => const DonationManagementScreen(),
      ),
      GoRoute(
        path: '/daily-briefing',
        builder: (context, state) => const DailyBriefingScreen(),
      ),
      GoRoute(
        path: '/send-message',
        builder: (context, state) => const SendMessageScreen(),
      ),
      GoRoute(
        path: '/pa-availability',
        builder: (context, state) => const PaAvailabilityScreen(),
      ),
      GoRoute(
        path: '/manage-locations',
        builder: (context, state) => const ManageLocationsScreen(),
      ),
      GoRoute(
        path: '/news-feed-management',
        builder: (context, state) => const NewsPostManagementScreen(),
      ),
      GoRoute(
        path: '/social-links-management',
        builder: (context, state) => const SocialLinksManagementScreen(),
      ),
      GoRoute(
        path: '/officials',
        builder: (context, state) => const OfficialsScreen(),
      ),
      GoRoute(
        path: '/officials-management',
        builder: (context, state) => const OfficialsManagementScreen(),
      ),
      GoRoute(
        path: '/emergency-contacts',
        builder: (context, state) => const EmergencyContactsScreen(),
      ),
      GoRoute(
        path: '/emergency-contacts-management',
        builder: (context, state) => const EmergencyContactsManagementScreen(),
      ),
      GoRoute(
        path: '/manage-issues',
        builder: (context, state) => const ManageIssuesScreen(),
      ),
      GoRoute(
        path: '/manage-feedback-projects',
        builder: (context, state) => const ManageFeedbackProjectsScreen(),
      ),
    ],
  );
});
