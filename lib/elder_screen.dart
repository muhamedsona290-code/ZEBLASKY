import 'dart:async';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'config.dart';
import 'main.dart';

class ElderScreen extends StatefulWidget {
  final VoidCallback onSwitch;
  const ElderScreen({super.key, required this.onSwitch});
  @override
  State<ElderScreen> createState() => _E();
}

class _E extends State<ElderScreen> {
  bool busy = false;
  String? msg;
  String? _activeCallId;
  bool _answered = false;
  List<Map<String, dynamic>> _questions = [];
  int _qIdx = 0;
  bool _hadConcern = false;
  String? _ivrPrompt;
  late final AudioPlayer _audioPlayer;
  late final AudioPlayer _ringPlayer;
  Timer? _vibrateTimer;
  Timer? _schedTimer;
  bool _isRinging = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _ringPlayer = AudioPlayer();
    _schedTimer = Timer.periodic(const Duration(seconds: 10), (_) => _checkDueSchedules());
    _checkDueSchedules();
  }

  @override
  void dispose() {
    _stopRingtone();
    _schedTimer?.cancel();
    _ringPlayer.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _startRingtone() async {
    if (_isRinging) return;
    _isRinging = true;
    try {
      await _ringPlayer.setReleaseMode(ReleaseMode.loop);
      // High-quality public telecom telephone ring sound
      await _ringPlayer.play(UrlSource('https://actions.google.com/sounds/v1/telephones/phone_ring.ogg'));
    } catch (_) {}
    _vibrateTimer?.cancel();
    _vibrateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      HapticFeedback.heavyImpact();
    });
  }

  void _stopRingtone() {
    if (!_isRinging) return;
    _isRinging = false;
    _vibrateTimer?.cancel();
    _vibrateTimer = null;
    try {
      _ringPlayer.stop();
    } catch (_) {}
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

        bool exotelPlaced = false;
        try {
          final res = await db.functions.invoke('start-call', body: {'elder_id': elderId});
          if (res.status == 200 && res.data != null && res.data['call_sid'] != null) {
            exotelPlaced = true;
            debugPrint('Elder screen: Cellular call successfully dispatched via Exotel');
          } else {
            debugPrint('Elder screen: Exotel error HTTP ${res.status}: ${res.data}');
          }
        } catch (e) {
          debugPrint('Elder screen: Exotel invoke exception: $e');
        }

        if (!exotelPlaced) {
          await db.from('checkins').insert({
            'elder_id': elderId,
            'source': 'scheduled_call',
            'call_status': 'INITIATED',
            'result': 'PENDING',
          });
        }
      }
    } catch (e) {
      debugPrint('Elder screen schedule error: $e');
    }
  }

  void _playPrompt(String? audioUrl) {
    if (audioUrl == null || audioUrl.isEmpty) return;
    try {
      if (audioUrl.startsWith('data:audio')) {
        final comma = audioUrl.indexOf(',');
        final b64 = comma != -1 ? audioUrl.substring(comma + 1) : audioUrl;
        _audioPlayer.play(BytesSource(base64Decode(b64)));
      } else if (audioUrl.startsWith('http')) {
        _audioPlayer.play(UrlSource(audioUrl));
      } else {
        _audioPlayer.play(DeviceFileSource(audioUrl));
      }
    } catch (_) {}
  }

  Future<void> run(Future<void> Function() f, String ok) async {
    if (busy) return; // prevent duplicate submissions
    setState(() { busy = true; msg = null; });
    try { await f(); msg = ok; } catch (e) { msg = 'Could not send. Please try again or call for help.'; }
    if (mounted) setState(() => busy = false);
  }

  Future<void> imOkay() => run(() async {
        await db.from('checkins').insert({'elder_id': elderId, 'source': 'app', 'food': true, 'meds': true, 'result': 'FINE', 'call_status': 'COMPLETED'});
      }, "You're checked in");

  Future<void> sos(String why) => run(() async {
        try { await db.from('incidents').insert({'elder_id': elderId, 'trigger': why}); }
        on Exception catch (e) { if (!e.toString().contains('23505')) rethrow; } // already open: fine
        await db.from('checkins').insert({'elder_id': elderId, 'source': 'app', 'result': 'CONCERN', 'call_status': 'COMPLETED'});
      }, 'Help requested');

  void helpSheet() => showModalBottomSheet(context: context, builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        for (final r in ['I feel unwell', 'I missed a meal', 'I feel lonely', 'Other'])
          ListTile(minTileHeight: 56, title: Text(r, style: const TextStyle(fontSize: 18)), onTap: () { Navigator.pop(context); sos('app: $r'); }),
      ])));

  Future<void> _acceptCall(Map<String, dynamic> call) async {
    _stopRingtone();
    HapticFeedback.mediumImpact();
    List<Map<String, dynamic>> qs = [];
    try {
      final rows = await db.from('questions').select().eq('elder_id', elderId).eq('enabled', true).order('position');
      qs = List<Map<String, dynamic>>.from(rows);
    } catch (_) {}
    if (qs.isEmpty) {
      qs = [
        {'id': null, 'text': 'Have you eaten your food?', 'options': [{'key': '1', 'label': 'Yes', 'concern': false}, {'key': '2', 'label': 'No', 'concern': true}]},
        {'id': null, 'text': 'Have you taken your medicines on time?', 'options': [{'key': '1', 'label': 'Yes', 'concern': false}, {'key': '2', 'label': 'No', 'concern': true}]},
      ];
    }
    await db.from('checkins').update({'call_status': 'ANSWERED'}).eq('id', call['id']);
    if (mounted) {
      setState(() {
        _activeCallId = call['id'] as String;
        _answered = true;
        _questions = qs;
        _qIdx = 0;
        _hadConcern = false;
        _ivrPrompt = null;
      });
      if (qs.isNotEmpty) {
        _playPrompt(qs[0]['audio_url']?.toString());
      }
    }
  }

  Future<void> _declineOrHangup(Map<String, dynamic> call) async {
    _stopRingtone();
    _audioPlayer.stop();
    HapticFeedback.lightImpact();
    final id = call['id'] as String;
    final wasAnswered = _answered && _activeCallId == id;
    await db.from('checkins').update({
      'call_status': wasAnswered ? 'COMPLETED' : 'UNANSWERED',
      if (!_hadConcern) 'result': 'UNANSWERED',
    }).eq('id', id);
    if (mounted) {
      setState(() {
        _activeCallId = null;
        _answered = false;
        _ivrPrompt = null;
        msg = 'Call ended (unanswered)';
      });
    }
  }

  Future<void> _pressDigit(Map<String, dynamic> call, String digit) async {
    if (busy || _qIdx >= _questions.length) return;
    HapticFeedback.selectionClick();
    final q = _questions[_qIdx];
    final opts = List<Map<String, dynamic>>.from((q['options'] as List).map((o) => Map<String, dynamic>.from(o)));
    final match = opts.where((o) => o['key'].toString() == digit).toList();
    if (match.isEmpty) {
      setState(() => _ivrPrompt = 'Key $digit is not an option. Repeating question — please press ${opts.map((o) => o['key']).join(' or ')}.');
      return;
    }
    final opt = match.first;
    final isConcern = opt['concern'] == true;
    final qText = q['text'].toString();
    final lower = qText.toLowerCase();

    setState(() {
      busy = true;
      _ivrPrompt = 'Pressed $digit (${opt['label']})';
    });

    try {
      try {
        await db.from('answers').insert({
          'checkin_id': call['id'],
          if (q['id'] != null) 'question_id': q['id'],
          'question_text': qText,
          'key': digit,
          'label': opt['label'],
        });
      } catch (_) {}

      final upd = <String, dynamic>{'call_status': 'ANSWERED'};
      if (lower.contains('food') || lower.contains('eat') || lower.contains('meal')) upd['food'] = !isConcern;
      if (lower.contains('med') || lower.contains('tablet') || lower.contains('pill')) upd['meds'] = !isConcern;
      if (isConcern) {
        _hadConcern = true;
        upd['result'] = 'CONCERN';
      }
      await db.from('checkins').update(upd).eq('id', call['id']);

      if (isConcern) {
        try {
          await db.from('incidents').insert({
            'elder_id': elderId,
            'trigger': 'call: "$qText" -> ${opt['label']}',
          });
        } catch (_) {}
      }

      if (_qIdx + 1 < _questions.length) {
        if (mounted) {
          setState(() {
            _qIdx++;
            _ivrPrompt = null;
          });
          _playPrompt(_questions[_qIdx]['audio_url']?.toString());
        }
      } else {
        await db.from('checkins').update({
          'call_status': 'COMPLETED',
          'result': _hadConcern ? 'CONCERN' : 'FINE',
        }).eq('id', call['id']);
        if (mounted) {
          setState(() {
            _activeCallId = null;
            _answered = false;
            _ivrPrompt = null;
            msg = _hadConcern ? 'Call finished — family notified' : 'Call finished — checked in!';
          });
        }
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget _buildCallOverlay(Map<String, dynamic> call, String elderName, String elderPhone) {
    final inIvr = _answered && _activeCallId == call['id'] && _qIdx < _questions.length;
    if (!inIvr) {
      return Card(
        color: const Color(0xFF1F382E),
        margin: const EdgeInsets.only(bottom: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.ring_volume, color: Colors.white, size: 54),
              const SizedBox(height: 12),
              const Text('Incoming Koode Check-in Call', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('$elderName ($elderPhone)', style: const TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB93832), minimumSize: const Size(0, 60)),
                      onPressed: () => _declineOrHangup(call),
                      icon: const Icon(Icons.call_end),
                      label: const Text('Decline', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), minimumSize: const Size(0, 60)),
                      onPressed: () => _acceptCall(call),
                      icon: const Icon(Icons.call),
                      label: const Text('Answer', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final q = _questions[_qIdx];
    final opts = List<Map<String, dynamic>>.from((q['options'] as List).map((o) => Map<String, dynamic>.from(o)));
    final optByKey = {for (final o in opts) o['key'].toString(): o};

    return Card(
      color: const Color(0xFF1F382E),
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Question ${_qIdx + 1} of ${_questions.length}', style: const TextStyle(color: Colors.white70, fontSize: 16)),
                Text(elderPhone, style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              q['text'].toString(),
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final o in opts)
                  Chip(
                    backgroundColor: o['concern'] == true ? const Color(0xFFFBE9E7) : const Color(0xFFE8F5E9),
                    label: Text('Press ${o['key']} = ${o['label']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
            if (_ivrPrompt != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(8)),
                child: Text(_ivrPrompt!, style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ],
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.5,
              children: [
                for (var k = 1; k <= 9; k++)
                  () {
                    final o = optByKey['$k'];
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: o != null ? Colors.white : Colors.white24,
                        foregroundColor: o != null ? Colors.black87 : Colors.white70,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: busy ? null : () => _pressDigit(call, '$k'),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('$k', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          if (o != null)
                            Text(o['label'].toString(), overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    );
                  }(),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB93832), minimumSize: const Size(0, 52)),
              onPressed: () => _declineOrHangup(call),
              icon: const Icon(Icons.call_end),
              label: const Text('End Call', style: TextStyle(fontSize: 17)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext c) {
    final h = DateTime.now().hour;
    final greet = h < 12 ? 'Good morning' : h < 17 ? 'Good afternoon' : 'Good evening';
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: db.from('elders').stream(primaryKey: ['id']).eq('id', elderId).limit(1),
      builder: (c, es) {
        final elder = (es.data?.isNotEmpty ?? false) ? es.data!.first : null;
        final elderName = (elder?['name'] ?? 'Lakshmi Amma').toString();
        final elderPhone = (elder?['phone'] ?? '+91XXXXXXXXXX').toString();

        return Scaffold(
          appBar: AppBar(title: const Text('Koode'), backgroundColor: Colors.transparent, actions: [IconButton(tooltip: 'Switch phone role', onPressed: widget.onSwitch, icon: const Icon(Icons.swap_horiz))]),
          body: SafeArea(child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: db.from('checkins').stream(primaryKey: ['id']).eq('elder_id', elderId).order('created_at', ascending: false).limit(1),
            builder: (c, s) {
              final last = (s.data?.isNotEmpty ?? false) ? s.data!.first : null;
              final activeCall = last != null &&
                      last['result'] == 'PENDING' &&
                      (['RINGING', 'INITIATED', 'SCHEDULED', 'ANSWERED'].contains(last['call_status']))
                  ? last
                  : null;

              final isIncoming = activeCall != null && !_answered;
              if (isIncoming) {
                WidgetsBinding.instance.addPostFrameCallback((_) => _startRingtone());
              } else {
                WidgetsBinding.instance.addPostFrameCallback((_) => _stopRingtone());
              }
              final t = last == null ? null : DateTime.parse(last['created_at']).toLocal();
              final today = t != null && DateUtils.isSameDay(t, DateTime.now());
              final fine = today && last!['result'] == 'FINE';

              return ListView(padding: const EdgeInsets.all(24), children: [
                Text('$greet, $elderName', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600)),
                Text('Phone: $elderPhone', style: const TextStyle(fontSize: 15, color: Color(0xFF626B68))),
                const SizedBox(height: 16),
                if (activeCall != null) _buildCallOverlay(activeCall, elderName, elderPhone),
                Card(child: ListTile(
                  leading: Icon(fine ? Icons.check_circle : Icons.schedule, size: 32, color: fine ? const Color(0xFF477B5B) : const Color(0xFF626B68)),
                  title: Text(fine ? 'Checked in' : 'Check-in needed', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                  subtitle: Text(fine ? DateFormat.jm().format(t) : 'Not yet today', style: const TextStyle(fontSize: 16)))),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: FilledButton.icon(style: FilledButton.styleFrom(minimumSize: const Size(0, 64)), onPressed: busy ? null : imOkay, icon: const Icon(Icons.check), label: const Text("I'm okay", style: TextStyle(fontSize: 18)))),
                  const SizedBox(width: 12),
                  Expanded(child: OutlinedButton.icon(style: OutlinedButton.styleFrom(minimumSize: const Size(0, 64)), onPressed: busy ? null : helpSheet, icon: const Icon(Icons.support_agent), label: const Text('I need help', style: TextStyle(fontSize: 18)))),
                ]),
                if (msg != null) Padding(padding: const EdgeInsets.only(top: 16), child: Text(msg!, style: const TextStyle(fontSize: 18), semanticsLabel: msg)),
                const SizedBox(height: 32),
                FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB93832), minimumSize: const Size(0, 72)), onPressed: busy ? null : () => sos('app: SOS'), icon: const Icon(Icons.phone_in_talk), label: const Text('Call for help (SOS)', style: TextStyle(fontSize: 20))),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: db.from('incidents').stream(primaryKey: ['id']).eq('elder_id', elderId).order('created_at', ascending: false).limit(1),
                  builder: (c, s) {
                    final i = (s.data?.isNotEmpty ?? false) ? s.data!.first : null;
                    if (i == null || ['RESOLVED', 'CANCELLED'].contains(i['status'])) return const SizedBox();
                    return Card(color: const Color(0xFFFBE9E7), margin: const EdgeInsets.only(top: 16), child: ListTile(
                      leading: const Icon(Icons.warning_amber, color: Color(0xFFB93832)),
                      title: const Text('Help requested', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                      subtitle: Text('Stage: ${i['status'].toString().replaceAll('_', ' ').toLowerCase()}', style: const TextStyle(fontSize: 16))));
                  }),
              ]);
            })),
        );
      },
    );
  }
}
