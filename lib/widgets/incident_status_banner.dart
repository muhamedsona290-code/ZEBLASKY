import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../theme/koode_theme.dart';
import 'incident_timeline.dart';

class IncidentStatusBanner extends StatefulWidget {
  final Map<String, dynamic> incident;
  final String elderName;
  final String elderPhone;
  final VoidCallback onUpdated;

  const IncidentStatusBanner({
    super.key,
    required this.incident,
    required this.elderName,
    required this.elderPhone,
    required this.onUpdated,
  });

  @override
  State<IncidentStatusBanner> createState() => _IncidentStatusBannerState();
}

class _IncidentStatusBannerState extends State<IncidentStatusBanner> {
  bool _isUpdating = false;

  int get _stageIndex => IncidentTimeline.stageIndexFromStatus(widget.incident['status']);

  String get _stageName {
    final idx = _stageIndex;
    if (idx >= 0 && idx < incidentStages.length) return incidentStages[idx];
    return 'Alert active';
  }

  String get _responderName {
    final status = widget.incident['status'] as String? ?? '';
    final ack = widget.incident['acknowledged_by'] as String?;
    if (ack != null && ack.isNotEmpty) return ack;
    if (status == 'EN_ROUTE' || status == 'ARRIVED') {
      return 'Suresh Uncle (Neighbor - 2 mins away)';
    }
    return 'Primary Family Circle (Meera / Rahul)';
  }

  String get _responderPhone {
    if (_responderName.contains('Suresh')) return '+919447001122';
    return '+971501234567';
  }

  Future<void> _updateStage(String newStatus, {String? notes}) async {
    setState(() => _isUpdating = true);
    try {
      final payload = <String, dynamic>{
        'status': newStatus,
        'acknowledged_by': 'Meera (Caregiver Admin)',
      };
      if (newStatus == 'RESOLVED') {
        payload['resolved_at'] = DateTime.now().toUtc().toIso8601String();
      }
      if (notes != null && notes.trim().isNotEmpty) {
        payload['notes'] = notes.trim();
      }
      await db.from('incidents').update(payload).eq('id', widget.incident['id']);
      widget.onUpdated();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update stage: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  void _showResolveDialog() {
    final notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: KoodeColors.surface,
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: KoodeColors.sage),
            SizedBox(width: 8),
            Text(
              'Resolve Incident',
              style: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confirm that ${widget.elderName} is safe and the concern has been resolved.',
              style: const TextStyle(fontSize: 14, color: KoodeColors.ink),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Resolution note (required for record)',
                hintText: 'e.g. Neighbor checked in, Amma had lunch and resting.',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: KoodeColors.sage),
            onPressed: () {
              Navigator.pop(ctx);
              _updateStage('RESOLVED', notes: notesController.text);
            },
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Confirm Safe & Resolve'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trigger = widget.incident['trigger'] as String? ?? 'Check-in concern reported';
    final createdAt = widget.incident['created_at'] != null
        ? DateTime.tryParse(widget.incident['created_at'])?.toLocal()
        : null;
    final timeStr = createdAt != null ? DateFormat('h:mm a').format(createdAt) : 'Just now';

    return Semantics(
      label: 'Emergency Alert: ${widget.elderName} needs help. Stage: $_stageName. Responder: $_responderName.',
      container: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: KoodeColors.emergencyLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: KoodeColors.emergency, width: 2),
          boxShadow: [
            BoxShadow(
              color: KoodeColors.emergency.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Emergency Alert Title & Pulse
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: KoodeColors.emergency,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.elderName} needs help',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: KoodeColors.emergency,
                          ),
                        ),
                        Text(
                          'Alerted at $timeStr • Stage: $_stageName',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: KoodeColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Reason / trigger banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: KoodeColors.emergency.withValues(alpha: 0.2)),
                ),
                child: Text(
                  'Reason: $trigger',
                  style: const TextStyle(fontSize: 13, color: KoodeColors.ink, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 16),
              // Timeline Progression
              IncidentTimeline(currentStageIndex: _stageIndex),
              const SizedBox(height: 16),
              const Divider(color: KoodeColors.divider),
              const SizedBox(height: 12),
              // Responder Info
              Row(
                children: [
                  const Icon(Icons.shield_rounded, size: 18, color: KoodeColors.olive),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Assigned Responder',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: KoodeColors.secondaryText),
                        ),
                        Text(
                          _responderName,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: KoodeColors.ink),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Actions Row
              Row(
                children: [
                  // Call Responder Button
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: KoodeColors.olive,
                        side: const BorderSide(color: KoodeColors.olive),
                        minimumSize: const Size(0, 48),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Calling responder $_responderName at $_responderPhone…')),
                        );
                      },
                      icon: const Icon(Icons.phone_in_talk_rounded, size: 18),
                      label: const Text('Call Responder'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Resolve Button
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: KoodeColors.sage,
                        minimumSize: const Size(0, 48),
                      ),
                      onPressed: _isUpdating ? null : _showResolveDialog,
                      icon: const Icon(Icons.check_circle_rounded, size: 18),
                      label: const Text('Mark Resolved'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Stage Advance Controls for Demo / Testing
              Center(
                child: Wrap(
                  spacing: 6,
                  children: [
                    if (_stageIndex < 1)
                      TextButton(
                        onPressed: () => _updateStage('ACKNOWLEDGED'),
                        child: const Text('Accept Alert', style: TextStyle(fontSize: 12)),
                      ),
                    if (_stageIndex < 2)
                      TextButton(
                        onPressed: () => _updateStage('EN_ROUTE'),
                        child: const Text('Mark En Route', style: TextStyle(fontSize: 12)),
                      ),
                    if (_stageIndex < 3)
                      TextButton(
                        onPressed: () => _updateStage('ARRIVED'),
                        child: const Text('Mark Arrived', style: TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
