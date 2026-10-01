import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/app_models.dart';
import '../../core/services/api_service.dart';

class CustomLocationsState {
  final List<CustomCity> cities;
  final List<CustomVillage> villages;
  final bool isLoading;

  CustomLocationsState({
    required this.cities,
    required this.villages,
    this.isLoading = false,
  });

  CustomLocationsState copyWith({
    List<CustomCity>? cities,
    List<CustomVillage>? villages,
    bool? isLoading,
  }) {
    return CustomLocationsState(
      cities: cities ?? this.cities,
      villages: villages ?? this.villages,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class CustomLocationsNotifier extends StateNotifier<CustomLocationsState> {
  final ApiService _apiService;

  CustomLocationsNotifier(this._apiService)
      : super(CustomLocationsState(cities: [], villages: [])) {
    loadCustomLocations();
  }

  Future<void> loadCustomLocations() async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await _apiService.getCustomLocations();
      state = CustomLocationsState(
        cities: List<CustomCity>.from(res['cities'] ?? []),
        villages: List<CustomVillage>.from(res['villages'] ?? []),
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> addCity(String stateName, String cityName, {String? nameMr, String? nameHi}) async {
    await _apiService.addCustomCity(stateName, cityName, nameMr: nameMr, nameHi: nameHi);
    await loadCustomLocations();
  }

  Future<void> addVillage(String cityName, String villageName, {String? nameMr, String? nameHi}) async {
    await _apiService.addCustomVillage(cityName, villageName, nameMr: nameMr, nameHi: nameHi);
    await loadCustomLocations();
  }
}

final customLocationsProvider =
    StateNotifierProvider<CustomLocationsNotifier, CustomLocationsState>((ref) {
  return CustomLocationsNotifier(ref.watch(apiServiceProvider));
});
