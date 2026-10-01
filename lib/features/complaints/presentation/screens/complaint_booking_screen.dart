import 'package:mantri_app/core/utils/app_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mantri_app/core/services/firebase_service.dart';
import 'package:mantri_app/core/services/api_service.dart';
import 'package:mantri_app/features/complaints/complaints_provider.dart';
import 'package:mantri_app/core/models/app_models.dart';
import 'package:mantri_app/features/auth/presentation/screens/role_wrapper.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ComplaintBookingScreen extends ConsumerStatefulWidget {
  const ComplaintBookingScreen({super.key});

  @override
  ConsumerState<ComplaintBookingScreen> createState() => _ComplaintBookingScreenState();
}

class _ComplaintBookingScreenState extends ConsumerState<ComplaintBookingScreen> {
  final _descController = TextEditingController();
  final _locController = TextEditingController();
  String _selectedCategory = 'Infrastructure';
  File? _imageFile;
  bool _isLoading = false;

  final List<String> _categories = [
    'Infrastructure',
    'Electricity',
    'Water Supply',
    'Health & Hygiene',
    'Education',
    'Other'
  ];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image != null) {
      setState(() => _imageFile = File(image.path));
    }
  }

  Future<void> _submit() async {
    final user = ref.read(userDataProvider).value;
    if (user == null) return;
    if (_descController.text.trim().isEmpty) {
      AppDialogs.showErrorDialog(context, userMessage: 'Please enter a description');
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageUrl;
      if (_imageFile != null) {
        imageUrl = await ref.read(firestoreServiceProvider).uploadImage(
          _imageFile!,
          'complaints/${user.uid}',
        );
      }

      final complaint = Complaint(
        id: '',
        userId: user.uid,
        userName: user.name,
        category: _selectedCategory,
        description: _descController.text.trim(),
        location: _locController.text.trim(),
        status: 'pending',
        createdAt: DateTime.now(),
        imageUrl: imageUrl,
      );

      await ref.read(apiServiceProvider).addComplaint(complaint);
      ref.invalidate(complaintsProvider);
      
      if (mounted) {
        await AppDialogs.showSuccessDialog(context, message: 'Complaint submitted successfully!');
        if (mounted) context.pop();
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showErrorDialog(context, technicalError: e);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post a Complaint')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('What is the issue about?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  onChanged: (val) => setState(() => _selectedCategory = val!),
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Describe the issue in detail...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Location / Landmark', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: _locController,
              decoration: InputDecoration(
                hintText: 'Where is this issue located?',
                prefixIcon: const Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Attach Photo (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                ),
                child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.file(_imageFile!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.grey.shade600),
                          const SizedBox(height: 8),
                          Text('Tap to add a photo', style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDB7E20),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Complaint', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
