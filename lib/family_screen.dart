import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';
import 'customize_screen.dart';
import 'main.dart';
import 'models/care_reminder.dart';
import 'tabs/family_care_plan_tab.dart';
import 'tabs/family_home_tab.dart';
import 'tabs/family_support_tab.dart';
import 'tabs/family_wellbeing_tab.dart';
import 'theme/koode_theme.dart';
import 'widgets/elder_selector.dart';
import 'widgets/family_header.dart';
import 'widgets/family_scaffold.dart';

class FamilyScreen extends StatefulWidget {
  final VoidCallback onSwitch;
  const FamilyScreen({super.key, required this.onSwitch});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  int _currentTabIndex = 0;
  Timer? _schedTimer;

  // Multi-Elder Management
  late List<ElderInfo> _elders;
  late ElderInfo _selectedElder;

  // Care Reminders
  List<CareReminder> _reminders = [];

  @override
  void initState() {
    super.initState();
    _elders = [
      const ElderInfo(
        id: elderId,
        name: 'Lakshmi Amma',
        relationship: 'Mother (Amma)',
        phone: '+91XXXXXXXXXX',
        hasConsent: true,
      ),
      const ElderInfo(
        id: '00000000-0000-0000-0000-000000000002',
        name: 'Gopalan Appa',
        relationship: 'Father (Appa)',
        phone: '+919846000000',
        hasConsent: true,
      ),
    ];
    _selectedElder = _elders.first;

    _loadSavedElder();
    _loadReminders();
    _schedTimer = Timer.periodic(const Duration(seconds: 15), (_) => _checkDueSchedules());
  }

  @override
  void dispose() {
    _schedTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSavedElder() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('koode_selected_elder_id');
    if (savedId != null) {
      final match = _elders.where((e) => e.id == savedId);
      if (match.isNotEmpty) {
        setState(() => _selectedElder = match.first);
      }
    }
  }

  Future<void> _selectElder(ElderInfo elder) async {
    setState(() => _selectedElder = elder);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('koode_selected_elder_id', elder.id);
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('koode_reminders_${_selectedElder.id}');
    if (raw != null) {
      try {
        final List list = jsonDecode(raw);
        setState(() {
          _reminders = list.map((x) => CareReminder.fromJson(Map<String, dynamic>.from(x))).toList();
        });
        return;
      } catch (_) {}
    }

    // Default seeded reminders
    _reminders = [
      const CareReminder(
        id: '1',
        title: 'Morning Diabetes & BP Tablet',
        time: '08:00 AM',
        category: 'Medication',
        description: 'Take strictly after breakfast idli / dosa with warm water.',
        isEnabled: true,
      ),
      const CareReminder(
        id: '2',
        title: 'Lunch & Hydration Check',
        time: '01:00 PM',
        category: 'Meal',
        description: 'Ensure fresh hot meal and 1 glass of boiled water.',
        isEnabled: true,
      ),
      const CareReminder(
        id: '3',
        title: 'Evening Blood Pressure Pill',
        time: '07:00 PM',
        category: 'Medication',
        description: 'Dr. Preethi 5mg dosage before dinner.',
        isEnabled: true,
      ),
      const CareReminder(
        id: '4',
        title: 'Night Security & Door Lock',
        time: '08:30 PM',
        category: 'Routine',
        description: 'Verify veranda light on and front door bolted.',
        isEnabled: false,
      ),
    ];
    setState(() {});
  }

  Future<void> _saveReminders(List<CareReminder> updated) async {
    setState(() => _reminders = updated);
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_reminders.map((x) => x.toJson()).toList());
    await prefs.setString('koode_reminders_${_selectedElder.id}', raw);
  }

  void _showMessage(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: KoodeColors.olive,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _checkDueSchedules() async {
    try {
      final nowIso = DateTime.now().toUtc().toIso8601String();
      final due = await db
          .from('call_schedules')
          .select()
          .eq('elder_id', _selectedElder.id)
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
    _showMessage(fromSchedule ? 'Scheduled check-in call ringing…' : 'Initiating call to ${_selectedElder.name}…');
    bool exotelPlaced = false;
    try {
      final res = await db.functions.invoke('start-call', body: {'elder_id': _selectedElder.id});
      if (res.status == 200) exotelPlaced = true;
    } catch (_) {}
    if (!exotelPlaced) {
      await db.from('checkins').insert({
        'elder_id': _selectedElder.id,
        'source': fromSchedule ? 'scheduled_call' : 'call',
        'call_status': 'INITIATED',
        'result': 'PENDING',
      });
    }
    _showMessage('Calling ${_selectedElder.name} now. Waiting for keypad pickup…');
  }

  // Simulation & testing tools
  Future<void> simulate(bool pressed1) async {
    final checkinRes = await db.from('checkins').insert({
      'elder_id': _selectedElder.id,
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
          'elder_id': _selectedElder.id,
          'trigger': 'Simulated call: Missed food / medicines (concern reported)',
        });
      } catch (_) {}
    }
    _showMessage(pressed1 ? 'Simulated: Check-in recorded (All is well)' : 'Simulated: Concern alert triggered!');
  }

  Future<void> triggerEmergency() async {
    try {
      await db.from('incidents').insert({
        'elder_id': _selectedElder.id,
        'trigger': 'Emergency SOS button triggered from elder phone',
      });
      _showMessage('Emergency escalation incident created!');
    } catch (e) {
      _showMessage('Failed to create incident: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: db
          .from('incidents')
          .stream(primaryKey: ['id'])
          .eq('elder_id', _selectedElder.id)
          .order('created_at', ascending: false)
          .limit(1),
      builder: (context, incidentSnap) {
        final activeIncident = (incidentSnap.data?.isNotEmpty ?? false) &&
                !['RESOLVED', 'CANCELLED'].contains(incidentSnap.data!.first['status'])
            ? incidentSnap.data!.first
            : null;

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: db
              .from('checkins')
              .stream(primaryKey: ['id'])
              .eq('elder_id', _selectedElder.id)
              .order('created_at', ascending: false)
              .limit(50),
          builder: (context, checkinsSnap) {
            final checkinList = checkinsSnap.data ?? [];
            final latestCheckin = checkinList.isEmpty ? null : checkinList.first;
            final isCallActive = latestCheckin != null &&
                latestCheckin['result'] == 'PENDING' &&
                ['INITIATED', 'SCHEDULED', 'ANSWERED'].contains(latestCheckin['call_status']);

            final hasConcern = latestCheckin != null && latestCheckin['result'] == 'CONCERN';

            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: db.from('answers').stream(primaryKey: ['id']).order('created_at'),
              builder: (context, ansSnap) {
                final allAnswers = ansSnap.data ?? [];

                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: db
                      .from('call_schedules')
                      .stream(primaryKey: ['id'])
                      .eq('elder_id', _selectedElder.id)
                      .order('next_run_at'),
                  builder: (context, schedSnap) {
                    final schedules = schedSnap.data ?? [];

                    // Next upcoming active reminder
                    final activeReminders = _reminders.where((r) => r.isEnabled).toList();
                    final nextReminder = activeReminders.isNotEmpty ? activeReminders.first : null;

                    return FamilyScaffold(
                      currentIndex: _currentTabIndex,
                      onTabSelected: (idx) => setState(() => _currentTabIndex = idx),
                      hasActiveIncident: activeIncident != null,
                      hasPendingConcern: hasConcern,
                      header: FamilyHeader(
                        currentElder: _selectedElder,
                        elders: _elders,
                        onElderSelected: _selectElder,
                        onSwitchRole: widget.onSwitch,
                        onOpenSettings: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CustomizeScreen()),
                        ),
                        unreadNotificationsCount: activeIncident != null ? 1 : 0,
                      ),
                      body: IndexedStack(
                        index: _currentTabIndex,
                        children: [
                          // Tab 0: Home
                          FamilyHomeTab(
                            currentElder: _selectedElder,
                            activeIncident: activeIncident,
                            latestCheckin: latestCheckin,
                            checkins: checkinList,
                            nextReminder: nextReminder,
                            isCallActive: isCallActive,
                            onCallElder: () => callNow(),
                            onSwitchTab: (idx) => setState(() => _currentTabIndex = idx),
                            onSimulateFine: () => simulate(true),
                            onSimulateConcern: () => simulate(false),
                            onTriggerEmergency: triggerEmergency,
                            onIncidentUpdated: () => setState(() {}),
                          ),
                          // Tab 1: Wellbeing History
                          FamilyWellbeingTab(
                            currentElder: _selectedElder,
                            checkins: checkinList,
                            allAnswers: allAnswers,
                            isLoading: checkinsSnap.connectionState == ConnectionState.waiting,
                            onRefresh: () => setState(() {}),
                          ),
                          // Tab 2: Care Plan
                          FamilyCarePlanTab(
                            currentElder: _selectedElder,
                            reminders: _reminders,
                            onRemindersChanged: _saveReminders,
                            schedules: schedules,
                            onRefreshSchedules: () => setState(() {}),
                          ),
                          // Tab 3: Support & Trusted Contacts
                          FamilySupportTab(
                            currentElder: _selectedElder,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
