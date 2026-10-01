import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/app_models.dart';
import '../../core/services/api_service.dart';

final eventsProvider = FutureProvider<List<Event>>((ref) async {
  return ref.watch(apiServiceProvider).getEvents();
});
