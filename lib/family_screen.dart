import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'config.dart';
import 'customize_screen.dart';
import 'main.dart';

const olive = Color(0xFF343B2D), sage = Color(0xFF78866A), concern = Color(0xFFA56D24), emergency = Color(0xFFB74638), unknown = Color(0xFF77786F);
const stages = ['Alert sent', 'Accepted', 'En route', 'Arrived', 'Resolved'];

class FamilyScreen extends StatefulWidget {
  final VoidCallback onSwitch;
  const FamilyScreen({super.key, required this.onSwitch});
  @override
  State<FamilyScreen> createState() => _F();
}

class _F extends State<FamilyScreen> {
  String? msg;
  Timer? _schedTimer;
  void say(String m) { if (mounted) setState(() => msg = m); }

  @override
  void initState() {
    super.initState();
    _checkDueSchedules();
    _schedTimer = Timer.periodic(const Duration(seconds: 5), (_) => _checkDueSchedules());
  }

  @override
  void dispose() {
    _schedTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkDueSchedules() async {
    try {
      final nowIso = DateTime.now().toUtc().toIso8601String();
      final due = await db
          .from('call_schedules')
          .select()
          .eq('elder_id', elderId)
          .eq('active', true)
          .lte('next_run_at', nowIso)
          .limit(5);

      for (final s in due) {
        final done = ((s['runs_done'] as num?)?.toInt() ?? 0) + 1;
        final intervalMin = (s['interval_minutes'] as num?)?.toInt() ?? 1440;
        final repeatCount = (s['repeat_count'] as num?)?.toInt() ?? 1;

        final rawNext = s['next_run_at'] != null ? DateTime.tryParse(s['next_run_at']) : null;
        final baseTime = rawNext ?? DateTime.now();
        final nextIso = baseTime.add(Duration(minutes: intervalMin)).toUtc().toIso8601String();

        await db.from('call_schedules').update({
          'runs_done': done,
          'next_run_at': nextIso,
          'active': done < repeatCount,
        }).eq('id', s['id']);

        await callNow(fromSchedule: true);
      }
    } catch (e) {
      debugPrint('Schedule check exception: $e');
    }
  }

  Future<void> callNow({bool fromSchedule = false}) async {
    say(fromSchedule ? 'Initiating scheduled cellular call…' : 'Initiating cellular call to Elder…');
    bool exotelPlaced = false;
    String? exotelError;

    try {
      final res = await db.functions.invoke('start-call', body: {'elder_id': elderId});
      if (res.status == 200 && res.data != null && res.data['call_sid'] != null) {
        exotelPlaced = true;
        final dialed = res.data['dialed_phone'] ?? 'Elder SIM';
        say('Cellular call placed via Exotel! Dialing $dialed…');
      } else {
        final err = res.data is Map ? (res.data['error'] ?? res.data['message']) : null;
        exotelError = err?.toString() ?? 'HTTP ${res.status} error from Exotel';
      }
    } catch (e) {
      exotelError = e.toString();
    }

    if (!exotelPlaced) {
      debugPrint('Exotel cellular call failed: $exotelError');
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.phone_missed, color: Color(0xFFB93832)),
                SizedBox(width: 8),
                Expanded(child: Text('Cellular Call Not Placed', style: TextStyle(fontSize: 18))),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'The cellular GSM call to the elder\'s SIM could not be placed through Exotel:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEECEB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFF5C2C0)),
                  ),
                  child: Text(
                    exotelError ?? 'Unknown error',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF8B1A10)),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'How to resolve:\n'
                  '• In Exotel trial accounts, verify the destination mobile number in Exotel Console -> Whitelisted numbers.\n'
                  '• Go to Customize -> Grandparent phone details and ensure a valid 10-digit number is saved.\n'
                  '• Check that EXOTEL_SID, EXOTEL_KEY, EXOTEL_TOKEN & EXOPHONE secrets are set in Supabase.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF5A665E), height: 1.35),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  db.from('checkins').insert({
                    'elder_id': elderId,
                    'source': fromSchedule ? 'scheduled_call' : 'call',
                    'call_status': 'INITIATED',
                    'result': 'PENDING',
                  });
                  say('Simulating call inside app only…');
                },
                child: const Text('Fallback to In-App Call'),
              ),
            ],
          ),
        );
      }
    }
  }

  // Mock-adapter path so the whole workflow can also be triggered from one phone if needed.
  Future<void> simulate(bool pressed1) async {
    await db.from('checkins').insert({'elder_id': elderId, 'source': 'simulated', 'food': pressed1, 'meds': pressed1, 'result': pressed1 ? 'FINE' : 'CONCERN', 'call_status': 'ANSWERED'});
    if (!pressed1) { try { await db.from('incidents').insert({'elder_id': elderId, 'trigger': 'simulated call: pressed 2'}); } catch (_) {} }
    say(pressed1 ? 'Simulated: pressed 1' : 'Simulated: pressed 2');
  }
  Future<void> setStatus(String id, String s) => db.from('incidents').update({
        'status': s, 'acknowledged_by': 'Family phone',
        if (s == 'RESOLVED') 'resolved_at': DateTime.now().toUtc().toIso8601String()}).eq('id', id);

  ({String label, IconData icon, Color color}) statusOf(Map<String, dynamic>? c, bool incident) {
    if (incident) return (label: 'Help requested', icon: Icons.warning_amber, color: emergency);
    if (c == null) return (label: 'No response yet', icon: Icons.schedule, color: unknown);
    if (c['result'] == 'PENDING') {
      final cs = c['call_status'];
      return (label: cs == 'ANSWERED' ? 'On call — answering questions…' : 'Ringing Elder phone…', icon: Icons.phone_in_talk, color: olive);
    }
    switch (c['result']) {
      case 'FINE': return (label: 'All is well', icon: Icons.check_circle, color: const Color(0xFF3F5A33));
      case 'CONCERN': return (label: 'Needs follow-up', icon: Icons.error_outline, color: concern);
      default: return (label: 'No response yet', icon: Icons.schedule, color: unknown); // PENDING/UNANSWERED never shown as fine
    }
  }

  @override
  Widget build(BuildContext c) => StreamBuilder<List<Map<String, dynamic>>>(
        stream: db.from('elders').stream(primaryKey: ['id']).eq('id', elderId).limit(1),
        builder: (c, es) {
          final elder = (es.data?.isNotEmpty ?? false) ? es.data!.first : null;
          final elderName = (elder?['name'] ?? 'Lakshmi Amma').toString();
          final elderPhone = (elder?['phone'] ?? '+91XXXXXXXXXX').toString();

          return Scaffold(
            appBar: AppBar(title: const Text('Koode'), backgroundColor: Colors.transparent, actions: [
              IconButton(tooltip: 'Customize questions, schedule & phone', onPressed: () => Navigator.push(c, MaterialPageRoute(builder: (_) => const CustomizeScreen())), icon: const Icon(Icons.tune)),
              IconButton(tooltip: 'Switch phone role', onPressed: widget.onSwitch, icon: const Icon(Icons.swap_horiz)),
            ]),
            body: SafeArea(child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: db.from('incidents').stream(primaryKey: ['id']).eq('elder_id', elderId).order('created_at', ascending: false).limit(1),
              builder: (c, is_) {
                final inc = (is_.data?.isNotEmpty ?? false) && !['RESOLVED', 'CANCELLED'].contains(is_.data!.first['status']) ? is_.data!.first : null;
                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: db.from('checkins').stream(primaryKey: ['id']).eq('elder_id', elderId).order('created_at', ascending: false).limit(30),
                  builder: (c, cs) {
                    return StreamBuilder<List<Map<String, dynamic>>>(
                      stream: db.from('answers').stream(primaryKey: ['id']).order('created_at'),
                      builder: (c, ansSnap) {
                        final list = cs.data ?? [];
                        final allAnswers = ansSnap.data ?? [];
                        final st = statusOf(list.isEmpty ? null : list.first, inc != null);
                        final t = list.isEmpty ? null : DateTime.parse(list.first['created_at']).toLocal();
                        return ListView(padding: const EdgeInsets.all(20), children: [
                          Text("Here's how $elderName is doing today.", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 16),
                          Semantics(container: true, label: '$elderName, ${st.label}${t == null ? '' : ', last update ${DateFormat.jm().format(t)}'}',
                            child: Card(color: const Color(0xFFFFFDF8), child: ListTile(minTileHeight: 72,
                              leading: Icon(st.icon, color: st.color, size: 34),
                              title: Text(elderName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                              subtitle: Text('Phone: $elderPhone\n${st.label} · ${t == null ? 'No check-ins yet' : DateFormat('d MMM, h:mm a').format(t)}', style: TextStyle(fontSize: 15, color: st.color)), isThreeLine: true))),
                          if (inc != null) _incident(inc, elderName),
                          const SizedBox(height: 8),
                          FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: olive, minimumSize: const Size(0, 56)), onPressed: () => callNow(), icon: const Icon(Icons.phone), label: Text('Call $elderName now ($elderPhone)', style: const TextStyle(fontSize: 17))),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)), onPressed: () => Navigator.push(c, MaterialPageRoute(builder: (_) => const CustomizeScreen())), icon: const Icon(Icons.tune), label: const Text('Customize questions, schedule & phone', style: TextStyle(fontSize: 16))),
                          if (msg != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(msg!)),
                          const SizedBox(height: 24),
                          const Text('This week', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          _week(list),
                          const SizedBox(height: 24),
                          const Text('Check-in history', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
                          if (list.isEmpty) const Padding(padding: EdgeInsets.all(8), child: Text('No check-ins recorded for this period.')),
                          for (final r in list.take(10)) _tile(r, allAnswers.where((a) => a['checkin_id'] == r['id']).toList()),
                          const SizedBox(height: 24),
                          ExpansionTile(title: const Text('Demo tools (quick single-phone simulate)'), children: [
                            Row(children: [
                              Expanded(child: OutlinedButton(onPressed: () => simulate(true), child: const Text('Press 1 (fine)'))),
                              const SizedBox(width: 8),
                              Expanded(child: OutlinedButton(onPressed: () => simulate(false), child: const Text('Press 2 (concern)'))),
                            ]),
                            const Padding(padding: EdgeInsets.all(8), child: Text('Quick simulation without second phone.', style: TextStyle(color: unknown))),
                          ]),
                        ]);
                      },
                    );
                  });
              })),
          );
        },
      );

  Widget _incident(Map<String, dynamic> i, String elderName) {
    final s = i['status'] as String;
    final idx = {'ACKNOWLEDGED': 1, 'EN_ROUTE': 2, 'ARRIVED': 3}[s] ?? 0;
    final level = i['level'];
    return Card(color: const Color(0xFFFBE9E7), margin: const EdgeInsets.only(top: 12), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('$elderName needs help', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: emergency)),
      if (i['trigger'] != null) Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('Reason: ${i['trigger']}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
      Text(idx == 0 ? 'Escalation level $level of 3. Nobody has accepted yet.${s == 'LEVEL_3_ESCALATION' ? '\nCall emergency services (112). Pending manual contact.' : ''}' : 'Stage: ${stages[idx]}', style: const TextStyle(fontSize: 16)),
      const SizedBox(height: 8),
      for (var k = 0; k < stages.length; k++) Row(children: [Icon(k <= idx ? Icons.check_circle : Icons.radio_button_unchecked, size: 18, color: k <= idx ? emergency : unknown), const SizedBox(width: 8), Text(stages[k] + (k == idx ? '  (current)' : ''))]),
      const SizedBox(height: 12),
      Wrap(spacing: 8, children: [
        if (idx == 0) FilledButton(onPressed: () => setStatus(i['id'], 'ACKNOWLEDGED'), child: const Text('Accept')),
        if (idx == 1) FilledButton(onPressed: () => setStatus(i['id'], 'EN_ROUTE'), child: const Text("I'm on my way")),
        if (idx == 2) FilledButton(onPressed: () => setStatus(i['id'], 'ARRIVED'), child: const Text("I've arrived")),
        if (idx >= 1) OutlinedButton(onPressed: () => setStatus(i['id'], 'RESOLVED'), child: const Text('Resolve')),
      ]),
    ])));
  }

  Widget _week(List<Map<String, dynamic>> list) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        for (var d = 6; d >= 0; d--) () {
          final day = DateTime.now().subtract(Duration(days: d));
          final r = list.where((x) => DateUtils.isSameDay(DateTime.parse(x['created_at']).toLocal(), day)).map((x) => x['result']).toList();
          final res = r.contains('CONCERN') ? 'CONCERN' : r.contains('FINE') ? 'FINE' : r.isNotEmpty ? 'UNANSWERED' : null;
          final name = {'FINE': 'checked in', 'CONCERN': 'needs follow-up', 'UNANSWERED': 'no response'}[res] ?? 'no data';
          return Semantics(label: '${DateFormat.EEEE().format(day)}: $name', excludeSemantics: true, child: Column(children: [
            Text(DateFormat.E().format(day).substring(0, 2)),
            Icon(res == 'FINE' ? Icons.check_circle : res == 'CONCERN' ? Icons.error : res == null ? Icons.remove : Icons.schedule, color: res == 'FINE' ? sage : res == 'CONCERN' ? concern : unknown)]));
        }(),
      ]);

  Widget _tile(Map<String, dynamic> r, List<Map<String, dynamic>> answers) {
    final res = r['result'] as String;
    final label = {'FINE': 'Checked in', 'CONCERN': 'Needs follow-up', 'UNANSWERED': 'No response', 'PENDING': 'Call in progress'}[res] ?? res;
    String ans(dynamic v) => v == null ? '–' : (v ? 'Yes' : 'No');
    final details = answers.isNotEmpty
        ? answers.map((a) => '• ${a['question_text']}: ${a['label']} (key ${a['key']})').join('\n')
        : 'Food eaten: ${ans(r['food'])} · Medicines taken: ${ans(r['meds'])}';
    return ListTile(contentPadding: EdgeInsets.zero, title: Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
      subtitle: Text('${DateFormat('d MMM, h:mm a').format(DateTime.parse(r['created_at']).toLocal())} · ${r['source']}\n$details'));
  }
}
