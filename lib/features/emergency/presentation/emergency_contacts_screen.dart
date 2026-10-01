import 'package:mantri_app/core/utils/app_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mantri_app/core/models/app_models.dart';
import 'package:mantri_app/core/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

final emergencyContactsProvider = FutureProvider.autoDispose<List<EmergencyContact>>((ref) {
  return ref.read(apiServiceProvider).getEmergencyContacts();
});

// Color scheme
const _navyBlue = Color(0xFF1B3B5A);
const _saffron = Color(0xFFDB7E20);
const _bgColor = Color(0xFFF5F7FA);

class EmergencyContactsScreen extends ConsumerWidget {
  const EmergencyContactsScreen({super.key});

  Future<void> _callNumber(String phone, BuildContext context) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        AppDialogs.showErrorDialog(context, userMessage: 'Could not call $phone');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(emergencyContactsProvider);

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: Text(
          'Emergency & Important Numbers',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 16),
        ),
        backgroundColor: _navyBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: contactsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: _saffron)),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading contacts', style: GoogleFonts.poppins(color: Colors.red)),
            ],
          ),
        ),
        data: (contacts) {
          if (contacts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.phone_disabled, size: 72, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No emergency contacts available',
                    style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(emergencyContactsProvider.future),
            color: _saffron,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final contact = contacts[index];
                return _EmergencyContactCard(
                  contact: contact,
                  onCall: () => _callNumber(contact.phone, context),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _EmergencyContactCard extends StatelessWidget {
  final EmergencyContact contact;
  final VoidCallback onCall;

  const _EmergencyContactCard({required this.contact, required this.onCall});

  // Return an icon based on the name or department
  IconData _iconForContact(String name) {
    final n = name.toLowerCase();
    if (n.contains('ambulance') || n.contains('medical') || n.contains('hospital')) {
      return Icons.local_hospital;
    } else if (n.contains('police') || n.contains('law')) {
      return Icons.local_police;
    } else if (n.contains('fire')) {
      return Icons.local_fire_department;
    } else if (n.contains('disaster') || n.contains('emergency')) {
      return Icons.warning_amber;
    } else if (n.contains('electric') || n.contains('power')) {
      return Icons.electric_bolt;
    } else if (n.contains('water')) {
      return Icons.water_drop;
    } else {
      return Icons.phone_in_talk;
    }
  }

  Color _colorForContact(String name) {
    final n = name.toLowerCase();
    if (n.contains('ambulance') || n.contains('medical') || n.contains('hospital')) {
      return Colors.red.shade600;
    } else if (n.contains('police') || n.contains('law')) {
      return Colors.blue.shade700;
    } else if (n.contains('fire')) {
      return Colors.deepOrange;
    } else if (n.contains('disaster') || n.contains('emergency')) {
      return Colors.orange.shade700;
    } else {
      return _navyBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForContact(contact.name);
    final icon = _iconForContact(contact.name);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.name,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: _navyBlue,
                    ),
                  ),
                  if (contact.department != null && contact.department!.isNotEmpty)
                    Text(
                      contact.department!,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    contact.phone,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: 1.2,
                    ),
                  ),
                  if (contact.description != null && contact.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        contact.description!,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Call Button
            ElevatedButton.icon(
              onPressed: onCall,
              icon: const Icon(Icons.phone, size: 16),
              label: const Text('Call'),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
