import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mantri_app/core/services/api_service.dart';
import 'package:mantri_app/features/complaints/complaints_provider.dart';
import 'package:mantri_app/core/models/app_models.dart';

final complaintStatusFilterProvider = StateProvider<String>((ref) => 'all');

class GrievanceManagementScreen extends ConsumerWidget {
  const GrievanceManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complaintsAsync = ref.watch(complaintsProvider);
    final selectedFilter = ref.watch(complaintStatusFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Grievances'),
        backgroundColor: const Color.fromARGB(255, 219, 126, 32),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter by Status',
            onSelected: (val) {
              ref.read(complaintStatusFilterProvider.notifier).state = val;
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'all',
                child: Row(
                  children: [
                    Icon(Icons.list, color: selectedFilter == 'all' ? const Color(0xFFDB7E20) : Colors.grey),
                    const SizedBox(width: 8),
                    Text('All', style: TextStyle(fontWeight: selectedFilter == 'all' ? FontWeight.bold : FontWeight.normal)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'pending',
                child: Row(
                  children: [
                    Icon(Icons.pending, color: selectedFilter == 'pending' ? Colors.orange : Colors.grey),
                    const SizedBox(width: 8),
                    Text('Pending', style: TextStyle(fontWeight: selectedFilter == 'pending' ? FontWeight.bold : FontWeight.normal)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'in progress',
                child: Row(
                  children: [
                    Icon(Icons.sync, color: selectedFilter == 'in progress' ? Colors.blue : Colors.grey),
                    const SizedBox(width: 8),
                    Text('In Process', style: TextStyle(fontWeight: selectedFilter == 'in progress' ? FontWeight.bold : FontWeight.normal)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'resolved',
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: selectedFilter == 'resolved' ? Colors.green : Colors.grey),
                    const SizedBox(width: 8),
                    Text('Resolved', style: TextStyle(fontWeight: selectedFilter == 'resolved' ? FontWeight.bold : FontWeight.normal)),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(complaintsProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(complaintsProvider),
        child: complaintsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (complaints) {
            final filteredComplaints = complaints.where((c) {
              if (selectedFilter == 'all') return true;
              return c.status.toLowerCase() == selectedFilter.toLowerCase();
            }).toList();

            if (filteredComplaints.isEmpty) {
              return Center(
                child: Text(
                  selectedFilter == 'all'
                      ? 'No complaints filed yet.'
                      : 'No ${selectedFilter.toLowerCase()} grievances found.',
                  style: const TextStyle(fontSize: 15, color: Colors.grey),
                ),
              );
            }

            return ListView.builder(
              itemCount: filteredComplaints.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final complaint = filteredComplaints[index];
                return _ComplaintManagementCard(complaint: complaint);
              },
            );
          },
        ),
      ),
    );
  }
}

class _ComplaintManagementCard extends ConsumerWidget {
  final Complaint complaint;
  const _ComplaintManagementCard({required this.complaint});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusLower = complaint.status.toLowerCase();
    final Color statusColor = statusLower == 'resolved'
        ? Colors.green
        : (statusLower == 'in progress' || statusLower == 'in_process' ? Colors.blue : Colors.orange);

    final displayStatus = statusLower == 'in progress' || statusLower == 'in_process'
        ? 'IN PROCESS'
        : complaint.status.toUpperCase();

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
                    complaint.userName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Change Status',
                  onSelected: (String newStatus) async {
                    if (newStatus != statusLower) {
                      await ref
                          .read(apiServiceProvider)
                          .updateComplaintStatus(complaint.id, newStatus);
                      ref.invalidate(complaintsProvider);
                    }
                  },
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  itemBuilder: (context) => [
                    const PopupMenuItem<String>(
                      value: 'pending',
                      child: Row(
                        children: [
                          Icon(Icons.pending, color: Colors.orange, size: 18),
                          SizedBox(width: 8),
                          Text('Pending',
                              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.orange)),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'in progress',
                      child: Row(
                        children: [
                          Icon(Icons.sync, color: Colors.blue, size: 18),
                          SizedBox(width: 8),
                          Text('In Process',
                              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue)),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'resolved',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 18),
                          SizedBox(width: 8),
                          Text('Resolved',
                              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green)),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withValues(alpha: 0.4), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusLower == 'resolved'
                              ? Icons.check_circle
                              : (statusLower == 'in progress' || statusLower == 'in_process'
                                  ? Icons.sync
                                  : Icons.pending),
                          size: 14,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          displayStatus,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.arrow_drop_down, size: 18, color: statusColor),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Category: ${complaint.category}',
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color.fromARGB(255, 219, 126, 32))),
            const SizedBox(height: 4),
            Text(complaint.description, style: const TextStyle(color: Colors.black87)),
            if (complaint.imageUrl != null && complaint.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  complaint.imageUrl!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(),
                ),
              ),
            ],
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(complaint.location,
                        style: const TextStyle(color: Colors.grey, fontSize: 12))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

