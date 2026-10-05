/// auth_service.dart (formerly firebase_service.dart)
/// Pure Laravel Sanctum authentication — no Firebase dependency.
library;

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_models.dart';
import 'api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────

final authServiceProvider = Provider((ref) => AuthService(ref));

/// Holds the currently logged-in user. Null = logged out.
final laravelUserProvider = StateProvider<AppUser?>((ref) => null);

/// Mimics authStateProvider used by role_wrapper / app_router.
/// Returns a future that resolves to the current AppUser (or null).
final authStateProvider = FutureProvider<AppUser?>((ref) async {
  // If laravelUserProvider is already set, use it.
  final cached = ref.read(laravelUserProvider);
  if (cached != null) return cached;

  // Otherwise try to restore from saved token.
  final prefs = await SharedPreferences.getInstance();
  if (!prefs.containsKey('auth_token')) return null;

  try {
    final user = await ref.read(apiServiceProvider).getMe();
    if (user != null) {
      ref.read(laravelUserProvider.notifier).state = user;
    }
    return user;
  } catch (_) {
    return null;
  }
});

/// Provides the MP admin profile from Laravel /mp-profile.
final mpProfileDataProvider = FutureProvider<AppUser?>((ref) async {
  return ref.read(apiServiceProvider).getMpProfile();
});

/// Provides slider images from Laravel /slider-images.
final sliderImagesProvider = FutureProvider<List<String>>((ref) async {
  return ref.read(apiServiceProvider).getSliderImages();
});

// ─────────────────────────────────────────────────────────────────────────────
// AuthService
// ─────────────────────────────────────────────────────────────────────────────

class AuthService {
  final Ref _ref;
  AuthService(this._ref);

  // ── Login ──────────────────────────────────────────────────────────────────

  Future<void> signIn(String email, String password) async {
    final cleanEmail = email.trim();
    final cleanPassword = password.trim();

    final data = await _ref
        .read(apiServiceProvider)
        .login(cleanEmail, cleanPassword);
    final userMap = data['user'] as Map<String, dynamic>;
    final user = AppUser.fromMap(userMap, userMap['id'].toString());
    _ref.read(laravelUserProvider.notifier).state = user;
    // Invalidate authStateProvider so role_wrapper rebuilds
    _ref.invalidate(authStateProvider);
  }

  // ── Register ───────────────────────────────────────────────────────────────

  Future<void> signUp(
    String name,
    String? email,
    String password,
    UserRole role, {
    String? phone,
    String? state,
    String? city,
    String? area,
    String? ward,
    String? village,
    String? dob,
    String? profileImageUrl,
  }) async {
    final data = await _ref
        .read(apiServiceProvider)
        .register(
          name,
          email,
          password,
          role.name,
          phone: phone,
          state: state,
          city: city,
          area: area,
          ward: ward,
          village: village,
          dob: dob,
        );

    // If register returned the user object, set it immediately!
    if (data['user'] != null && data['user'] is Map) {
      final userMap = Map<String, dynamic>.from(data['user'] as Map);
      final user = AppUser.fromMap(userMap, userMap['id'].toString());
      _ref.read(laravelUserProvider.notifier).state = user;
      _ref.invalidate(authStateProvider);
    } else {
      // Auto-login fallback if user object was not in response
      final loginId = (email != null && email.isNotEmpty) ? email : phone;
      if (loginId != null && loginId.isNotEmpty) {
        await signIn(loginId, password);
      }
    }

    // Save profile image URL if provided (after registration/login so token is stored)
    if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
      try {
        await updateProfileImageUrl(profileImageUrl);
      } catch (_) {}
    }
  }

  // ── Register PA (Admin only) ───────────────────────────────────────────────

  Future<void> signUpPA({
    required String name,
    required String email,
    required String password,
    required PAProfile paProfile,
  }) async {
    await _ref
        .read(apiServiceProvider)
        .registerPa(
          name: name,
          email: email,
          password: password,
          paProfile: paProfile,
        );
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    // Clear token locally first
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _ref.read(laravelUserProvider.notifier).state = null;
    _ref.invalidate(authStateProvider);

    // Best-effort server-side logout (ignore errors)
    try {
      await _ref.read(apiServiceProvider).logout();
    } catch (_) {}
  }

  // ── Get current user data ──────────────────────────────────────────────────

  Future<AppUser?> getCurrentUserData({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = _ref.read(laravelUserProvider);
      if (cached != null) return cached;
    }
    final user = await _ref.read(apiServiceProvider).getMe();
    if (user != null) {
      _ref.read(laravelUserProvider.notifier).state = user;
    }
    return user;
  }

  // ── Profile image upload via Laravel /upload ──────────────────────────────

  Future<String> uploadProfileImage(File file) async {
    return await _ref.read(apiServiceProvider).uploadFile(file, 'profile');
  }

  Future<void> updateProfileImageUrl(String url) async {
    final updatedUser = await _ref.read(apiServiceProvider).updateUserProfile({
      'profile_image_url': url,
    });
    _ref.read(laravelUserProvider.notifier).state = updatedUser;
  }

  Future<void> updateUserProfile({
    String? name,
    String? phone,
    String? state,
    String? city,
    String? village,
    String? ward,
    String? area,
    String? dob,
    String? birthPlace,
    String? education,
    String? occupation,
    String? spouse,
    String? parents,
    String? vision,
    String? mission,
    String? politicalJourney,
    String? achievements,
  }) async {
    final updatedUser = await _ref.read(apiServiceProvider).updateUserProfile({
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (state != null) 'state': state,
      if (city != null) 'city': city,
      if (village != null) 'village': village,
      if (ward != null) 'ward': ward,
      if (area != null) 'area': area,
      if (dob != null) 'dob': dob,
      if (birthPlace != null) 'birth_place': birthPlace,
      if (education != null) 'education': education,
      if (occupation != null) 'occupation': occupation,
      if (spouse != null) 'spouse': spouse,
      if (parents != null) 'parents': parents,
      if (vision != null) 'vision': vision,
      if (mission != null) 'mission': mission,
      if (politicalJourney != null) 'political_journey': politicalJourney,
      if (achievements != null) 'achievements': achievements,
    });
    _ref.read(laravelUserProvider.notifier).state = updatedUser;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FirestoreService (stub) — all calls route to Laravel API via apiServiceProvider
// This stub keeps old call-sites compiling while we migrate screens individually.
// ─────────────────────────────────────────────────────────────────────────────

final firestoreServiceProvider = Provider((ref) => FirestoreService(ref));

class FirestoreService {
  final Ref _ref;
  FirestoreService(this._ref);

  // ── User ───────────────────────────────────────────────────────────────────
  Future<void> updateUserInfo(AppUser user) async {
    // No-op placeholder — update via API if a PATCH /me endpoint is added
  }

  // ── Appointments ───────────────────────────────────────────────────────────
  Stream<List<Appointment>> getAppointments() {
    return Stream.fromFuture(_ref.read(apiServiceProvider).getAppointments());
  }

  Stream<List<Appointment>> getPendingAppointments() {
    return Stream.fromFuture(
      _ref
          .read(apiServiceProvider)
          .getAppointments()
          .then((list) => list.where((a) => a.status == 'pending').toList()),
    );
  }

  Stream<List<Appointment>> getUserAppointments(String userId) {
    return Stream.fromFuture(
      _ref.read(apiServiceProvider).getCitizenAppointments(userId),
    );
  }

  Future<void> addAppointment(Appointment appointment) async {
    await _ref.read(apiServiceProvider).addAppointment(appointment);
  }

  Future<void> updateAppointmentStatus(String id, String status) async {
    await _ref.read(apiServiceProvider).updateAppointmentStatus(id, status);
  }

  Future<void> deleteAppointment(String id) async {
    await _ref.read(apiServiceProvider).deleteAppointment(id);
  }

  // ── Events ─────────────────────────────────────────────────────────────────
  Stream<List<Event>> getEvents() {
    return Stream.fromFuture(_ref.read(apiServiceProvider).getEvents());
  }

  Future<void> addEvent(Event event) async {
    await _ref.read(apiServiceProvider).addEvent(event);
  }

  Future<void> deleteEvent(String id) async {
    await _ref.read(apiServiceProvider).deleteEvent(id);
  }

  // ── Complaints ─────────────────────────────────────────────────────────────
  Stream<List<Complaint>> getComplaints() {
    return Stream.fromFuture(_ref.read(apiServiceProvider).getComplaints());
  }

  Future<void> addComplaint(Complaint complaint) async {
    await _ref.read(apiServiceProvider).addComplaint(complaint);
  }

  Future<void> updateComplaintStatus(String id, String status) async {
    await _ref.read(apiServiceProvider).updateComplaintStatus(id, status);
  }

  // ── Feedback ───────────────────────────────────────────────────────────────
  Stream<List<CitizenFeedback>> getFeedbacks() {
    return Stream.fromFuture(_ref.read(apiServiceProvider).getFeedbacks());
  }

  Future<void> addFeedback(CitizenFeedback feedback) async {
    await _ref.read(apiServiceProvider).addFeedback(feedback);
  }

  Future<void> deleteFeedback(String id) async {
    await _ref.read(apiServiceProvider).deleteFeedback(id);
  }

  // ── Schedule ───────────────────────────────────────────────────────────────
  Stream<List<ScheduleItem>> getDailySchedule(DateTime day) {
    return Stream.fromFuture(
      _ref
          .read(apiServiceProvider)
          .getSchedules(start: day, end: day.add(const Duration(days: 1))),
    );
  }

  Stream<List<ScheduleItem>> getScheduleRange(DateTime start, DateTime end) {
    return Stream.fromFuture(
      _ref.read(apiServiceProvider).getSchedules(start: start, end: end),
    );
  }

  Future<void> addScheduleItem(ScheduleItem item) async {
    await _ref.read(apiServiceProvider).addScheduleItem(item);
  }

  Future<void> updateScheduleStatus(String id, String status) async {
    await _ref.read(apiServiceProvider).updateScheduleStatus(id, status);
  }

  Future<void> deleteScheduleItem(String id) async {
    await _ref.read(apiServiceProvider).deleteScheduleItem(id);
  }

  // ── PA Profiles ────────────────────────────────────────────────────────────
  Stream<List<PAProfile>> getPAProfiles() {
    return Stream.fromFuture(_ref.read(apiServiceProvider).getPAProfiles());
  }

  Future<PAProfile?> getPAProfile(String uid) async {
    return _ref.read(apiServiceProvider).getPAProfile(uid);
  }

  Future<void> updatePAStatus(String uid, String status) async {
    await _ref.read(apiServiceProvider).updatePAStatus(uid, status);
  }

  Future<void> updatePAProfile(String uid, Map<String, dynamic> data) async {
    await _ref.read(apiServiceProvider).updatePAProfile(uid, data);
  }

  Future<void> deletePAProfile(String uid) async {
    await _ref.read(apiServiceProvider).deletePAProfile(uid);
  }

  // ── Image Upload ───────────────────────────────────────────────────────────
  Future<String?> uploadImage(File file, String path) async {
    try {
      return await _ref.read(apiServiceProvider).uploadFile(file, path);
    } catch (_) {
      return null;
    }
  }

  Future<void> uploadSliderImage(File file) async {
    final url = await _ref.read(apiServiceProvider).uploadFile(file, 'slider');
    await _ref.read(apiServiceProvider).addSliderImage(url);
  }

  Future<void> uploadSliderImageLink(String url) async {
    await _ref.read(apiServiceProvider).addSliderImage(url);
  }

  Future<void> deleteSliderImage(String url) async {
    await _ref.read(apiServiceProvider).deleteSliderImage(url);
  }
}

String _handleError(Object e) {
  return e.toString().replaceAll(RegExp(r'^.*?Exception.*?: '), '');
}
