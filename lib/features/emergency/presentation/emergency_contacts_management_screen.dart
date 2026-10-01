import 'package:mantri_app/core/utils/app_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mantri_app/core/models/app_models.dart';
import 'package:mantri_app/core/services/api_service.dart';

final allEmergencyContactsProvider = FutureProvider.autoDispose<List<EmergencyContact>>((ref) {
  return ref.read(apiServiceProvider).getEmergencyContacts(allContacts: true);
});

const _navyBlue = Color(0xFF1B3B5A);
const _saffron = Color(0xFFDB7E20);

class EmergencyContactsManagementScreen extends ConsumerWidget {
  const EmergencyContactsManagementScreen({super.key});

  void _showForm(BuildContext context, WidgetRef ref, {EmergencyContact? contact}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EmergencyContactForm(
        contact: contact,
        onSaved: () => ref.invalidate(allEmergencyContactsProvider),
      ),
    );
  }

  Future<void> _deleteContact(BuildContext context, WidgetRef ref, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Contact?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(apiServiceProvider).deleteEmergencyContact(id);
      ref.invalidate(allEmergencyContactsProvider);
      if (context.mounted) {
        AppDialogs.showWarningDialog(context, message: 'Contact deleted');
      }
    } catch (e) {
      if (context.mounted) {
        AppDialogs.showErrorDialog(context, technicalError: e);
      }
    }
  }

  Future<void> _toggleStatus(WidgetRef ref, EmergencyContact contact) async {
    try {
      await ref.read(apiServiceProvider).updateEmergencyContact(
        contact.id,
        {'status': !contact.status},
      );
      ref.invalidate(allEmergencyContactsProvider);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(allEmergencyContactsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'Emergency Contacts',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: _navyBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context, ref),
        backgroundColor: _saffron,
        icon: const Icon(Icons.add),
        label: Text('Add Contact', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
      body: contactsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: _saffron)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (contacts) {
          if (contacts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.phone_disabled, size: 72, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('No contacts yet. Tap + to add one.',
                      style: GoogleFonts.poppins(color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final c = contacts[index];
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  leading: CircleAvatar(
                    backgroundColor: c.status ? _saffron.withAlpha(30) : Colors.grey.shade200,
                    child: Icon(Icons.phone_in_talk,
                        color: c.status ? _saffron : Colors.grey),
                  ),
                  title: Text(c.name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (c.department != null && c.department!.isNotEmpty)
                        Text(c.department!, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      Text(c.phone,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            color: _navyBlue,
                            fontSize: 16,
                          )),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Enable/disable toggle
                      Switch(
                        value: c.status,
                        onChanged: (_) => _toggleStatus(ref, c),
                        activeColor: _saffron,
                      ),
                      // Edit
                      IconButton(
                        icon: const Icon(Icons.edit, color: _navyBlue),
                        onPressed: () => _showForm(context, ref, contact: c),
                      ),
                      // Delete
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteContact(context, ref, c.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ── Add/Edit Form ─────────────────────────────────────────────────────────────

class _EmergencyContactForm extends ConsumerStatefulWidget {
  final EmergencyContact? contact;
  final VoidCallback onSaved;

  const _EmergencyContactForm({this.contact, required this.onSaved});

  @override
  ConsumerState<_EmergencyContactForm> createState() => _EmergencyContactFormState();
}

class _EmergencyContactFormState extends ConsumerState<_EmergencyContactForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _departmentController;
  late final TextEditingController _phoneController;
  late final TextEditingController _descController;
  bool _status = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.contact?.name ?? '');
    _departmentController = TextEditingController(text: widget.contact?.department ?? '');
    _phoneController = TextEditingController(text: widget.contact?.phone ?? '');
    _descController = TextEditingController(text: widget.contact?.description ?? '');
    _status = widget.contact?.status ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _departmentController.dispose();
    _phoneController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final api = ref.read(apiServiceProvider);
      final contact = EmergencyContact(
        id: widget.contact?.id ?? '',
        name: _nameController.text.trim(),
        department: _departmentController.text.trim().isEmpty ? null : _departmentController.text.trim(),
        phone: _phoneController.text.trim(),
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        status: _status,
      );

      if (widget.contact == null) {
        await api.createEmergencyContact(contact);
      } else {
        await api.updateEmergencyContact(widget.contact!.id, contact.toMap());
      }

      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        AppDialogs.showErrorDialog(context, technicalError: e);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  widget.contact == null ? 'Add Emergency Contact' : 'Edit Contact',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: _navyBlue),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.badge)),
                  validator: (v) => (v == null || v.isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _departmentController,
                  decoration: const InputDecoration(labelText: 'Department', border: OutlineInputBorder(), prefixIcon: Icon(Icons.business)),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)),
                  keyboardType: TextInputType.phone,
                  validator: (v) => (v == null || v.isEmpty) ? 'Phone is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder(), prefixIcon: Icon(Icons.notes)),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: Text('Active / Visible to public', style: GoogleFonts.poppins()),
                  value: _status,
                  onChanged: (v) => setState(() => _status = v),
                  activeColor: _saffron,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _saffron,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          widget.contact == null ? 'Add Contact' : 'Update Contact',
                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
