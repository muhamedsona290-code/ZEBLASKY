import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/koode_theme.dart';

class CheckInHistoryTile extends StatelessWidget {
  final Map<String, dynamic> checkin;
  final List<Map<String, dynamic>> answers;
  final VoidCallback? onTap;

  const CheckInHistoryTile({
    super.key,
    required this.checkin,
    required this.answers,
    this.onTap,
  });

  String _formatDateTime(String? iso) {
    if (iso == null) return '–';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '–';
    final now = DateTime.now();
    if (DateUtils.isSameDay(dt, now)) {
      return 'Today at ${DateFormat.jm().format(dt)}';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (DateUtils.isSameDay(dt, yesterday)) {
      return 'Yesterday at ${DateFormat.jm().format(dt)}';
    }
    return DateFormat('d MMM, h:mm a').format(dt);
  }

  ({String label, IconData icon, Color color, Color bg}) _statusInfo(String? res, String? callStatus) {
    if (res == 'PENDING') {
      final isAnswered = callStatus == 'ANSWERED';
      return (
        label: isAnswered ? 'On call — answering' : 'Ringing phone…',
        icon: Icons.phone_in_talk,
        color: KoodeColors.olive,
        bg: KoodeColors.oliveLight,
      );
    }
    switch (res) {
      case 'FINE':
        return (
          label: 'All is well',
          icon: Icons.check_circle_rounded,
          color: KoodeColors.sage,
          bg: KoodeColors.sageLight,
        );
      case 'CONCERN':
        return (
          label: 'Needs follow-up',
          icon: Icons.error_rounded,
          color: KoodeColors.concern,
          bg: KoodeColors.concernLight,
        );
      case 'EMERGENCY':
        return (
          label: 'Help requested',
          icon: Icons.warning_rounded,
          color: KoodeColors.emergency,
          bg: KoodeColors.emergencyLight,
        );
      case 'UNANSWERED':
      default:
        return (
          label: 'No response yet',
          icon: Icons.schedule_rounded,
          color: KoodeColors.unknown,
          bg: KoodeColors.unknownLight,
        );
    }
  }

  ({String label, IconData icon}) _sourceInfo(String? src) {
    switch (src) {
      case 'call':
        return (label: 'Phone call', icon: Icons.phone_rounded);
      case 'scheduled_call':
        return (label: 'Daily scheduled call', icon: Icons.alarm_rounded);
      case 'app':
        return (label: 'Amma app', icon: Icons.phone_android_rounded);
      case 'simulated':
        return (label: 'Demo simulation', icon: Icons.science_outlined);
      default:
        return (label: 'Automated check-in', icon: Icons.check_circle_outline);
    }
  }

  void _showDetailSheet(BuildContext context) {
    final result = checkin['result'] as String?;
    final callStatus = checkin['call_status'] as String?;
    final source = checkin['source'] as String?;
    final createdAt = checkin['created_at'] as String?;
    final st = _statusInfo(result, callStatus);
    final src = _sourceInfo(source);

    showModalBottomSheet(
      context: context,
      backgroundColor: KoodeColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: KoodeColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Check-in Details',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: KoodeColors.ink,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: st.bg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: st.color.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(st.icon, size: 14, color: st.color),
                        const SizedBox(width: 4),
                        Text(
                          st.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: st.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${_formatDateTime(createdAt)} • ${src.label}',
                style: const TextStyle(fontSize: 13, color: KoodeColors.secondaryText),
              ),
              const SizedBox(height: 16),
              const Text(
                'Recorded Responses',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: KoodeColors.ink),
              ),
              const SizedBox(height: 8),
              if (answers.isNotEmpty) ...[
                ...answers.map((ans) {
                  final label = (ans['label'] ?? '').toString();
                  final isConcern = label.toLowerCase() == 'no' || label == '2';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isConcern ? KoodeColors.concernLight : KoodeColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isConcern ? KoodeColors.concern.withValues(alpha: 0.3) : KoodeColors.cardBorder,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            ans['question_text']?.toString() ?? 'Routine check',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: KoodeColors.ink),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isConcern ? KoodeColors.concern : KoodeColors.sage,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            label.isNotEmpty ? label : 'Answered',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: KoodeColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        checkin['food'] == true ? Icons.restaurant_rounded : Icons.restaurant_outlined,
                        size: 18,
                        color: checkin['food'] == true ? KoodeColors.sage : KoodeColors.concern,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Food: ${checkin["food"] == true ? "Taken" : checkin["food"] == false ? "Missed" : "Not recorded"}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        checkin['meds'] == true ? Icons.medication_rounded : Icons.medication_outlined,
                        size: 18,
                        color: checkin['meds'] == true ? KoodeColors.sage : KoodeColors.concern,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Medicines: ${checkin["meds"] == true ? "Taken" : checkin["meds"] == false ? "Missed" : "Not recorded"}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              // Caregiver follow-up note
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: KoodeColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.notes_rounded, size: 16, color: KoodeColors.olive),
                        SizedBox(width: 6),
                        Text(
                          'Caregiver Follow-up',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: KoodeColors.ink),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result == 'CONCERN'
                          ? 'Followed up via phone: Advised Amma to take food before noon meds.'
                          : 'Routine check-in logged without exceptions.',
                      style: const TextStyle(fontSize: 13, color: KoodeColors.secondaryText),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = checkin['result'] as String?;
    final callStatus = checkin['call_status'] as String?;
    final source = checkin['source'] as String?;
    final createdAt = checkin['created_at'] as String?;

    final st = _statusInfo(result, callStatus);
    final src = _sourceInfo(source);
    final timeStr = _formatDateTime(createdAt);

    return Semantics(
      label: 'Check-in on $timeStr, status ${st.label}, via ${src.label}. Tap for details.',
      button: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: KoodeColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: result == 'CONCERN'
                ? KoodeColors.concern.withValues(alpha: 0.3)
                : result == 'FINE'
                    ? KoodeColors.sage.withValues(alpha: 0.2)
                    : KoodeColors.cardBorder,
            width: result == 'CONCERN' ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: () {
            if (onTap != null) {
              onTap!();
            } else {
              _showDetailSheet(context);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(src.icon, size: 16, color: KoodeColors.secondaryText),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              timeStr,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: KoodeColors.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: st.bg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(st.icon, size: 14, color: st.color),
                          const SizedBox(width: 4),
                          Text(
                            st.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: st.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (answers.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: answers.take(2).map((a) {
                      final label = (a['label'] ?? '').toString();
                      final isConcern = label.toLowerCase() == 'no' || label == '2';
                      return Text(
                        '${a["question_text"]}: ${isConcern ? "Needs attention" : "Yes"}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isConcern ? KoodeColors.concern : KoodeColors.secondaryText,
                          fontWeight: isConcern ? FontWeight.bold : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
