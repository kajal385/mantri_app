import 'package:mantri_app/core/utils/app_dialogs.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mantri_app/core/services/api_service.dart';
import 'package:mantri_app/core/services/firebase_service.dart';
import 'package:mantri_app/features/projects/projects_provider.dart';
import 'package:mantri_app/core/models/app_models.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  void _showAdminCreator(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _AdminCreateProject(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(laravelUserProvider);
    final bool isAdmin = user?.email == 'gajarekajal2205@gmail.com' || user?.email == 'admin@gmail.com' || user?.role == UserRole.admin;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isAdmin ? 'Admin Console: Projects' : 'Development Showcase'),
          backgroundColor: const Color.fromARGB(255, 219, 126, 32),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Completed Projects'),
              Tab(text: 'Ongoing Projects'),
              Tab(text: 'Upcoming Plans'),
            ],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ref.invalidate(projectsProvider('Completed'));
                ref.invalidate(projectsProvider('Ongoing'));
                ref.invalidate(projectsProvider('Upcoming'));
              },
            ),
          ],
        ),
        body: const TabBarView(
          children: [
            _ProjectList(status: 'Completed'),
            _ProjectList(status: 'Ongoing'),
            _ProjectList(status: 'Upcoming'),
          ],
        ),
        floatingActionButton: isAdmin
            ? FloatingActionButton.extended(
                onPressed: () => _showAdminCreator(context),
                icon: const Icon(Icons.add_business),
                label: const Text('Add New Project'),
                backgroundColor: const Color(0xFFF57C00),
                foregroundColor: Colors.white,
              )
            : null,
      ),
    );
  }
}

class _ProjectList extends ConsumerWidget {
  final String status;
  const _ProjectList({required this.status});

  Future<void> _openMap(String location) async {
    final query = Uri.encodeComponent(location);
    final googleMapsUrl = "https://www.google.com/maps/search/?api=1&query=$query";
    if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
      await launchUrl(Uri.parse(googleMapsUrl));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(laravelUserProvider);
    final bool isAdmin = user?.email == 'gajarekajal2205@gmail.com' || user?.email == 'admin@gmail.com' || user?.role == UserRole.admin;
    final projectsAsync = ref.watch(projectsProvider(status));

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(projectsProvider(status)),
      child: projectsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (projects) {
          if (projects.isEmpty) return Center(child: Text('No $status items to display.'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              final beforeUrl = project.beforeImageUrl;
              final afterUrl = project.afterImageUrl;

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (beforeUrl != null || afterUrl != null)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (beforeUrl != null)
                                Expanded(
                                  child: Stack(
                                    alignment: Alignment.bottomCenter,
                                    children: [
                                      Image.network(beforeUrl, height: 180, width: double.infinity, fit: BoxFit.cover),
                                      Container(
                                        width: double.infinity,
                                        color: Colors.black54,
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: const Text('BEFORE', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                                      )
                                    ],
                                  ),
                                ),
                              if (beforeUrl != null && afterUrl != null)
                                const VerticalDivider(width: 2, color: Colors.white, thickness: 2),
                              if (afterUrl != null)
                                Expanded(
                                  child: Stack(
                                    alignment: Alignment.bottomCenter,
                                    children: [
                                      Image.network(afterUrl, height: 180, width: double.infinity, fit: BoxFit.cover),
                                      Container(
                                        width: double.infinity,
                                        color: Colors.black54,
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: const Text('AFTER', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                                      )
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  project.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1B3B5A)),
                                ),
                              ),
                              if (isAdmin)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Delete Showcase Item?'),
                                        content: const Text('Are you sure you want to permanently delete this project record?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                          ElevatedButton(
                                            onPressed: () async {
                                              await ref.read(apiServiceProvider).deleteProject(project.id);
                                              ref.invalidate(projectsProvider(status));
                                              if (context.mounted) Navigator.pop(ctx);
                                            },
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(project.description, style: TextStyle(color: Colors.grey.shade700, height: 1.4, fontSize: 13)),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildDetailRow(Icons.monetization_on, 'BUDGET', project.budget ?? 'N/A', Colors.green),
                              _buildDetailRow(Icons.calendar_today, 'TIMELINE', project.timeline ?? 'N/A', Colors.orange),
                              InkWell(
                                onTap: project.location != null ? () => _openMap(project.location!) : null,
                                child: _buildDetailRow(Icons.location_on, 'LOCATION', project.location ?? 'N/A', Colors.blue),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _AdminCreateProject extends ConsumerStatefulWidget {
  const _AdminCreateProject();

  @override
  ConsumerState<_AdminCreateProject> createState() => _AdminCreateProjectState();
}

class _AdminCreateProjectState extends ConsumerState<_AdminCreateProject> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _budgetController = TextEditingController();
  final _timelineController = TextEditingController();
  final _locationController = TextEditingController();
  String _selectedStatus = 'Ongoing';
  
  File? _beforeImg;
  File? _afterImg;
  bool _isPublishing = false;

  Future<void> _pickImage(bool isBefore) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      setState(() {
        if (isBefore) _beforeImg = File(picked.path);
        else _afterImg = File(picked.path);
      });
    }
  }

  Future<String?> _uploadToStorage(File file, String pathPrefix) async {
    try {
      return await ref.read(apiServiceProvider).uploadFile(file, 'projects/$pathPrefix');
    } catch (e) {
      return null;
    }
  }

  Future<void> _submit() async {
    if (_titleController.text.isEmpty || _descController.text.isEmpty) {
      AppDialogs.showErrorDialog(context, userMessage: 'Please fill title and description');
      return;
    }

    setState(() => _isPublishing = true);

    try {
      String? beforeUrl;
      String? afterUrl;

      if (_beforeImg != null) beforeUrl = await _uploadToStorage(_beforeImg!, 'before');
      if (_afterImg != null) afterUrl = await _uploadToStorage(_afterImg!, 'after');

      final project = Project(
        id: '',
        title: _titleController.text,
        description: _descController.text,
        budget: _budgetController.text,
        timeline: _timelineController.text,
        location: _locationController.text,
        status: _selectedStatus,
        beforeImageUrl: beforeUrl,
        afterImageUrl: afterUrl,
        createdAt: DateTime.now(),
      );

      await ref.read(apiServiceProvider).addProject(project);
      ref.invalidate(projectsProvider(_selectedStatus));

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      AppDialogs.showErrorDialog(context, technicalError: e);
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Publish New Project', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _imagePicker(true)),
                const SizedBox(width: 12),
                Expanded(child: _imagePicker(false)),
              ],
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(labelText: 'Section / Category', border: OutlineInputBorder()),
              items: ['Completed', 'Ongoing', 'Upcoming'].map((s) => DropdownMenuItem(value: s, child: Text(s == 'Upcoming' ? 'Upcoming Plans' : '$s Projects'))).toList(),
              onChanged: (val) => setState(() => _selectedStatus = val!),
            ),
            const SizedBox(height: 12),
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Project Title', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _descController, maxLines: 3, decoration: const InputDecoration(labelText: 'Project Requirements / Description', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(controller: _budgetController, decoration: const InputDecoration(labelText: 'Budget (e.g. 10 Cr)', border: OutlineInputBorder()))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: _timelineController, decoration: const InputDecoration(labelText: 'Timeline', border: OutlineInputBorder()))),
              ],
            ),
            const SizedBox(height: 12),
            TextField(controller: _locationController, decoration: const InputDecoration(labelText: 'Location / Ward / Village', border: OutlineInputBorder(), suffixIcon: Icon(Icons.location_on))),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isPublishing ? null : _submit,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF57C00), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _isPublishing ? const CircularProgressIndicator(color: Colors.white) : const Text('Publish Showcase Item'),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _imagePicker(bool isBefore) {
    final file = isBefore ? _beforeImg : _afterImg;
    return InkWell(
      onTap: () => _pickImage(isBefore),
      child: Container(
        height: 110,
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
        child: file == null 
          ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, color: isBefore ? Colors.grey : const Color(0xFFF57C00)), const SizedBox(height: 4), Text(isBefore ? 'Before' : 'After', style: const TextStyle(fontSize: 12))])
          : ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(file, fit: BoxFit.cover)),
      ),
    );
  }
}
