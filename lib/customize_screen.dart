import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'config.dart';
import 'main.dart';
import 'voice_recorder_widget.dart';

class CustomizeScreen extends StatelessWidget {
  const CustomizeScreen({super.key});
  @override
  Widget build(BuildContext c) => DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(title: const Text('Customize check-in'), bottom: const TabBar(tabs: [Tab(text: 'Questions'), Tab(text: 'Schedule'), Tab(text: 'Phone No.')])),
          body: const TabBarView(children: [_Questions(), _Schedules(), _ElderPhone()]),
        ),
      );
}

// ---------------- Questions ----------------
class _Questions extends StatelessWidget {
  const _Questions();
  @override
  Widget build(BuildContext c) => StreamBuilder<List<Map<String, dynamic>>>(
        stream: db.from('questions').stream(primaryKey: ['id']).eq('elder_id', elderId).order('position'),
        builder: (c, s) {
          if (s.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 48),
                    const SizedBox(height: 12),
                    const Text('Questions database table not found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Please run 002_custom.sql in Supabase SQL Editor.\n\nError: ${s.error}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                  ],
                ),
              ),
            );
          }
          final qs = s.data ?? [];
          return ListView(padding: const EdgeInsets.all(16), children: [
            const Text('Amma is asked these in order. Keys on her phone: press the number shown for each answer.'),
            const SizedBox(height: 12),
            if (qs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('No custom questions yet. Tap "Add question" below to create one with voice!')),
              ),
            for (var i = 0; i < qs.length; i++) Card(child: ListTile(
              leading: qs[i]['audio_url'] != null && (qs[i]['audio_url'] as String).isNotEmpty
                  ? const Tooltip(message: 'Voice recording attached', child: Icon(Icons.mic, color: Color(0xFF2E7D32)))
                  : const Icon(Icons.help_outline, color: Color(0xFF626B68)),
              title: Text('${i + 1}. ${qs[i]['text']}'),
              subtitle: Text((qs[i]['options'] as List).map((o) => '${o['key']} = ${o['label']}${o['concern'] == true ? ' (alert)' : ''}').join('  ·  ')),
              onTap: () => _edit(c, q: qs[i], pos: qs[i]['position']),
              trailing: IconButton(
                tooltip: 'Delete question',
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _confirmDeleteQuestion(c, qs[i]),
              ))),
            const SizedBox(height: 8),
            FilledButton.icon(onPressed: () => _edit(c, pos: qs.isEmpty ? 1 : (qs.last['position'] as int) + 1), icon: const Icon(Icons.add), label: const Text('Add question')),
          ]);
        },
      );

  Future<void> _confirmDeleteQuestion(BuildContext c, Map<String, dynamic> q) async {
    final confirmed = await showDialog<bool>(
      context: c,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Question?'),
        content: Text('Amma will no longer be asked "${q['text']}". Are you sure you want to delete this question?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB93832)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && q['id'] != null) {
      try {
        try {
          await db.from('answers').delete().eq('question_id', q['id']);
        } catch (_) {}
        await db.from('questions').delete().eq('id', q['id']);
        if (c.mounted) {
          ScaffoldMessenger.of(c).showSnackBar(
            const SnackBar(backgroundColor: Color(0xFF2E7D32), content: Text('✓ Question deleted successfully')),
          );
        }
      } catch (e) {
        if (c.mounted) {
          ScaffoldMessenger.of(c).showSnackBar(
            SnackBar(backgroundColor: Colors.red.shade800, content: Text('Could not delete: $e')),
          );
        }
      }
    }
  }

  Future<void> _edit(BuildContext c, {Map<String, dynamic>? q, required int pos}) async {
    final text = TextEditingController(text: q?['text'] ?? '');
    String? recordedAudio = q?['audio_url'];
    bool isVoiceMode = recordedAudio != null && recordedAudio.isNotEmpty;
    bool isSaving = false;
    final opts = q == null
        ? [{'key': '1', 'label': 'Yes', 'concern': false}, {'key': '2', 'label': 'No', 'concern': true}]
        : (q['options'] as List).map((o) => Map<String, dynamic>.from(o)).toList();

    const presets = [
      'Food kazhicho? (Have you eaten food?)',
      'Medicine edutho? (Have you taken your medicines?)',
      'Vellam kudicho? (Did you drink enough water?)',
      'Sugamano? (Are you doing well?)',
    ];

    await showDialog(context: c, builder: (_) => StatefulBuilder(builder: (c, set) => AlertDialog(
      title: Text(q == null ? 'New question' : 'Edit question'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Mode Selector: Text vs Voice Recording
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, icon: Icon(Icons.text_fields), label: Text('Text Question')),
            ButtonSegment(value: true, icon: Icon(Icons.mic), label: Text('Voice Question')),
          ],
          selected: {isVoiceMode},
          onSelectionChanged: (s) {
            set(() {
              isVoiceMode = s.first;
              if (!isVoiceMode) {
                recordedAudio = null;
              } else if (text.text.isEmpty) {
                text.text = 'Food kazhicho? (Voice Question)';
              }
            });
          },
        ),
        const SizedBox(height: 16),

        if (isVoiceMode) ...[
          // --- VOICE QUESTION SECTION ---
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFA5D6A7)),
            ),
            child: const Row(
              children: [
                Icon(Icons.record_voice_over, color: Color(0xFF2E7D32)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Amma will hear your recorded voice during the call instead of robot speech!',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1B5E20)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text('Choose or name your voice question:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF343B2D))),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final p in presets)
                ActionChip(
                  label: Text(p.split(' (')[0], style: const TextStyle(fontSize: 12)),
                  onPressed: () => set(() => text.text = p),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: text,
            decoration: const InputDecoration(
              labelText: 'Question name / title',
              hintText: 'e.g. Food kazhicho?',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          VoiceRecorderWidget(
            initialAudioUrl: recordedAudio,
            onAudioChanged: (url) => set(() {
              recordedAudio = url;
              if (url != null && text.text.trim().isEmpty) {
                text.text = 'Voice Check-in Question';
              }
            }),
          ),
        ] else ...[
          // --- TEXT QUESTION SECTION ---
          const Text('Quick Malayalam presets:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF343B2D))),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final p in presets)
                ActionChip(
                  label: Text(p.split(' (')[0], style: const TextStyle(fontSize: 12)),
                  onPressed: () => set(() => text.text = p),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: text,
            decoration: const InputDecoration(
              labelText: 'Type question text',
              hintText: 'e.g. Have you eaten your food?',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
        ],

        const SizedBox(height: 16),
        const Text('Keypad Answers (Amma presses 1 or 2):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF343B2D))),
        const SizedBox(height: 8),
        for (var i = 0; i < opts.length; i++) Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(children: [
            DropdownButton<String>(
              value: opts[i]['key'],
              items: [for (var k = 1; k <= 9; k++) DropdownMenuItem(value: '$k', child: Text('Press $k'))],
              onChanged: (v) => set(() => opts[i]['key'] = v),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                initialValue: opts[i]['label'],
                decoration: InputDecoration(
                  hintText: i == 0 ? 'e.g. Yes (Kazhichu)' : 'e.g. No (Kazhichilla)',
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                ),
                onChanged: (v) => opts[i]['label'] = v,
              ),
            ),
            const SizedBox(width: 4),
            Tooltip(
              message: 'Check to alert family if chosen',
              child: Column(
                children: [
                  Checkbox(
                    value: opts[i]['concern'] == true,
                    onChanged: (v) => set(() => opts[i]['concern'] = v),
                  ),
                  Text(opts[i]['concern'] == true ? 'Alert' : 'OK', style: TextStyle(fontSize: 10, color: opts[i]['concern'] == true ? Colors.red : Colors.green)),
                ],
              ),
            ),
            if (opts.length > 2) IconButton(icon: const Icon(Icons.close), onPressed: () => set(() => opts.removeAt(i))),
          ]),
        ),
        if (opts.length < 9) TextButton.icon(icon: const Icon(Icons.add), label: const Text('Add another answer key'), onPressed: () {
          final used = opts.map((o) => o['key']).toSet();
          set(() => opts.add({'key': [for (var k = 1; k <= 9; k++) '$k'].firstWhere((k) => !used.contains(k)), 'label': '', 'concern': false}));
        }),
      ])),
      actions: [
        if (q != null && q['id'] != null)
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Delete'),
            onPressed: isSaving ? null : () async {
              Navigator.pop(c);
              await _confirmDeleteQuestion(c, q);
            },
          ),
        TextButton(onPressed: isSaving ? null : () => Navigator.pop(c), child: const Text('Cancel')),
        FilledButton(
          onPressed: isSaving ? null : () async {
            final keys = opts.map((o) => o['key']).toList();
            if (text.text.trim().isEmpty || opts.any((o) => (o['label'] as String).trim().isEmpty) || keys.toSet().length != keys.length) {
              ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content: Text('Please fill the question title, all answer labels, and ensure keys are unique.'))); 
              return;
            }
            if (isVoiceMode && (recordedAudio == null || recordedAudio!.isEmpty)) {
              ScaffoldMessenger.of(c).showSnackBar(const SnackBar(backgroundColor: Colors.orange, content: Text('Please tap the microphone button to record your voice first!'))); 
              return;
            }
            set(() => isSaving = true);
            try {
              final row = {
                'text': text.text.trim(),
                'audio_url': isVoiceMode ? recordedAudio : null,
                'options': opts,
                'enabled': q?['enabled'] ?? true,
              };
              if (q == null || q['id'] == null) {
                await db.from('questions').insert({
                  ...row,
                  'elder_id': elderId,
                  'position': pos,
                });
              } else {
                await db.from('questions').update(row).eq('id', q['id']);
              }
              if (c.mounted) {
                Navigator.pop(c);
                ScaffoldMessenger.of(c).showSnackBar(
                  const SnackBar(backgroundColor: Color(0xFF2E7D32), content: Text('✓ Question saved successfully!')),
                );
              }
            } catch (err) {
              if (c.mounted) {
                ScaffoldMessenger.of(c).showSnackBar(
                  SnackBar(backgroundColor: Colors.red.shade800, content: Text('Could not save: $err')),
                );
              }
            } finally {
              if (c.mounted) set(() => isSaving = false);
            }
          }, 
          child: Text(isSaving ? 'Saving...' : 'Save Question'),
        ),
      ],
    )));
  }
}

// ---------------- Schedule ----------------
String _every(int m) => m % 1440 == 0 ? '${m ~/ 1440} day(s)' : m % 60 == 0 ? '${m ~/ 60} hour(s)' : '$m minute(s)';

class _Schedules extends StatelessWidget {
  const _Schedules();

  Future<void> _triggerScheduleNow(BuildContext c, Map<String, dynamic> r) async {
    try {
      ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content: Text('Triggering call for this schedule…')));
      bool exotelPlaced = false;
      String? exotelError;

      try {
        final res = await db.functions.invoke('start-call', body: {'elder_id': elderId});
        if (res.status == 200 && res.data != null && res.data['call_sid'] != null) {
          exotelPlaced = true;
        } else {
          final err = res.data is Map ? (res.data['error'] ?? res.data['message']) : null;
          exotelError = err?.toString() ?? 'Exotel returned HTTP ${res.status}';
        }
      } catch (e) {
        exotelError = e.toString();
      }

      if (!exotelPlaced) {
        await db.from('checkins').insert({
          'elder_id': elderId,
          'source': 'scheduled_call',
          'call_status': 'INITIATED',
          'result': 'PENDING',
        });
      }

      final done = ((r['runs_done'] as num?)?.toInt() ?? 0) + 1;
      final intervalMin = (r['interval_minutes'] as num?)?.toInt() ?? 1440;
      final repeatCount = (r['repeat_count'] as num?)?.toInt() ?? 1;
      final nextIso = DateTime.now().add(Duration(minutes: intervalMin)).toUtc().toIso8601String();

      await db.from('call_schedules').update({
        'runs_done': done,
        'next_run_at': nextIso,
        'active': done < repeatCount,
      }).eq('id', r['id']);

      if (c.mounted) {
        ScaffoldMessenger.of(c).showSnackBar(
          SnackBar(
            backgroundColor: exotelPlaced ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
            duration: const Duration(seconds: 4),
            content: Text(
              exotelPlaced
                  ? '✓ Cellular call placed via Exotel! SIM phone is ringing.'
                  : '⚠️ Exotel cellular call failed ($exotelError). In-app simulation initiated.',
            ),
          ),
        );
      }
    } catch (e) {
      if (c.mounted) {
        ScaffoldMessenger.of(c).showSnackBar(SnackBar(backgroundColor: Colors.red.shade800, content: Text('Trigger error: $e')));
      }
    }
  }

  Future<void> _confirmDeleteSchedule(BuildContext c, Map<String, dynamic> r) async {
    final confirmed = await showDialog<bool>(
      context: c,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Call Schedule?'),
        content: const Text('Amma will no longer receive automated calls from this schedule. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB93832)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && r['id'] != null) {
      try {
        await db.from('call_schedules').delete().eq('id', r['id']);
        if (c.mounted) {
          ScaffoldMessenger.of(c).showSnackBar(
            const SnackBar(backgroundColor: Color(0xFF2E7D32), content: Text('✓ Schedule deleted successfully')),
          );
        }
      } catch (e) {
        if (c.mounted) {
          ScaffoldMessenger.of(c).showSnackBar(
            SnackBar(backgroundColor: Colors.red.shade800, content: Text('Could not delete schedule: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext c) => StreamBuilder<List<Map<String, dynamic>>>(
        stream: db.from('call_schedules').stream(primaryKey: ['id']).eq('elder_id', elderId).order('start_at'),
        builder: (c, s) => ListView(padding: const EdgeInsets.all(16), children: [
          if (s.data?.isEmpty ?? true)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('No schedules yet. Tap "Add schedule" below to set automated calling times.')),
            ),
          for (final r in s.data ?? []) Card(child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: ListTile(
              leading: Icon(
                r['active'] == true ? Icons.alarm_on : Icons.alarm_off,
                color: r['active'] == true ? const Color(0xFF2E7D32) : const Color(0xFF626B68),
                size: 28,
              ),
              title: Text(DateFormat('d MMM y, h:mm a').format(DateTime.parse(r['start_at']).toLocal()), style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Text('${r['repeat_count']} call(s), every ${_every(r['interval_minutes'])} · Done: ${r['runs_done']}/${r['repeat_count']}'),
                  const SizedBox(height: 4),
                  if (r['next_run_at'] != null)
                    Text(
                      'Next call: ${DateFormat('h:mm a, d MMM').format(DateTime.parse(r['next_run_at']).toLocal())}',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2E7D32), fontSize: 13),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                        ),
                        icon: const Icon(Icons.phone_in_talk, size: 14),
                        label: const Text('Test Trigger', style: TextStyle(fontSize: 12)),
                        onPressed: () => _triggerScheduleNow(c, r),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                        ),
                        icon: const Icon(Icons.edit, size: 14),
                        label: const Text('Edit', style: TextStyle(fontSize: 12)),
                        onPressed: () => _editOrAdd(c, schedule: r),
                      ),
                    ],
                  ),
                ],
              ),
              isThreeLine: true,
              onTap: () => _editOrAdd(c, schedule: r),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Switch(
                  value: r['active'] == true,
                  onChanged: (v) async {
                    try {
                      await db.from('call_schedules').update({'active': v}).eq('id', r['id']);
                    } catch (e) {
                      if (c.mounted) ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text('Update error: $e')));
                    }
                  },
                ),
                IconButton(
                  tooltip: 'Delete schedule',
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _confirmDeleteSchedule(c, r),
                ),
              ]),
            ),
          )),
          const SizedBox(height: 8),
          FilledButton.icon(onPressed: () => _editOrAdd(c), icon: const Icon(Icons.add_alarm), label: const Text('Add schedule')),
        ]),
      );

  Future<void> _editOrAdd(BuildContext c, {Map<String, dynamic>? schedule}) async {
    final isEdit = schedule != null;
    var when = isEdit
        ? DateTime.parse(schedule['start_at']).toLocal()
        : DateTime.now().add(const Duration(minutes: 5));

    final totalMinutes = isEdit ? (schedule['interval_minutes'] as int) : 1440;
    int initialUnit = 1440;
    int initialValue = 1;
    if (totalMinutes % 1440 == 0) {
      initialUnit = 1440;
      initialValue = totalMinutes ~/ 1440;
    } else if (totalMinutes % 60 == 0) {
      initialUnit = 60;
      initialValue = totalMinutes ~/ 60;
    } else {
      initialUnit = 1;
      initialValue = totalMinutes;
    }

    final count = TextEditingController(text: isEdit ? schedule['repeat_count'].toString() : '1');
    final every = TextEditingController(text: initialValue.toString());
    var unit = initialUnit;
    var active = isEdit ? (schedule['active'] == true) : true;
    bool isSaving = false;

    await showDialog(context: c, builder: (_) => StatefulBuilder(builder: (ctx, set) => AlertDialog(
      title: Text(isEdit ? 'Edit call schedule' : 'New call schedule'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Quick presets for testing & setup:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF343B2D))),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            ActionChip(
              avatar: const Icon(Icons.timer_outlined, size: 14, color: Colors.deepOrange),
              label: const Text('In 1 minute (test)', style: TextStyle(fontSize: 12)),
              onPressed: () => set(() => when = DateTime.now().add(const Duration(minutes: 1))),
            ),
            ActionChip(
              label: const Text('In 5 minutes', style: TextStyle(fontSize: 12)),
              onPressed: () => set(() => when = DateTime.now().add(const Duration(minutes: 5))),
            ),
            ActionChip(
              label: const Text('Daily 8:00 AM', style: TextStyle(fontSize: 12)),
              onPressed: () {
                final now = DateTime.now();
                var t = DateTime(now.year, now.month, now.day, 8, 0);
                if (t.isBefore(now)) t = t.add(const Duration(days: 1));
                set(() {
                  when = t;
                  unit = 1440;
                  every.text = '1';
                });
              },
            ),
            ActionChip(
              label: const Text('Daily 8:00 PM', style: TextStyle(fontSize: 12)),
              onPressed: () {
                final now = DateTime.now();
                var t = DateTime(now.year, now.month, now.day, 20, 0);
                if (t.isBefore(now)) t = t.add(const Duration(days: 1));
                set(() {
                  when = t;
                  unit = 1440;
                  every.text = '1';
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text('Schedule start date & time:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF343B2D))),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text(DateFormat('d MMM y').format(when)),
              onPressed: () async {
                final d = await showDatePicker(
                  context: ctx,
                  initialDate: when,
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime(DateTime.now().year + 5),
                );
                if (d != null) set(() => when = DateTime(d.year, d.month, d.day, when.hour, when.minute));
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.access_time, size: 16),
              label: Text(DateFormat('h:mm a').format(when)),
              onPressed: () async {
                final t = await showTimePicker(context: ctx, initialTime: TimeOfDay.fromDateTime(when));
                if (t != null) set(() => when = DateTime(when.year, when.month, when.day, t.hour, t.minute));
              },
            ),
          ),
        ]),
        const SizedBox(height: 14),
        TextField(
          controller: count,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Number of calls (repeats)',
            hintText: 'e.g. 5',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: TextField(
              controller: every,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Repeat every',
                hintText: 'e.g. 1',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          DropdownButton<int>(
            value: unit,
            items: const [
              DropdownMenuItem(value: 1, child: Text('minutes')),
              DropdownMenuItem(value: 60, child: Text('hours')),
              DropdownMenuItem(value: 1440, child: Text('days')),
            ],
            onChanged: (v) => set(() => unit = v!),
          ),
        ]),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Schedule active', style: TextStyle(fontSize: 14)),
          value: active,
          onChanged: (v) => set(() => active = v),
        ),
      ])),
      actions: [
        if (isEdit)
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Delete'),
            onPressed: isSaving ? null : () async {
              Navigator.pop(ctx);
              await _confirmDeleteSchedule(c, schedule);
            },
          ),
        TextButton(onPressed: isSaving ? null : () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(
          onPressed: isSaving ? null : () async {
            final n = int.tryParse(count.text) ?? 0, e = (int.tryParse(every.text) ?? 0) * unit;
            if (n < 1 || e < 1) {
              ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Please enter whole numbers of 1 or more.')));
              return;
            }
            set(() => isSaving = true);
            try {
              final iso = when.toUtc().toIso8601String();
              if (isEdit) {
                await db.from('call_schedules').update({
                  'start_at': iso,
                  'next_run_at': iso,
                  'repeat_count': n,
                  'interval_minutes': e,
                  'active': active,
                }).eq('id', schedule['id']);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(c).showSnackBar(
                    const SnackBar(backgroundColor: Color(0xFF2E7D32), content: Text('✓ Schedule updated successfully!')),
                  );
                }
              } else {
                await db.from('call_schedules').insert({
                  'elder_id': elderId,
                  'start_at': iso,
                  'next_run_at': iso,
                  'repeat_count': n,
                  'interval_minutes': e,
                  'active': active,
                });
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(c).showSnackBar(
                    const SnackBar(backgroundColor: Color(0xFF2E7D32), content: Text('✓ New schedule created!')),
                  );
                }
              }
            } catch (err) {
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(backgroundColor: Colors.red.shade800, content: Text('Schedule save error: $err')));
              }
            } finally {
              if (ctx.mounted) set(() => isSaving = false);
            }
          },
          child: Text(isSaving ? 'Saving...' : (isEdit ? 'Save Changes' : 'Create Schedule')),
        ),
      ],
    )));
  }
}

// ---------------- Elder Phone Number ----------------
class _ElderPhone extends StatefulWidget {
  const _ElderPhone();
  @override
  State<_ElderPhone> createState() => _ElderPhoneState();
}

class _ElderPhoneState extends State<_ElderPhone> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  bool _consent = true;
  bool _loaded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final row = await db.from('elders').select().eq('id', elderId).maybeSingle();
    if (row != null && mounted) {
      setState(() {
        _name.text = (row['name'] ?? 'Lakshmi Amma').toString();
        _phone.text = (row['phone'] ?? '+91').toString();
        _consent = row['consent'] == true;
        _loaded = true;
      });
    }
  }

  Future<void> _save() async {
    if (_phone.text.trim().isEmpty || _name.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await db.from('elders').upsert({
        'id': elderId,
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'consent': _consent,
        'consent_at': DateTime.now().toUtc().toIso8601String(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phone number & details saved!')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext c) => !_loaded
      ? const Center(child: CircularProgressIndicator())
      : ListView(padding: const EdgeInsets.all(20), children: [
          const Text('Grandparent phone details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Saved in Supabase and preserved across all phones and scheduled calls.'),
          const SizedBox(height: 16),
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Elder name', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone number (e.g. +918714127772)', hintText: '+919876543210', border: OutlineInputBorder(), helperText: 'Enter real phone number. Must be whitelisted in Exotel trial to receive cellular calls.')),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Consent given to receive automated check-in calls'),
            value: _consent,
            onChanged: (v) => setState(() => _consent = v),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save),
            label: Text(_saving ? 'Saving…' : 'Save phone number'),
          ),
        ]);
}