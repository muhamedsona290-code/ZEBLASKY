import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/koode_theme.dart';
import '../widgets/checkin_history_tile.dart';
import '../widgets/checkin_week_strip.dart';
import '../widgets/elder_selector.dart';
import '../widgets/state_views.dart';

class FamilyWellbeingTab extends StatefulWidget {
  final ElderInfo currentElder;
  final List<Map<String, dynamic>> checkins;
  final List<Map<String, dynamic>> allAnswers;
  final bool isLoading;
  final VoidCallback onRefresh;

  const FamilyWellbeingTab({
    super.key,
    required this.currentElder,
    required this.checkins,
    required this.allAnswers,
    this.isLoading = false,
    required this.onRefresh,
  });

  @override
  State<FamilyWellbeingTab> createState() => _FamilyWellbeingTabState();
}

class _FamilyWellbeingTabState extends State<FamilyWellbeingTab> {
  DateTime? _selectedFilterDate;

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading && widget.checkins.isEmpty) {
      return const LoadingStateView(message: 'Loading wellbeing history…');
    }

    final filteredList = _selectedFilterDate == null
        ? widget.checkins
        : widget.checkins.where((x) {
            final dt = DateTime.tryParse(x['created_at']?.toString() ?? '')?.toLocal();
            return dt != null && DateUtils.isSameDay(dt, _selectedFilterDate!);
          }).toList();

    return RefreshIndicator(
      color: KoodeColors.olive,
      onRefresh: () async => widget.onRefresh(),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Title
          const Text(
            'Wellbeing & History',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: KoodeColors.secondaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "${widget.currentElder.name}’s wellbeing",
            style: KoodeTheme.displayTitle,
          ),
          const SizedBox(height: 6),
          const Text(
            'Clear records of daily check-ins, recorded food & medication answers, and caregiver follow-up notes.',
            style: TextStyle(fontSize: 14, color: KoodeColors.secondaryText, height: 1.3),
          ),
          const SizedBox(height: 18),

          // 7-day strip with accessible selector
          CheckInWeekStrip(
            checkins: widget.checkins,
            selectedDate: _selectedFilterDate,
            onSelectDate: (d) => setState(() => _selectedFilterDate = d),
          ),
          const SizedBox(height: 20),

          // Chronological list header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedFilterDate == null
                    ? 'Chronological Records'
                    : 'Check-ins for ${DateFormat('d MMMM').format(_selectedFilterDate!)}',
                style: KoodeTheme.sectionTitle,
              ),
              if (_selectedFilterDate != null)
                TextButton(
                  onPressed: () => setState(() => _selectedFilterDate = null),
                  child: const Text('Show all'),
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (filteredList.isEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: KoodeColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: KoodeColors.cardBorder),
              ),
              child: const EmptyStateView(
                title: 'No check-ins recorded',
                message: 'No check-ins recorded for this period.',
                icon: Icons.history_toggle_off_rounded,
              ),
            )
          else
            ...filteredList.map((checkin) {
              final answersForCheckin = widget.allAnswers
                  .where((a) => a['checkin_id']?.toString() == checkin['id']?.toString())
                  .toList();
              return CheckInHistoryTile(
                checkin: checkin,
                answers: answersForCheckin,
              );
            }),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
