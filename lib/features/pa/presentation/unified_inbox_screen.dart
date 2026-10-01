import 'package:mantri_app/core/utils/app_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/models/app_models.dart';
import '../../../core/services/api_service.dart';
import '../pa_providers.dart';
import '../../appointment/appointments_provider.dart';
import '../../complaints/complaints_provider.dart';

class UnifiedInboxScreen extends ConsumerStatefulWidget {
  const UnifiedInboxScreen({super.key});

  @override
  ConsumerState<UnifiedInboxScreen> createState() => _UnifiedInboxScreenState();
}

class _UnifiedInboxScreenState extends ConsumerState<UnifiedInboxScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedType = 'all'; // all, appointment, complaint, message
  String _selectedPriority = 'all'; // all, High, Medium, Low
  String _selectedStatus = 'all'; // all, pending, approved, rejected, resolved, in progress, follow-up due, overdue, escalated

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const saffron = Color.fromARGB(255, 219, 126, 32);
    final inboxAsync = ref.watch(unifiedInboxProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: saffron,
        foregroundColor: Colors.white,
        title: Text(
          'Unified Inbox',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(appointmentsProvider);
              ref.invalidate(complaintsProvider);
              ref.invalidate(messagesProvider);
              ref.invalidate(unifiedInboxProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filters Panel
          _buildSearchAndFilters(saffron),
          
          // Inbox List
          Expanded(
            child: inboxAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: saffron)),
              error: (err, stack) => Center(child: Text('Error loading inbox: $err')),
              data: (items) {
                // Apply filters
                final filtered = items.where((item) {
                  // Search check
                  final nameMatch = item.citizenName.toLowerCase().contains(_searchQuery.toLowerCase());
                  final categoryMatch = item.category.toLowerCase().contains(_searchQuery.toLowerCase());
                  
                  String detailText = '';
                  if (item.originalItem is Appointment) {
                    detailText = (item.originalItem as Appointment).issue;
                  } else if (item.originalItem is Complaint) {
                    detailText = (item.originalItem as Complaint).description;
                  } else if (item.originalItem is CitizenMessage) {
                    detailText = (item.originalItem as CitizenMessage).body;
                  }
                  final detailMatch = detailText.toLowerCase().contains(_searchQuery.toLowerCase());

                  if (_searchQuery.isNotEmpty && !nameMatch && !categoryMatch && !detailMatch) {
                    return false;
                  }

                  // Type check
                  if (_selectedType != 'all' && item.type != _selectedType) {
                    return false;
                  }

                  // Priority check
                  if (_selectedPriority != 'all' && item.priority.toLowerCase() != _selectedPriority.toLowerCase()) {
                    return false;
                  }

                  // Status check
                  if (_selectedStatus != 'all') {
                    if (_selectedStatus == 'escalated') {
                      bool isEsc = false;
                      if (item.originalItem is Appointment) isEsc = (item.originalItem as Appointment).isEscalated;
                      else if (item.originalItem is Complaint) isEsc = (item.originalItem as Complaint).isEscalated;
                      else if (item.originalItem is CitizenMessage) isEsc = (item.originalItem as CitizenMessage).isEscalated;
                      if (!isEsc) return false;
                    } else if (item.status.toLowerCase() != _selectedStatus.toLowerCase()) {
                      return false;
                    }
                  }

                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'No items match your filters.',
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
                    final item = filtered[index];
                    return _buildInboxCard(context, item, saffron);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(Color themeColor) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // Search Field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search citizen name, issue, subject...',
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
                borderSide: BorderSide(color: themeColor),
              ),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
          ),
          const SizedBox(height: 10),
          
          // Horizontal filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Type Dropdown
                _buildFilterDropdown(
                  label: 'Type',
                  value: _selectedType,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Types')),
                    DropdownMenuItem(value: 'appointment', child: Text('Appointments')),
                    DropdownMenuItem(value: 'complaint', child: Text('Grievances')),
                    DropdownMenuItem(value: 'message', child: Text('Messages')),
                  ],
                  onChanged: (val) => setState(() => _selectedType = val!),
                ),
                const SizedBox(width: 8),

                // Priority Dropdown
                _buildFilterDropdown(
                  label: 'Priority',
                  value: _selectedPriority,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Priorities')),
                    DropdownMenuItem(value: 'High', child: Text('High')),
                    DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'Low', child: Text('Low')),
                  ],
                  onChanged: (val) => setState(() => _selectedPriority = val!),
                ),
                const SizedBox(width: 8),

                // Status Dropdown
                _buildFilterDropdown(
                  label: 'Status',
                  value: _selectedStatus,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Statuses')),
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'approved', child: Text('Approved')),
                    DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                    DropdownMenuItem(value: 'in progress', child: Text('In Process')),
                    DropdownMenuItem(value: 'escalated', child: Text('Escalated')),
                  ],
                  onChanged: (val) => setState(() => _selectedStatus = val!),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items,
          onChanged: onChanged,
          style: GoogleFonts.poppins(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w500),
          icon: const Icon(Icons.arrow_drop_down, size: 18),
        ),
      ),
    );
  }

  Widget _buildInboxCard(BuildContext context, InboxItem item, Color themeColor) {
    Color typeColor;
    IconData typeIcon;
    String typeLabel = '';

    switch (item.type) {
      case 'appointment':
        typeColor = Colors.purple;
        typeIcon = Icons.calendar_month;
        typeLabel = 'Appointment';
        break;
      case 'complaint':
        typeColor = Colors.red;
        typeIcon = Icons.gavel;
        typeLabel = 'Grievance';
        break;
      default:
        typeColor = Colors.blue;
        typeIcon = Icons.message;
        typeLabel = 'Message';
    }

    Color priorityColor;
    switch (item.priority.toLowerCase()) {
      case 'high':
        priorityColor = Colors.red;
        break;
      case 'medium':
        priorityColor = Colors.orange;
        break;
      default:
        priorityColor = Colors.grey;
    }

    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(item.dateTime);

    bool isEscalated = false;
    if (item.originalItem is Appointment) isEscalated = (item.originalItem as Appointment).isEscalated;
    else if (item.originalItem is Complaint) isEscalated = (item.originalItem as Complaint).isEscalated;
    else if (item.originalItem is CitizenMessage) isEscalated = (item.originalItem as CitizenMessage).isEscalated;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () => _showItemDetailsBottomSheet(context, item, themeColor),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Type badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(typeIcon, color: typeColor, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          typeLabel,
                          style: GoogleFonts.poppins(
                            color: typeColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Priority badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: priorityColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      '${item.priority} Priority',
                      style: GoogleFonts.poppins(
                        color: priorityColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Subject / Category
              Text(
                item.category,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1B3B5A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Citizen Name
              Row(
                children: [
                  Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text(
                    item.citizenName,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              const Divider(),
              const SizedBox(height: 4),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Date
                  Text(
                    dateStr,
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
                  ),

                  // Status
                  Row(
                    children: [
                      if (isEscalated) ...[
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade900,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'ESCALATED',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getStatusColor(item.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          item.status.toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(item.status),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'resolved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'in progress':
      case 'in_process':
        return Colors.blue;
      case 'follow-up due':
        return Colors.amber.shade800;
      case 'overdue':
        return Colors.redAccent;
      case 'escalated':
        return Colors.red.shade900;
      default:
        return Colors.orange;
    }
  }

  void _showItemDetailsBottomSheet(BuildContext context, InboxItem item, Color themeColor) {
    // Determine details
    String details = '';
    String subDetails = '';
    String phone = '';
    DateTime? followUpDate;
    DateTime? reminderDate;
    bool isEscalated = false;
    String escalatedTo = '';

    if (item.originalItem is Appointment) {
      final a = item.originalItem as Appointment;
      details = a.issue;
      phone = a.phone ?? 'No phone provided';
      subDetails = 'Scheduled Time: ${a.time}';
      followUpDate = a.followUpDate;
      reminderDate = a.reminderDate;
      isEscalated = a.isEscalated;
      escalatedTo = a.escalatedTo ?? '';
    } else if (item.originalItem is Complaint) {
      final c = item.originalItem as Complaint;
      details = c.description;
      phone = 'Location: ${c.location}';
      followUpDate = c.followUpDate;
      reminderDate = c.reminderDate;
      isEscalated = c.isEscalated;
      escalatedTo = c.escalatedTo ?? '';
    } else if (item.originalItem is CitizenMessage) {
      final m = item.originalItem as CitizenMessage;
      details = m.body;
      phone = m.phone ?? 'No phone provided';
      subDetails = 'Email: ${m.userEmail}';
      followUpDate = m.followUpDate;
      reminderDate = m.reminderDate;
      isEscalated = m.isEscalated;
      escalatedTo = m.escalatedTo ?? '';
    }

    String selectedStatus = item.status;
    String selectedPriority = item.priority;
    bool isEscalatedState = isEscalated;
    final escToController = TextEditingController(text: escalatedTo);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.8,
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
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Manage Inbox Item',
                            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: themeColor),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 12),

                      // Citizen info
                      Text(
                        item.citizenName,
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      if (phone.isNotEmpty) Text(phone, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600)),
                      if (subDetails.isNotEmpty) Text(subDetails, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600)),
                      const SizedBox(height: 12),

                      // Details Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Category/Subject: ${item.category}',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              details,
                              style: GoogleFonts.poppins(fontSize: 13, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Manage Section
                      Text('Update Status', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ['pending', 'approved', 'resolved', 'in progress', 'follow-up due', 'overdue'].map((status) {
                          final isSelected = selectedStatus.toLowerCase() == status.toLowerCase();
                          return ChoiceChip(
                            label: Text(status.toUpperCase(), style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold)),
                            selected: isSelected,
                            selectedColor: themeColor.withOpacity(0.2),
                            labelStyle: TextStyle(color: isSelected ? themeColor : Colors.black87),
                            onSelected: (val) {
                              if (val) setModalState(() => selectedStatus = status);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Override Priority
                      Text('Override Priority', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      Row(
                        children: ['High', 'Medium', 'Low'].map((priority) {
                          final isSelected = selectedPriority == priority;
                          Color chipColor;
                          if (priority == 'High') chipColor = Colors.red;
                          else if (priority == 'Medium') chipColor = Colors.orange;
                          else chipColor = Colors.grey;

                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(priority),
                              selected: isSelected,
                              selectedColor: chipColor.withOpacity(0.2),
                              labelStyle: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? chipColor : Colors.black87,
                              ),
                              onSelected: (val) {
                                if (val) setModalState(() => selectedPriority = priority);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Follow-up Reminders
                      Text('Follow-up Date & Reminder', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: followUpDate ?? DateTime.now().add(const Duration(days: 1)),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (date != null) {
                                  setModalState(() => followUpDate = date);
                                }
                              },
                              icon: const Icon(Icons.calendar_month, size: 16),
                              label: Text(
                                followUpDate == null
                                    ? 'Set Follow-up'
                                    : DateFormat('dd MMM').format(followUpDate!),
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: reminderDate ?? DateTime.now().add(const Duration(days: 1)),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (date != null) {
                                  setModalState(() => reminderDate = date);
                                }
                              },
                              icon: const Icon(Icons.notifications, size: 16),
                              label: Text(
                                reminderDate == null
                                    ? 'Set Reminder'
                                    : DateFormat('dd MMM').format(reminderDate!),
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Escalation
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Escalate Case', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                          Switch(
                            value: isEscalatedState,
                            activeColor: Colors.red,
                            onChanged: (val) {
                              setModalState(() => isEscalatedState = val);
                            },
                          ),
                        ],
                      ),
                      if (isEscalatedState) ...[
                        const SizedBox(height: 8),
                        TextField(
                          controller: escToController,
                          decoration: InputDecoration(
                            labelText: 'Escalate to (e.g. MP Anup Dhotre, Department)',
                            labelStyle: const TextStyle(fontSize: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),

                      // Save changes button
                      ElevatedButton(
                        onPressed: () async {
                          final api = ref.read(apiServiceProvider);
                          final id = item.id;
                          final followUpMap = {
                            'follow_up_date': followUpDate?.toIso8601String(),
                            'reminder_date': reminderDate?.toIso8601String(),
                            'status': selectedStatus,
                            'is_escalated': isEscalatedState ? 1 : 0,
                            'escalated_to': isEscalatedState ? escToController.text.trim() : null,
                          };

                          try {
                            if (item.type == 'appointment') {
                              if (selectedStatus != item.status) {
                                await api.updateAppointmentStatus(id, selectedStatus);
                              }
                              if (selectedPriority != item.priority) {
                                await api.updateAppointmentPriority(id, selectedPriority);
                              }
                              await api.updateAppointmentFollowUp(id, followUpMap);
                            } else if (item.type == 'complaint') {
                              if (selectedStatus != item.status) {
                                await api.updateComplaintStatus(id, selectedStatus);
                              }
                              if (selectedPriority != item.priority) {
                                await api.updateComplaintPriority(id, selectedPriority);
                              }
                              await api.updateComplaintFollowUp(id, followUpMap);
                            } else if (item.type == 'message') {
                              if (selectedStatus != item.status) {
                                await api.updateMessageStatus(id, selectedStatus);
                              }
                              if (selectedPriority != item.priority) {
                                await api.updateMessagePriority(id, selectedPriority);
                              }
                              await api.updateMessageFollowUp(id, followUpMap);
                            }

                            // Invalidate & refresh
                            ref.invalidate(appointmentsProvider);
                            ref.invalidate(complaintsProvider);
                            ref.invalidate(messagesProvider);
                            ref.invalidate(unifiedInboxProvider);

                            if (context.mounted) {
                              Navigator.pop(context); // Close bottom sheet
                              AppDialogs.showSuccessDialog(context, message: 'Changes saved successfully!');
                            }
                          } catch (e) {
                            if (context.mounted) {
                              AppDialogs.showErrorDialog(context, userMessage: 'Error saving changes:', technicalError: e);
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
                          'Save Changes',
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
