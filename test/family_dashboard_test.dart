import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koode/models/care_reminder.dart';
import 'package:koode/models/trusted_contact.dart';
import 'package:koode/theme/koode_theme.dart';
import 'package:koode/widgets/checkin_history_tile.dart';
import 'package:koode/widgets/checkin_week_strip.dart';
import 'package:koode/widgets/contact_action_tile.dart';
import 'package:koode/widgets/elder_status_panel.dart';
import 'package:koode/widgets/incident_timeline.dart';
import 'package:koode/widgets/reminder_summary_tile.dart';

void main() {
  Widget wrapWidget(Widget child, {double width = 390, double height = 844}) {
    return MaterialApp(
      theme: KoodeTheme.theme,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            height: height,
            child: SingleChildScrollView(child: child),
          ),
        ),
      ),
    );
  }

  group('Koode Family Dashboard Specification Tests', () {
    testWidgets('ElderStatusPanel displays elder name, status, and accessible semantics', (tester) async {
      final testTime = DateTime.now();
      await tester.pumpWidget(wrapWidget(
        ElderStatusPanel(
          elderName: 'Lakshmi Amma',
          elderPhone: '+919876543210',
          hasConsent: true,
          statusType: ElderStatusType.fine,
          statusLabel: 'All is well',
          statusDescription: 'Check-in completed. Food and medications confirmed.',
          lastCheckinTime: testTime,
          onCall: () {},
          onViewProfile: () {},
        ),
      ));

      expect(find.text('Lakshmi Amma'), findsOneWidget);
      expect(find.text('All is well'), findsOneWidget);
      expect(find.text('Consent verified'), findsOneWidget);
      expect(find.textContaining('Today at'), findsOneWidget);

      // Verify accessibility semantics
      final semanticsFinder = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label?.contains('Lakshmi Amma') == true,
      );
      expect(semanticsFinder, findsWidgets);
    });

    testWidgets('CheckInWeekStrip has accessible day labels without relying on color alone', (tester) async {
      final now = DateTime.now();
      final checkins = [
        {
          'id': '1',
          'created_at': now.toIso8601String(),
          'result': 'FINE',
        },
        {
          'id': '2',
          'created_at': now.subtract(const Duration(days: 1)).toIso8601String(),
          'result': 'CONCERN',
        },
      ];

      await tester.pumpWidget(wrapWidget(
        CheckInWeekStrip(
          checkins: checkins,
          selectedDate: null,
          onSelectDate: (_) {},
        ),
      ));

      expect(find.text('This Week'), findsOneWidget);
      // Verify text summary legend is visible (no color-only reliance)
      expect(find.textContaining('checked in'), findsOneWidget);
      expect(find.textContaining('concern'), findsOneWidget);
      expect(find.textContaining('no response'), findsOneWidget);
    });

    testWidgets('IncidentTimeline renders all 5 progression stages', (tester) async {
      await tester.pumpWidget(wrapWidget(
        const IncidentTimeline(currentStageIndex: 2), // En route
      ));

      expect(find.text('Alert sent'), findsOneWidget);
      expect(find.text('Accepted'), findsOneWidget);
      expect(find.text('En route'), findsOneWidget);
      expect(find.text('Arrived'), findsOneWidget);
      expect(find.text('Resolved'), findsOneWidget);
    });

    testWidgets('ReminderSummaryTile handles both upcoming reminder and empty states', (tester) async {
      // Empty state
      await tester.pumpWidget(wrapWidget(
        ReminderSummaryTile(
          nextReminder: null,
          onViewCarePlan: () {},
        ),
      ));
      expect(find.text('No upcoming reminders'), findsOneWidget);

      // Active state
      await tester.pumpWidget(wrapWidget(
        ReminderSummaryTile(
          nextReminder: const CareReminder(
            id: '1',
            title: 'Evening Blood Pressure Tablet',
            time: '07:00 PM',
            category: 'Medication',
          ),
          onViewCarePlan: () {},
        ),
      ));
      expect(find.text('Evening Blood Pressure Tablet'), findsOneWidget);
      expect(find.textContaining('07:00 PM'), findsOneWidget);
    });

    testWidgets('ContactActionTile displays verified identity and consented actions', (tester) async {
      const contact = TrustedContact(
        id: '1',
        name: 'Suresh Uncle',
        relationship: 'Next-door Neighbor (Kochi)',
        phone: '+919447001122',
        tier: 2,
        locationNote: 'Key holder (2 mins away)',
      );

      bool called = false;
      bool messaged = false;

      await tester.pumpWidget(wrapWidget(
        ContactActionTile(
          contact: contact,
          onCall: () => called = true,
          onMessage: () => messaged = true,
        ),
      ));

      expect(find.text('Suresh Uncle'), findsOneWidget);
      expect(find.text('Next-door Neighbor (Kochi)'), findsOneWidget);
      expect(find.text('+919447001122'), findsOneWidget);
      expect(find.text('Key holder (2 mins away)'), findsOneWidget);

      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(called, isTrue);

      await tester.tap(find.byType(OutlinedButton));
      await tester.pump();
      expect(messaged, isTrue);
    });

    testWidgets('CheckInHistoryTile displays recorded questions and answers', (tester) async {
      final checkin = {
        'id': 'chk-1',
        'result': 'CONCERN',
        'source': 'call',
        'created_at': DateTime.now().toIso8601String(),
      };
      final answers = [
        {
          'checkin_id': 'chk-1',
          'question_text': 'Have you eaten your food?',
          'label': 'Yes',
        },
        {
          'checkin_id': 'chk-1',
          'question_text': 'Have you taken your medicines on time?',
          'label': 'No',
        },
      ];

      await tester.pumpWidget(wrapWidget(
        CheckInHistoryTile(
          checkin: checkin,
          answers: answers,
        ),
      ));

      expect(find.text('Needs follow-up'), findsOneWidget);
      expect(find.textContaining('Have you taken your medicines'), findsOneWidget);
    });

    testWidgets('Responsive test: Layout remains usable at 320px width without overflow', (tester) async {
      // 320 px width (Acceptance Checklist: Layout remains usable at 320 px width)
      await tester.pumpWidget(wrapWidget(
        Column(
          children: [
            ElderStatusPanel(
              elderName: 'Lakshmi Amma',
              elderPhone: '+919876543210',
              hasConsent: true,
              statusType: ElderStatusType.concern,
              statusLabel: 'Needs follow-up',
              statusDescription: 'Reported missed medication.',
              lastCheckinTime: DateTime.now(),
              onCall: () {},
              onViewProfile: () {},
            ),
            const SizedBox(height: 12),
            ReminderSummaryTile(
              nextReminder: const CareReminder(
                id: '1',
                title: 'Morning Tablet',
                time: '08:00 AM',
                category: 'Medication',
              ),
              onViewCarePlan: () {},
            ),
            const SizedBox(height: 12),
            const IncidentTimeline(currentStageIndex: 1),
          ],
        ),
        width: 320,
      ));

      // If there are render overflows, tester.takeException() will catch them
      expect(tester.takeException(), isNull);
    });
  });
}
