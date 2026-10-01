import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mantri_app/core/services/firebase_service.dart';
import 'package:mantri_app/core/models/app_models.dart';
import 'package:mantri_app/features/admin/presentation/admin_dashboard.dart';
import 'package:mantri_app/features/pa/presentation/pa_dashboard.dart' hide SizedBox;
import 'package:mantri_app/features/user/presentation/user_dashboard.dart';

final userDataProvider = FutureProvider<AppUser?>((ref) async {
  final authUser = await ref.watch(authStateProvider.future);
  if (authUser == null) return null;
  return ref.read(authServiceProvider).getCurrentUserData(forceRefresh: true);
});

class RoleWrapper extends ConsumerWidget {
  const RoleWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final userData = ref.watch(userDataProvider);

    return authState.when(
      data: (authUser) {
        // If logged out, navigate immediately to the login screen.
        if (authUser == null) {
          return const _LogoutRedirect();
        }

        return userData.when(
          data: (user) {
            if (user == null) {
              // If no profile data could be retrieved, log out to be safe
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.read(authServiceProvider).signOut();
              });
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            switch (user.role) {
              case UserRole.admin:
                // Strict check: Only authorized emails can see the Admin Dashboard
                if (user.email == 'gajarekajal2205@gmail.com' ||
                    user.email == 'mykiranamartdevelopers@gmail.com' ||
                    user.email == 'admin@gmail.com') {
                  return const AdminDashboard();
                } else {
                  // Fallback for safety
                  return const UserDashboard();
                }
              case UserRole.pa:
                return const PADashboard();
              case UserRole.user:
                return const UserDashboard();
            }
          },
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, stack) => _ErrorScreen(e: e, ref: ref),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, stack) => _ErrorScreen(e: e, ref: ref),
    );
  }
}

// Navigates to /login after the current frame completes.
class _LogoutRedirect extends StatefulWidget {
  const _LogoutRedirect();

  @override
  State<_LogoutRedirect> createState() => _LogoutRedirectState();
}

class _LogoutRedirectState extends State<_LogoutRedirect> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go('/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final Object e;
  final WidgetRef ref;
  const _ErrorScreen({required this.e, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $e'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(userDataProvider),
              child: const Text('Retry'),
            ),
            TextButton(
              onPressed: () => ref.read(authServiceProvider).signOut(),
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
