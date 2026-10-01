import 'package:mantri_app/core/utils/app_dialogs.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mantri_app/core/services/firebase_service.dart';
import 'package:mantri_app/core/services/api_service.dart';
import 'package:mantri_app/core/models/app_models.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

enum _CalViewMode { day, threeDays, week, month }

const _saffron = Color.fromARGB(255, 219, 126, 32);
const _navy = Color(0xFF1B3B5A);
const double _hourH = 60.0; // height of one hour row in the time grid
const int _startHour = 6; // 6 AM
const int _endHour = 23; // 11 PM

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

TimeOfDay _parseTimeStr(String timeStr) {
  try {
    final parts = timeStr.trim().split(' ');
    final timeParts = parts[0].split(':');
    int hour = int.parse(timeParts[0]);
    final int minute =
        timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 0 : 0;
    final bool isPM = parts.length > 1 && parts[1].toUpperCase() == 'PM';
    if (isPM && hour != 12) hour += 12;
    if (!isPM && hour == 12) hour = 0;
    return TimeOfDay(hour: hour, minute: minute);
  } catch (_) {
    return const TimeOfDay(hour: 9, minute: 0);
  }
}

double _timeOffset(TimeOfDay t) {
  final h = (t.hour - _startHour).clamp(0, _endHour - _startHour).toDouble();
  return h * _hourH + (t.minute / 60.0) * _hourH;
}

Color _typeColor(String type) {
  switch (type) {
    case 'Speech':
      return const Color(0xFFE65100);
    case 'Appointment':
      return const Color(0xFF6A1B9A);
    case 'Event':
      return const Color(0xFF00695C);
    default:
      return const Color(0xFF1565C0);
  }
}

IconData _typeIcon(String type) {
  switch (type) {
    case 'Speech':
      return Icons.record_voice_over;
    case 'Appointment':
      return Icons.people;
    case 'Event':
      return Icons.campaign;
    default:
      return Icons.event_note;
  }
}

String _hourLabel(int h) {
  if (h == 0) return '12 AM';
  if (h < 12) return '$h AM';
  if (h == 12) return '12 PM';
  return '${h - 12} PM';
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

// ─────────────────────────────────────────────────────────────────────────────
// Main Screen
// ─────────────────────────────────────────────────────────────────────────────

class ScheduleManagementScreen extends ConsumerStatefulWidget {
  const ScheduleManagementScreen({super.key});

  @override
  ConsumerState<ScheduleManagementScreen> createState() =>
      _ScheduleManagementScreenState();
}

class _ScheduleManagementScreenState
    extends ConsumerState<ScheduleManagementScreen> {
  _CalViewMode _viewMode = _CalViewMode.month;
  DateTime _anchor = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  List<ScheduleItem> _events = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  // ── Date Range ─────────────────────────────────────────────────────────────

  (DateTime, DateTime) _getDateRange() {
    switch (_viewMode) {
      case _CalViewMode.day:
        final d = _selectedDay;
        return (
          DateTime(d.year, d.month, d.day),
          DateTime(d.year, d.month, d.day, 23, 59, 59),
        );
      case _CalViewMode.threeDays:
        final s = DateTime(_anchor.year, _anchor.month, _anchor.day);
        return (s, s.add(const Duration(days: 2, hours: 23, minutes: 59)));
      case _CalViewMode.week:
        final weekStart = _anchor.subtract(Duration(days: _anchor.weekday - 1));
        final s = DateTime(weekStart.year, weekStart.month, weekStart.day);
        return (s, s.add(const Duration(days: 6, hours: 23, minutes: 59)));
      case _CalViewMode.month:
        final s = DateTime(_anchor.year, _anchor.month, 1);
        final e = DateTime(_anchor.year, _anchor.month + 1, 0, 23, 59, 59);
        return (s, e);
    }
  }

  // ── Data Fetch ─────────────────────────────────────────────────────────────

  Future<void> _fetchEvents() async {
    setState(() => _loading = true);
    try {
      final (start, end) = _getDateRange();
      final items = await ref
          .read(apiServiceProvider)
          .getSchedules(start: start, end: end);
      if (mounted) setState(() => _events = items);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  void _navigate(int delta) {
    setState(() {
      switch (_viewMode) {
        case _CalViewMode.day:
          _selectedDay = _selectedDay.add(Duration(days: delta));
          _anchor = _selectedDay;
        case _CalViewMode.threeDays:
          _anchor = _anchor.add(Duration(days: delta * 3));
        case _CalViewMode.week:
          _anchor = _anchor.add(Duration(days: delta * 7));
        case _CalViewMode.month:
          _anchor = DateTime(_anchor.year, _anchor.month + delta, 1);
      }
    });
    _fetchEvents();
  }

  void _goToToday() {
    setState(() {
      _anchor = DateTime.now();
      _selectedDay = DateTime.now();
    });
    _fetchEvents();
  }

  // ── Dialogs ────────────────────────────────────────────────────────────────

  void _showViewPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (ctx) => _ViewPickerSheet(
            current: _viewMode,
            onSelect: (mode) {
              setState(() => _viewMode = mode);
              Navigator.pop(ctx);
              _fetchEvents();
            },
          ),
    );
  }

  void _showAddDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddScheduleItemForm(date: _selectedDay),
    ).then((_) => _fetchEvents());
  }

  void _showItemDetails(BuildContext context, ScheduleItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ItemDetailSheet(item: item, ref: ref),
    );
  }

  // ── Header title ───────────────────────────────────────────────────────────

  String _headerTitle() {
    switch (_viewMode) {
      case _CalViewMode.day:
        return DateFormat('MMMM yyyy').format(_selectedDay);
      case _CalViewMode.threeDays:
        final end = _anchor.add(const Duration(days: 2));
        return '${DateFormat('MMM d').format(_anchor)} – ${DateFormat('MMM d').format(end)}';
      case _CalViewMode.week:
        final wStart = _anchor.subtract(Duration(days: _anchor.weekday - 1));
        final wEnd = wStart.add(const Duration(days: 6));
        return '${DateFormat('MMM d').format(wStart)} – ${DateFormat('MMM d, yyyy').format(wEnd)}';
      case _CalViewMode.month:
        return DateFormat('MMMM yyyy').format(_anchor);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: _saffron,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          tooltip: 'Change view',
          onPressed: _showViewPicker,
        ),
        centerTitle: false,
        title: GestureDetector(
          onTap: () async {
            if (!mounted) return;
            final picked = await showDatePicker(
              context: context,
              initialDate: _anchor,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              builder:
                  (ctx, child) => Theme(
                    data: Theme.of(ctx).copyWith(
                      colorScheme: const ColorScheme.light(primary: _saffron),
                    ),
                    child: child!,
                  ),
            );
            if (picked != null && mounted) {
              setState(() {
                _anchor = picked;
                _selectedDay = picked;
              });
              _fetchEvents();
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  _headerTitle(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                Icons.arrow_drop_down,
                color: Colors.white70,
                size: 20,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _goToToday,
            child: const Text(
              'Today',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _navigate(-1),
            tooltip: 'Previous',
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _navigate(1),
            tooltip: 'Next',
          ),
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator(color: _saffron))
              : _viewMode == _CalViewMode.month
              ? _MonthView(
                anchor: _anchor,
                selectedDay: _selectedDay,
                events: _events,
                onDayTap: (day) {
                  setState(() {
                    _selectedDay = day;
                    _anchor = day;
                    _viewMode = _CalViewMode.day;
                  });
                  _fetchEvents();
                },
                onEventTap: (e) => _showItemDetails(context, e),
              )
              : _TimeGridView(
                viewMode: _viewMode,
                anchor: _anchor,
                selectedDay: _selectedDay,
                events: _events,
                onDayTap: (day) => setState(() => _selectedDay = day),
                onEventTap: (e) => _showItemDetails(context, e),
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Agenda'),
        backgroundColor: _saffron,
        foregroundColor: Colors.white,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// View Picker Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _ViewPickerSheet extends StatelessWidget {
  final _CalViewMode current;
  final void Function(_CalViewMode) onSelect;
  const _ViewPickerSheet({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    const items = [
      (_CalViewMode.day, Icons.view_day_outlined, 'Day'),
      (_CalViewMode.threeDays, Icons.view_column_outlined, '3 Days'),
      (_CalViewMode.week, Icons.view_week_outlined, 'Week'),
      (_CalViewMode.month, Icons.grid_view_rounded, 'Month'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'View',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _navy,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((entry) {
            final (mode, icon, label) = entry;
            final selected = current == mode;
            return ListTile(
              selected: selected,
              selectedTileColor: _saffron.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              leading: Icon(
                icon,
                color: selected ? _saffron : Colors.grey.shade600,
              ),
              title: Text(
                label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? _saffron : null,
                ),
              ),
              trailing:
                  selected ? const Icon(Icons.check, color: _saffron) : null,
              onTap: () => onSelect(mode),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Month View
// ─────────────────────────────────────────────────────────────────────────────

class _MonthView extends StatelessWidget {
  final DateTime anchor;
  final DateTime selectedDay;
  final List<ScheduleItem> events;
  final void Function(DateTime) onDayTap;
  final void Function(ScheduleItem) onEventTap;

  const _MonthView({
    required this.anchor,
    required this.selectedDay,
    required this.events,
    required this.onDayTap,
    required this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(anchor.year, anchor.month, 1);
    final daysInMonth = DateTime(anchor.year, anchor.month + 1, 0).day;
    final startWeekday = firstDay.weekday; // 1=Mon … 7=Sun
    final today = DateTime.now();

    // Group events by date key
    final Map<String, List<ScheduleItem>> byDay = {};
    for (final e in events) {
      final key = DateFormat('yyyy-MM-dd').format(e.date);
      byDay.putIfAbsent(key, () => []).add(e);
    }

    // Events on selected day
    final selKey = DateFormat('yyyy-MM-dd').format(selectedDay);
    final selEvents = byDay[selKey] ?? [];

    return Column(
      children: [
        // Day-of-week headers
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children:
                ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                    .map(
                      (d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color:
                                  (d == 'Sat' || d == 'Sun')
                                      ? Colors.red.shade300
                                      : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
        ),
        Container(height: 1, color: Colors.grey.shade200),

        // Calendar grid
        Expanded(
          flex: 3,
          child: GridView.builder(
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.58,
            ),
            itemCount: startWeekday - 1 + daysInMonth,
            itemBuilder: (ctx, index) {
              if (index < startWeekday - 1) return const SizedBox();
              final day = index - (startWeekday - 1) + 1;
              final date = DateTime(anchor.year, anchor.month, day);
              final key = DateFormat('yyyy-MM-dd').format(date);
              final dayEvents = byDay[key] ?? [];
              final isToday = _isSameDay(date, today);
              final isSelected = _isSameDay(date, selectedDay);

              return GestureDetector(
                onTap: () => onDayTap(date),
                child: Container(
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? _saffron.withValues(alpha: 0.08)
                            : Colors.white,
                    border: Border.all(
                      color:
                          isSelected
                              ? _saffron.withValues(alpha: 0.4)
                              : Colors.grey.shade100,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 4),
                      // Day number
                      Container(
                        width: 26,
                        height: 26,
                        decoration:
                            isToday
                                ? const BoxDecoration(
                                  color: _saffron,
                                  shape: BoxShape.circle,
                                )
                                : null,
                        alignment: Alignment.center,
                        child: Text(
                          '$day',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color:
                                isToday
                                    ? Colors.white
                                    : (date.weekday >= 6
                                        ? Colors.red.shade300
                                        : Colors.black87),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Event chips (up to 2)
                      ...dayEvents
                          .take(2)
                          .map(
                            (e) => Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 2,
                                vertical: 1,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _typeColor(e.type),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                e.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 7,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ),
                      if (dayEvents.length > 2)
                        Text(
                          '+${dayEvents.length - 2}',
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.grey.shade500,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Selected day event list panel
        Container(height: 1, color: Colors.grey.shade200),
        Expanded(
          flex: 2,
          child: Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: _saffron,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('EEEE, d MMMM').format(selectedDay),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _saffron,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${selEvents.length} event${selEvents.length == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                if (selEvents.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.event_available,
                            size: 36,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No events scheduled',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      children:
                          selEvents
                              .map(
                                (e) => _CompactEventTile(
                                  item: e,
                                  onTap: () => onEventTap(e),
                                ),
                              )
                              .toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Compact Event Tile (used in month panel & schedule list)
// ─────────────────────────────────────────────────────────────────────────────

class _CompactEventTile extends StatelessWidget {
  final ScheduleItem item;
  final VoidCallback onTap;
  const _CompactEventTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(item.type);
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_typeIcon(item.type), color: color, size: 16),
            const SizedBox(height: 2),
            Text(
              item.time,
              style: TextStyle(
                color: color,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      title: Text(
        item.title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle:
          item.location != null
              ? Text(
                item.location!,
                style: const TextStyle(fontSize: 11),
                overflow: TextOverflow.ellipsis,
              )
              : Text(
                item.type,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
      onTap: onTap,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Time Grid View (Day / 3-Day / Week)
// ─────────────────────────────────────────────────────────────────────────────

class _TimeGridView extends StatefulWidget {
  final _CalViewMode viewMode;
  final DateTime anchor;
  final DateTime selectedDay;
  final List<ScheduleItem> events;
  final void Function(DateTime) onDayTap;
  final void Function(ScheduleItem) onEventTap;

  const _TimeGridView({
    required this.viewMode,
    required this.anchor,
    required this.selectedDay,
    required this.events,
    required this.onDayTap,
    required this.onEventTap,
  });

  @override
  State<_TimeGridView> createState() => _TimeGridViewState();
}

class _TimeGridViewState extends State<_TimeGridView> {
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    // Auto-scroll to 8 AM on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        final offset = (8 - _startHour) * _hourH;
        _scrollCtrl.jumpTo(
          offset.clamp(0.0, _scrollCtrl.position.maxScrollExtent),
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  List<DateTime> _getDays() {
    switch (widget.viewMode) {
      case _CalViewMode.day:
        final d = widget.selectedDay;
        return [DateTime(d.year, d.month, d.day)];
      case _CalViewMode.threeDays:
        final s = DateTime(
          widget.anchor.year,
          widget.anchor.month,
          widget.anchor.day,
        );
        return List.generate(3, (i) => s.add(Duration(days: i)));
      case _CalViewMode.week:
        final wStart = widget.anchor.subtract(
          Duration(days: widget.anchor.weekday - 1),
        );
        final s = DateTime(wStart.year, wStart.month, wStart.day);
        return List.generate(7, (i) => s.add(Duration(days: i)));
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = _getDays();
    final today = DateTime.now();
    final Map<String, List<ScheduleItem>> byDay = {};
    for (final e in widget.events) {
      final key = DateFormat('yyyy-MM-dd').format(e.date);
      byDay.putIfAbsent(key, () => []).add(e);
    }

    return Column(
      children: [
        // ── Day header row ──
        Container(
          color: Colors.white,
          child: Row(
            children: [
              const SizedBox(width: 56), // gutter for time labels
              ...days.map((day) {
                final isToday = _isSameDay(day, today);
                final isSelected = _isSameDay(day, widget.selectedDay);
                return Expanded(
                  child: GestureDetector(
                    onTap: () => widget.onDayTap(day),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration:
                          isSelected
                              ? const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: _saffron, width: 3),
                                ),
                              )
                              : null,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DateFormat('E').format(day),
                            style: TextStyle(
                              fontSize: 11,
                              color: isToday ? _saffron : Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 32,
                            height: 32,
                            decoration:
                                isToday
                                    ? const BoxDecoration(
                                      color: _saffron,
                                      shape: BoxShape.circle,
                                    )
                                    : null,
                            alignment: Alignment.center,
                            child: Text(
                              '${day.day}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isToday ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        Container(height: 1, color: Colors.grey.shade200),

        // ── Scrollable time grid ──
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollCtrl,
            child: SizedBox(
              height: (_endHour - _startHour + 1) * _hourH,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time labels column
                  SizedBox(
                    width: 56,
                    child: Column(
                      children: List.generate(
                        _endHour - _startHour + 1,
                        (i) => SizedBox(
                          height: _hourH,
                          child: Align(
                            alignment: Alignment.topRight,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8, top: 4),
                              child: Text(
                                _hourLabel(_startHour + i),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Day columns
                  ...days.map((day) {
                    final key = DateFormat('yyyy-MM-dd').format(day);
                    final dayEvents = byDay[key] ?? [];
                    final isToday = _isSameDay(day, today);

                    return Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                        child: Stack(
                          clipBehavior: Clip.hardEdge,
                          children: [
                            // Whole-hour grid lines
                            ...List.generate(
                              _endHour - _startHour + 1,
                              (i) => Positioned(
                                top: i * _hourH,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 1,
                                  color: Colors.grey.shade100,
                                ),
                              ),
                            ),
                            // Half-hour dashed lines
                            ...List.generate(
                              _endHour - _startHour + 1,
                              (i) => Positioned(
                                top: i * _hourH + _hourH / 2,
                                left: 8,
                                right: 0,
                                child: Container(
                                  height: 1,
                                  color: Colors.grey.shade50,
                                ),
                              ),
                            ),
                            // Current time red line
                            if (isToday)
                              Positioned(
                                top: _timeOffset(TimeOfDay.now()),
                                left: 0,
                                right: 0,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        height: 2,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            // Events
                            ...dayEvents.map((e) => _buildEventBlock(e)),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventBlock(ScheduleItem item) {
    final t = _parseTimeStr(item.time);
    final top = _timeOffset(
      t,
    ).clamp(0.0, (_endHour - _startHour) * _hourH - 24);
    final color = _typeColor(item.type);

    return Positioned(
      top: top,
      left: 2,
      right: 2,
      child: GestureDetector(
        onTap: () => widget.onEventTap(item),
        child: Container(
          height: _hourH - 6,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(6),
            border: Border(left: BorderSide(color: color, width: 3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              Text(
                item.time,
                style: const TextStyle(color: Colors.white70, fontSize: 9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Item Detail Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _ItemDetailSheet extends ConsumerWidget {
  final ScheduleItem item;
  final WidgetRef ref;
  const _ItemDetailSheet({required this.item, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef wRef) {
    final color = _typeColor(item.type);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.type.toUpperCase(),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        wRef
                            .read(firestoreServiceProvider)
                            .deleteScheduleItem(item.id);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: 'Delete',
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _saffron,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  '${item.time}  •  ${DateFormat('EEEE, MMM d, yyyy').format(item.date)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Divider(height: 40),
            const Text(
              'Description',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              item.description,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            if (item.location != null) ...[
              const Text(
                'Location',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 18, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.location!,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ],
              ),
              if (item.mapUrl != null) ...[
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse(item.mapUrl!);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  icon: const Icon(Icons.map, size: 18),
                  label: const Text('Open in Google Maps'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
            if (item.organizerName != null ||
                item.organizerContact != null) ...[
              const Text(
                'Organizer Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    if (item.organizerName != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.person,
                            size: 18,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            item.organizerName!,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    if (item.organizerContact != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 18, color: Colors.grey),
                          const SizedBox(width: 12),
                          Text(
                            item.organizerContact!,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            if (item.imageUrl != null) ...[
              const Text(
                'Program Photo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  item.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 24),
            ],
            // Action buttons
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    AppDialogs.showErrorDialog(context);
                  },
                  icon: const Icon(Icons.notifications_active, size: 14),
                  label: const Text(
                    'Notify MP',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                ),
                if (item.mapUrl != null)
                  ElevatedButton.icon(
                    onPressed: () async {
                      final uri = Uri.parse(item.mapUrl!);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                    icon: const Icon(Icons.location_on, size: 14),
                    label: const Text(
                      'Location',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Schedule Item Form  (unchanged from original)
// ─────────────────────────────────────────────────────────────────────────────

class _AddScheduleItemForm extends StatefulWidget {
  final DateTime date;
  const _AddScheduleItemForm({required this.date});

  @override
  State<_AddScheduleItemForm> createState() => _AddScheduleItemFormState();
}

class _AddScheduleItemFormState extends State<_AddScheduleItemForm> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _timeController = TextEditingController();
  final _orgNameController = TextEditingController();
  final _orgContactController = TextEditingController();
  final _locationController = TextEditingController();
  final _mapUrlController = TextEditingController();
  final _dateController = TextEditingController();
  late DateTime _selectedDate;
  String _type = 'Program';
  File? _selectedImage;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.date;
    _dateController.text = DateFormat(
      'EEEE, MMM dd, yyyy',
    ).format(_selectedDate);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && mounted) {
      setState(() => _timeController.text = picked.format(context));
    }
  }

  Future<void> _selectDate() async {
    const saffron = Color.fromARGB(255, 219, 126, 32);
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDate.isBefore(DateTime.now())
              ? DateTime.now()
              : _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder:
          (ctx, child) => Theme(
            data: Theme.of(
              ctx,
            ).copyWith(colorScheme: const ColorScheme.light(primary: saffron)),
            child: child!,
          ),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('EEEE, MMM dd, yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Add Daily Agenda Item',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(
                labelText: 'Agenda Type',
                border: OutlineInputBorder(),
              ),
              items:
                  ['Program', 'Appointment', 'Speech', 'Event']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _selectDate,
              child: IgnorePointer(
                child: TextField(
                  controller: _dateController,
                  decoration: const InputDecoration(
                    labelText: 'Select Date',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _selectTime,
              child: IgnorePointer(
                child: TextField(
                  controller: _timeController,
                  decoration: const InputDecoration(
                    labelText: 'Select Time',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.access_time),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Short Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _orgNameController,
              decoration: const InputDecoration(
                labelText: 'Organizer Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _orgContactController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: const InputDecoration(
                labelText: 'Organizer Contact',
                border: OutlineInputBorder(),
                prefixText: '+91 ',
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Event Address / Location',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _mapUrlController,
              decoration: const InputDecoration(
                labelText: 'Google Maps URL (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.map),
              ),
            ),
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Program Photo',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            if (_selectedImage != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      _selectedImage!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.red,
                      radius: 15,
                      child: IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 15,
                          color: Colors.white,
                        ),
                        onPressed: () => setState(() => _selectedImage = null),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              )
            else
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.add_a_photo),
                label: const Text('Upload Program Photo'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            const SizedBox(height: 24),
            Consumer(
              builder: (context, ref, _) {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        _isUploading
                            ? null
                            : () async {
                              if (_titleController.text.isEmpty) return;
                              if (_orgContactController.text.isNotEmpty &&
                                  _orgContactController.text.length != 10) {
                                AppDialogs.showErrorDialog(context);
                                return;
                              }

                              if (_timeController.text.isEmpty) {
                                AppDialogs.showErrorDialog(
                                  context,
                                  userMessage: 'Please select a time.',
                                );
                                return;
                              }

                              final now = DateTime.now();
                              final parsedTime = _parseTimeStr(
                                _timeController.text,
                              );
                              final selectedDateTime = DateTime(
                                _selectedDate.year,
                                _selectedDate.month,
                                _selectedDate.day,
                                parsedTime.hour,
                                parsedTime.minute,
                              );

                              if (selectedDateTime.isBefore(now)) {
                                AppDialogs.showErrorDialog(
                                  context,
                                  userMessage:
                                      "Please select today's or a future date and time.",
                                );
                                return;
                              }

                              setState(() => _isUploading = true);
                              String? finalImageUrl;
                              if (_selectedImage != null) {
                                finalImageUrl = await ref
                                    .read(firestoreServiceProvider)
                                    .uploadImage(
                                      _selectedImage!,
                                      'schedule_photos',
                                    );
                              }
                              final item = ScheduleItem(
                                id: '',
                                title: _titleController.text,
                                type: _type,
                                time: _timeController.text,
                                date: _selectedDate,
                                description: _descController.text,
                                organizerName:
                                    _orgNameController.text.isNotEmpty
                                        ? _orgNameController.text
                                        : null,
                                organizerContact:
                                    _orgContactController.text.isNotEmpty
                                        ? _orgContactController.text
                                        : null,
                                imageUrl: finalImageUrl,
                                location:
                                    _locationController.text.isNotEmpty
                                        ? _locationController.text
                                        : null,
                                mapUrl:
                                    _mapUrlController.text.isNotEmpty
                                        ? _mapUrlController.text
                                        : null,
                              );
                              await ref
                                  .read(firestoreServiceProvider)
                                  .addScheduleItem(item);
                              if (context.mounted) Navigator.pop(context);
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _navy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child:
                        _isUploading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Text('Add to Schedule'),
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
