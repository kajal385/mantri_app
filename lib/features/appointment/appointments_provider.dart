import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/app_models.dart';
import '../../core/services/api_service.dart';
import '../../core/services/firebase_service.dart';

// Admin/PA: all appointments (requires Sanctum token)
final appointmentsProvider = FutureProvider<List<Appointment>>((ref) async {
  return ref.watch(apiServiceProvider).getAppointments();
});

// Citizen: their own appointments via public endpoint (no Sanctum token needed)
final userAppointmentsProvider = FutureProvider<List<Appointment>>((ref) async {
  final user = ref.watch(laravelUserProvider);
  if (user == null) return [];
  final api = ref.watch(apiServiceProvider);
  return api.getCitizenAppointments(user.uid);
});
