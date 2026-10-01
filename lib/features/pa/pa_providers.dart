import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/app_models.dart';
import '../../core/services/api_service.dart';
import '../appointment/appointments_provider.dart';
import '../complaints/complaints_provider.dart';

// Unified Inbox Item
class InboxItem {
  final String id;
  final String type; // 'appointment', 'complaint', 'message'
  final String category; // Category/Subject
  final String citizenName;
  final String priority; // High, Medium, Low
  final DateTime dateTime;
  final String status; // Pending, Approved, Rejected, Resolved, In Process, etc.
  final dynamic originalItem;

  InboxItem({
    required this.id,
    required this.type,
    required this.category,
    required this.citizenName,
    required this.priority,
    required this.dateTime,
    required this.status,
    required this.originalItem,
  });
}

// ── Messages Provider ────────────────────────────────────────────────────────

final messagesProvider = FutureProvider<List<CitizenMessage>>((ref) async {
  return ref.watch(apiServiceProvider).getMessages();
});



// ── Meeting Notes Provider ────────────────────────────────────────────────────

final meetingNotesProvider = FutureProvider<List<MeetingNote>>((ref) async {
  return ref.watch(apiServiceProvider).getMeetingNotes();
});

// ── Donations Providers ───────────────────────────────────────────────────────

final donationsProvider = FutureProvider<List<Donation>>((ref) async {
  return ref.watch(apiServiceProvider).getDonations();
});

final donationSummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.watch(apiServiceProvider).getDonationSummary();
});

// ── Unified Inbox Provider ───────────────────────────────────────────────────

final unifiedInboxProvider = FutureProvider<List<InboxItem>>((ref) async {
  final appointmentsAsync = ref.watch(appointmentsProvider);
  final complaintsAsync = ref.watch(complaintsProvider);
  final messagesAsync = ref.watch(messagesProvider);

  final List<InboxItem> items = [];

  appointmentsAsync.whenData((appointments) {
    for (final appt in appointments) {
      items.add(InboxItem(
        id: appt.id,
        type: 'appointment',
        category: 'Appointment Booking',
        citizenName: appt.userName,
        priority: appt.priority,
        dateTime: appt.date,
        status: appt.status,
        originalItem: appt,
      ));
    }
  });

  complaintsAsync.whenData((complaints) {
    for (final complaint in complaints) {
      items.add(InboxItem(
        id: complaint.id,
        type: 'complaint',
        category: complaint.category,
        citizenName: complaint.userName,
        priority: complaint.priority,
        dateTime: complaint.createdAt,
        status: complaint.status,
        originalItem: complaint,
      ));
    }
  });

  messagesAsync.whenData((messages) {
    for (final msg in messages) {
      items.add(InboxItem(
        id: msg.id,
        type: 'message',
        category: msg.subject,
        citizenName: msg.userName,
        priority: msg.priority,
        dateTime: msg.createdAt,
        status: msg.status,
        originalItem: msg,
      ));
    }
  });

  // Sort by date-time descending
  items.sort((a, b) => b.dateTime.compareTo(a.dateTime));
  return items;
});
