import 'package:mantri_app/core/utils/app_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mantri_app/core/services/api_service.dart';
import 'package:mantri_app/features/appointment/appointments_provider.dart';
import 'package:mantri_app/core/models/app_models.dart';
import 'package:url_launcher/url_launcher.dart';

final appointmentStatusFilterProvider = StateProvider<String>((ref) => 'all');

class AppointmentManagementScreen extends ConsumerWidget {
  const AppointmentManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(appointmentsProvider);
    final selectedFilter = ref.watch(appointmentStatusFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Appointments'),
        backgroundColor: const Color.fromARGB(255, 219, 126, 32),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter by Status',
            onSelected: (val) {
              ref.read(appointmentStatusFilterProvider.notifier).state = val;
            },
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: 'all',
                    child: Row(
                      children: [
                        Icon(
                          Icons.list,
                          color:
                              selectedFilter == 'all'
                                  ? const Color(0xFFDB7E20)
                                  : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'All',
                          style: TextStyle(
                            fontWeight:
                                selectedFilter == 'all'
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'pending',
                    child: Row(
                      children: [
                        Icon(
                          Icons.pending,
                          color:
                              selectedFilter == 'pending'
                                  ? Colors.orange
                                  : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Pending',
                          style: TextStyle(
                            fontWeight:
                                selectedFilter == 'pending'
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'approved',
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color:
                              selectedFilter == 'approved'
                                  ? Colors.green
                                  : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Approved',
                          style: TextStyle(
                            fontWeight:
                                selectedFilter == 'approved'
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'rejected',
                    child: Row(
                      children: [
                        Icon(
                          Icons.cancel,
                          color:
                              selectedFilter == 'rejected'
                                  ? Colors.red
                                  : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Rejected',
                          style: TextStyle(
                            fontWeight:
                                selectedFilter == 'rejected'
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(appointmentsProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(appointmentsProvider),
        child: appointmentsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (appts) {
            final filteredAppts =
                appts.where((a) {
                  if (selectedFilter == 'all') return true;
                  return a.status.toLowerCase() == selectedFilter.toLowerCase();
                }).toList();

            if (filteredAppts.isEmpty) {
              return Center(
                child: Text(
                  selectedFilter == 'all'
                      ? 'No appointments found.'
                      : 'No ${selectedFilter.toLowerCase()} appointments found.',
                  style: const TextStyle(fontSize: 15, color: Colors.grey),
                ),
              );
            }
            return ListView.builder(
              itemCount: filteredAppts.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final appt = filteredAppts[index];
                return _AppointmentCard(appt: appt);
              },
            );
          },
        ),
      ),
    );
  }
}

class _AppointmentCard extends ConsumerWidget {
  final Appointment appt;
  const _AppointmentCard({required this.appt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusLower = appt.status.toLowerCase();
    final statusColor =
        statusLower == 'approved'
            ? Colors.green
            : (statusLower == 'rejected' ? Colors.red : Colors.orange);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    appt.userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Change Status',
                  onSelected: (String newStatus) async {
                    if (newStatus != statusLower) {
                      await ref
                          .read(apiServiceProvider)
                          .updateAppointmentStatus(appt.id, newStatus);
                      ref.invalidate(appointmentsProvider);
                    }
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem<String>(
                          value: 'pending',
                          child: Row(
                            children: [
                              Icon(
                                Icons.pending,
                                color: Colors.orange,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Pending',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'approved',
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Approve',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'rejected',
                          child: Row(
                            children: [
                              Icon(Icons.cancel, color: Colors.red, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Reject',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusLower == 'approved'
                              ? Icons.check_circle
                              : (statusLower == 'rejected'
                                  ? Icons.cancel
                                  : Icons.pending),
                          size: 14,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          appt.status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.arrow_drop_down,
                          size: 18,
                          color: statusColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (appt.token != null && appt.token!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'TOKEN: ${appt.token}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF57C00),
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Purpose: ${appt.issue}',
              style: const TextStyle(color: Colors.black87),
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  '${appt.date.day}/${appt.date.month}/${appt.date.year} at ${appt.time}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            if (statusLower == 'approved') ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          () => _sendNotification(context, appt, isSms: false),
                      icon: const Icon(Icons.message, size: 18),
                      label: const Text('WhatsApp'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          () => _sendNotification(context, appt, isSms: true),
                      icon: const Icon(Icons.sms, size: 18),
                      label: const Text('SMS'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E88E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _sendNotification(
    BuildContext context,
    Appointment appt, {
    required bool isSms,
  }) async {
    final phone = appt.phone ?? '';
    if (phone.isEmpty) {
      AppDialogs.showErrorDialog(context, userMessage: 'User phone number is not available.');
      return;
    }

    final message =
        "नमस्कार ${appt.userName},\n\n"
        "आपली भेट निश्चित झाली आहे (Approved).\n"
        "टोकन क्रमांक: ${appt.token ?? ''}\n"
        "दिनांक: ${appt.date.day}/${appt.date.month}/${appt.date.year}\n"
        "वेळ: ${appt.time}\n\n"
        "कार्यालय: खासदार अनुपजी धोत्रे कार्यालय, अकोला.\n"
        "धन्यवाद!";

    final encodedMsg = Uri.encodeComponent(message);

    final whatsappUrl = Uri.parse(
      "whatsapp://send?phone=91$phone&text=$encodedMsg",
    );
    final smsUrl = Uri.parse("sms:91$phone?body=$encodedMsg");

    try {
      if (isSms) {
        if (await canLaunchUrl(smsUrl)) {
          await launchUrl(smsUrl);
        } else {
          if (context.mounted) {
            AppDialogs.showErrorDialog(context, userMessage: 'Could not launch SMS app.');
          }
        }
      } else {
        if (await canLaunchUrl(whatsappUrl)) {
          await launchUrl(whatsappUrl);
        } else {
          final webUrl = Uri.parse("https://wa.me/91$phone?text=$encodedMsg");
          await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      debugPrint("Could not launch $e");
      if (context.mounted) {
        AppDialogs.showErrorDialog(context, userMessage: 'Failed to open app:', technicalError: e);
      }
    }
  }
}
