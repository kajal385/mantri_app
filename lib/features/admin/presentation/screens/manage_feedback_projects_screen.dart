import 'package:mantri_app/core/utils/app_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mantri_app/core/services/api_service.dart';
import 'package:mantri_app/features/feedback/providers/feedback_project_categories_provider.dart';

class ManageFeedbackProjectsScreen extends ConsumerStatefulWidget {
  const ManageFeedbackProjectsScreen({super.key});

  @override
  ConsumerState<ManageFeedbackProjectsScreen> createState() =>
      _ManageFeedbackProjectsScreenState();
}

class _ManageFeedbackProjectsScreenState
    extends ConsumerState<ManageFeedbackProjectsScreen> {
  final _categoryController = TextEditingController();

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _addCategory() async {
    final name = _categoryController.text.trim();
    if (name.isEmpty) return;

    try {
      await ref.read(apiServiceProvider).addFeedbackProjectCategory(name);
      ref.invalidate(feedbackProjectCategoriesProvider);
      _categoryController.clear();
      if (mounted) {
        AppDialogs.showErrorDialog(context, userMessage: 'Project category added successfully');
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showErrorDialog(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const saffron = Color(0xFFDB7E20);
    final categoriesAsync = ref.watch(feedbackProjectCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Feedback Projects'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _categoryController,
                    decoration: const InputDecoration(
                      labelText: 'New Project Category',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _addCategory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: saffron,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 24),
                  ),
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Existing Project Categories',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: categoriesAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(
                    child: Text('Error: $err',
                        style: const TextStyle(color: Colors.red))),
                data: (categories) {
                  return ListView.builder(
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      return Card(
                        child: ListTile(
                          title: Text(categories[index]),
                          leading:
                              const Icon(Icons.folder, color: saffron),
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
