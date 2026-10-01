import 'package:mantri_app/core/utils/app_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mantri_app/core/models/app_models.dart';
import 'package:mantri_app/core/services/firebase_service.dart';

class PAStaffListScreen extends ConsumerStatefulWidget {
  const PAStaffListScreen({super.key});

  @override
  ConsumerState<PAStaffListScreen> createState() => _PAStaffListScreenState();
}

class _PAStaffListScreenState extends ConsumerState<PAStaffListScreen> {
  List<PAProfile> _profiles = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    setState(() { _loading = true; _error = null; });
    try {
      final profiles = await ref.read(firestoreServiceProvider).getPAProfiles().first;
      if (mounted) setState(() => _profiles = profiles);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const saffron = Color.fromARGB(255, 219, 126, 32);
    const orangeAccent = Color(0xFFF57C00);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: saffron,
        foregroundColor: Colors.white,
        title: Text('PA Staff Directory', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadProfiles,
          ),
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: 'Register New PA',
            onPressed: () async {
              await context.push('/register-pa');
              _loadProfiles(); // Refresh after registering a new PA
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : RefreshIndicator(
                  onRefresh: _loadProfiles,
                  child: _profiles.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 120),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.people_outline, size: 80, color: Colors.grey.shade300),
                                  const SizedBox(height: 16),
                                  Text('No PA accounts yet', style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey)),
                                  const SizedBox(height: 8),
                                  Text('Tap + to register a Personal Assistant', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      await context.push('/register-pa');
                                      _loadProfiles();
                                    },
                                    icon: const Icon(Icons.add),
                                    label: const Text('Register PA'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: saffron,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _profiles.length,
                          itemBuilder: (context, index) {
                            return _PACard(
                              profile: _profiles[index],
                              saffron: saffron,
                              orangeAccent: orangeAccent,
                              onRefresh: _loadProfiles,
                            );
                          },
                        ),
                ),
    );
  }
}

class _PACard extends ConsumerWidget {
  final PAProfile profile;
  final Color saffron;
  final Color orangeAccent;
  final VoidCallback? onRefresh;
  const _PACard({required this.profile, required this.saffron, required this.orangeAccent, this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = profile.status == 'active';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showDetailSheet(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header row
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: saffron.withOpacity(0.1),
                    backgroundImage: profile.profileImageUrl != null
                        ? NetworkImage(profile.profileImageUrl!)
                        : null,
                    child: profile.profileImageUrl == null
                        ? Text(
                            profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'P',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: saffron),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profile.name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(profile.designation, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isActive ? '● Active' : '● Inactive',
                                style: TextStyle(
                                  color: isActive ? Colors.green : Colors.red,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'ID: ${profile.employeeId}',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _confirmDelete(context, ref),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              // Info grid
              Row(
                children: [
                  Expanded(child: _infoChip(Icons.email_outlined, profile.email)),
                  const SizedBox(width: 8),
                  Expanded(child: _infoChip(Icons.phone_outlined, profile.phone)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _infoChip(Icons.location_city_outlined, profile.officeLocation)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _infoChip(
                      Icons.calendar_today_outlined,
                      DateFormat('dd MMM yyyy').format(profile.joiningDate),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _infoChip(Icons.person_pin_outlined, 'Assigned to: ${profile.assignedTo}'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: saffron.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: saffron),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  void _confirmStatusChange(BuildContext context, WidgetRef ref) {
    final isCurrentlyActive = profile.status == 'active';
    final newStatus = isCurrentlyActive ? 'inactive' : 'active';
    final saffron = Color.fromARGB(255, 219, 126, 32);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${isCurrentlyActive ? 'Deactivate' : 'Activate'} Account'),
        content: Text(
          isCurrentlyActive
              ? 'Are you sure you want to mark ${profile.name} as Inactive? They will no longer have access to the PA panel.'
              : 'Are you sure you want to reactivate ${profile.name}\'s account?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: isCurrentlyActive ? Colors.orange : Colors.green),
            onPressed: () async {
              Navigator.pop(ctx);
              // Close the bottom sheet too
              Navigator.pop(context);
              await ref.read(firestoreServiceProvider).updatePAStatus(profile.uid, newStatus);
              if (context.mounted) {
                AppDialogs.showSuccessDialog(context, message: 'PA account status updated to ${newStatus.toUpperCase()}');
                onRefresh?.call(); // Refresh the list
              }
            },
            child: Text(isCurrentlyActive ? 'Deactivate' : 'Activate', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove PA Account'),
        content: Text('Are you sure you want to permanently remove ${profile.name}\'s account?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(firestoreServiceProvider).deletePAProfile(profile.uid);
              if (context.mounted) {
                AppDialogs.showErrorDialog(context, userMessage: 'PA profile removed from directory');
                onRefresh?.call(); // Refresh the list
              }
            },
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDetailSheet(BuildContext context, WidgetRef ref) {
    PAProfile currentProfile = profile;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (ctx, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: SingleChildScrollView(
            controller: scrollCtrl,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 20),
                // Profile header
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 45,
                        backgroundColor: saffron.withOpacity(0.1),
                        backgroundImage: currentProfile.profileImageUrl != null ? NetworkImage(currentProfile.profileImageUrl!) : null,
                        child: currentProfile.profileImageUrl == null
                            ? Text(currentProfile.name.isNotEmpty ? currentProfile.name[0].toUpperCase() : 'P', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: saffron))
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(currentProfile.name, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
                      Text(currentProfile.designation, style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: saffron.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('Employee ID: ${currentProfile.employeeId}', style: TextStyle(color: saffron, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _detailSection('Personal Details', [
                  _detailRow(Icons.email_outlined, 'Email', currentProfile.email),
                  _detailRow(Icons.phone_outlined, 'Mobile', currentProfile.phone),
                  _detailRow(Icons.home_outlined, 'Address', currentProfile.address),
                  _detailRow(Icons.school_outlined, 'Education', currentProfile.education),
                ]),
                const SizedBox(height: 16),
                _detailSection('Official Details', [
                  _detailRow(Icons.assignment_ind_outlined, 'Designation', currentProfile.designation),
                  _detailRow(Icons.person_pin_outlined, 'Assigned To', currentProfile.assignedTo),
                  _detailRow(Icons.location_city_outlined, 'Office Location', currentProfile.officeLocation),
                  _detailRow(Icons.calendar_today_outlined, 'Joining Date', DateFormat('dd MMMM yyyy').format(currentProfile.joiningDate)),
                  _detailRow(Icons.circle, 'Status', currentProfile.status.toUpperCase(), valueColor: currentProfile.status == 'active' ? Colors.green : Colors.red),
                ]),
                const SizedBox(height: 16),
                _detailSection('Identity Verification', [
                  _detailRow(Icons.credit_card_outlined, 'ID Type', currentProfile.idProofType),
                  _detailRow(Icons.numbers_outlined, 'ID Number', currentProfile.idProofNumber),
                ]),
                const SizedBox(height: 16),
                _detailSection('System Info', [
                  _detailRow(Icons.access_time, 'Account Created', DateFormat('dd MMM yyyy, hh:mm a').format(currentProfile.createdAt)),
                  _detailRow(Icons.fingerprint, 'UID', currentProfile.uid),
                ]),
                const SizedBox(height: 32),
                // Edit Profile Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showEditPADialog(context, ref, currentProfile, (updatedProfile) {
                      setSheetState(() {
                        currentProfile = updatedProfile;
                      });
                    }),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit PA Personal Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: saffron,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Change Status Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmStatusChange(context, ref),
                    icon: Icon(currentProfile.status == 'active' ? Icons.block : Icons.check_circle_outline),
                    label: Text(currentProfile.status == 'active' ? 'Mark as Inactive / Left Job' : 'Mark as Active / Working'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      foregroundColor: currentProfile.status == 'active' ? Colors.orange : Colors.green,
                      side: BorderSide(color: currentProfile.status == 'active' ? Colors.orange : Colors.green),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmDelete(context, ref),
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Permanently Remove Account'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.red.shade100),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _detailSection(String title, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: saffron)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: saffron.withOpacity(0.03),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: saffron.withOpacity(0.08)),
          ),
          child: Column(children: rows),
        ),
      ],
    );
  }

  Widget _detailRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: saffron.withOpacity(0.6)),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: valueColor),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditPADialog(BuildContext context, WidgetRef ref, PAProfile currentProfile, Function(PAProfile) onUpdate) {
    final nameCtrl = TextEditingController(text: currentProfile.name);
    final phoneCtrl = TextEditingController(text: currentProfile.phone);
    final emailCtrl = TextEditingController(text: currentProfile.email);
    final desigCtrl = TextEditingController(text: currentProfile.designation);
    final empIdCtrl = TextEditingController(text: currentProfile.employeeId);
    final officeCtrl = TextEditingController(text: currentProfile.officeLocation);
    final eduCtrl = TextEditingController(text: currentProfile.education);
    final addressCtrl = TextEditingController(text: currentProfile.address);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit PA Details (${currentProfile.name})'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person))),
              const SizedBox(height: 10),
              TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile Phone', prefixIcon: Icon(Icons.phone))),
              const SizedBox(height: 10),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email))),
              const SizedBox(height: 10),
              TextField(controller: desigCtrl, decoration: const InputDecoration(labelText: 'Designation', prefixIcon: Icon(Icons.badge))),
              const SizedBox(height: 10),
              TextField(controller: empIdCtrl, decoration: const InputDecoration(labelText: 'Employee ID', prefixIcon: Icon(Icons.numbers))),
              const SizedBox(height: 10),
              TextField(controller: officeCtrl, decoration: const InputDecoration(labelText: 'Office Location', prefixIcon: Icon(Icons.location_city))),
              const SizedBox(height: 10),
              TextField(controller: eduCtrl, decoration: const InputDecoration(labelText: 'Education', prefixIcon: Icon(Icons.school))),
              const SizedBox(height: 10),
              TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.home))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: saffron, foregroundColor: Colors.white),
            onPressed: () async {
              final data = {
                'name': nameCtrl.text.trim(),
                'phone': phoneCtrl.text.trim(),
                'email': emailCtrl.text.trim(),
                'designation': desigCtrl.text.trim(),
                'employeeId': empIdCtrl.text.trim(),
                'officeLocation': officeCtrl.text.trim(),
                'education': eduCtrl.text.trim(),
                'address': addressCtrl.text.trim(),
              };
              await ref.read(firestoreServiceProvider).updatePAProfile(currentProfile.uid, data);
              if (ctx.mounted) Navigator.pop(ctx);
              
              final updatedProfile = currentProfile.copyWith(
                name: nameCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                email: emailCtrl.text.trim(),
                designation: desigCtrl.text.trim(),
                employeeId: empIdCtrl.text.trim(),
                officeLocation: officeCtrl.text.trim(),
                education: eduCtrl.text.trim(),
                address: addressCtrl.text.trim(),
              );
              
              onUpdate(updatedProfile);

              if (context.mounted) {
                // Do not pop context here to keep the bottom sheet open
                AppDialogs.showSuccessDialog(context, message: 'PA Profile updated successfully!');
                onRefresh?.call(); // Refresh the list
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }
}
