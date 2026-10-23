import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const olive = Color(0xFF343B2D);
const sage = Color(0xFF4D7C5F);
const sageLight = Color(0xFFE8F3EB);
const concern = Color(0xFFA56D24);
const concernLight = Color(0xFFFEF3E2);
const emergency = Color(0xFFC53030);
const unknown = Color(0xFF8F938C);

class FamilyWeeklyOverview extends StatelessWidget {
  final List<Map<String, dynamic>> checkins;
  final DateTime? selectedDate;
  final ValueChanged<DateTime?> onSelectDate;

  const FamilyWeeklyOverview({
    super.key,
    required this.checkins,
    required this.selectedDate,
    required this.onSelectDate,
  });

  @override
  Widget build(BuildContext context) {
    int totalFineDays = 0;
    int totalConcernDays = 0;
    int totalDaysWithData = 0;

    final daysData = <Map<String, dynamic>>[];

    for (var d = 6; d >= 0; d--) {
      final day = DateTime.now().subtract(Duration(days: d));
      final dayRecords = checkins.where((x) {
        final dt = DateTime.tryParse(x['created_at']?.toString() ?? '')?.toLocal();
        return dt != null && DateUtils.isSameDay(dt, day);
      }).toList();

      final results = dayRecords.map((x) => x['result']).toList();
      String? dayResult;
      if (results.contains('CONCERN')) {
        dayResult = 'CONCERN';
        totalConcernDays++;
        totalDaysWithData++;
      } else if (results.contains('FINE')) {
        dayResult = 'FINE';
        totalFineDays++;
        totalDaysWithData++;
      } else if (results.isNotEmpty) {
        dayResult = 'UNANSWERED';
        totalDaysWithData++;
      }

      daysData.add({
        'date': day,
        'result': dayResult,
        'count': dayRecords.length,
      });
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.calendar_month_outlined, size: 20, color: olive),
                  SizedBox(width: 8),
                  Text(
                    '7-Day Weekly Overview',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: olive),
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
                  child: const Text('Show All', style: TextStyle(fontSize: 13, color: sage)),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // 7 Days Pill Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: daysData.map((d) {
              final date = d['date'] as DateTime;
              final res = d['result'] as String?;
              final isToday = DateUtils.isSameDay(date, DateTime.now());
              final isSelected = selectedDate != null && DateUtils.isSameDay(date, selectedDate!);

              Color bg;
              Color iconColor;
              IconData icon;

              if (res == 'FINE') {
                bg = sageLight;
                iconColor = sage;
                icon = Icons.check_circle;
              } else if (res == 'CONCERN') {
                bg = concernLight;
                iconColor = concern;
                icon = Icons.error;
              } else if (res == 'UNANSWERED') {
                bg = const Color(0xFFF1F1EF);
                iconColor = unknown;
                icon = Icons.schedule;
              } else {
                bg = const Color(0xFFF7F7F6);
                iconColor = Colors.grey.shade400;
                icon = Icons.remove;
              }

              final dayLetter = DateFormat.E().format(date).substring(0, 1);
              final dayNum = DateFormat('d').format(date);

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: InkWell(
                    onTap: () {
                      if (isSelected) {
                        onSelectDate(null);
                      } else {
                        onSelectDate(date);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? olive.withValues(alpha: 0.08) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? olive
                              : isToday
                                  ? olive.withValues(alpha: 0.3)
                                  : Colors.transparent,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            dayLetter,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                              color: isToday ? olive : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dayNum,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                              color: isToday ? olive : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: bg,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, size: 16, color: iconColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Summary Stats Pill Row
          Row(
            children: [
              _metricPill(
                icon: Icons.done_all,
                label: '$totalFineDays days safe',
                color: sage,
                bgColor: sageLight,
              ),
              const SizedBox(width: 8),
              if (totalConcernDays > 0) ...[
                _metricPill(
                  icon: Icons.notification_important_outlined,
                  label: '$totalConcernDays follow-ups',
                  color: concern,
                  bgColor: concernLight,
                ),
                const SizedBox(width: 8),
              ],
              _metricPill(
                icon: Icons.pie_chart_outline,
                label: '$totalDaysWithData/7 active',
                color: olive,
                bgColor: const Color(0xFFF2F4EE),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricPill({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
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
