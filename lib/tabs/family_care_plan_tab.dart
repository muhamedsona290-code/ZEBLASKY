import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/care_note.dart';
import '../models/care_reminder.dart';
import '../theme/koode_theme.dart';
import '../widgets/elder_selector.dart';
import '../widgets/state_views.dart';

class FamilyCarePlanTab extends StatefulWidget {
  final ElderInfo currentElder;
  final List<CareReminder> reminders;
  final ValueChanged<List<CareReminder>> onRemindersChanged;
  final List<Map<String, dynamic>> schedules;
  final VoidCallback onRefreshSchedules;

  const FamilyCarePlanTab({
    super.key,
    required this.currentElder,
    required this.reminders,
    required this.onRemindersChanged,
    required this.schedules,
    required this.onRefreshSchedules,
  });

  @override
  State<FamilyCarePlanTab> createState() => _FamilyCarePlanTabState();
}

class _FamilyCarePlanTabState extends State<FamilyCarePlanTab> {
  int _selectedSection = 0; // 0 = Reminders, 1 = Check-in Schedule, 2 = Care Notes
  final bool _hasEditPermission = true; // Authorized caregiver

  List<CareNote> _careNotes = [];

  @override
  void initState() {
    super.initState();
    _loadCareNotes();
  }

  Future<void> _loadCareNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('koode_care_notes_${widget.currentElder.id}');
    if (raw != null) {
      try {
        final List list = jsonDecode(raw);
        setState(() {
          _careNotes = list.map((x) => CareNote.fromJson(Map<String, dynamic>.from(x))).toList();
        });
        return;
      } catch (_) {}
    }

    // Default seeded authorized notes
    _careNotes = [
      CareNote(
        id: '1',
        author: 'Meera Nair',
        role: 'Primary Family Admin',
        note: 'Dr. Preethi confirmed BP medication should be taken strictly after morning idli/food.',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      CareNote(
        id: '2',
        author: 'Suresh Uncle',
        role: 'Neighbor Key Holder',
        note: 'Spare front door key is kept safely in neighbor home locker for any rapid entry.',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      CareNote(
        id: '3',
        author: 'Rahul Nair',
        role: 'Son (Dubai)',
        note: 'Amma prefers Malayalam keypad prompts. Avoid calling between 2 PM and 3:30 PM (rest time).',
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
      ),
    ];
    setState(() {});
  }

  Future<void> _saveCareNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_careNotes.map((x) => x.toJson()).toList());
    await prefs.setString('koode_care_notes_${widget.currentElder.id}', raw);
  }

  void _confirmDeleteReminder(CareReminder reminder) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: KoodeColors.surface,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: KoodeColors.concern),
            SizedBox(width: 8),
            Text(
              'Remove Reminder?',
              style: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to remove "${reminder.title}" (${reminder.time}) from ${widget.currentElder.name}’s care plan? This change will notify authorized family members.',
          style: const TextStyle(fontSize: 14, color: KoodeColors.ink),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Reminder'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: KoodeColors.emergency),
            onPressed: () {
              Navigator.pop(ctx);
              final updated = widget.reminders.where((r) => r.id != reminder.id).toList();
              widget.onRemindersChanged(updated);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Removed reminder "${reminder.title}"')),
              );
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showAddReminderDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    TimeOfDay selectedTime = const TimeOfDay(hour: 8, minute: 0);
    String category = 'Medication';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: KoodeColors.surface,
          title: const Text(
            'Add Care Reminder',
            style: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Reminder title',
                    hintText: 'e.g. Morning Blood Pressure Tablet',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Notes / Instructions',
                    hintText: 'e.g. Take with warm water after food',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time_rounded, color: KoodeColors.olive),
                  title: Text(
                    'Time: ${selectedTime.format(context)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: TextButton(
                    child: const Text('Change'),
                    onPressed: () async {
                      final picked = await showTimePicker(context: context, initialTime: selectedTime);
                      if (picked != null) {
                        setModalState(() => selectedTime = picked);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Medication', child: Text('Medication')),
                    DropdownMenuItem(value: 'Meal', child: Text('Meal / Nutrition')),
                    DropdownMenuItem(value: 'Routine', child: Text('Routine / Exercise')),
                    DropdownMenuItem(value: 'Check-in', child: Text('Check-in call')),
                  ],
                  onChanged: (v) {
                    if (v != null) setModalState(() => category = v);
                  },
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
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) return;
                final newRem = CareReminder(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: titleCtrl.text.trim(),
                  time: selectedTime.format(context),
                  category: category,
                  description: descCtrl.text.trim(),
                  isEnabled: true,
                );
                final updated = [...widget.reminders, newRem];
                widget.onRemindersChanged(updated);
                Navigator.pop(ctx);
              },
              child: const Text('Save Reminder'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddNoteDialog() {
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: KoodeColors.surface,
        title: const Text(
          'Add Authorized Care Note',
          style: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Care notes are visible to verified family members and responder key-holders.',
              style: TextStyle(fontSize: 13, color: KoodeColors.secondaryText),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Care note',
                hintText: 'e.g. Doctor adjusted dosage to 5mg, take before 8 PM.',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (noteCtrl.text.trim().isEmpty) return;
              final newNote = CareNote(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                author: 'Meera Nair',
                role: 'Family Admin',
                note: noteCtrl.text.trim(),
                createdAt: DateTime.now(),
              );
              setState(() => _careNotes.insert(0, newNote));
              _saveCareNotes();
              Navigator.pop(ctx);
            },
            child: const Text('Save Note'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Care Plan & Routine',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: KoodeColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${widget.currentElder.name}’s routine",
                  style: KoodeTheme.displayTitle,
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: KoodeColors.oliveLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline_rounded, size: 14, color: KoodeColors.olive),
                  SizedBox(width: 4),
                  Text(
                    'Authorized',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: KoodeColors.olive),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Section Selector: Reminders, Check-ins, Care notes (Section 4.3)
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: KoodeColors.surfaceVariant,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              _sectionTab(0, 'Reminders (${widget.reminders.length})'),
              _sectionTab(1, 'Check-in Schedule'),
              _sectionTab(2, 'Care Notes (${_careNotes.length})'),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Section Content
        if (_selectedSection == 0) ...[
          // Reminders Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Daily Reminders', style: KoodeTheme.sectionTitle),
              if (_hasEditPermission)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: KoodeColors.olive,
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _showAddReminderDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Reminder', style: TextStyle(fontSize: 13)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.reminders.isEmpty)
            const EmptyStateView(
              title: 'No reminders set',
              message: 'Add routine reminders for medications, meals, or wellness checks.',
              icon: Icons.alarm_off_rounded,
            )
          else
            ...widget.reminders.map((rem) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: KoodeColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: KoodeColors.cardBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: rem.isEnabled ? KoodeColors.oliveLight : KoodeColors.unknownLight,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        rem.category == 'Medication'
                            ? Icons.medication_rounded
                            : rem.category == 'Meal'
                                ? Icons.restaurant_rounded
                                : Icons.schedule_rounded,
                        size: 20,
                        color: rem.isEnabled ? KoodeColors.olive : KoodeColors.unknown,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rem.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: rem.isEnabled ? KoodeColors.ink : KoodeColors.secondaryText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${rem.time} • ${rem.category}',
                            style: const TextStyle(fontSize: 13, color: KoodeColors.secondaryText),
                          ),
                          if (rem.description.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              rem.description,
                              style: const TextStyle(fontSize: 12, color: KoodeColors.secondaryText),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (_hasEditPermission) ...[
                      Switch.adaptive(
                        value: rem.isEnabled,
                        activeTrackColor: KoodeColors.olive,
                        onChanged: (val) {
                          final updated = widget.reminders.map((r) {
                            if (r.id == rem.id) return r.copyWith(isEnabled: val);
                            return r;
                          }).toList();
                          widget.onRemindersChanged(updated);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: KoodeColors.secondaryText, size: 20),
                        tooltip: 'Remove reminder',
                        onPressed: () => _confirmDeleteReminder(rem),
                      ),
                    ],
                  ],
                ),
              );
            }),
        ] else if (_selectedSection == 1) ...[
          // Check-in Schedule Section (Section 4.3)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Automated IVR Schedule', style: KoodeTheme.sectionTitle),
              IconButton(
                icon: const Icon(Icons.refresh, color: KoodeColors.olive),
                onPressed: widget.onRefreshSchedules,
                tooltip: 'Refresh schedule',
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'The Koode system automatically places automated Malayalam phone calls to Lakshmi Amma at these scheduled times.',
            style: TextStyle(fontSize: 13, color: KoodeColors.secondaryText),
          ),
          const SizedBox(height: 14),
          if (widget.schedules.isEmpty)
            const EmptyStateView(
              title: 'No active schedule',
              message: 'Check-in schedule is managed via Supabase call_schedules.',
              icon: Icons.calendar_today_rounded,
            )
          else
            ...widget.schedules.map((s) {
              final nextRun = s['next_run_at'] != null ? DateTime.tryParse(s['next_run_at'])?.toLocal() : null;
              final intervalMin = s['interval_minutes'] as int? ?? 1440;
              final runsDone = s['runs_done'] as int? ?? 0;
              final repeatCount = s['repeat_count'] as int? ?? 1;
              final isActive = s['active'] == true;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: KoodeColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: KoodeColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.phone_in_talk_rounded, color: KoodeColors.olive, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              intervalMin == 1440 ? 'Daily Check-in Call' : 'Recurring Check-in ($intervalMin min)',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: KoodeColors.ink),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isActive ? KoodeColors.sageLight : KoodeColors.unknownLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isActive ? 'Active' : 'Completed',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isActive ? KoodeColors.sage : KoodeColors.unknown,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(color: KoodeColors.divider),
                    const SizedBox(height: 8),
                    Text(
                      nextRun != null
                          ? 'Next Call: ${DateFormat("d MMM, h:mm a").format(nextRun)} IST (Local Time)'
                          : 'Next Call: Pending server trigger',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: KoodeColors.ink),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Calls completed: $runsDone / $repeatCount • Timezone: Asia/Kolkata (IST, GMT+5:30)',
                      style: const TextStyle(fontSize: 12, color: KoodeColors.secondaryText),
                    ),
                  ],
                ),
              );
            }),
        ] else ...[
          // Care Notes Section (Section 4.3)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Authorized Care Notes', style: KoodeTheme.sectionTitle),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: KoodeColors.olive,
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _showAddNoteDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Note', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Keep sensitive clinical details minimal. Authorized notes coordinate everyday elder support across family members and neighbors.',
            style: TextStyle(fontSize: 13, color: KoodeColors.secondaryText),
          ),
          const SizedBox(height: 14),
          if (_careNotes.isEmpty)
            const EmptyStateView(
              title: 'No care notes recorded',
              message: 'Add coordination notes for routines, physician advice, or key holders.',
              icon: Icons.note_alt_outlined,
            )
          else
            ..._careNotes.map((n) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: KoodeColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: KoodeColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${n.author} (${n.role})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: KoodeColors.olive),
                        ),
                        Text(
                          DateFormat('d MMM').format(n.createdAt),
                          style: const TextStyle(fontSize: 12, color: KoodeColors.secondaryText),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      n.note,
                      style: const TextStyle(fontSize: 14, color: KoodeColors.ink, height: 1.35),
                    ),
                  ],
                ),
              );
            }),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _sectionTab(int index, String label) {
    final isSelected = _selectedSection == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedSection = index),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? KoodeColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? KoodeColors.olive : KoodeColors.secondaryText,
            ),
          ),
        ),
      ),
    );
  }
}
