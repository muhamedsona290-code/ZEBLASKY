import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/koode_theme.dart';

enum ElderStatusType {
  fine,
  concern,
  unanswered,
  emergency,
  inCall,
  stale,
}

class ElderStatusPanel extends StatelessWidget {
  final String elderName;
  final String elderPhone;
  final bool hasConsent;
  final ElderStatusType statusType;
  final String statusLabel;
  final String statusDescription;
  final DateTime? lastCheckinTime;
  final VoidCallback onCall;
  final VoidCallback onViewProfile;

  const ElderStatusPanel({
    super.key,
    required this.elderName,
    required this.elderPhone,
    required this.hasConsent,
    required this.statusType,
    required this.statusLabel,
    required this.statusDescription,
    required this.lastCheckinTime,
    required this.onCall,
    required this.onViewProfile,
  });

  ({Color color, Color bg, IconData icon}) _styleForStatus() {
    switch (statusType) {
      case ElderStatusType.fine:
        return (
          color: KoodeColors.sage,
          bg: KoodeColors.sageLight,
          icon: Icons.check_circle_rounded,
        );
      case ElderStatusType.concern:
        return (
          color: KoodeColors.concern,
          bg: KoodeColors.concernLight,
          icon: Icons.error_rounded,
        );
      case ElderStatusType.emergency:
        return (
          color: KoodeColors.emergency,
          bg: KoodeColors.emergencyLight,
          icon: Icons.warning_rounded,
        );
      case ElderStatusType.inCall:
        return (
          color: KoodeColors.olive,
          bg: KoodeColors.oliveLight,
          icon: Icons.phone_in_talk_rounded,
        );
      case ElderStatusType.stale:
      case ElderStatusType.unanswered:
        return (
          color: KoodeColors.unknown,
          bg: KoodeColors.unknownLight,
          icon: Icons.schedule_rounded,
        );
    }
  }

  String _formatTimestamp(DateTime? dt) {
    if (dt == null) return 'No check-in recorded yet';
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

  @override
  Widget build(BuildContext context) {
    final style = _styleForStatus();
    final timeStr = _formatTimestamp(lastCheckinTime);
    final combinedSemanticLabel = '$elderName, $statusLabel, $timeStr. $statusDescription';

    return Semantics(
      label: combinedSemanticLabel,
      container: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 330;
          final statusBadge = Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: style.bg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: style.color.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(style.icon, size: 15, color: style.color),
                const SizedBox(width: 5),
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: style.color,
                  ),
                ),
              ],
            ),
          );

          return Container(
            decoration: BoxDecoration(
              color: KoodeColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: statusType == ElderStatusType.emergency
                    ? KoodeColors.emergency.withValues(alpha: 0.3)
                    : statusType == ElderStatusType.concern
                        ? KoodeColors.concern.withValues(alpha: 0.3)
                        : KoodeColors.cardBorder,
                width: statusType == ElderStatusType.emergency || statusType == ElderStatusType.concern ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(isNarrow ? 14 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Elder Avatar, Info, Status Badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Avatar with status indicator ring
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: isNarrow ? 24 : 28,
                            backgroundColor: KoodeColors.olive.withValues(alpha: 0.12),
                            child: Text(
                              elderName.isNotEmpty ? elderName[0] : 'L',
                              style: TextStyle(
                                fontSize: isNarrow ? 20 : 24,
                                fontWeight: FontWeight.bold,
                                color: KoodeColors.olive,
                              ),
                            ),
                          ),
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: style.color,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              elderName,
                              style: TextStyle(
                                fontSize: isNarrow ? 17 : 20,
                                fontWeight: FontWeight.bold,
                                color: KoodeColors.ink,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              elderPhone,
                              style: TextStyle(fontSize: isNarrow ? 12 : 13, color: KoodeColors.secondaryText),
                            ),
                            if (isNarrow) ...[
                              const SizedBox(height: 6),
                              statusBadge,
                            ],
                          ],
                        ),
                      ),
                      if (!isNarrow) statusBadge,
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Explanation of status
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: style.bg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      statusDescription,
                      style: TextStyle(
                        fontSize: 13,
                        color: style.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: KoodeColors.divider),
                  const SizedBox(height: 10),
                  // Bottom row: Timestamp & Consent
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time_rounded, size: 14, color: KoodeColors.secondaryText),
                          const SizedBox(width: 4),
                          Text(
                            timeStr,
                            style: const TextStyle(fontSize: 12, color: KoodeColors.secondaryText),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            hasConsent ? Icons.verified_rounded : Icons.help_outline_rounded,
                            size: 14,
                            color: hasConsent ? KoodeColors.sage : KoodeColors.concern,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            hasConsent ? 'Consent verified' : 'Consent pending',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: hasConsent ? KoodeColors.sage : KoodeColors.concern,
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
        },
      ),
    );
  }
}
