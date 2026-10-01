import 'package:mantri_app/core/utils/app_dialogs.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mantri_app/core/models/app_models.dart';
import 'package:mantri_app/core/services/api_service.dart';

class SocialLinksManagementScreen extends ConsumerStatefulWidget {
  const SocialLinksManagementScreen({super.key});

  @override
  ConsumerState<SocialLinksManagementScreen> createState() => _SocialLinksManagementScreenState();
}

class _SocialLinksManagementScreenState extends ConsumerState<SocialLinksManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _facebookController = TextEditingController();
  final _instagramController = TextEditingController();
  final _xController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadLinks();
  }

  Future<void> _loadLinks() async {
    try {
      final links = await ref.read(apiServiceProvider).getSocialLinks();
      if (links != null) {
        _facebookController.text = links.facebookUrl ?? '';
        _instagramController.text = links.instagramUrl ?? '';
        _xController.text = links.xUrl ?? '';
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showErrorDialog(context, userMessage: 'Error loading links:', technicalError: e);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveLinks() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final links = SocialLinks(
        facebookUrl: _facebookController.text.trim(),
        instagramUrl: _instagramController.text.trim(),
        xUrl: _xController.text.trim(),
      );
      await ref.read(apiServiceProvider).updateSocialLinks(links);
      if (mounted) {
        AppDialogs.showSuccessDialog(context, message: 'Social links updated successfully!');
      }
    } on DioException catch (e) {
      if (mounted) {
        final errMsg = e.message ?? e.error?.toString() ?? 'Unknown error';
        AppDialogs.showErrorDialog(context, userMessage: errMsg, technicalError: e);
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showErrorDialog(context, userMessage: 'Error saving links:', technicalError: e);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }


  @override
  void dispose() {
    _facebookController.dispose();
    _instagramController.dispose();
    _xController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Social Links'),
        backgroundColor: const Color(0xFF1B3B5A),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Update the official social media URLs below. Leave blank to hide the link.',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _facebookController,
                      decoration: const InputDecoration(
                        labelText: 'Facebook URL',
                        prefixIcon: Icon(Icons.facebook, color: Colors.blue),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _instagramController,
                      decoration: const InputDecoration(
                        labelText: 'Instagram URL',
                        prefixIcon: Icon(Icons.camera_alt, color: Colors.pink),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _xController,
                      decoration: const InputDecoration(
                        labelText: 'X (Twitter) URL',
                        prefixIcon: Icon(Icons.alternate_email, color: Colors.black87),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveLinks,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF57C00), // Saffron
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Save Links',
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
