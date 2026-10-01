import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/app_models.dart';
import '../../core/services/api_service.dart';
import '../../core/services/firebase_service.dart';

// Admin/PA: all complaints
final complaintsProvider = FutureProvider<List<Complaint>>((ref) async {
  return ref.watch(apiServiceProvider).getComplaints();
});

// Citizen: only their own complaints filtered server-side
final userComplaintsProvider = FutureProvider<List<Complaint>>((ref) async {
  final user = ref.watch(laravelUserProvider);
  if (user == null) return [];
  return ref.watch(apiServiceProvider).getComplaints(userId: user.uid);
});
