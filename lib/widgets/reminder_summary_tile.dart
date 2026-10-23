import 'package:flutter/material.dart';
import '../models/care_reminder.dart';
import '../theme/koode_theme.dart';

class ReminderSummaryTile extends StatelessWidget {
  final CareReminder? nextReminder;
  final VoidCallback onViewCarePlan;

  const ReminderSummaryTile({
    super.key,
    required this.nextReminder,
    required this.onViewCarePlan,
  });

  @override
  Widget build(BuildContext context) {
    final hasReminder = nextReminder != null && nextReminder!.isEnabled;

    return Semantics(
      label: hasReminder
          ? 'Next reminder: ${nextReminder!.title} at ${nextReminder!.time}. Tap to view care plan.'
          : 'No upcoming reminders. Tap to view care plan.',
      button: true,
      child: Container(
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
                color: hasReminder ? KoodeColors.oliveLight : KoodeColors.unknownLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasReminder ? Icons.alarm_on_rounded : Icons.alarm_off_rounded,
                size: 20,
                color: hasReminder ? KoodeColors.olive : KoodeColors.unknown,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Next Reminder',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: KoodeColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (hasReminder) ...[
                    Text(
                      nextReminder!.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: KoodeColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${nextReminder!.time} • ${nextReminder!.category}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: KoodeColors.secondaryText,
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'No upcoming reminders',
                      style: TextStyle(
                        fontSize: 14,
                        color: KoodeColors.secondaryText,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            TextButton(
              onPressed: onViewCarePlan,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Care plan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  SizedBox(width: 2),
                  Icon(Icons.chevron_right, size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
