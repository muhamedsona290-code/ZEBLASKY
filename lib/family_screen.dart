import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'config.dart';
import 'customize_screen.dart';
import 'family_checkin_card.dart';
import 'family_incident_banner.dart';
import 'family_incident_history_sheet.dart';
import 'family_responders_sheet.dart';
import 'family_weekly_overview.dart';
import 'main.dart';

const olive = Color(0xFF343B2D);
const sage = Color(0xFF4D7C5F);
const concern = Color(0xFFA56D24);
const emergency = Color(0xFFC53030);
const unknown = Color(0xFF77786F);

class FamilyScreen extends StatefulWidget {
  final VoidCallback onSwitch;
  const FamilyScreen({super.key, required this.onSwitch});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  String? msg;
  Timer? _schedTimer;
  DateTime? _selectedFilterDate;

  void say(String m) {
    if (mounted) setState(() => msg = m);
  }

  @override
  void initState() {
    super.initState();
    _schedTimer = Timer.periodic(const Duration(seconds: 15), (_) => _checkDueSchedules());
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
        final done = (s['runs_done'] as int) + 1;
        final next = DateTime.parse(s['next_run_at'])
            .add(Duration(minutes: s['interval_minutes'] as int))
            .toUtc()
            .toIso8601String();
        final claimed = await db
            .from('call_schedules')
            .update({
              'runs_done': done,
              'next_run_at': next,
              'active': done < (s['repeat_count'] as int),
            })
            .eq('id', s['id'])
            .eq('next_run_at', s['next_run_at'])
            .select();
        if (claimed.isNotEmpty) {
          await callNow(fromSchedule: true);
        }
      }
    } catch (_) {}
  }

  Future<void> callNow({bool fromSchedule = false}) async {
    say(fromSchedule ? 'Scheduled check-in call ringing on Elder phone…' : 'Ringing Elder phone…');
    bool exotelPlaced = false;
    try {
      final res = await db.functions.invoke('start-call', body: {'elder_id': elderId});
      if (res.status == 200) exotelPlaced = true;
    } catch (_) {}
    if (!exotelPlaced) {
      await db.from('checkins').insert({
        'elder_id': elderId,
        'source': fromSchedule ? 'scheduled_call' : 'call',
        'call_status': 'INITIATED',
        'result': 'PENDING',
      });
    }
    say('Calling Elder phone now. Waiting for keypad answers on their phone…');
  }

  // Mock-adapter path for quick single-phone simulation during demos
  Future<void> simulate(bool pressed1) async {
    final checkinRes = await db.from('checkins').insert({
      'elder_id': elderId,
      'source': 'simulated',
      'food': pressed1,
      'meds': pressed1,
      'result': pressed1 ? 'FINE' : 'CONCERN',
      'call_status': 'ANSWERED',
    }).select().maybeSingle();

    if (checkinRes != null) {
      final checkinId = checkinRes['id'];
      try {
        await db.from('answers').insert([
          {
            'checkin_id': checkinId,
            'question_text': 'Have you eaten your food?',
            'key': pressed1 ? '1' : '2',
            'label': pressed1 ? 'Yes' : 'No',
          },
          {
            'checkin_id': checkinId,
            'question_text': 'Have you taken your medicines on time?',
            'key': pressed1 ? '1' : '2',
            'label': pressed1 ? 'Yes' : 'No',
          },
        ]);
      } catch (_) {}
    }

    if (!pressed1) {
      try {
        await db.from('incidents').insert({
          'elder_id': elderId,
          'trigger': 'simulated call: pressed 2 (concern)',
        });
      } catch (_) {}
    }
    say(pressed1 ? 'Simulated: Check-in recorded (Fine)' : 'Simulated: Check-in recorded (Concern alert triggered)');
  }

  ({String label, IconData icon, Color color, Color bg}) statusOf(Map<String, dynamic>? c, bool incident) {
    if (incident) {
      return (
        label: 'Help requested',
        icon: Icons.warning_amber_rounded,
        color: emergency,
        bg: const Color(0xFFFFF1F0),
      );
    }
    if (c == null) {
      return (
        label: 'No check-in yet',
        icon: Icons.schedule,
        color: unknown,
        bg: const Color(0xFFF2F2F0),
      );
    }
    if (c['result'] == 'PENDING') {
      final cs = c['call_status'];
      return (
        label: cs == 'ANSWERED' ? 'On call — answering questions…' : 'Ringing Elder phone…',
        icon: Icons.phone_in_talk,
        color: olive,
        bg: const Color(0xFFF1F4EE),
      );
    }
    switch (c['result']) {
      case 'FINE':
        return (
          label: 'All is well',
          icon: Icons.check_circle,
          color: sage,
          bg: const Color(0xFFE8F3EB),
        );
      case 'CONCERN':
        return (
          label: 'Needs follow-up',
          icon: Icons.error_outline,
          color: concern,
          bg: const Color(0xFFFEF3E2),
        );
      default:
        return (
          label: 'No response yet',
          icon: Icons.schedule,
          color: unknown,
          bg: const Color(0xFFF2F2F0),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: db.from('elders').stream(primaryKey: ['id']).eq('id', elderId).limit(1),
      builder: (context, es) {
        final elder = (es.data?.isNotEmpty ?? false) ? es.data!.first : null;
        final elderName = (elder?['name'] ?? 'Lakshmi Amma').toString();
        final elderPhone = (elder?['phone'] ?? '+91XXXXXXXXXX').toString();
        final consent = elder?['consent'] == true;

        return Scaffold(
          backgroundColor: const Color(0xFFF7F5EE),
          appBar: AppBar(
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: Colors.transparent,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: olive,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'കൂടെ Koode',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Family',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: olive),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Trusted Responders & Neighbors',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => FamilyRespondersSheet(elderName: elderName)),
                ),
                icon: const Icon(Icons.people_outline, color: olive),
              ),
              IconButton(
                tooltip: 'Incident History',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => FamilyIncidentHistorySheet(elderName: elderName)),
                ),
                icon: const Icon(Icons.history, color: olive),
              ),
              IconButton(
                tooltip: 'Customize questions, schedule & phone',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CustomizeScreen()),
                ),
                icon: const Icon(Icons.tune, color: olive),
              ),
              IconButton(
                tooltip: 'Switch phone role',
                onPressed: widget.onSwitch,
                icon: const Icon(Icons.swap_horiz, color: olive),
              ),
            ],
          ),
          body: SafeArea(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: db
                  .from('incidents')
                  .stream(primaryKey: ['id'])
                  .eq('elder_id', elderId)
                  .order('created_at', ascending: false)
                  .limit(1),
              builder: (context, incidentSnap) {
                final inc = (incidentSnap.data?.isNotEmpty ?? false) &&
                        !['RESOLVED', 'CANCELLED'].contains(incidentSnap.data!.first['status'])
                    ? incidentSnap.data!.first
                    : null;

                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: db
                      .from('checkins')
                      .stream(primaryKey: ['id'])
                      .eq('elder_id', elderId)
                      .order('created_at', ascending: false)
                      .limit(40),
                  builder: (context, checkinsSnap) {
                    return StreamBuilder<List<Map<String, dynamic>>>(
                      stream: db.from('answers').stream(primaryKey: ['id']).order('created_at'),
                      builder: (context, ansSnap) {
                        final checkinList = checkinsSnap.data ?? [];
                        final allAnswers = ansSnap.data ?? [];

                        final latestCheckin = checkinList.isEmpty ? null : checkinList.first;
                        final isCallActive = latestCheckin != null &&
                            latestCheckin['result'] == 'PENDING' &&
                            ['INITIATED', 'SCHEDULED', 'ANSWERED'].contains(latestCheckin['call_status']);

                        final st = statusOf(latestCheckin, inc != null);
                        final lastCheckinTime = latestCheckin != null && latestCheckin['created_at'] != null
                            ? DateTime.tryParse(latestCheckin['created_at'])?.toLocal()
                            : null;

                        // Filter list if a specific day is selected in the weekly overview
                        final filteredList = _selectedFilterDate == null
                            ? checkinList
                            : checkinList.where((x) {
                                final dt = DateTime.tryParse(x['created_at']?.toString() ?? '')?.toLocal();
                                return dt != null && DateUtils.isSameDay(dt, _selectedFilterDate!);
                              }).toList();

                        return ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          children: [
                            // Greeting
                            Text(
                              "Caregiver Overview",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "How is $elderName today?",
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: olive,
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Hero Status Card
                            _buildHeroCard(
                              elderName: elderName,
                              elderPhone: elderPhone,
                              consent: consent,
                              st: st,
                              lastCheckinTime: lastCheckinTime,
                              isCallActive: isCallActive,
                              onCallNow: () => callNow(),
                            ),

                            // Realtime Call In-Progress Banner
                            if (isCallActive)
                              _buildActiveCallCard(latestCheckin['call_status'], elderName, elderPhone),

                            // Realtime Incident Escalation Banner
                            if (inc != null)
                              FamilyIncidentBanner(
                                incident: inc,
                                elderName: elderName,
                                elderPhone: elderPhone,
                                onUpdated: () => setState(() {}),
                              ),

                            const SizedBox(height: 12),

                            // Direct Call Button & Quick Actions Row
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: olive,
                                      minimumSize: const Size(0, 52),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                    onPressed: () => callNow(),
                                    icon: const Icon(Icons.phone_in_talk, size: 20),
                                    label: Text(
                                      'Call $elderName now',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 2,
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(0, 52),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      side: const BorderSide(color: olive, width: 1.2),
                                    ),
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const CustomizeScreen()),
                                    ),
                                    icon: const Icon(Icons.tune, color: olive, size: 20),
                                    label: const Text(
                                      'Settings',
                                      style: TextStyle(color: olive, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            if (msg != null) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline, size: 18, color: olive),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        msg!,
                                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 20),

                            // 7-Day Weekly Overview Card
                            FamilyWeeklyOverview(
                              checkins: checkinList,
                              selectedDate: _selectedFilterDate,
                              onSelectDate: (d) => setState(() => _selectedFilterDate = d),
                            ),

                            const SizedBox(height: 22),

                            // Caregiver Circle & Responder Summary Bar
                            _buildResponderQuickBar(elderName),

                            const SizedBox(height: 22),

                            // Check-in History Section
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _selectedFilterDate == null
                                      ? 'Recent Check-ins'
                                      : 'Check-ins for ${DateFormat('d MMM').format(_selectedFilterDate!)}',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: olive),
                                ),
                                if (_selectedFilterDate != null)
                                  TextButton(
                                    onPressed: () => setState(() => _selectedFilterDate = null),
                                    child: const Text('View all', style: TextStyle(color: sage)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            if (filteredList.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Center(
                                  child: Text(
                                    'No check-ins recorded for this period.',
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                ),
                              )
                            else
                              ...filteredList.take(15).map((r) {
                                final answersForCheckin = allAnswers
                                    .where((a) => a['checkin_id']?.toString() == r['id']?.toString())
                                    .toList();
                                return FamilyCheckinCard(
                                  checkin: r,
                                  answers: answersForCheckin,
                                );
                              }),

                            const SizedBox(height: 20),

                            // Simulation & Testing Tools
                            Theme(
                              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                collapsedBackgroundColor: Colors.white,
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                leading: const Icon(Icons.science_outlined, color: Colors.purple),
                                title: const Text(
                                  'Demo Testing Tools',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.purple),
                                ),
                                subtitle: const Text(
                                  'Simulate responses without a 2nd phone',
                                  style: TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: sage,
                                                  side: const BorderSide(color: sage),
                                                ),
                                                onPressed: () => simulate(true),
                                                icon: const Icon(Icons.check, size: 16),
                                                label: const Text('Simulate Fine'),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: concern,
                                                  side: const BorderSide(color: concern),
                                                ),
                                                onPressed: () => simulate(false),
                                                icon: const Icon(Icons.warning_amber, size: 16),
                                                label: const Text('Simulate Concern'),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        const Text(
                                          'Inserts simulated check-in and questions responses into Supabase.',
                                          style: TextStyle(fontSize: 11, color: Colors.black45),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroCard({
    required String elderName,
    required String elderPhone,
    required bool consent,
    required ({String label, IconData icon, Color color, Color bg}) st,
    required DateTime? lastCheckinTime,
    required bool isCallActive,
    required VoidCallback onCallNow,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar with live indicator ring
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: olive.withValues(alpha: 0.12),
                      child: Text(
                        elderName.isNotEmpty ? elderName[0] : 'L',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: olive,
                        ),
                      ),
                    ),
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: st.color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        elderName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.phone_iphone, size: 14, color: Colors.black45),
                          const SizedBox(width: 4),
                          Text(
                            elderPhone,
                            style: const TextStyle(fontSize: 13, color: Colors.black54),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Status Badge Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: st.bg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(st.icon, size: 16, color: st.color),
                      const SizedBox(width: 6),
                      Text(
                        st.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: st.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 15, color: Colors.black45),
                    const SizedBox(width: 5),
                    Text(
                      lastCheckinTime == null
                          ? 'No check-in recorded yet'
                          : 'Last update: ${DateFormat('d MMM, h:mm a').format(lastCheckinTime)}',
                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      consent ? Icons.verified : Icons.help_outline,
                      size: 15,
                      color: consent ? sage : concern,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      consent ? 'Consent verified' : 'Consent pending',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: consent ? sage : concern,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveCallCard(String? callStatus, String elderName, String elderPhone) {
    final isAnswered = callStatus == 'ANSWERED';
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F382E),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: olive.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAnswered ? '$elderName answered! In IVR Call…' : 'Check-in Call Ringing on $elderName’s Phone…',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isAnswered
                      ? 'Lakshmi Amma is responding to keypad questions (1-9).'
                      : 'Waiting for pickup at $elderPhone…',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponderQuickBar(String elderName) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.shield_outlined, color: olive, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Responder & Caregiver Circle',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: olive),
                  ),
                ],
              ),
              InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => FamilyRespondersSheet(elderName: elderName)),
                ),
                child: const Text('Manage', style: TextStyle(color: sage, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            '3-Tier Emergency Escalation network protects Lakshmi Amma 24/7:',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _responderChip('Tier 1: Family (Abroad & Local)', olive),
              const SizedBox(width: 6),
              _responderChip('Tier 2: Neighbors', concern),
              const SizedBox(width: 6),
              _responderChip('Tier 3: 112/108', emergency),
            ],
          ),
        ],
      ),
    );
  }

  Widget _responderChip(String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
        ),
      ),
    );
  }
}
