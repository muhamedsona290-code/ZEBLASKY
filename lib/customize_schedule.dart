import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'config.dart';
import 'main.dart';

const olive = Color(0xFF343B2D);
const sage = Color(0xFF4D7C5F);
const sageLight = Color(0xFFE8F3EB);
const concern = Color(0xFFA56D24);
const emergency = Color(0xFFC53030);

class CustomizeScheduleTab extends StatefulWidget {
  const CustomizeScheduleTab({super.key});

  @override
  State<CustomizeScheduleTab> createState() => _CustomizeScheduleTabState();
}

class _CustomizeScheduleTabState extends State<CustomizeScheduleTab> {
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    // Update countdown every 30 seconds
    _countdownTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatInterval(int m) {
    if (m % 1440 == 0) {
      final days = m ~/ 1440;
      return days == 1 ? 'Daily (Every 24 hrs)' : 'Every $days days';
    }
    if (m % 60 == 0) {
      final hours = m ~/ 60;
      return hours == 1 ? 'Every hour' : 'Every $hours hours';
    }
    return 'Every $m minutes';
  }

  String _formatCountdown(String? nextRunIso, bool active) {
    if (!active) return 'Schedule paused';
    if (nextRunIso == null) return 'Not scheduled';
    final nextRun = DateTime.tryParse(nextRunIso)?.toLocal();
    if (nextRun == null) return 'Invalid time';

    final now = DateTime.now();
    final diff = nextRun.difference(now);

    if (diff.isNegative) {
      return 'Due now (calling soon)';
    }

    if (diff.inMinutes < 60) {
      return 'Runs in ${diff.inMinutes} minute${diff.inMinutes == 1 ? '' : 's'}';
    } else if (diff.inHours < 24) {
      final hrs = diff.inHours;
      final mins = diff.inMinutes % 60;
      return 'Runs in ${hrs}h ${mins}m (${DateFormat.jm().format(nextRun)})';
    } else {
      return 'Runs on ${DateFormat('d MMM, h:mm a').format(nextRun)}';
    }
  }

  Future<void> _toggleSchedule(String id, bool active) async {
    await db.from('call_schedules').update({'active': active}).eq('id', id);
  }

  Future<void> _deleteSchedule(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Call Schedule?'),
        content: const Text('Are you sure you want to remove this automated check-in schedule?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: emergency),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await db.from('call_schedules').delete().eq('id', id);
    }
  }

  Future<void> _addPreset(String title, TimeOfDay time) async {
    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    final iso = scheduled.toUtc().toIso8601String();

    await db.from('call_schedules').insert({
      'elder_id': elderId,
      'start_at': iso,
      'next_run_at': iso,
      'repeat_count': 30, // 30 days
      'interval_minutes': 1440, // 24 hours
      'active': true,
      'runs_done': 0,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added "$title" daily schedule!')),
      );
    }
  }

  Future<void> _addCustomSchedule() async {
    var when = DateTime.now().add(const Duration(minutes: 10));
    final countCtrl = TextEditingController(text: '7');
    final everyCtrl = TextEditingController(text: '1');
    var unit = 1440; // days in minutes

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: const Text('New Automated Call Schedule'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Amma will receive an automated voice call from Koode at the specified times.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 14),
                const Text('First Call Start Time:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: olive)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(DateFormat('d MMM y').format(when)),
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: ctx,
                            initialDate: when,
                            firstDate: DateTime.now().subtract(const Duration(days: 1)),
                            lastDate: DateTime(DateTime.now().year + 3),
                          );
                          if (d != null) {
                            set(() => when = DateTime(d.year, d.month, d.day, when.hour, when.minute));
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.access_time, size: 16),
                        label: Text(DateFormat('h:mm a').format(when)),
                        onPressed: () async {
                          final t = await showTimePicker(
                            context: ctx,
                            initialTime: TimeOfDay.fromDateTime(when),
                          );
                          if (t != null) {
                            set(() => when = DateTime(when.year, when.month, when.day, t.hour, t.minute));
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: countCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Total repeat count',
                    hintText: 'e.g. 7 calls (for a week), 30 calls (for a month)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: everyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Repeat every',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<int>(
                        initialValue: unit,
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('Minute(s)')),
                          DropdownMenuItem(value: 60, child: Text('Hour(s)')),
                          DropdownMenuItem(value: 1440, child: Text('Day(s)')),
                        ],
                        onChanged: (v) => set(() => unit = v ?? 1440),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: olive),
              onPressed: () async {
                final count = int.tryParse(countCtrl.text) ?? 0;
                final every = (int.tryParse(everyCtrl.text) ?? 0) * unit;

                if (count < 1 || every < 1) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Please enter valid positive numbers.')),
                  );
                  return;
                }

                final iso = when.toUtc().toIso8601String();
                await db.from('call_schedules').insert({
                  'elder_id': elderId,
                  'start_at': iso,
                  'next_run_at': iso,
                  'repeat_count': count,
                  'interval_minutes': every,
                  'runs_done': 0,
                  'active': true,
                });

                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save Schedule'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: db
          .from('call_schedules')
          .stream(primaryKey: ['id'])
          .eq('elder_id', elderId)
          .order('start_at'),
      builder: (context, snapshot) {
        final schedules = snapshot.data ?? [];

        return ListView(
          padding: const EdgeInsets.all(18),
          children: [
            // Info Header
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F5F1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: sage.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.alarm_on, color: sage, size: 24),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Automated check-in calls ring on Amma’s phone at set intervals to confirm she took medicines and had meals.',
                      style: TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quick Preset Suggestions
            const Text(
              'Quick Geriatric Check-in Presets:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: olive),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _presetChip(
                    title: 'Morning Meds & Breakfast',
                    timeStr: '8:30 AM Daily',
                    onTap: () => _addPreset('Morning Meds & Breakfast', const TimeOfDay(hour: 8, minute: 30)),
                  ),
                  const SizedBox(width: 8),
                  _presetChip(
                    title: 'Afternoon Lunch',
                    timeStr: '1:30 PM Daily',
                    onTap: () => _addPreset('Afternoon Lunch', const TimeOfDay(hour: 13, minute: 30)),
                  ),
                  const SizedBox(width: 8),
                  _presetChip(
                    title: 'Night Medicine',
                    timeStr: '8:30 PM Daily',
                    onTap: () => _addPreset('Night Medicine', const TimeOfDay(hour: 20, minute: 30)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Schedule Cards List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Active Call Schedules',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: olive),
                ),
                Text(
                  '${schedules.length} configured',
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (schedules.isEmpty)
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.schedule, size: 40, color: Colors.black26),
                    SizedBox(height: 10),
                    Text(
                      'No schedules yet. Tap below or choose a preset to set up automated check-ins for Amma.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ],
                ),
              )
            else
              ...schedules.map((r) {
                final id = r['id'] as String;
                final active = r['active'] == true;
                final repeatCount = (r['repeat_count'] as num?)?.toInt() ?? 1;
                final runsDone = (r['runs_done'] as num?)?.toInt() ?? 0;
                final intervalMins = (r['interval_minutes'] as num?)?.toInt() ?? 1440;
                final startAt = r['start_at']?.toString();
                final nextRunAt = r['next_run_at']?.toString();

                final progress = repeatCount > 0 ? (runsDone / repeatCount).clamp(0.0, 1.0) : 0.0;
                final isCompleted = runsDone >= repeatCount;

                final countdown = _formatCountdown(nextRunAt, active);

                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: active ? sage.withValues(alpha: 0.3) : Colors.black12,
                      width: active ? 1.5 : 1,
                    ),
                  ),
                  color: active ? Colors.white : const Color(0xFFF8F8F7),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: Interval and Active Toggle
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: active ? sageLight : const Color(0xFFEBEBE9),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.ring_volume,
                                size: 18,
                                color: active ? sage : Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatInterval(intervalMins),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: active ? Colors.black87 : Colors.grey.shade600,
                                    ),
                                  ),
                                  if (startAt != null)
                                    Text(
                                      'First call: ${DateFormat('d MMM, h:mm a').format(DateTime.parse(startAt).toLocal())}',
                                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                                    ),
                                ],
                              ),
                            ),
                            Switch(
                              value: active,
                              activeThumbColor: sage,
                              onChanged: (v) => _toggleSchedule(id, v),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Upcoming Countdown Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: active
                                ? (countdown.contains('Due') ? const Color(0xFFFEF3E2) : const Color(0xFFF1F5F2))
                                : const Color(0xFFF0F0EE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                active ? Icons.hourglass_top : Icons.pause_circle_outline,
                                size: 16,
                                color: active ? sage : Colors.black45,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  countdown,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: active ? Colors.black87 : Colors.black45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Repeat Progress Bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progress: $runsDone of $repeatCount calls done',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87),
                            ),
                            Text(
                              isCompleted ? 'Completed' : '${(progress * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isCompleted ? sage : olive,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isCompleted ? sage : (active ? olive : Colors.grey),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              tooltip: 'Delete schedule',
                              icon: const Icon(Icons.delete_outline, size: 20, color: emergency),
                              onPressed: () => _deleteSchedule(id),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),

            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: olive,
                minimumSize: const Size(0, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _addCustomSchedule,
              icon: const Icon(Icons.add_alarm),
              label: const Text('Add Custom Schedule', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _presetChip({
    required String title,
    required String timeStr,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: olive.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.add_circle_outline, size: 14, color: sage),
                const SizedBox(width: 5),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: olive)),
              ],
            ),
            const SizedBox(height: 2),
            Text(timeStr, style: const TextStyle(fontSize: 11, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
