import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'main.dart';

const olive = Color(0xFF343B2D);
const sage = Color(0xFF4D7C5F);
const concernColor = Color(0xFFA56D24);
const emergencyRed = Color(0xFFC53030);
const emergencyBg = Color(0xFFFFF1F0);
const unknownGray = Color(0xFF77786F);

const stages = ['Alert sent', 'Accepted', 'En route', 'Arrived', 'Resolved'];

class FamilyIncidentBanner extends StatefulWidget {
  final Map<String, dynamic> incident;
  final String elderName;
  final String elderPhone;
  final VoidCallback onUpdated;

  const FamilyIncidentBanner({
    super.key,
    required this.incident,
    required this.elderName,
    required this.elderPhone,
    required this.onUpdated,
  });

  @override
  State<FamilyIncidentBanner> createState() => _FamilyIncidentBannerState();
}

class _FamilyIncidentBannerState extends State<FamilyIncidentBanner> {
  bool _updating = false;

  int _stageIndex(String status) {
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

  Future<void> _updateStatus(String status, {String? notes}) async {
    setState(() => _updating = true);
    try {
      final payload = <String, dynamic>{
        'status': status,
        'acknowledged_by': 'Family phone (Caregiver)',
      };
      if (status == 'RESOLVED') {
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
          SnackBar(content: Text('Failed to update incident: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  void _showResolveDialog() {
    final notesController = TextEditingController(
      text: widget.incident['notes']?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: sage),
            SizedBox(width: 8),
            Text('Resolve Incident'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confirm that ${widget.elderName} is safe and the concern has been attended to.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Resolution notes (optional)',
                hintText: 'e.g. Neighbor checked in, Amma had her meal and resting safely.',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: sage),
            onPressed: () {
              Navigator.pop(ctx);
              _updateStatus('RESOLVED', notes: notesController.text);
            },
            icon: const Icon(Icons.check),
            label: const Text('Mark as Resolved'),
          ),
        ],
      ),
    );
  }

  void _showEmergencyModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.emergency, color: emergencyRed, size: 28),
                  const SizedBox(width: 10),
                  Text(
                    'Emergency Escalation Actions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Direct assistance for ${widget.elderName} (${widget.elderPhone})',
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: emergencyRed.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_hospital, color: emergencyRed),
                ),
                title: const Text('Call Emergency Ambulance (108)', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Free 24x7 medical emergency response across Kerala'),
                trailing: const Icon(Icons.phone),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Dialing 108 Emergency Ambulance...')),
                  );
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_police, color: Colors.blue),
                ),
                title: const Text('Call National Emergency (112)', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Police, Fire and Disaster Rescue services'),
                trailing: const Icon(Icons.phone),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Dialing 112 National Emergency Helpline...')),
                  );
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: olive.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.people, color: olive),
                ),
                title: const Text('Alert Local Trusted Neighbor (Suresh Uncle)', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Next-door spare key holder · 2 mins away'),
                trailing: const Icon(Icons.phone),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Calling trusted neighbor Suresh Uncle...')),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = (widget.incident['status'] ?? 'LEVEL_1_NOTIFIED') as String;
    final currentIdx = _stageIndex(status);
    final level = (widget.incident['level'] as num?)?.toInt() ?? 1;
    final trigger = (widget.incident['trigger'] ?? 'Emergency assistance requested').toString();
    final ackBy = widget.incident['acknowledged_by']?.toString();
    final notes = widget.incident['notes']?.toString();
    final createdAtStr = widget.incident['created_at']?.toString();
    final createdAt = createdAtStr != null ? DateTime.parse(createdAtStr).toLocal() : null;

    final isLevel3 = status == 'LEVEL_3_ESCALATION' || level >= 3;

    return Container(
      margin: const EdgeInsets.only(top: 14, bottom: 6),
      decoration: BoxDecoration(
        color: emergencyBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLevel3 ? emergencyRed : emergencyRed.withValues(alpha: 0.35),
          width: isLevel3 ? 2 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: emergencyRed.withValues(alpha: isLevel3 ? 0.16 : 0.08),
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
            // Top Row: Emergency Alert Title & Level Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: emergencyRed.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: emergencyRed, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.elderName} needs attention',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: emergencyRed,
                        ),
                      ),
                      if (createdAt != null)
                        Text(
                          'Triggered ${DateFormat('h:mm a').format(createdAt)} · ${DateFormat('d MMM').format(createdAt)}',
                          style: TextStyle(fontSize: 12, color: Colors.red.shade900),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isLevel3 ? emergencyRed : emergencyRed.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isLevel3 ? 'LEVEL 3' : 'LEVEL $level',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isLevel3 ? Colors.white : emergencyRed,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Trigger Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: emergencyRed),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Trigger: $trigger',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Escalation status message
            if (currentIdx == 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isLevel3 ? Colors.red.shade900 : const Color(0xFF6B1D16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      isLevel3 ? Icons.error : Icons.timer_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isLevel3
                          ? 'Escalated to Tier 3! Automated calls sending to local responders & services.'
                          : 'Unacknowledged incident. Server auto-escalates every 30s until accepted.',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Visual Progress Tracker Across Stages
            const Text(
              'Incident Response Stages',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54),
            ),
            const SizedBox(height: 8),

            LayoutBuilder(
              builder: (ctx, constraints) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(stages.length, (i) {
                    final isPastOrCurrent = i <= currentIdx;
                    final isCurrent = i == currentIdx;

                    return Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              if (i > 0)
                                Expanded(
                                  child: Container(
                                    height: 3,
                                    color: i <= currentIdx ? emergencyRed : Colors.grey.shade300,
                                  ),
                                ),
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isPastOrCurrent ? emergencyRed : Colors.white,
                                  border: Border.all(
                                    color: isPastOrCurrent ? emergencyRed : Colors.grey.shade400,
                                    width: isCurrent ? 2.5 : 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: isPastOrCurrent
                                      ? const Icon(Icons.check, size: 13, color: Colors.white)
                                      : Text(
                                          '${i + 1}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                ),
                              ),
                              if (i < stages.length - 1)
                                Expanded(
                                  child: Container(
                                    height: 3,
                                    color: i < currentIdx ? emergencyRed : Colors.grey.shade300,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            stages[i],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                              color: isCurrent ? emergencyRed : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                );
              },
            ),

            if (ackBy != null && currentIdx > 0) ...[
              const SizedBox(height: 10),
              Text(
                'Responder: $ackBy',
                style: const TextStyle(fontSize: 12, color: Colors.black54, fontStyle: FontStyle.italic),
              ),
            ],

            if (notes != null && notes.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Notes: $notes',
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ],

            const SizedBox(height: 16),

            // Action Buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (currentIdx == 0)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: emergencyRed,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _updating ? null : () => _updateStatus('ACKNOWLEDGED'),
                    icon: const Icon(Icons.thumb_up_alt_outlined, size: 18),
                    label: const Text('Accept Alert'),
                  ),
                if (currentIdx == 1)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _updating ? null : () => _updateStatus('EN_ROUTE'),
                    icon: const Icon(Icons.directions_car_outlined, size: 18),
                    label: const Text("I'm on my way"),
                  ),
                if (currentIdx == 2)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: olive,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _updating ? null : () => _updateStatus('ARRIVED'),
                    icon: const Icon(Icons.location_on_outlined, size: 18),
                    label: const Text("I've arrived"),
                  ),
                if (currentIdx >= 1)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: sage, width: 1.5),
                      foregroundColor: sage,
                    ),
                    onPressed: _updating ? null : _showResolveDialog,
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Resolve Incident'),
                  ),
                if (isLevel3)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade900,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _showEmergencyModal,
                    icon: const Icon(Icons.phone_forwarded, size: 18),
                    label: const Text('Emergency Services (112)'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
