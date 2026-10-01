import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/app_models.dart';
import '../../core/services/api_service.dart';

final projectsProvider = FutureProvider.family<List<Project>, String?>((ref, status) async {
  return ref.watch(apiServiceProvider).getProjects(status: status);
});
