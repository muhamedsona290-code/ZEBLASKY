import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'config.dart';
import 'main.dart';

const olive = Color(0xFF343B2D);
const sage = Color(0xFF4D7C5F);
const concern = Color(0xFFA56D24);
const emergency = Color(0xFFC53030);

class FamilyIncidentHistorySheet extends StatelessWidget {
  final String elderName;

  const FamilyIncidentHistorySheet({super.key, required this.elderName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident & Escalation History'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: db
            .from('incidents')
            .stream(primaryKey: ['id'])
            .eq('elder_id', elderId)
            .order('created_at', ascending: false)
            .limit(50),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_user_outlined, size: 64, color: sage.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    Text(
                      'No Incidents Recorded',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$elderName has had peaceful, safe check-ins with no emergency escalations.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              final trigger = item['trigger']?.toString() ?? 'Alert triggered';
              final status = item['status']?.toString() ?? 'ACTIVE';
              final level = item['level'] ?? 1;
              final ackBy = item['acknowledged_by']?.toString();
              final notes = item['notes']?.toString();
              final createdStr = item['created_at']?.toString();
              final resolvedStr = item['resolved_at']?.toString();

              final isResolved = status == 'RESOLVED';
              final isCancelled = status == 'CANCELLED';
              final isOpen = !isResolved && !isCancelled;

              final createdDt = createdStr != null ? DateTime.tryParse(createdStr)?.toLocal() : null;
              final resolvedDt = resolvedStr != null ? DateTime.tryParse(resolvedStr)?.toLocal() : null;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isOpen
                                  ? const Color(0xFFFFF1F0)
                                  : isResolved
                                      ? const Color(0xFFE8F3EB)
                                      : const Color(0xFFF0F0EE),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isOpen
                                      ? Icons.warning_amber
                                      : isResolved
                                          ? Icons.check_circle_outline
                                          : Icons.cancel_outlined,
                                  size: 14,
                                  color: isOpen ? emergency : (isResolved ? sage : Colors.grey),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isOpen ? 'ACTIVE INCIDENT' : status,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isOpen ? emergency : (isResolved ? sage : Colors.black54),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: olive.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Level $level',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: olive),
                            ),
                          ),
                          const Spacer(),
                          if (createdDt != null)
                            Text(
                              DateFormat('d MMM y, h:mm a').format(createdDt),
                              style: const TextStyle(fontSize: 12, color: Colors.black45),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        trigger,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                      if (ackBy != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Handled by: $ackBy',
                          style: const TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                      ],
                      if (notes != null && notes.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.sticky_note_2_outlined, size: 16, color: Colors.black54),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Resolution Notes: $notes',
                                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (resolvedDt != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Resolved at: ${DateFormat('d MMM, h:mm a').format(resolvedDt)}',
                          style: TextStyle(fontSize: 12, color: Colors.green.shade800),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
