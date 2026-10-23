import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/koode_theme.dart';

class CheckInWeekStrip extends StatelessWidget {
  final List<Map<String, dynamic>> checkins;
  final DateTime? selectedDate;
  final ValueChanged<DateTime?> onSelectDate;
  final VoidCallback? onViewWellbeing;

  const CheckInWeekStrip({
    super.key,
    required this.checkins,
    required this.selectedDate,
    required this.onSelectDate,
    this.onViewWellbeing,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = <Map<String, dynamic>>[];

    int fineCount = 0;
    int concernCount = 0;
    int missedCount = 0;

    for (var i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayCheckins = checkins.where((c) {
        final dt = DateTime.tryParse(c['created_at']?.toString() ?? '')?.toLocal();
        return dt != null && DateUtils.isSameDay(dt, day);
      }).toList();

      final results = dayCheckins.map((c) => c['result']).toList();
      String status;
      String accessibilityLabel;
      Color color;
      Color bg;
      IconData icon;

      final dayName = DateFormat('EEEE').format(day);

      if (results.contains('CONCERN')) {
        status = 'CONCERN';
        accessibilityLabel = '$dayName: concern recorded';
        color = KoodeColors.concern;
        bg = KoodeColors.concernLight;
        icon = Icons.error_outline_rounded;
        concernCount++;
      } else if (results.contains('FINE')) {
        status = 'FINE';
        accessibilityLabel = '$dayName: checked in, all well';
        color = KoodeColors.sage;
        bg = KoodeColors.sageLight;
        icon = Icons.check_circle_rounded;
        fineCount++;
      } else if (dayCheckins.isNotEmpty) {
        status = 'UNANSWERED';
        accessibilityLabel = '$dayName: no response yet';
        color = KoodeColors.unknown;
        bg = KoodeColors.unknownLight;
        icon = Icons.schedule_rounded;
        missedCount++;
      } else {
        status = 'NONE';
        accessibilityLabel = '$dayName: no scheduled check-in';
        color = KoodeColors.unknown;
        bg = KoodeColors.unknownLight;
        icon = Icons.remove_rounded;
      }

      days.add({
        'date': day,
        'dayName': DateFormat('E').format(day), // Mon, Tue...
        'dayNumber': DateFormat('d').format(day),
        'status': status,
        'accessibilityLabel': accessibilityLabel,
        'color': color,
        'bg': bg,
        'icon': icon,
        'count': dayCheckins.length,
      });
    }

    return Container(
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
              const Row(
                children: [
                  Icon(Icons.date_range_rounded, size: 18, color: KoodeColors.olive),
                  SizedBox(width: 8),
                  Text(
                    'This Week',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: KoodeColors.ink,
                    ),
                  ),
                ],
              ),
              if (selectedDate != null)
                TextButton(
                  onPressed: () => onSelectDate(null),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Show all', style: TextStyle(color: KoodeColors.sage, fontSize: 13)),
                )
              else if (onViewWellbeing != null)
                TextButton(
                  onPressed: onViewWellbeing,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('History', style: TextStyle(color: KoodeColors.olive, fontSize: 13, fontWeight: FontWeight.w600)),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right, size: 16),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // 7-day row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: days.map((d) {
              final date = d['date'] as DateTime;
              final isSelected = selectedDate != null && DateUtils.isSameDay(date, selectedDate!);
              final isToday = DateUtils.isSameDay(date, now);
              final Color col = d['color'] as Color;
              final Color bgCol = d['bg'] as Color;
              final IconData ic = d['icon'] as IconData;

              return Expanded(
                child: Semantics(
                  label: d['accessibilityLabel'] as String,
                  selected: isSelected,
                  button: true,
                  child: InkWell(
                    onTap: () {
                      if (isSelected) {
                        onSelectDate(null);
                      } else {
                        onSelectDate(date);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? KoodeColors.oliveLight
                            : isToday
                                ? KoodeColors.surfaceVariant
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? KoodeColors.olive
                              : isToday
                                  ? KoodeColors.cardBorder
                                  : Colors.transparent,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            d['dayName'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? KoodeColors.olive : KoodeColors.secondaryText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            d['dayNumber'] as String,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? KoodeColors.olive : KoodeColors.ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: bgCol,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(ic, size: 14, color: col),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          // Plain language summary (No reliance on color alone!)
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _legendItem(KoodeColors.sage, '$fineCount checked in'),
              _legendItem(KoodeColors.concern, '$concernCount concern${concernCount == 1 ? "" : "s"}'),
              _legendItem(KoodeColors.unknown, '$missedCount no response'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(fontSize: 12, color: KoodeColors.secondaryText),
        ),
      ],
    );
  }
}
