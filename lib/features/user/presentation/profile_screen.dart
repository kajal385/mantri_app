import 'package:mantri_app/core/utils/app_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mantri_app/features/auth/presentation/screens/role_wrapper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mantri_app/core/services/firebase_service.dart';
import 'package:mantri_app/core/models/app_models.dart';
import 'package:go_router/go_router.dart';
import 'package:mantri_app/core/constants/states_cities_data.dart';
import 'package:mantri_app/core/providers/locations_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:mantri_app/core/utils/image_helper.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditing = false;
  bool _isUploading = false;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _wardController;
  late TextEditingController _dobController;
  late TextEditingController _stateController;
  late TextEditingController _cityController;
  late TextEditingController _villageController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _wardController = TextEditingController();
    _dobController = TextEditingController();
    _stateController = TextEditingController();
    _cityController = TextEditingController();
    _villageController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _wardController.dispose();
    _dobController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _villageController.dispose();
    super.dispose();
  }

  void _initFields(AppUser user) {
    if (_nameController.text.isEmpty) _nameController.text = user.name;
    if (_phoneController.text.isEmpty) _phoneController.text = user.phone ?? '';
    if (_stateController.text.isEmpty) _stateController.text = user.state ?? '';
    if (_cityController.text.isEmpty) _cityController.text = user.city ?? '';
    if (_villageController.text.isEmpty) _villageController.text = user.village ?? '';
    if (_wardController.text.isEmpty) _wardController.text = user.ward ?? '';
    if (_dobController.text.isEmpty) _dobController.text = user.dob ?? '';
  }

  void _clearControllers() {
    _nameController.clear();
    _phoneController.clear();
    _stateController.clear();
    _cityController.clear();
    _villageController.clear();
    _wardController.clear();
    _dobController.clear();
  }

  Future<void> _saveProfile(AppUser currentUser) async {
    try {
      await ref
          .read(authServiceProvider)
          .updateUserProfile(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            state: _stateController.text.trim().isNotEmpty ? _stateController.text.trim() : null,
            city: _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : null,
            village: _villageController.text.trim().isNotEmpty ? _villageController.text.trim() : null,
            ward: _wardController.text.trim().isNotEmpty ? _wardController.text.trim() : null,
            dob: _dobController.text.trim().isNotEmpty ? _dobController.text.trim() : null,
          );
      await ref.refresh(userDataProvider.future);
      _clearControllers();
      setState(() => _isEditing = false);
      if (mounted) {
        AppDialogs.showSuccessDialog(context, message: 'Profile updated successfully!');
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showErrorDialog(context, technicalError: e);
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // Compress image
    );

    if (image != null) {
      setState(() => _isUploading = true);
      try {
        // 1. Crop Image
        final croppedFile = await ImageHelper.cropImage(File(image.path));
        if (croppedFile == null) {
          setState(() => _isUploading = false);
          return; // User cancelled crop
        }

        final authService = ref.read(authServiceProvider);
        // 2. Upload Cropped Image
        final imageUrl = await authService.uploadProfileImage(croppedFile);
        await authService.updateProfileImageUrl(imageUrl);

        // Refresh profile data
        ref.invalidate(userDataProvider);

        if (mounted) {
          AppDialogs.showSuccessDialog(context, message: 'Profile photo updated!');
        }
      } catch (e) {
        if (mounted) {
          AppDialogs.showErrorDialog(context, userMessage: 'Upload failed:', technicalError: e);
        }
      } finally {
        if (mounted) {
          setState(() => _isUploading = false);
        }
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)), // default to 18 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(userDataProvider);
    final customLocs = ref.watch(customLocationsProvider);
    final saffron = const Color(0xFFDB7E20);
    final navy = const Color(0xFF1B3B5A);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Settings'),
        actions: [
          userData.when(
            data:
                (user) => IconButton(
                  icon: Icon(_isEditing ? Icons.close : Icons.edit),
                  onPressed: () {
                    setState(() {
                      if (_isEditing) {
                        _clearControllers();
                        _isEditing = false;
                      } else {
                        if (user != null) _initFields(user);
                        _isEditing = true;
                      }
                    });
                  },
                ),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final shouldLogout = await AppDialogs.showLogoutConfirmationDialog(context);
              if (shouldLogout && mounted) {
                await ref.read(authServiceProvider).signOut();
                if (mounted) context.go('/login');
              }
            },
          ),
        ],
      ),
      body: userData.when(
        data: (user) {
          if (user == null)
            return const Center(child: Text('No profile found.'));
          if (_isEditing) _initFields(user);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildProfileHeader(user, saffron, navy),
                const SizedBox(height: 30),
                if (_isEditing) ...[
                  _buildEditField('Full Name', _nameController, Icons.person),
                  _buildEditField(
                    'Mobile Number',
                    _phoneController,
                    Icons.phone,
                  ),
                  _buildEditField('State', _stateController, Icons.map),
                  _buildEditField('City', _cityController, Icons.location_city),
                  _buildEditField('Village', _villageController, Icons.home),
                  _buildEditField('Ward Number', _wardController, Icons.map),
                  _buildEditField('Date of Birth', _dobController, Icons.calendar_today, readOnly: true, onTap: () => _selectDate(context)),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => _saveProfile(user),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: navy,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ] else ...[
                  _buildInfoSection(
                    title: 'Personal Details',
                    items: [
                      _buildInfoTile(Icons.email, 'Email Address', user.email),
                      _buildInfoTile(
                        Icons.phone,
                        'Mobile Number',
                        user.phone ?? 'Not set',
                      ),
                      if (user.dob != null && user.dob!.isNotEmpty)
                        _buildInfoTile(
                          Icons.calendar_today,
                          'Date of Birth',
                          user.dob!,
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildInfoSection(
                    title: 'Location & Ward',
                    items: [
                      _buildInfoTile(
                        Icons.map,
                        'State',
                        user.state ?? 'Not provided',
                      ),
                      _buildInfoTile(
                        Icons.location_city,
                        'City',
                        user.city ?? 'Not provided',
                      ),
                      _buildInfoTile(
                        Icons.map,
                        'Ward Number',
                        user.ward ?? 'Not provided',
                      ),
                      _buildInfoTile(
                        Icons.home,
                        'Village Name',
                        user.village ?? 'Not provided',
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildProfileHeader(AppUser user, Color saffron, Color navy) {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: navy.withValues(alpha: 0.1),
              backgroundImage:
                  user.profileImageUrl != null
                      ? NetworkImage(user.profileImageUrl!)
                      : null,
              child:
                  user.profileImageUrl == null
                      ? Icon(Icons.person, size: 60, color: navy)
                      : null,
            ),
            if (_isUploading)
              const Positioned.fill(
                child: Center(child: CircularProgressIndicator()),
              ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _isUploading ? null : _pickAndUploadImage,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: saffron,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          user.name,
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text(
          user.role.name.toUpperCase(),
          style: TextStyle(
            color: saffron,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection({
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1B3B5A), size: 20),
      title: Text(
        label,
        style: const TextStyle(fontSize: 11, color: Colors.grey),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
    );
  }

  Widget _buildEditField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF1B3B5A)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    IconData icon,
    List<String> items,
    String? value,
    void Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: DropdownButtonFormField<String>(
        value: value,
        hint: Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        disabledHint: items.isEmpty
            ? Text(
                'No $label available',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              )
            : null,
        style: const TextStyle(fontSize: 14, color: Colors.black),
        items: items.isEmpty ? null : items
            .map(
              (e) => DropdownMenuItem(
                value: e,
                child: Text(e, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFF1B3B5A)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          filled: true,
          fillColor: Colors.white,
        ),
        isExpanded: true,
      ),
    );
  }
}
