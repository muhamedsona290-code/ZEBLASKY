import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'config.dart';
import 'main.dart';

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
          final qs = s.data ?? [];
          return ListView(padding: const EdgeInsets.all(16), children: [
            const Text('Amma is asked these in order. Keys on her phone: press the number shown for each answer.'),
            for (var i = 0; i < qs.length; i++) Card(child: ListTile(
              title: Text('${i + 1}. ${qs[i]['text']}'),
              subtitle: Text((qs[i]['options'] as List).map((o) => '${o['key']} = ${o['label']}${o['concern'] == true ? ' (alert)' : ''}').join('  ·  ')),
              onTap: () => _edit(c, q: qs[i], pos: qs[i]['position']),
              trailing: IconButton(tooltip: 'Delete question', icon: const Icon(Icons.delete_outline), onPressed: () => db.from('questions').delete().eq('id', qs[i]['id'])))),
            const SizedBox(height: 8),
            FilledButton.icon(onPressed: () => _edit(c, pos: qs.isEmpty ? 1 : (qs.last['position'] as int) + 1), icon: const Icon(Icons.add), label: const Text('Add question')),
          ]);
        },
      );

  Future<void> _edit(BuildContext c, {Map<String, dynamic>? q, required int pos}) async {
    final text = TextEditingController(text: q?['text'] ?? ''), audio = TextEditingController(text: q?['audio_url'] ?? '');
    final opts = q == null
        ? [{'key': '1', 'label': 'Yes', 'concern': false}, {'key': '2', 'label': 'No', 'concern': true}]
        : (q['options'] as List).map((o) => Map<String, dynamic>.from(o)).toList();
    await showDialog(context: c, builder: (_) => StatefulBuilder(builder: (c, set) => AlertDialog(
      title: Text(q == null ? 'New question' : 'Edit question'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: text, decoration: const InputDecoration(labelText: 'Question'), maxLines: null),
        TextField(controller: audio, decoration: const InputDecoration(labelText: 'Malayalam audio URL (optional)')),
        const SizedBox(height: 12),
        for (var i = 0; i < opts.length; i++) Row(children: [
          DropdownButton<String>(value: opts[i]['key'], items: [for (var k = 1; k <= 9; k++) DropdownMenuItem(value: '$k', child: Text('$k'))], onChanged: (v) => set(() => opts[i]['key'] = v)),
          const SizedBox(width: 8),
          Expanded(child: TextFormField(initialValue: opts[i]['label'], decoration: const InputDecoration(hintText: 'Answer'), onChanged: (v) => opts[i]['label'] = v)),
          Tooltip(message: 'Alert family if chosen', child: Checkbox(value: opts[i]['concern'] == true, onChanged: (v) => set(() => opts[i]['concern'] = v))),
          if (opts.length > 1) IconButton(icon: const Icon(Icons.close), onPressed: () => set(() => opts.removeAt(i))),
        ]),
        if (opts.length < 9) TextButton.icon(icon: const Icon(Icons.add), label: const Text('Add answer'), onPressed: () {
          final used = opts.map((o) => o['key']).toSet();
          set(() => opts.add({'key': [for (var k = 1; k <= 9; k++) '$k'].firstWhere((k) => !used.contains(k)), 'label': '', 'concern': false}));
        }),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
        FilledButton(onPressed: () async {
          final keys = opts.map((o) => o['key']).toList();
          if (text.text.trim().isEmpty || opts.any((o) => (o['label'] as String).trim().isEmpty) || keys.toSet().length != keys.length) {
            ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content: Text('Fill the question, every answer, and use each key once.'))); return;
          }
          final row = {'text': text.text.trim(), 'audio_url': audio.text.trim().isEmpty ? null : audio.text.trim(), 'options': opts};
          q == null ? await db.from('questions').insert({...row, 'elder_id': elderId, 'position': pos}) : await db.from('questions').update(row).eq('id', q['id']);
          if (c.mounted) Navigator.pop(c);
        }, child: const Text('Save')),
      ],
    )));
  }
}

// ---------------- Schedule ----------------
String _every(int m) => m % 1440 == 0 ? '${m ~/ 1440} day(s)' : m % 60 == 0 ? '${m ~/ 60} hour(s)' : '$m minute(s)';

class _Schedules extends StatelessWidget {
  const _Schedules();
  @override
  Widget build(BuildContext c) => StreamBuilder<List<Map<String, dynamic>>>(
        stream: db.from('call_schedules').stream(primaryKey: ['id']).eq('elder_id', elderId).order('start_at'),
        builder: (c, s) => ListView(padding: const EdgeInsets.all(16), children: [
          if (s.data?.isEmpty ?? true) const Text('No schedules yet. Add one so Amma gets an automatic call.'),
          for (final r in s.data ?? []) Card(child: ListTile(
            title: Text(DateFormat('d MMM y, h:mm a').format(DateTime.parse(r['start_at']).toLocal())),
            subtitle: Text('${r['repeat_count']} call(s), every ${_every(r['interval_minutes'])}\nDone: ${r['runs_done']}/${r['repeat_count']}'), isThreeLine: true,
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              Switch(value: r['active'] == true, onChanged: (v) => db.from('call_schedules').update({'active': v}).eq('id', r['id'])),
              IconButton(tooltip: 'Delete schedule', icon: const Icon(Icons.delete_outline), onPressed: () => db.from('call_schedules').delete().eq('id', r['id'])),
            ]))),
          FilledButton.icon(onPressed: () => _add(c), icon: const Icon(Icons.add_alarm), label: const Text('Add schedule')),
        ]),
      );

  Future<void> _add(BuildContext c) async {
    var when = DateTime.now().add(const Duration(minutes: 5));
    final count = TextEditingController(text: '1'), every = TextEditingController(text: '1');
    var unit = 1440;
    await showDialog(context: c, builder: (_) => StatefulBuilder(builder: (c, set) => AlertDialog(
      title: const Text('New call schedule'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        OutlinedButton.icon(icon: const Icon(Icons.calendar_today), label: Text(DateFormat('d MMM y').format(when)), onPressed: () async {
          final d = await showDatePicker(context: c, initialDate: when, firstDate: DateTime.now().subtract(const Duration(days: 1)), lastDate: DateTime(DateTime.now().year + 3));
          if (d != null) set(() => when = DateTime(d.year, d.month, d.day, when.hour, when.minute));
        }),
        OutlinedButton.icon(icon: const Icon(Icons.access_time), label: Text(DateFormat('h:mm a').format(when)), onPressed: () async {
          final t = await showTimePicker(context: c, initialTime: TimeOfDay.fromDateTime(when));
          if (t != null) set(() => when = DateTime(when.year, when.month, when.day, t.hour, t.minute));
        }),
        TextField(controller: count, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Number of calls (repeats)')),
        Row(children: [
          Expanded(child: TextField(controller: every, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Repeat every'))),
          const SizedBox(width: 12),
          DropdownButton<int>(value: unit, items: const [DropdownMenuItem(value: 1, child: Text('minutes')), DropdownMenuItem(value: 60, child: Text('hours')), DropdownMenuItem(value: 1440, child: Text('days'))], onChanged: (v) => set(() => unit = v!)),
        ]),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
        FilledButton(onPressed: () async {
          final n = int.tryParse(count.text) ?? 0, e = (int.tryParse(every.text) ?? 0) * unit;
          if (n < 1 || e < 1) { ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content: Text('Enter whole numbers of 1 or more.'))); return; }
          final iso = when.toUtc().toIso8601String();
          await db.from('call_schedules').insert({'elder_id': elderId, 'start_at': iso, 'next_run_at': iso, 'repeat_count': n, 'interval_minutes': e});
          if (c.mounted) Navigator.pop(c);
        }, child: const Text('Save')),
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
          TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone number (with +91)', hintText: '+919876543210', border: OutlineInputBorder())),
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