import 'package:mantri_app/core/utils/app_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/states_cities_data.dart';
import '../../../core/providers/locations_provider.dart';

class ManageLocationsScreen extends ConsumerStatefulWidget {
  const ManageLocationsScreen({super.key});

  @override
  ConsumerState<ManageLocationsScreen> createState() =>
      _ManageLocationsScreenState();
}

class _ManageLocationsScreenState extends ConsumerState<ManageLocationsScreen> {
  static const Color saffron = Color(0xFFFF9933);
  static const Color navy = Color(0xFF1B3B5A);

  final _cityFormKey = GlobalKey<FormState>();
  final _villageFormKey = GlobalKey<FormState>();

  // Add City form states
  String? _selectedCityState;
  final _cityNameController = TextEditingController();
  final _cityNameMrController = TextEditingController();
  final _cityNameHiController = TextEditingController();

  // Add Village form states
  String? _selectedVillageState;
  String? _selectedVillageCity;
  final _villageNameController = TextEditingController();
  final _villageNameMrController = TextEditingController();
  final _villageNameHiController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _cityNameController.dispose();
    _cityNameMrController.dispose();
    _cityNameHiController.dispose();
    _villageNameController.dispose();
    _villageNameMrController.dispose();
    _villageNameHiController.dispose();
    super.dispose();
  }

  Future<void> _submitCity() async {
    if (!_cityFormKey.currentState!.validate()) return;
    if (_selectedCityState == null) return;

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(customLocationsProvider.notifier)
          .addCity(
            _selectedCityState!,
            _cityNameController.text.trim(),
            nameMr:
                _cityNameMrController.text.trim().isEmpty
                    ? null
                    : _cityNameMrController.text.trim(),
            nameHi:
                _cityNameHiController.text.trim().isEmpty
                    ? null
                    : _cityNameHiController.text.trim(),
          );

      if (mounted) {
        AppDialogs.showSuccessDialog(context, message: 'City added successfully!');
        _cityNameController.clear();
        _cityNameMrController.clear();
        _cityNameHiController.clear();
        setState(() {
          _selectedCityState = null;
        });
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showErrorDialog(context, userMessage: 'Failed to add city:', technicalError: e);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitVillage() async {
    if (!_villageFormKey.currentState!.validate()) return;
    if (_selectedVillageCity == null) return;

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(customLocationsProvider.notifier)
          .addVillage(
            _selectedVillageCity!,
            _villageNameController.text.trim(),
            nameMr:
                _villageNameMrController.text.trim().isEmpty
                    ? null
                    : _villageNameMrController.text.trim(),
            nameHi:
                _villageNameHiController.text.trim().isEmpty
                    ? null
                    : _villageNameHiController.text.trim(),
          );

      if (mounted) {
        AppDialogs.showSuccessDialog(context, message: 'Village added successfully!');
        _villageNameController.clear();
        _villageNameMrController.clear();
        _villageNameHiController.clear();
        setState(() {
          _selectedVillageState = null;
          _selectedVillageCity = null;
        });
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showErrorDialog(context, userMessage: 'Failed to add village:', technicalError: e);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customLocations = ref.watch(customLocationsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: navy,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text(
            'Manage Locations',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          bottom: const TabBar(
            indicatorColor: saffron,
            indicatorWeight: 4,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.location_city), text: 'Add City'),
              Tab(icon: Icon(Icons.home), text: 'Add Village'),
            ],
          ),
        ),
        body: Stack(
          children: [
            TabBarView(
              children: [
                _buildCityTab(customLocations),
                _buildVillageTab(customLocations),
              ],
            ),
            if (_isSubmitting)
              Container(
                color: Colors.black26,
                child: const Center(
                  child: CircularProgressIndicator(color: saffron),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCityTab(CustomLocationsState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 4,
            shadowColor: Colors.black12,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _cityFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Missing City',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: navy,
                      ),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: _selectedCityState,
                      onChanged:
                          (val) => setState(() => _selectedCityState = val),
                      validator:
                          (v) => v == null ? 'Please select a state' : null,
                      decoration: InputDecoration(
                        labelText: 'Select State',
                        prefixIcon: const Icon(Icons.map, color: saffron),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items:
                          StatesCitiesData.allStates
                              .map(
                                (s) =>
                                    DropdownMenuItem(value: s, child: Text(s)),
                              )
                              .toList(),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cityNameController,
                      validator:
                          (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Please enter city name'
                                  : null,
                      decoration: InputDecoration(
                        labelText: 'City Name (English)',
                        prefixIcon: const Icon(
                          Icons.location_city,
                          color: saffron,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cityNameMrController,
                      decoration: InputDecoration(
                        labelText: 'City Name (Marathi / मराठी) - Optional',
                        prefixIcon: const Icon(Icons.translate, color: saffron),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cityNameHiController,
                      decoration: InputDecoration(
                        labelText: 'City Name (Hindi / हिंदी) - Optional',
                        prefixIcon: const Icon(Icons.translate, color: saffron),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: navy,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _submitCity,
                        child: const Text(
                          'Add City',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          Text(
            'Custom Cities List (${state.cities.length})',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: navy,
            ),
          ),
          const SizedBox(height: 12),
          state.cities.isEmpty
              ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text('No custom cities added yet.')),
              )
              : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.cities.length,
                itemBuilder: (context, index) {
                  final city = state.cities[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.amber,
                        child: Icon(Icons.location_city, color: Colors.white),
                      ),
                      title: Text(
                        city.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('State: ${city.state}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (city.nameMr != null)
                            Text(
                              'मराठी: ${city.nameMr}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          if (city.nameHi != null)
                            Text(
                              'हिंदी: ${city.nameHi}',
                              style: const TextStyle(fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        ],
      ),
    );
  }

  Widget _buildVillageTab(CustomLocationsState state) {
    // Combine static cities for the selected state and custom cities for the selected state
    final allCitiesForState =
        _selectedVillageState == null
            ? <String>[]
            : StatesCitiesData.getCities(
              _selectedVillageState!,
              customCities: state.cities,
            );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 4,
            shadowColor: Colors.black12,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _villageFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Missing Village',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: navy,
                      ),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: _selectedVillageState,
                      onChanged: (val) {
                        setState(() {
                          _selectedVillageState = val;
                          _selectedVillageCity = null;
                        });
                      },
                      validator:
                          (v) => v == null ? 'Please select a state' : null,
                      decoration: InputDecoration(
                        labelText: 'Select State',
                        prefixIcon: const Icon(Icons.map, color: saffron),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items:
                          StatesCitiesData.allStates
                              .map(
                                (s) =>
                                    DropdownMenuItem(value: s, child: Text(s)),
                              )
                              .toList(),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedVillageCity,
                      onChanged:
                          (val) => setState(() => _selectedVillageCity = val),
                      validator:
                          (v) => v == null ? 'Please select a city' : null,
                      decoration: InputDecoration(
                        labelText: 'Select City',
                        prefixIcon: const Icon(
                          Icons.location_city,
                          color: saffron,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items:
                          allCitiesForState
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(
                                    StatesCitiesData.getLocalizedCityName(
                                      c,
                                      'en',
                                      customCities: state.cities,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _villageNameController,
                      validator:
                          (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Please enter village name'
                                  : null,
                      decoration: InputDecoration(
                        labelText: 'Village Name (English)',
                        prefixIcon: const Icon(Icons.home, color: saffron),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _villageNameMrController,
                      decoration: InputDecoration(
                        labelText: 'Village Name (Marathi / मराठी) - Optional',
                        prefixIcon: const Icon(Icons.translate, color: saffron),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _villageNameHiController,
                      decoration: InputDecoration(
                        labelText: 'Village Name (Hindi / हिंदी) - Optional',
                        prefixIcon: const Icon(Icons.translate, color: saffron),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: navy,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _submitVillage,
                        child: const Text(
                          'Add Village',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          Text(
            'Custom Villages List (${state.villages.length})',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: navy,
            ),
          ),
          const SizedBox(height: 12),
          state.villages.isEmpty
              ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text('No custom villages added yet.')),
              )
              : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.villages.length,
                itemBuilder: (context, index) {
                  final village = state.villages[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.green,
                        child: Icon(Icons.home, color: Colors.white),
                      ),
                      title: Text(
                        village.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('City: ${village.city}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (village.nameMr != null)
                            Text(
                              'मराठी: ${village.nameMr}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          if (village.nameHi != null)
                            Text(
                              'हिंदी: ${village.nameHi}',
                              style: const TextStyle(fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        ],
      ),
    );
  }
}
