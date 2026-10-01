import 'package:mantri_app/core/utils/app_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mantri_app/core/services/api_service.dart';
import 'package:mantri_app/features/appointment/providers/appointment_issues_provider.dart';

class ManageIssuesScreen extends ConsumerStatefulWidget {
  const ManageIssuesScreen({super.key});

  @override
  ConsumerState<ManageIssuesScreen> createState() => _ManageIssuesScreenState();
}

class _ManageIssuesScreenState extends ConsumerState<ManageIssuesScreen> {
  final _issueController = TextEditingController();

  @override
  void dispose() {
    _issueController.dispose();
    super.dispose();
  }

  Future<void> _addIssue() async {
    final issueName = _issueController.text.trim();
    if (issueName.isEmpty) return;

    try {
      await ref.read(apiServiceProvider).addAppointmentIssue(issueName);
      ref.invalidate(appointmentIssuesProvider);
      _issueController.clear();
      if (mounted) {
        AppDialogs.showSuccessDialog(
          context,
          message: 'Issue added successfully',
        );
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showErrorDialog(context, technicalError: e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const saffron = Color(0xFFDB7E20);
    final issuesAsync = ref.watch(appointmentIssuesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Appointment Issues')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _issueController,
                    decoration: const InputDecoration(
                      labelText: 'New Issue / Purpose',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _addIssue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: saffron,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 24,
                    ),
                  ),
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Existing Issues',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: issuesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error:
                    (err, stack) => Center(
                      child: Text(
                        'Error: $err',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                data: (issues) {
                  return ListView.builder(
                    itemCount: issues.length,
                    itemBuilder: (context, index) {
                      return Card(
                        child: ListTile(
                          title: Text(issues[index]),
                          leading: const Icon(Icons.label, color: saffron),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
