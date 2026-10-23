import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const olive = Color(0xFF343B2D);
const sage = Color(0xFF4D7C5F);
const sageLight = Color(0xFFE8F3EB);
const concern = Color(0xFFA56D24);
const concernLight = Color(0xFFFEF3E2);
const emergency = Color(0xFFC53030);
const emergencyLight = Color(0xFFFFF1F0);
const unknown = Color(0xFF77786F);

class FamilyCheckinCard extends StatelessWidget {
  final Map<String, dynamic> checkin;
  final List<Map<String, dynamic>> answers;

  const FamilyCheckinCard({
    super.key,
    required this.checkin,
    required this.answers,
  });

  String _formatDateTime(String? iso) {
    if (iso == null) return '–';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '–';
    final now = DateTime.now();
    if (DateUtils.isSameDay(dt, now)) {
      return 'Today, ${DateFormat.jm().format(dt)}';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (DateUtils.isSameDay(dt, yesterday)) {
      return 'Yesterday, ${DateFormat.jm().format(dt)}';
    }
    return DateFormat('d MMM, h:mm a').format(dt);
  }

  ({String label, IconData icon, Color color, Color bg}) _sourceInfo(String? s) {
    switch (s) {
      case 'call':
        return (label: 'Phone Call', icon: Icons.call, color: olive, bg: const Color(0xFFEAECE7));
      case 'scheduled_call':
        return (label: 'Scheduled Call', icon: Icons.schedule_send, color: const Color(0xFF1D5C6F), bg: const Color(0xFFE5F4F8));
      case 'app':
        return (label: 'Amma App', icon: Icons.phone_android, color: sage, bg: sageLight);
      case 'simulated':
        return (label: 'Demo Sim', icon: Icons.science_outlined, color: Colors.purple.shade700, bg: Colors.purple.shade50);
      default:
        return (label: 'Check-in', icon: Icons.check_circle_outline, color: unknown, bg: const Color(0xFFF0F0EE));
    }
  }

  ({String label, IconData icon, Color color, Color bg}) _resultInfo(String? res, String? callStatus) {
    if (res == 'PENDING') {
      final isAnswered = callStatus == 'ANSWERED';
      return (
        label: isAnswered ? 'On Call — Answering' : 'Ringing Amma…',
        icon: Icons.phone_in_talk,
        color: olive,
        bg: const Color(0xFFF1F3EC),
      );
    }
    switch (res) {
      case 'FINE':
        return (label: 'All is well', icon: Icons.check_circle, color: sage, bg: sageLight);
      case 'CONCERN':
        return (label: 'Needs follow-up', icon: Icons.error, color: concern, bg: concernLight);
      case 'UNANSWERED':
        return (label: 'Unanswered', icon: Icons.phone_missed, color: unknown, bg: const Color(0xFFF2F2F0));
      default:
        return (label: res ?? 'Unknown', icon: Icons.help_outline, color: unknown, bg: const Color(0xFFF2F2F0));
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = checkin['result'] as String?;
    final callStatus = checkin['call_status'] as String?;
    final source = checkin['source'] as String?;
    final createdAt = checkin['created_at'] as String?;

    final resInfo = _resultInfo(result, callStatus);
    final srcInfo = _sourceInfo(source);

    final hasAnswers = answers.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: result == 'CONCERN'
              ? concern.withValues(alpha: 0.3)
              : result == 'FINE'
                  ? sage.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.06),
          width: result == 'CONCERN' ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Result Badge & Timestamp
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: resInfo.bg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(resInfo.icon, size: 16, color: resInfo.color),
                      const SizedBox(width: 6),
                      Text(
                        resInfo.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: resInfo.color,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: srcInfo.bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(srcInfo.icon, size: 13, color: srcInfo.color),
                      const SizedBox(width: 4),
                      Text(
                        srcInfo.label,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: srcInfo.color),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDateTime(createdAt),
                  style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Content: Custom Question Answers or Legacy flags
            if (hasAnswers) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: answers.map((ans) {
                  final qText = ans['question_text']?.toString() ?? 'Question';
                  final label = ans['label']?.toString() ?? 'Answered';
                  final key = ans['key']?.toString() ?? '';
                  final isConcern = result == 'CONCERN' && (
                    label.toLowerCase().contains('no') ||
                    label.toLowerCase().contains('miss') ||
                    label.toLowerCase().contains('unwell')
                  );

                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isConcern ? concernLight : const Color(0xFFF9FAF8),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isConcern ? concern.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.04),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          isConcern ? Icons.error_outline : Icons.check_circle_outline,
                          size: 16,
                          color: isConcern ? concern : sage,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            qText,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isConcern ? concern : sage,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$label (Key $key)',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ] else ...[
              // Fallback for app quick check-in or simple boolean records
              Row(
                children: [
                  _statusTag(
                    label: 'Meals: ${checkin['food'] == true ? 'Had meal' : checkin['food'] == false ? 'Missed' : 'Not recorded'}',
                    isGood: checkin['food'] == true,
                    isBad: checkin['food'] == false,
                  ),
                  const SizedBox(width: 8),
                  _statusTag(
                    label: 'Medicines: ${checkin['meds'] == true ? 'Taken' : checkin['meds'] == false ? 'Missed' : 'Not recorded'}',
                    isGood: checkin['meds'] == true,
                    isBad: checkin['meds'] == false,
                  ),
                ],
              ),
            ],

            if (callStatus != null && callStatus != 'COMPLETED' && callStatus != 'SCHEDULED') ...[
              const SizedBox(height: 6),
              Text(
                'Call status: $callStatus',
                style: const TextStyle(fontSize: 11, color: Colors.black45, fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusTag({required String label, required bool isGood, required bool isBad}) {
    final color = isBad ? concern : (isGood ? sage : unknown);
    final bg = isBad ? concernLight : (isGood ? sageLight : const Color(0xFFF3F3F1));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isBad ? Icons.close : (isGood ? Icons.check : Icons.remove),
            size: 14,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
