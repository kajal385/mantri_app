import 'package:mantri_app/core/utils/app_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/app_models.dart';
import '../../../core/services/api_service.dart';

final departmentsAdminProvider = FutureProvider.autoDispose<List<Department>>((ref) {
  return ref.watch(apiServiceProvider).getDepartments(); // Get all
});

final officialsAdminProvider = FutureProvider.autoDispose<List<Official>>((ref) {
  return ref.watch(apiServiceProvider).getOfficials(); // Get all
});

class OfficialsManagementScreen extends ConsumerWidget {
  const OfficialsManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text('Manage Officials'),
          backgroundColor: Colors.orange.shade800,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Officials'),
              Tab(text: 'Departments'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _OfficialsList(),
            _DepartmentsList(),
          ],
        ),
      ),
    );
  }
}

// ── Departments Tab ─────────────────────────────────────────────────────────

class _DepartmentsList extends ConsumerWidget {
  const _DepartmentsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deptsAsync = ref.watch(departmentsAdminProvider);

    return Scaffold(
      body: deptsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (departments) {
          if (departments.isEmpty) return const Center(child: Text('No departments.'));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: departments.length,
            itemBuilder: (context, index) {
              final dept = departments[index];
              return Card(
                child: ListTile(
                  title: Text(dept.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: dept.description != null ? Text(dept.description!) : null,
                  trailing: Switch(
                    value: dept.status,
                    onChanged: (val) async {
                      try {
                        await ref.read(apiServiceProvider).updateDepartment(dept.id, {'status': val});
                        ref.invalidate(departmentsAdminProvider);
                      } catch (e) {
                        AppDialogs.showErrorDialog(context, technicalError: e);
                      }
                    },
                  ),
                  onLongPress: () async {
                    try {
                      await ref.read(apiServiceProvider).deleteDepartment(dept.id);
                      ref.invalidate(departmentsAdminProvider);
                    } catch (e) {
                      AppDialogs.showErrorDialog(context, technicalError: e);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDepartmentSheet(context, ref),
        backgroundColor: Colors.orange.shade800,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDepartmentSheet(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16, right: 16, top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Add Department', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder())),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.isEmpty) return;
                  try {
                    await ref.read(apiServiceProvider).createDepartment(
                      Department(id: '', name: nameCtrl.text, description: descCtrl.text, status: true),
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                    ref.invalidate(departmentsAdminProvider);
                  } catch (e) {
                    AppDialogs.showErrorDialog(context, technicalError: e);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800),
                child: const Text('Save', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

// ── Officials Tab ───────────────────────────────────────────────────────────

class _OfficialsList extends ConsumerWidget {
  const _OfficialsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final officialsAsync = ref.watch(officialsAdminProvider);

    return Scaffold(
      body: officialsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (officials) {
          if (officials.isEmpty) return const Center(child: Text('No officials.'));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: officials.length,
            itemBuilder: (context, index) {
              final o = officials[index];
              return Card(
                child: ListTile(
                  title: Text(o.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${o.department?.name ?? 'Unknown'} • ${o.designation ?? ''}'),
                  trailing: Switch(
                    value: o.status,
                    onChanged: (val) async {
                      try {
                        await ref.read(apiServiceProvider).updateOfficial(o.id, {'status': val});
                        ref.invalidate(officialsAdminProvider);
                      } catch (e) {
                        AppDialogs.showErrorDialog(context, technicalError: e);
                      }
                    },
                  ),
                  onLongPress: () async {
                    try {
                      await ref.read(apiServiceProvider).deleteOfficial(o.id);
                      ref.invalidate(officialsAdminProvider);
                    } catch (e) {
                      AppDialogs.showErrorDialog(context, technicalError: e);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOfficialSheet(context, ref),
        backgroundColor: Colors.orange.shade800,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddOfficialSheet(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final desigCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String? selectedDeptId;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Consumer(
          builder: (context, sheetRef, child) {
            return StatefulBuilder(
              builder: (context, setState) {
                final deptsAsync = sheetRef.watch(departmentsAdminProvider);
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                left: 24, right: 24, top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Add Official',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Name *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 14),
                    deptsAsync.when(
                      loading: () => Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 12),
                            Text('Loading departments...', style: TextStyle(color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                      error: (e, s) => Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.red.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Text('Failed to load departments. Check connection.', style: TextStyle(color: Colors.red.shade700)),
                      ),
                      data: (depts) {
                        if (depts.isEmpty) {
                          return Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.orange.shade300),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: const Text('No departments found. Please add departments first.'),
                          );
                        }
                        return DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Department *',
                            prefixIcon: Icon(Icons.business),
                          ),
                          value: selectedDeptId,
                          items: depts.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
                          onChanged: (v) => setState(() => selectedDeptId = v),
                          hint: const Text('Select Department'),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: desigCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Designation',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.work),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: isSaving ? null : () async {
                        if (nameCtrl.text.trim().isEmpty) {
                          AppDialogs.showErrorDialog(context, userMessage: 'Name is required');
                          return;
                        }
                        if (selectedDeptId == null) {
                          AppDialogs.showErrorDialog(context, userMessage: 'Please select a department');
                          return;
                        }
                        setState(() => isSaving = true);
                        try {
                          await ref.read(apiServiceProvider).createOfficial(
                            Official(
                              id: '',
                              departmentId: selectedDeptId!,
                              name: nameCtrl.text.trim(),
                              designation: desigCtrl.text.trim().isEmpty ? null : desigCtrl.text.trim(),
                              phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                              status: true,
                            ),
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                          ref.invalidate(officialsAdminProvider);
                        } catch (e) {
                          setState(() => isSaving = false);
                          AppDialogs.showErrorDialog(context, technicalError: e);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade800,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Save Official', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
          },
        );
      },
    );
  }
}
