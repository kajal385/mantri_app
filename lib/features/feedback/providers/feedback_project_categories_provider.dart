import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mantri_app/core/services/api_service.dart';

final feedbackProjectCategoriesProvider = FutureProvider<List<String>>((ref) async {
  return ref.read(apiServiceProvider).getFeedbackProjectCategories();
});
