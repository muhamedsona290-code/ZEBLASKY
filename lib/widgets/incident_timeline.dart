import 'package:flutter/material.dart';
import '../theme/koode_theme.dart';

const incidentStages = ['Alert sent', 'Accepted', 'En route', 'Arrived', 'Resolved'];

class IncidentTimeline extends StatelessWidget {
  final int currentStageIndex; // 0 to 4

  const IncidentTimeline({
    super.key,
    required this.currentStageIndex,
  });

  static int stageIndexFromStatus(String? status) {
    switch (status) {
      case 'ACKNOWLEDGED':
        return 1;
      case 'EN_ROUTE':
        return 2;
      case 'ARRIVED':
        return 3;
      case 'RESOLVED':
        return 4;
      default:
        // 'ACTIVE', 'LEVEL_1_NOTIFIED', 'LEVEL_2_NOTIFIED', 'LEVEL_3_ESCALATION'
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(incidentStages.length * 2 - 1, (index) {
            if (index.isEven) {
              final stageIdx = index ~/ 2;
              final isPassed = stageIdx < currentStageIndex;
              final isCurrent = stageIdx == currentStageIndex;

              return Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCurrent
                      ? KoodeColors.emergency
                      : isPassed
                          ? KoodeColors.sage
                          : KoodeColors.unknownLight,
                  border: Border.all(
                    color: isCurrent
                        ? Colors.white
                        : isPassed
                            ? KoodeColors.sage
                            : KoodeColors.divider,
                    width: isCurrent ? 2 : 1,
                  ),
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: KoodeColors.emergency.withValues(alpha: 0.4),
                            blurRadius: 6,
                            spreadRadius: 1,
                          )
                        ]
                      : null,
                ),
                child: Center(
                  child: isPassed
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : isCurrent
                          ? const Icon(Icons.circle, size: 10, color: Colors.white)
                          : Text(
                              '${stageIdx + 1}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: KoodeColors.secondaryText,
                              ),
                            ),
                ),
              );
            } else {
              // Connector line
              final stageBefore = index ~/ 2;
              final isPassed = stageBefore < currentStageIndex;

              return Expanded(
                child: Container(
                  height: 3,
                  color: isPassed ? KoodeColors.sage : KoodeColors.divider,
                ),
              );
            }
          }),
        ),
        const SizedBox(height: 8),
        // Stage label row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(incidentStages.length, (idx) {
            final isCurrent = idx == currentStageIndex;
            return SizedBox(
              width: 58,
              child: Text(
                incidentStages[idx],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                  color: isCurrent ? KoodeColors.emergency : KoodeColors.secondaryText,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
