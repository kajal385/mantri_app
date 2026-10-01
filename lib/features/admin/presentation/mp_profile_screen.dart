import 'package:mantri_app/core/utils/app_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mantri_app/features/auth/presentation/screens/role_wrapper.dart';
import 'package:mantri_app/core/models/app_models.dart';
import 'package:mantri_app/core/constants/app_constants.dart';
import 'package:mantri_app/core/services/firebase_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:mantri_app/core/utils/image_helper.dart';

class MPProfileScreen extends ConsumerStatefulWidget {
  const MPProfileScreen({super.key});
  @override
  ConsumerState<MPProfileScreen> createState() => _MPProfileScreenState();
}

class _MPProfileScreenState extends ConsumerState<MPProfileScreen> {
  bool _isEditing = false;
  bool _isUploading = false;
  bool _isSaving = false;

  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _dobCtrl;
  late TextEditingController _birthPlaceCtrl;
  late TextEditingController _educationCtrl;
  late TextEditingController _occupationCtrl;
  late TextEditingController _spouseCtrl;
  late TextEditingController _parentsCtrl;
  late TextEditingController _visionCtrl;
  late TextEditingController _missionCtrl;
  late TextEditingController _politicalJourneyCtrl;
  late TextEditingController _achievementsCtrl;

  static const saffron = Color.fromARGB(255, 219, 126, 32);
  static const orangeAccent = Color(0xFFF57C00);

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _dobCtrl = TextEditingController();
    _birthPlaceCtrl = TextEditingController();
    _educationCtrl = TextEditingController();
    _occupationCtrl = TextEditingController();
    _spouseCtrl = TextEditingController();
    _parentsCtrl = TextEditingController();
    _visionCtrl = TextEditingController();
    _missionCtrl = TextEditingController();
    _politicalJourneyCtrl = TextEditingController();
    _achievementsCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _dobCtrl.dispose();
    _birthPlaceCtrl.dispose();
    _educationCtrl.dispose();
    _occupationCtrl.dispose();
    _spouseCtrl.dispose();
    _parentsCtrl.dispose();
    _visionCtrl.dispose();
    _missionCtrl.dispose();
    _politicalJourneyCtrl.dispose();
    _achievementsCtrl.dispose();
    super.dispose();
  }

  void _initFields(AppUser user) {
    _nameCtrl.text = user.name.isNotEmpty ? user.name : 'Anup Sanjay Dhotre';
    _phoneCtrl.text = user.phone ?? '';
    _emailCtrl.text = user.email;
    _dobCtrl.text = user.dob ?? '24 May 1984';
    _birthPlaceCtrl.text = user.birthPlace ?? 'Akola, Maharashtra';
    _educationCtrl.text = user.education ?? 'B.Com (Symbiosis College)';
    _occupationCtrl.text = user.occupation ?? 'Agriculturist';
    _spouseCtrl.text = user.spouse ?? 'Samiksha Anup Dhotre';
    _parentsCtrl.text = user.parents ?? 'Sanjay Shamrao Dhotre and Suhasini Dhotre';
    _visionCtrl.text = user.vision ?? 'To build a sustainable, tech-enabled, and prosperous Akola where every citizen has access to modern infrastructure and equitable opportunities.';
    _missionCtrl.text = user.mission ?? 'Empowering rural communities through irrigation projects, boosting local employment, and ensuring transparent governance via digital integration.';
    _politicalJourneyCtrl.text = user.politicalJourney ??
        "2024: Elected as Member of Parliament (MP) from Akola constituency with a significant mandate.\n"
        "2019-2023: Active leadership in local developmental projects and strengthening party grassroots in Akola.\n"
        "2014-2018: Worked extensively on agricultural reforms and irrigation awareness in Vidarbha region.";
    _achievementsCtrl.text = user.achievements ??
        "Youth Icon for Rural Development: Recognized for pioneering digital literacy in rural Akola schools.\n"
        "Agricultural Excellence Award: For implementing innovative drip irrigation models in family orchards.";
  }

  Future<void> _saveProfile({bool exitEditMode = false}) async {
    setState(() => _isSaving = true);
    try {
      await ref.read(authServiceProvider).updateUserProfile(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        dob: _dobCtrl.text.trim(),
        birthPlace: _birthPlaceCtrl.text.trim(),
        education: _educationCtrl.text.trim(),
        occupation: _occupationCtrl.text.trim(),
        spouse: _spouseCtrl.text.trim(),
        parents: _parentsCtrl.text.trim(),
        vision: _visionCtrl.text.trim(),
        mission: _missionCtrl.text.trim(),
        politicalJourney: _politicalJourneyCtrl.text.trim(),
        achievements: _achievementsCtrl.text.trim(),
      );
      await ref.refresh(userDataProvider.future);
      await ref.refresh(mpProfileDataProvider.future);
      if (exitEditMode) {
        setState(() => _isEditing = false);
      }
      if (mounted) {
        AppDialogs.showSuccessDialog(context, message: 'Biography updated successfully!');
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showErrorDialog(context, technicalError: e);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickAndUploadPhoto(AppUser user) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
    if (image == null) return;
    setState(() => _isUploading = true);
    try {
      final cropped = await ImageHelper.cropImage(File(image.path));
      if (cropped == null) return;
      final auth = ref.read(authServiceProvider);
      final url = await auth.uploadProfileImage(cropped);
      await auth.updateProfileImageUrl(url);
      ref.invalidate(userDataProvider);
      ref.invalidate(mpProfileDataProvider);
      if (mounted) {
        AppDialogs.showSuccessDialog(context, message: 'Profile photo updated!');
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showErrorDialog(context, userMessage: 'Upload failed:', technicalError: e);
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mpData = ref.watch(mpProfileDataProvider).value;
    final userData = ref.watch(userDataProvider).value;
    final isAdmin = userData?.role == UserRole.admin;
    final displayUser = (isAdmin && userData != null) ? userData : mpData;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: saffron,
            expandedHeight: 260,
            pinned: true,
            actions: [
              if (isAdmin)
                IconButton(
                  icon: Icon(_isEditing ? Icons.close : Icons.edit, color: Colors.white),
                  tooltip: _isEditing ? 'Cancel' : 'Edit Biography',
                  onPressed: () {
                    final targetUser = displayUser;
                    if (!_isEditing && targetUser != null) _initFields(targetUser);
                    setState(() => _isEditing = !_isEditing);
                  },
                ),
              if (_isEditing)
                _isSaving
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                      )
                    : IconButton(
                        icon: const Icon(Icons.check, color: Colors.white),
                        tooltip: 'Save & Exit',
                        onPressed: () => _saveProfile(exitEditMode: true),
                      ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text('MP Anup Sanjay Dhotre',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [saffron, orangeAccent],
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          children: [
                             CircleAvatar(
                              radius: 54,
                              backgroundColor: Colors.white24,
                              child: CircleAvatar(
                                radius: 50,
                                backgroundImage: displayUser?.profileImageUrl != null
                                    ? NetworkImage(displayUser!.profileImageUrl!)
                                    : const AssetImage(AppConstants.mpProfileImage) as ImageProvider,
                              ),
                            ),
                            if (_isUploading)
                              const Positioned.fill(
                                child: Center(child: CircularProgressIndicator(color: Colors.white)),
                              ),
                            if (isAdmin)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _isUploading ? null : () => _pickAndUploadPhoto(userData!),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: orangeAccent,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          displayUser?.email ?? '',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: _isEditing && userData != null
                  ? _buildEditForm(userData)
                  : _buildViewMode(displayUser),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildEditForm(AppUser user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Personal Info', Icons.person),
        _editField('Full Name', _nameCtrl, Icons.badge),
        _editField('Mobile', _phoneCtrl, Icons.phone),
        _editField('Date of Birth', _dobCtrl, Icons.cake),
        _editField('Place of Birth', _birthPlaceCtrl, Icons.location_city),
        _editField('Education', _educationCtrl, Icons.school),
        _editField('Occupation', _occupationCtrl, Icons.work),
        const SizedBox(height: 20),
        _sectionHeader('Family', Icons.family_restroom),
        _editField('Spouse', _spouseCtrl, Icons.favorite),
        _editField('Parents', _parentsCtrl, Icons.people),
        const SizedBox(height: 20),
        _sectionHeader('Vision & Mission', Icons.lightbulb),
        _editField('Vision', _visionCtrl, Icons.visibility, maxLines: 4),
        _editField('Mission', _missionCtrl, Icons.flag, maxLines: 4),
        const SizedBox(height: 20),
        _sectionHeader('Political Journey & Achievements', Icons.timeline),
        _editField('Political Journey (Year: Details per line)', _politicalJourneyCtrl, Icons.history, maxLines: 6),
        _editField('Achievements (Title: Description per line)', _achievementsCtrl, Icons.emoji_events, maxLines: 6),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveProfile,
            icon: _isSaving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save),
            label: const Text('Save Biography'),
            style: ElevatedButton.styleFrom(
              backgroundColor: saffron,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildViewMode(AppUser? mpData) {
    final journeyText = mpData?.politicalJourney ??
        "2024: Elected as Member of Parliament (MP) from Akola constituency with a significant mandate.\n"
        "2019-2023: Active leadership in local developmental projects and strengthening party grassroots in Akola.\n"
        "2014-2018: Worked extensively on agricultural reforms and irrigation awareness in Vidarbha region.";
    final journeyLines = journeyText.split('\n').where((line) => line.trim().isNotEmpty).toList();

    final achievementsText = mpData?.achievements ??
        "Youth Icon for Rural Development: Recognized for pioneering digital literacy in rural Akola schools.\n"
        "Agricultural Excellence Award: For implementing innovative drip irrigation models in family orchards.";
    final achievementsLines = achievementsText.split('\n').where((line) => line.trim().isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Political Profile', Icons.stars),
        _bioTile('Current Role', 'Member of Parliament (MP), Akola'),
        _bioTile('Elected Date', 'June 2024'),
        _bioTile('Party Affiliation', 'Bharatiya Janata Party (BJP)'),
        _bioTile('Organization', 'Rashtriya Swayamsevak Sangh (RSS)'),

        const SizedBox(height: 24),
        _sectionHeader('Personal Information', Icons.person),
        _bioTile('Full Name', mpData?.name ?? 'Anup Sanjay Dhotre'),
        _bioTile('Mobile', mpData?.phone ?? 'Not set'),
        _bioTile('Date of Birth', mpData?.dob ?? '24 May 1984'),
        _bioTile('Place of Birth', mpData?.birthPlace ?? 'Akola, Maharashtra'),
        _bioTile('Education', mpData?.education ?? 'B.Com (Symbiosis College)'),
        _bioTile('Occupation', mpData?.occupation ?? 'Agriculturist'),

        const SizedBox(height: 24),
        _sectionHeader('Family & Background', Icons.family_restroom),
        _bioTile('Spouse', mpData?.spouse ?? 'Samiksha Anup Dhotre'),
        _bioTile('Parents', mpData?.parents ?? 'Sanjay Shamrao Dhotre and Suhasini Dhotre'),

        const SizedBox(height: 24),
        _sectionHeader('Vision & Mission', Icons.lightbulb),
        _bioTile('Vision',
            mpData?.vision ?? 'To build a sustainable, tech-enabled, and prosperous Akola where every citizen has access to modern infrastructure and equitable opportunities.'),
        _bioTile('Mission',
            mpData?.mission ?? 'Empowering rural communities through irrigation projects, boosting local employment, and ensuring transparent governance via digital integration.'),

        const SizedBox(height: 24),
        _sectionHeader('Political Journey', Icons.timeline),
        ...journeyLines.map((line) {
          final parts = line.split(':');
          if (parts.length >= 2) {
            final year = parts[0].trim();
            final detail = parts.sublist(1).join(':').trim();
            return _timelineItem(year, detail);
          }
          return _timelineItem('-', line.trim());
        }),

        const SizedBox(height: 24),
        _sectionHeader('Achievements & Awards', Icons.emoji_events),
        ...achievementsLines.map((line) {
          final parts = line.split(':');
          if (parts.length >= 2) {
            final title = parts[0].trim();
            final description = parts.sublist(1).join(':').trim();
            return _achievementTile(title, description);
          }
          return _achievementTile(line.trim(), '');
        }),

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: orangeAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: saffron)),
          ),
        ],
      ),
    );
  }

  Widget _bioTile(String label, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _editField(String label, TextEditingController ctrl, IconData icon, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: saffron),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _timelineItem(String year, String detail) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: saffron.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(year, style: const TextStyle(fontWeight: FontWeight.bold, color: saffron)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(detail, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _achievementTile(String title, String description) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 4),
          Text(description, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ],
      ),
    );
  }
}
