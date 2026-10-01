import 'package:mantri_app/core/utils/app_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/models/app_models.dart';
import '../../../core/services/api_service.dart';
import '../pa_providers.dart';
import '../../appointment/appointments_provider.dart';

class MeetingNotesScreen extends ConsumerStatefulWidget {
  const MeetingNotesScreen({super.key});

  @override
  ConsumerState<MeetingNotesScreen> createState() => _MeetingNotesScreenState();
}

class _MeetingNotesScreenState extends ConsumerState<MeetingNotesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const saffron = Color.fromARGB(255, 219, 126, 32);
    final notesAsync = ref.watch(meetingNotesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: saffron,
        foregroundColor: Colors.white,
        title: Text(
          'Meeting Notes & Minutes',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(meetingNotesProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search notes, participants, decisions, actions...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: saffron),
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
          ),

          // Notes List
          Expanded(
            child: notesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: saffron)),
              error: (err, stack) => Center(child: Text('Error loading notes: $err')),
              data: (notes) {
                // Apply search query filter
                final filtered = notes.where((note) {
                  if (_searchQuery.isEmpty) return true;
                  final q = _searchQuery.toLowerCase();
                  return note.meetingTitle.toLowerCase().contains(q) ||
                      note.participants.toLowerCase().contains(q) ||
                      note.discussionPoints.toLowerCase().contains(q) ||
                      note.decisions.toLowerCase().contains(q) ||
                      note.actionItems.toLowerCase().contains(q);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notes, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'No meeting notes found.',
                          style: GoogleFonts.poppins(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final note = filtered[index];
                    return _buildNoteCard(context, note, saffron);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: saffron,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_comment),
        onPressed: () => _showAddNoteBottomSheet(context, saffron),
      ),
    );
  }

  Widget _buildNoteCard(BuildContext context, MeetingNote note, Color themeColor) {
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(note.meetingDate);
    final followUpStr = note.followUpDate != null ? DateFormat('dd MMM yyyy').format(note.followUpDate!) : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    note.meetingTitle,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1B3B5A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  DateFormat('dd MMM').format(note.meetingDate),
                  style: GoogleFonts.poppins(color: themeColor, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              dateStr,
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 12),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.people_outline, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Participants: ${note.participants}',
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _buildCollapsibleSection('Discussion Points', note.discussionPoints, Icons.notes),
            _buildCollapsibleSection('Decisions', note.decisions, Icons.check_circle_outline),
            _buildCollapsibleSection('Action Items', note.actionItems, Icons.pending_actions),

            if (followUpStr != null) ...[
              const Divider(),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.assignment_late_outlined, size: 14, color: Colors.orange),
                  const SizedBox(width: 6),
                  Text(
                    'Follow-up Date: $followUpStr',
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsibleSection(String title, String content, IconData icon) {
    if (content.isEmpty) return const SizedBox.shrink();
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        leading: Icon(icon, size: 16, color: const Color(0xFF1B3B5A)),
        title: Text(
          title,
          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1B3B5A)),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 36, bottom: 8, right: 16),
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                content,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade800, height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddNoteBottomSheet(BuildContext context, Color themeColor) {
    final titleController = TextEditingController();
    final participantsController = TextEditingController();
    final pointsController = TextEditingController();
    final decisionsController = TextEditingController();
    final actionsController = TextEditingController();
    DateTime meetingDate = DateTime.now();
    DateTime? followUpDate;
    Appointment? selectedAppointment;

    // Fetch approved appointments for linking
    final appointmentsAsync = ref.read(appointmentsProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              maxChildSize: 0.95,
              minChildSize: 0.5,
              builder: (_, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(24),
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Text(
                        'Add Meeting Minutes',
                        style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: themeColor),
                      ),
                      const Divider(),
                      const SizedBox(height: 12),

                      // Optional appointment link
                      appointmentsAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (list) {
                          final approvedList = list.where((a) => a.status.toLowerCase() == 'approved').toList();
                          if (approvedList.isEmpty) return const SizedBox.shrink();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Link to Appointment (Optional)',
                                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<Appointment>(
                                isExpanded: true,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                value: selectedAppointment,
                                items: approvedList.map((a) {
                                  final dateStr = DateFormat('dd MMM').format(a.date);
                                  return DropdownMenuItem<Appointment>(
                                    value: a,
                                    child: Text('[${a.userName}] - $dateStr: ${a.issue}', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setModalState(() {
                                    selectedAppointment = val;
                                    if (val != null) {
                                      titleController.text = 'Meeting: ${val.userName} - ${val.issue}';
                                      participantsController.text = '${val.userName}, Personal Assistant';
                                    }
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                            ],
                          );
                        },
                      ),

                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Meeting Title / Subject'),
                      ),
                      const SizedBox(height: 8),

                      TextField(
                        controller: participantsController,
                        decoration: const InputDecoration(labelText: 'Participants (comma-separated)'),
                      ),
                      const SizedBox(height: 12),

                      // Meeting Date Selection
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Meeting Date/Time:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          TextButton.icon(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: meetingDate,
                                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                lastDate: DateTime.now().add(const Duration(days: 30)),
                              );
                              if (date != null) {
                                setModalState(() => meetingDate = DateTime(date.year, date.month, date.day, meetingDate.hour, meetingDate.minute));
                              }
                            },
                            icon: const Icon(Icons.calendar_month),
                            label: Text(DateFormat('dd MMM yyyy').format(meetingDate)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      TextField(
                        controller: pointsController,
                        decoration: const InputDecoration(labelText: 'Discussion Points'),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 8),

                      TextField(
                        controller: decisionsController,
                        decoration: const InputDecoration(labelText: 'Decisions Taken'),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 8),

                      TextField(
                        controller: actionsController,
                        decoration: const InputDecoration(labelText: 'Action Items'),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),

                      // Follow up date picker
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Follow-up Date (Optional):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          TextButton.icon(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: followUpDate ?? DateTime.now().add(const Duration(days: 7)),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (date != null) {
                                setModalState(() => followUpDate = date);
                              }
                            },
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              followUpDate == null
                                  ? 'Not Set'
                                  : DateFormat('dd MMM yyyy').format(followUpDate!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      ElevatedButton(
                        onPressed: () async {
                          if (titleController.text.trim().isEmpty ||
                              participantsController.text.trim().isEmpty ||
                              pointsController.text.trim().isEmpty ||
                              decisionsController.text.trim().isEmpty ||
                              actionsController.text.trim().isEmpty) {
                            AppDialogs.showErrorDialog(context, userMessage: 'Please fill in all details');
                            return;
                          }

                          final note = MeetingNote(
                            id: '',
                            appointmentId: selectedAppointment?.id,
                            meetingTitle: titleController.text.trim(),
                            meetingDate: meetingDate,
                            participants: participantsController.text.trim(),
                            discussionPoints: pointsController.text.trim(),
                            decisions: decisionsController.text.trim(),
                            actionItems: actionsController.text.trim(),
                            followUpDate: followUpDate,
                            createdAt: DateTime.now(),
                          );

                          try {
                            await ref.read(apiServiceProvider).addMeetingNote(note);
                            ref.invalidate(meetingNotesProvider);
                            if (context.mounted) {
                              Navigator.pop(context); // Close bottom sheet
                              AppDialogs.showSuccessDialog(context, message: 'Minutes of Meeting saved successfully!');
                            }
                          } catch (e) {
                            if (context.mounted) {
                              AppDialogs.showErrorDialog(context, userMessage: 'Failed to save meeting notes:', technicalError: e);
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Save Minutes',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
