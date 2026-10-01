import 'package:mantri_app/core/utils/app_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mantri_app/core/services/api_service.dart';
import 'package:mantri_app/core/models/app_models.dart';
import 'package:mantri_app/features/auth/presentation/screens/role_wrapper.dart';
import 'package:mantri_app/features/feedback/providers/feedback_project_categories_provider.dart';
import 'package:go_router/go_router.dart';

class CitizenFeedbackScreen extends ConsumerStatefulWidget {
  const CitizenFeedbackScreen({super.key});

  @override
  ConsumerState<CitizenFeedbackScreen> createState() =>
      _CitizenFeedbackScreenState();
}

class _CitizenFeedbackScreenState
    extends ConsumerState<CitizenFeedbackScreen> {
  final _commentController = TextEditingController();
  final _otherCategoryController = TextEditingController();
  double _rating = 0;
  bool _isLoading = false;
  String? _selectedCategory;

  @override
  void dispose() {
    _commentController.dispose();
    _otherCategoryController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    final user = ref.read(userDataProvider).value;
    if (user == null) return;

    if (_selectedCategory == null) {
      AppDialogs.showErrorDialog(context, userMessage: 'Please select a project category.');
      return;
    }

    final String effectiveCategory = _selectedCategory == 'Other'
        ? (_otherCategoryController.text.trim().isEmpty
            ? 'Other'
            : _otherCategoryController.text.trim())
        : _selectedCategory!;

    if (_rating == 0) {
      AppDialogs.showErrorDialog(context, userMessage: 'Please select a rating.');
      return;
    }

    final feedback = CitizenFeedback(
      id: '',
      userId: user.uid,
      userName: user.name,
      projectCategory: effectiveCategory,
      rating: _rating,
      comment: _commentController.text.trim(),
      createdAt: DateTime.now(),
    );

    setState(() => _isLoading = true);

    try {
      final existingFeedbacks = await ref.read(apiServiceProvider).getFeedbacks();
      final hasSubmitted = existingFeedbacks.any((f) => 
        f.userId == user.uid && f.projectCategory.toLowerCase() == effectiveCategory.toLowerCase()
      );
      
      if (hasSubmitted) {
        if (mounted) {
          AppDialogs.showErrorDialog(context, userMessage: 'You have already submitted feedback for this project.');
          setState(() => _isLoading = false);
        }
        return;
      }

      await ref.read(apiServiceProvider).addFeedback(feedback);

      if (mounted) {
        await AppDialogs.showSuccessDialog(context, message: 'Thank you! Your feedback has been recorded.');
        // Reset form
        setState(() {
          _rating = 0;
          _selectedCategory = null;
        });
        _commentController.clear();
        _otherCategoryController.clear();
        if (mounted) context.pop();
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showErrorDialog(context, userMessage: 'Failed to submit feedback:', technicalError: e);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const saffron = Color(0xFFDB7E20);
    final categoriesAsync = ref.watch(feedbackProjectCategoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Share Feedback')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Project Category',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),

              // Dropdown from API
              categoriesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Text('Error loading categories: $err',
                    style: const TextStyle(color: Colors.red)),
                data: (categories) {
                  // Ensure "Other" is always at the end
                  final allOptions = [...categories];
                  if (!allOptions.contains('Other Project') &&
                      !allOptions.contains('Other')) {
                    allOptions.add('Other');
                  }

                  // Reset if selected item is no longer in list
                  if (_selectedCategory != null &&
                      !allOptions.contains(_selectedCategory)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() => _selectedCategory = null);
                    });
                  }

                  return DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Project Category',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    items: allOptions
                        .map((cat) => DropdownMenuItem<String>(
                              value: cat,
                              child: Text(cat,
                                  overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedCategory = val),
                    validator: (val) =>
                        val == null ? 'Please select a category' : null,
                  );
                },
              ),

              // Show text field if 'Other' is selected
              if (_selectedCategory == 'Other') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _otherCategoryController,
                  decoration: InputDecoration(
                    labelText: 'Please specify your project category',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],

              const SizedBox(height: 30),
              const Text(
                'How satisfied are you?',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: () =>
                        setState(() => _rating = index + 1.0),
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 40,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 30),
              const Text(
                'Your Comments',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _commentController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Share your thoughts on the work done...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitFeedback,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: saffron,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Submit Review',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
