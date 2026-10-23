import 'package:flutter/material.dart';
import '../models/care_reminder.dart';
import '../theme/koode_theme.dart';
import '../widgets/checkin_week_strip.dart';
import '../widgets/elder_selector.dart';
import '../widgets/elder_status_panel.dart';
import '../widgets/incident_status_banner.dart';
import '../widgets/reminder_summary_tile.dart';

class FamilyHomeTab extends StatelessWidget {
  final ElderInfo currentElder;
  final Map<String, dynamic>? activeIncident;
  final Map<String, dynamic>? latestCheckin;
  final List<Map<String, dynamic>> checkins;
  final CareReminder? nextReminder;
  final bool isCallActive;
  final VoidCallback onCallElder;
  final ValueChanged<int> onSwitchTab;
  final VoidCallback onSimulateFine;
  final VoidCallback onSimulateConcern;
  final VoidCallback onTriggerEmergency;
  final VoidCallback onIncidentUpdated;

  const FamilyHomeTab({
    super.key,
    required this.currentElder,
    required this.activeIncident,
    required this.latestCheckin,
    required this.checkins,
    required this.nextReminder,
    required this.isCallActive,
    required this.onCallElder,
    required this.onSwitchTab,
    required this.onSimulateFine,
    required this.onSimulateConcern,
    required this.onTriggerEmergency,
    required this.onIncidentUpdated,
  });

  String _greetingText() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning, Meera';
    if (hour < 17) return 'Good afternoon, Meera';
    return 'Good evening, Meera';
  }

  ({ElderStatusType type, String label, String description}) _resolveElderStatus() {
    if (activeIncident != null) {
      return (
        type: ElderStatusType.emergency,
        label: 'Help requested',
        description: 'Active emergency escalation in progress. Tap banner to coordinate.',
      );
    }
    if (isCallActive) {
      final cs = latestCheckin?['call_status'];
      return (
        type: ElderStatusType.inCall,
        label: 'In check-in call',
        description: cs == 'ANSWERED'
            ? '${currentElder.name} is on call answering questions.'
            : 'Check-in call is currently ringing on ${currentElder.name}’s phone.',
      );
    }
    if (latestCheckin == null) {
      return (
        type: ElderStatusType.unanswered,
        label: 'No check-in yet',
        description: 'Waiting for today’s scheduled morning check-in.',
      );
    }
    final res = latestCheckin!['result'];
    switch (res) {
      case 'FINE':
        return (
          type: ElderStatusType.fine,
          label: 'All is well',
          description: 'Check-in completed. Food and medications confirmed.',
        );
      case 'CONCERN':
        return (
          type: ElderStatusType.concern,
          label: 'Needs follow-up',
          description: '${currentElder.name} indicated a concern during the check-in call.',
        );
      default:
        return (
          type: ElderStatusType.unanswered,
          label: 'No response yet',
          description: 'Scheduled check-in call was not answered.',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = _resolveElderStatus();
    final lastTime = latestCheckin?['created_at'] != null
        ? DateTime.tryParse(latestCheckin!['created_at'])?.toLocal()
        : null;

    final hasConcern = st.type == ElderStatusType.concern;
    final hasUnanswered = st.type == ElderStatusType.unanswered;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        // 1. Greeting & Context
        Text(
          _greetingText(),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: KoodeColors.secondaryText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Here’s how ${currentElder.name} is doing today",
          style: KoodeTheme.displayTitle,
        ),
        const SizedBox(height: 18),

        // 2. Active Alert Banner (Section 4.4) - Highest Priority
        if (activeIncident != null)
          IncidentStatusBanner(
            incident: activeIncident!,
            elderName: currentElder.name,
            elderPhone: currentElder.phone,
            onUpdated: onIncidentUpdated,
          ),

        // Realtime Call In-Progress Card
        if (isCallActive) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: KoodeColors.olive,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: KoodeColors.olive.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
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
                        latestCheckin?['call_status'] == 'ANSWERED'
                            ? '${currentElder.name} answered! Responding now…'
                            : 'Calling ${currentElder.name}’s phone…',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Live IVR automated check-in in progress.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 3. Elder Status Panel (Section 4.1)
        ElderStatusPanel(
          elderName: currentElder.name,
          elderPhone: currentElder.phone,
          hasConsent: currentElder.hasConsent,
          statusType: st.type,
          statusLabel: st.label,
          statusDescription: st.description,
          lastCheckinTime: lastTime,
          onCall: onCallElder,
          onViewProfile: () => onSwitchTab(2), // go to care plan
        ),
        const SizedBox(height: 16),

        // 4. Primary Next Action (Section 1 & 4.1)
        // Show one clear action: follow up, call, confirm, or view active incident.
        if (hasConcern || hasUnanswered) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: hasConcern ? KoodeColors.concernLight : KoodeColors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasConcern ? KoodeColors.concern.withValues(alpha: 0.4) : KoodeColors.cardBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      hasConcern ? Icons.priority_high_rounded : Icons.info_outline_rounded,
                      color: hasConcern ? KoodeColors.concern : KoodeColors.ink,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      hasConcern ? 'Recommended Action: Follow up' : 'Recommended Action: Place a check-in call',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: hasConcern ? KoodeColors.concern : KoodeColors.ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  hasConcern
                      ? '${currentElder.name} reported missing medications or food. A quick phone call is recommended to ensure everything is fine.'
                      : 'The scheduled check-in was unanswered. You can place a direct check-in call now.',
                  style: const TextStyle(fontSize: 13, color: KoodeColors.secondaryText),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: hasConcern ? KoodeColors.concern : KoodeColors.olive,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: onCallElder,
                  icon: const Icon(Icons.phone_in_talk_rounded, size: 20),
                  label: Text('Call ${currentElder.name} now'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ] else ...[
          // Standard Routine Quick Call button
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: KoodeColors.olive,
              minimumSize: const Size(double.infinity, 54),
            ),
            onPressed: onCallElder,
            icon: const Icon(Icons.phone_in_talk_rounded, size: 20),
            label: Text('Place check-in call to ${currentElder.name}'),
          ),
          const SizedBox(height: 16),
        ],

        // 5. Next Reminder (Section 4.1)
        ReminderSummaryTile(
          nextReminder: nextReminder,
          onViewCarePlan: () => onSwitchTab(2),
        ),
        const SizedBox(height: 16),

        // 6. This Week 7-Day Summary (Section 4.1)
        CheckInWeekStrip(
          checkins: checkins,
          selectedDate: null,
          onSelectDate: (_) => onSwitchTab(1), // navigate to wellbeing tab
          onViewWellbeing: () => onSwitchTab(1),
        ),
        const SizedBox(height: 20),

        // 7. Testing & Simulation Expansion Tile (Accessible for demos)
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            collapsedBackgroundColor: KoodeColors.surface,
            backgroundColor: KoodeColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            leading: const Icon(Icons.science_outlined, color: Colors.purple),
            title: const Text(
              'Demo & Testing Controls',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.purple),
            ),
            subtitle: const Text(
              'Simulate check-in responses or test emergency escalation',
              style: TextStyle(fontSize: 12, color: KoodeColors.secondaryText),
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
                              foregroundColor: KoodeColors.sage,
                              side: const BorderSide(color: KoodeColors.sage),
                            ),
                            onPressed: onSimulateFine,
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('Simulate Fine'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: KoodeColors.concern,
                              side: const BorderSide(color: KoodeColors.concern),
                            ),
                            onPressed: onSimulateConcern,
                            icon: const Icon(Icons.warning_amber, size: 16),
                            label: const Text('Simulate Concern'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: KoodeColors.emergency,
                        side: const BorderSide(color: KoodeColors.emergency),
                        minimumSize: const Size(double.infinity, 44),
                      ),
                      onPressed: onTriggerEmergency,
                      icon: const Icon(Icons.emergency_rounded, size: 16),
                      label: const Text('Trigger Emergency Incident'),
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
  }
}
