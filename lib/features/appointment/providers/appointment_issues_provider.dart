import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mantri_app/core/services/api_service.dart';

final appointmentIssuesProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  final issues = await apiService.getAppointmentIssues();
  return issues.isEmpty ? ['Other'] : issues;
});
