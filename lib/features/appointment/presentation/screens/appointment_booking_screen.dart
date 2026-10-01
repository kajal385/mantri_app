import 'package:mantri_app/core/utils/app_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mantri_app/core/services/firebase_service.dart';
import 'package:mantri_app/core/services/api_service.dart';
import 'package:mantri_app/features/appointment/appointments_provider.dart';
import 'package:mantri_app/features/appointment/providers/appointment_issues_provider.dart';
import 'package:mantri_app/core/models/app_models.dart';
import 'package:mantri_app/features/auth/presentation/screens/role_wrapper.dart';
import 'package:intl/intl.dart';

final nextAvailableSlotsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.read(apiServiceProvider).getNextAvailableSlots();
});

class AppointmentBookingScreen extends ConsumerStatefulWidget {
  final Appointment? existingAppointment;
  const AppointmentBookingScreen({super.key, this.existingAppointment});

  @override
  ConsumerState<AppointmentBookingScreen> createState() =>
      _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends ConsumerState<AppointmentBookingScreen> {
  final _issueController = TextEditingController();
  final _customIssueController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _selectedSlot;
  String? _selectedIssue;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userData = ref.read(userDataProvider).value;
      if (widget.existingAppointment != null) {
        final appt = widget.existingAppointment!;
        _phoneController.text = appt.phone ?? '';
        setState(() {
          _selectedIssue = appt.issue;
          _selectedSlot = appt.time;
        });
      } else if (userData?.phone != null) {
        _phoneController.text = userData!.phone!;
      }
    });
  }

  @override
  void dispose() {
    _issueController.dispose();
    _customIssueController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit(String? dateStr) async {
    final finalIssue = _selectedIssue == 'Other' ? _customIssueController.text.trim() : _selectedIssue;

    if (finalIssue == null || finalIssue.isEmpty || _selectedSlot == null || dateStr == null) {
      AppDialogs.showErrorDialog(context, userMessage: 'Please fill all fields and select a slot');
      return;
    }

    final user = ref.read(laravelUserProvider);
    if (user == null) return;

    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(dateStr);
    } catch (e) {
      parsedDate = DateTime.now();
    }

    final appt = Appointment(
      id: widget.existingAppointment?.id ?? '',
      userId: widget.existingAppointment?.userId ?? user.uid,
      userName: widget.existingAppointment?.userName ?? user.name,
      issue: finalIssue,
      date: parsedDate,
      time: _selectedSlot!,
      status: widget.existingAppointment?.status ?? 'pending',
      phone: _phoneController.text.trim(),
    );

    try {
      if (widget.existingAppointment != null) {
        await ref.read(apiServiceProvider).updateAppointment(appt);
      } else {
        await ref.read(apiServiceProvider).addAppointment(appt);
      }
      ref.invalidate(userAppointmentsProvider);
      ref.invalidate(appointmentsProvider);
      ref.invalidate(nextAvailableSlotsProvider);
      if (mounted) {
        await AppDialogs.showSuccessDialog(context, message: 'Appointment Request Sent!');
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString().replaceFirst('Exception: ', '');
        if (msg.toLowerCase().contains('booked') || msg.toLowerCase().contains('slot')) {
          ref.invalidate(nextAvailableSlotsProvider);
          setState(() {
            _selectedSlot = null;
          });
        }
        AppDialogs.showErrorDialog(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const saffron = Color(0xFFDB7E20);
    final slotsAsync = ref.watch(nextAvailableSlotsProvider);
    final issuesAsync = ref.watch(appointmentIssuesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Book Appointment')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Request a meeting with MP Anup Dhotre',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              issuesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Text('Error loading issues: $err', style: const TextStyle(color: Colors.red)),
                data: (issues) {
                  return Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedIssue,
                        decoration: const InputDecoration(
                          labelText: 'Purpose of Meeting / Issue',
                          border: OutlineInputBorder(),
                        ),
                        items: issues.map((issue) {
                          return DropdownMenuItem<String>(
                            value: issue,
                            child: Text(issue),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedIssue = value;
                          });
                        },
                      ),
                      if (_selectedIssue == 'Other') ...[
                        const SizedBox(height: 16),
                        TextField(
                          controller: _customIssueController,
                          decoration: const InputDecoration(
                            labelText: 'Please specify your issue',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number for Confirmation',
                  hintText: 'Enter 10-digit mobile number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 32),

              slotsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Error loading slots: $err',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                data: (data) {
                  final dateStr = data['date'] as String?;
                  final slots = (data['slots'] as List<dynamic>?)?.cast<String>() ?? [];

                  if (dateStr == null || slots.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Currently no appointments are available.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  DateTime parsedDate = DateTime.now();
                  try {
                    parsedDate = DateTime.parse(dateStr);
                  } catch (_) {}
                  final formattedDate = DateFormat('dd MMMM yyyy').format(parsedDate);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Next Available Date',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: saffron,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Available Slots',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: slots.map((slot) {
                          final isSelected = _selectedSlot == slot;
                          return ChoiceChip(
                            label: Text(slot),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedSlot = selected ? slot : null;
                              });
                            },
                            selectedColor: saffron,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: _selectedSlot == null ? null : () => _submit(dateStr),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: saffron,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade400,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Center(
                          child: Text(
                            'Confirm Appointment',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
