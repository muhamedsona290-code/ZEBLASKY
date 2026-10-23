import 'package:flutter/material.dart';
import '../models/trusted_contact.dart';
import '../theme/koode_theme.dart';

class ContactActionTile extends StatelessWidget {
  final TrustedContact contact;
  final VoidCallback onCall;
  final VoidCallback onMessage;

  const ContactActionTile({
    super.key,
    required this.contact,
    required this.onCall,
    required this.onMessage,
  });

  Color _tierColor(int tier) {
    switch (tier) {
      case 1:
        return KoodeColors.olive;
      case 2:
        return KoodeColors.concern;
      case 3:
      default:
        return KoodeColors.emergency;
    }
  }

  String _tierLabel(int tier) {
    switch (tier) {
      case 1:
        return 'Tier 1: Family Circle';
      case 2:
        return 'Tier 2: Local Neighbor';
      case 3:
      default:
        return 'Tier 3: Emergency 24/7';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tColor = _tierColor(contact.tier);
    final tLabel = _tierLabel(contact.tier);

    return Semantics(
      label: '${contact.name}, ${contact.relationship}. Phone: ${contact.phone}. $tLabel.',
      container: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: KoodeColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: KoodeColors.cardBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: tColor.withValues(alpha: 0.12),
                    child: Text(
                      contact.name.isNotEmpty ? contact.name[0] : 'C',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: tColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                contact.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: KoodeColors.ink,
                                ),
                              ),
                            ),
                            if (contact.isPrimary) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: KoodeColors.oliveLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Primary',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: KoodeColors.olive,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          contact.relationship,
                          style: const TextStyle(fontSize: 13, color: KoodeColors.secondaryText),
                        ),
                        if (contact.locationNote.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 12, color: KoodeColors.secondaryText),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  contact.locationNote,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, color: KoodeColors.secondaryText),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: tColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: tColor.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      'T${contact.tier}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: tColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: KoodeColors.divider),
              const SizedBox(height: 8),
              // Verified Contact Actions
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  Text(
                    contact.phone,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: KoodeColors.ink,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: onMessage,
                        icon: const Icon(Icons.message_rounded, size: 14),
                        label: const Text('Message', style: TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: tColor,
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: onCall,
                        icon: const Icon(Icons.phone_rounded, size: 14),
                        label: const Text('Call', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
