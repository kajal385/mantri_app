import 'package:mantri_app/core/utils/app_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/app_models.dart';
import '../../../core/services/api_service.dart';

final departmentsProvider = FutureProvider.autoDispose<List<Department>>((ref) {
  return ref.watch(apiServiceProvider).getDepartments(status: true);
});

final officialsProvider = FutureProvider.autoDispose<List<Official>>((ref) {
  return ref.watch(apiServiceProvider).getOfficials(status: true);
});

class OfficialsScreen extends ConsumerWidget {
  const OfficialsScreen({super.key});

  Future<void> _makePhoneCall(String phoneNumber, BuildContext context) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (context.mounted) {
        AppDialogs.showErrorDialog(context, userMessage: 'Could not launch dialer');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final officialsAsync = ref.watch(officialsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Government Officials'),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
      ),
      body: officialsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (officials) {
          if (officials.isEmpty) {
            return const Center(child: Text('No officials found.'));
          }

          // Group by department name
          final Map<String, List<Official>> grouped = {};
          for (var o in officials) {
            final deptName = o.department?.name ?? 'Other';
            if (!grouped.containsKey(deptName)) {
              grouped[deptName] = [];
            }
            grouped[deptName]!.add(o);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: grouped.length,
            itemBuilder: (context, index) {
              final deptName = grouped.keys.elementAt(index);
              final deptOfficials = grouped[deptName]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      deptName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                  ...deptOfficials.map((official) => Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange.shade100,
                            child: Icon(Icons.person, color: Colors.orange.shade800),
                          ),
                          title: Text(
                            official.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (official.designation != null && official.designation!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(official.designation!),
                                ),
                              if (official.phone != null && official.phone!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(official.phone!),
                                ),
                            ],
                          ),
                          trailing: official.phone != null && official.phone!.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.phone, color: Colors.green),
                                  onPressed: () => _makePhoneCall(official.phone!, context),
                                )
                              : null,
                        ),
                      )),
                  const SizedBox(height: 16),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
