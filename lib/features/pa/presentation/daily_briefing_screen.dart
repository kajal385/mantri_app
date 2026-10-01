import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/models/app_models.dart';
import '../pa_providers.dart';
import '../../appointment/appointments_provider.dart';
import '../../complaints/complaints_provider.dart';

class DailyBriefingScreen extends ConsumerWidget {
  const DailyBriefingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const saffron = Color.fromARGB(255, 219, 126, 32);
    const darkBlue = Color(0xFF1B3B5A);

    final appointmentsAsync = ref.watch(appointmentsProvider);
    final complaintsAsync = ref.watch(complaintsProvider);
    final messagesAsync = ref.watch(messagesProvider);

    final now = DateTime.now();
    final todayStr = DateFormat('EEEE, dd MMMM yyyy').format(now);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: saffron,
        foregroundColor: Colors.white,
        title: Text(
          'Daily MP Briefing',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(appointmentsProvider);
              ref.invalidate(complaintsProvider);
              ref.invalidate(messagesProvider);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            _buildExecutiveHeader(todayStr, darkBlue, saffron),
            const SizedBox(height: 20),

            // Statistics Grid
            _buildBriefingStatsGrid(
              ref,
              appointmentsAsync,
              complaintsAsync,
              messagesAsync,
              saffron,
            ),
            const SizedBox(height: 24),

            // Sections
            Text(
              "Today's Appointments",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: darkBlue,
              ),
            ),
            const SizedBox(height: 8),
            _buildTodayAppointmentsSection(context, ref, appointmentsAsync, saffron),
            const SizedBox(height: 24),

            Text(
              "Urgent & High-Priority Matters",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade900,
              ),
            ),
            const SizedBox(height: 8),
            _buildUrgentMattersSection(
              context,
              ref,
              appointmentsAsync,
              complaintsAsync,
              messagesAsync,
            ),
            const SizedBox(height: 24),

            Text(
              "Important Messages & Grievances",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: darkBlue,
              ),
            ),
            const SizedBox(height: 8),
            _buildMessagesAndGrievancesSection(
              context,
              ref,
              complaintsAsync,
              messagesAsync,
              saffron,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildExecutiveHeader(
    String dateStr,
    Color darkColor,
    Color accentColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [darkColor, const Color(0xFF2E3349)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HON. MEMBER OF PARLIAMENT',
            style: GoogleFonts.poppins(
              color: accentColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Anup Dhotre Briefing Desk',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dateStr,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildBriefingStatsGrid(
    WidgetRef ref,
    AsyncValue<List<Appointment>> appts,
    AsyncValue<List<Complaint>> complaints,
    AsyncValue<List<CitizenMessage>> messages,
    Color saffron,
  ) {
    int todayApptCount = 0;
    int pendingGrievanceCount = 0;
    int urgentCount = 0;

    final now = DateTime.now();

    appts.whenData((list) {
      todayApptCount =
          list.where((a) {
            return a.date.year == now.year &&
                a.date.month == now.month &&
                a.date.day == now.day &&
                a.status.toLowerCase() != 'rejected';
          }).length;
      urgentCount +=
          list
              .where(
                (a) =>
                    a.priority.toLowerCase() == 'high' &&
                    a.status.toLowerCase() == 'pending',
              )
              .length;
    });

    complaints.whenData((list) {
      pendingGrievanceCount =
          list.where((c) => c.status.toLowerCase() == 'pending').length;
      urgentCount +=
          list
              .where(
                (c) =>
                    c.priority.toLowerCase() == 'high' &&
                    c.status.toLowerCase() == 'pending',
              )
              .length;
    });

    messages.whenData((list) {
      urgentCount +=
          list
              .where(
                (m) =>
                    m.priority.toLowerCase() == 'high' &&
                    m.status.toLowerCase() == 'pending',
              )
              .length;
    });

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _briefingStatCard(
          "Today's Appointments",
          '$todayApptCount',
          Icons.calendar_month,
          Colors.purple,
        ),
        _briefingStatCard(
          "Pending Grievances",
          '$pendingGrievanceCount',
          Icons.gavel,
          Colors.red,
        ),
        _briefingStatCard(
          "Urgent Actions Due",
          '$urgentCount',
          Icons.warning_amber_rounded,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _briefingStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayAppointmentsSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Appointment>> appointmentsAsync,
    Color themeColor,
  ) {
    final now = DateTime.now();
    return appointmentsAsync.when(
      loading: () => const Center(child: LinearProgressIndicator()),
      error: (_, __) => const Text('Error loading today appointments'),
      data: (list) {
        final todayList =
            list.where((a) {
              return a.date.year == now.year &&
                  a.date.month == now.month &&
                  a.date.day == now.day &&
                  a.status.toLowerCase() != 'rejected';
            }).toList();

        if (todayList.isEmpty) {
          return _emptySectionCard('No appointments scheduled for today.');
        }

        return Column(
          children:
              todayList.map((a) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    onTap: () {
                      _showBriefingDetailSheet(
                        context,
                        'Appointment',
                        a.userName,
                        a.issue,
                        themeColor,
                        a.time,
                      );
                    },
                    leading: CircleAvatar(
                      backgroundColor: themeColor.withOpacity(0.1),
                      foregroundColor: themeColor,
                      child: const Icon(Icons.access_time, size: 20),
                    ),
                    title: Text(
                      a.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(
                      a.issue,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Text(
                      a.time,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: themeColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }).toList(),
        );
      },
    );
  }

  Widget _buildUrgentMattersSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Appointment>> appts,
    AsyncValue<List<Complaint>> complaints,
    AsyncValue<List<CitizenMessage>> messages,
  ) {
    final List<Widget> urgentWidgets = [];

    appts.whenData((list) {
      final highAppts =
          list
              .where(
                (a) =>
                    a.priority.toLowerCase() == 'high' &&
                    a.status.toLowerCase() == 'pending',
              )
              .toList();
      for (final a in highAppts) {
        urgentWidgets.add(
          _buildUrgentItemCard(
            context,
            'Appointment Request',
            a.userName,
            a.issue,
            Colors.purple,
          ),
        );
      }
    });

    complaints.whenData((list) {
      final highComplaints =
          list
              .where(
                (c) =>
                    c.priority.toLowerCase() == 'high' &&
                    c.status.toLowerCase() == 'pending',
              )
              .toList();
      for (final c in highComplaints) {
        urgentWidgets.add(
          _buildUrgentItemCard(
            context,
            'Grievance Filed',
            c.userName,
            c.description,
            Colors.red,
          ),
        );
      }
    });

    messages.whenData((list) {
      final highMessages =
          list
              .where(
                (m) =>
                    m.priority.toLowerCase() == 'high' &&
                    m.status.toLowerCase() == 'pending',
              )
              .toList();
      for (final m in highMessages) {
        urgentWidgets.add(
          _buildUrgentItemCard(
            context,
            'Important Message',
            m.userName,
            '${m.subject}: ${m.body}',
            Colors.blue,
          ),
        );
      }
    });

    if (urgentWidgets.isEmpty) {
      return _emptySectionCard('No high-priority or urgent matters pending.');
    }

    return Column(children: urgentWidgets);
  }

  Widget _buildUrgentItemCard(
    BuildContext context,
    String typeLabel,
    String name,
    String detail,
    Color typeColor,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.red.withOpacity(0.3), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        onTap: () {
          _showBriefingDetailSheet(
            context,
            typeLabel,
            name,
            detail,
            typeColor,
            'High Priority',
          );
        },
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                typeLabel,
                style: TextStyle(
                  color: typeColor,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Spacer(),
            const Text(
              'HIGH PRIORITY',
              style: TextStyle(
                color: Colors.red,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessagesAndGrievancesSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Complaint>> complaintsAsync,
    AsyncValue<List<CitizenMessage>> messagesAsync,
    Color themeColor,
  ) {
    final List<Widget> listWidgets = [];

    complaintsAsync.whenData((list) {
      final pendingG =
          list.where((c) => c.status.toLowerCase() == 'pending').toList();
      for (final c in pendingG) {
        listWidgets.add(
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              onTap: () {
                _showBriefingDetailSheet(
                  context,
                  'Grievance',
                  c.userName,
                  '${c.category} - ${c.description}',
                  Colors.red,
                  DateFormat('dd MMM yyyy').format(c.createdAt),
                );
              },
              leading: const Icon(Icons.gavel, color: Colors.red),
              title: Text(
                c.userName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              subtitle: Text(
                'Grievance: ${c.category} - ${c.description}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        );
      }
    });

    messagesAsync.whenData((list) {
      final pendingM =
          list.where((m) => m.status.toLowerCase() == 'pending').toList();
      for (final m in pendingM) {
        listWidgets.add(
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              onTap: () {
                _showBriefingDetailSheet(
                  context,
                  'Important Message',
                  m.userName,
                  '${m.subject}\n\n${m.body}',
                  Colors.blue,
                  DateFormat('dd MMM yyyy').format(m.createdAt),
                );
              },
              leading: const Icon(Icons.message, color: Colors.blue),
              title: Text(
                m.userName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              subtitle: Text(
                'Message: ${m.subject} - ${m.body}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        );
      }
    });

    if (listWidgets.isEmpty) {
      return _emptySectionCard('No pending grievances or messages.');
    }

    return Column(
      children: listWidgets.take(5).toList(),
    ); // Limits to recent 5 items
  }

  Widget _emptySectionCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 13),
        ),
      ),
    );
  }

  void _showBriefingDetailSheet(
    BuildContext context,
    String type,
    String name,
    String detail,
    Color themeColor, [
    String? dateStr,
  ]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollCtrl,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      type.toUpperCase(),
                      style: GoogleFonts.poppins(
                        color: themeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (dateStr != null) ...[
                    const Spacer(),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'From: $name',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1B3B5A),
                ),
              ),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                detail,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
