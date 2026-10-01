import 'package:mantri_app/core/utils/app_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mantri_app/core/models/app_models.dart';
import 'package:mantri_app/core/services/api_service.dart';
import 'package:intl/intl.dart';

final paAvailabilitiesProvider =
    FutureProvider.autoDispose<List<PaAvailability>>((ref) async {
      return ref.read(apiServiceProvider).getPaAvailabilities();
    });

class PaAvailabilityScreen extends ConsumerStatefulWidget {
  const PaAvailabilityScreen({super.key});

  @override
  ConsumerState<PaAvailabilityScreen> createState() =>
      _PaAvailabilityScreenState();
}

class _PaAvailabilityScreenState extends ConsumerState<PaAvailabilityScreen> {
  final ScrollController _scrollController = ScrollController();
  DateTime _selectedDate = DateTime.now();
  bool _isAvailable = true;
  TimeOfDay? _startTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay? _endTime = const TimeOfDay(hour: 17, minute: 0);

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final today = DateTime.now();
    final firstDate = DateTime(today.year, today.month, today.day);
    DateTime initialDate = _selectedDate;
    if (initialDate.isBefore(firstDate)) {
      initialDate = firstDate;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: firstDate.add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadAvailabilityForSelectedDate();
    }
  }

  void _loadAvailabilityForSelectedDate() {
    final asyncData = ref.read(paAvailabilitiesProvider);
    if (asyncData is AsyncData<List<PaAvailability>>) {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final existing = asyncData.value.cast<PaAvailability?>().firstWhere(
        (a) => a?.date.split('T')[0] == dateStr || a?.date == dateStr,
        orElse: () => null,
      );

      if (existing != null) {
        setState(() {
          _isAvailable = existing.isAvailable;
          _startTime =
              existing.startTime != null
                  ? _parseTime(existing.startTime!)
                  : null;
          _endTime =
              existing.endTime != null ? _parseTime(existing.endTime!) : null;
        });
      } else {
        setState(() {
          _isAvailable = true;
          _startTime = const TimeOfDay(hour: 10, minute: 0);
          _endTime = const TimeOfDay(hour: 17, minute: 0);
        });
      }
    }
  }

  TimeOfDay _parseTime(String timeString) {
    try {
      final parts = timeString.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return const TimeOfDay(hour: 10, minute: 0);
    }
  }

  String _formatDateString(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _formatDisplayTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '';
    final tod = _parseTime(timeStr);
    return tod.format(context);
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime:
          isStart
              ? (_startTime ?? const TimeOfDay(hour: 10, minute: 0))
              : (_endTime ?? const TimeOfDay(hour: 17, minute: 0)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _saveAvailability() async {
    try {
      final String startTimeStr =
          _startTime != null
              ? '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}'
              : '10:00';
      final String endTimeStr =
          _endTime != null
              ? '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}'
              : '17:00';

      final availability = PaAvailability(
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
        isAvailable: _isAvailable,
        startTime: startTimeStr,
        endTime: endTimeStr,
      );

      await ref.read(apiServiceProvider).updatePaAvailability(availability);
      ref.invalidate(paAvailabilitiesProvider);

      if (mounted) {
        AppDialogs.showSuccessDialog(context, message: 'Availability updated successfully!');
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showErrorDialog(context, userMessage: 'Failed to update:', technicalError: e);
      }
    }
  }

  Future<void> _showEditDialog(PaAvailability item) async {
    DateTime tempDate = DateTime.tryParse(item.date) ?? DateTime.now();
    bool tempIsAvailable = item.isAvailable;
    TimeOfDay? tempStartTime =
        item.startTime != null
            ? _parseTime(item.startTime!)
            : const TimeOfDay(hour: 10, minute: 0);
    TimeOfDay? tempEndTime =
        item.endTime != null
            ? _parseTime(item.endTime!)
            : const TimeOfDay(hour: 17, minute: 0);

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Availability'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: const Text('Date'),
                      subtitle: Text(
                        DateFormat('dd MMM yyyy').format(tempDate),
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final today = DateTime.now();
                        final firstDate = DateTime(today.year, today.month, today.day);
                        DateTime initialDate = tempDate;
                        if (initialDate.isBefore(firstDate)) {
                          initialDate = firstDate;
                        }

                        final picked = await showDatePicker(
                          context: context,
                          initialDate: initialDate,
                          firstDate: firstDate,
                          lastDate: firstDate.add(
                            const Duration(days: 365),
                          ),
                        );
                        if (picked != null)
                          setDialogState(() => tempDate = picked);
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Is Available?'),
                      value: tempIsAvailable,
                      onChanged:
                          (val) => setDialogState(() => tempIsAvailable = val),
                    ),
                    if (tempIsAvailable) ...[
                      ListTile(
                        title: const Text('Start Time'),
                        subtitle: Text(tempStartTime?.format(context) ?? ''),
                        trailing: const Icon(Icons.access_time),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime:
                                tempStartTime ??
                                const TimeOfDay(hour: 10, minute: 0),
                          );
                          if (picked != null)
                            setDialogState(() => tempStartTime = picked);
                        },
                      ),
                      ListTile(
                        title: const Text('End Time'),
                        subtitle: Text(tempEndTime?.format(context) ?? ''),
                        trailing: const Icon(Icons.access_time),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime:
                                tempEndTime ??
                                const TimeOfDay(hour: 17, minute: 0),
                          );
                          if (picked != null)
                            setDialogState(() => tempEndTime = picked);
                        },
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    try {
                      final startTimeStr =
                          tempStartTime != null
                              ? '${tempStartTime!.hour.toString().padLeft(2, '0')}:${tempStartTime!.minute.toString().padLeft(2, '0')}'
                              : '10:00';
                      final endTimeStr =
                          tempEndTime != null
                              ? '${tempEndTime!.hour.toString().padLeft(2, '0')}:${tempEndTime!.minute.toString().padLeft(2, '0')}'
                              : '17:00';

                      final updatedAvailability = PaAvailability(
                        id: item.id,
                        date: DateFormat('yyyy-MM-dd').format(tempDate),
                        isAvailable: tempIsAvailable,
                        startTime: startTimeStr,
                        endTime: endTimeStr,
                      );

                      await ref
                          .read(apiServiceProvider)
                          .updatePaAvailability(updatedAvailability);
                      ref.invalidate(paAvailabilitiesProvider);

                      if (mounted) {
                        AppDialogs.showSuccessDialog(context, message: 'Availability updated successfully!');
                      }
                    } catch (e) {
                      if (mounted) {
                        AppDialogs.showErrorDialog(context, userMessage: 'Failed to update:', technicalError: e);
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteAvailability(PaAvailability item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Availability'),
            content: Text(
              'Are you sure you want to delete availability for ${_formatDateString(item.date)}'
              '${item.isAvailable ? ' (${_formatDisplayTime(item.startTime)} - ${_formatDisplayTime(item.endTime)})' : ''}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await ref.read(apiServiceProvider).deletePaAvailability(item.id);
        ref.invalidate(paAvailabilitiesProvider);
        if (mounted) {
          AppDialogs.showWarningDialog(context, message: 'Availability deleted successfully!');
        }
      } catch (e) {
        if (mounted) {
          AppDialogs.showErrorDialog(context, userMessage: 'Failed to delete:', technicalError: e);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const saffron = Color.fromARGB(255, 219, 126, 32);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Availability Management'),
        backgroundColor: saffron,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Set PA Availability for Appointments',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ListTile(
                title: const Text('Selected Date'),
                subtitle: Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
                trailing: const Icon(Icons.calendar_today, color: saffron),
                onTap: () => _selectDate(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Is Available?'),
                subtitle: Text(
                  _isAvailable
                      ? 'Citizens can book slots on this date'
                      : 'No slots will be available on this date',
                ),
                value: _isAvailable,
                onChanged: (val) {
                  setState(() {
                    _isAvailable = val;
                  });
                },
                activeColor: saffron,
              ),
              if (_isAvailable) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: const Text('Start Time'),
                        subtitle: Text(
                          _startTime?.format(context) ?? 'Not set',
                        ),
                        trailing: const Icon(Icons.access_time),
                        onTap: () => _selectTime(context, true),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ListTile(
                        title: const Text('End Time'),
                        subtitle: Text(_endTime?.format(context) ?? 'Not set'),
                        trailing: const Icon(Icons.access_time),
                        onTap: () => _selectTime(context, false),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveAvailability,
                style: ElevatedButton.styleFrom(
                  backgroundColor: saffron,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Save Availability',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 32),
              const Text(
                'Upcoming Availabilities',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ref
                  .watch(paAvailabilitiesProvider)
                  .when(
                    loading:
                        () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Text('Error: $err'),
                    data: (availabilities) {
                      if (availabilities.isEmpty) {
                        return const Text('No upcoming availabilities set.');
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: availabilities.length,
                        itemBuilder: (context, index) {
                          final item = availabilities[index];
                          return Card(
                            child: ListTile(
                              title: Text(
                                _formatDateString(item.date),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                item.isAvailable
                                    ? 'Available (${_formatDisplayTime(item.startTime)} - ${_formatDisplayTime(item.endTime)})'
                                    : 'Unavailable',
                              ),
                              leading: Icon(
                                item.isAvailable
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                color:
                                    item.isAvailable
                                        ? Colors.green
                                        : Colors.red,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () => _showEditDialog(item),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _deleteAvailability(item),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
