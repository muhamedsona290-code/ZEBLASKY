import 'package:flutter/material.dart';
import '../theme/koode_theme.dart';

class ElderInfo {
  final String id;
  final String name;
  final String relationship;
  final String phone;
  final bool hasConsent;

  const ElderInfo({
    required this.id,
    required this.name,
    required this.relationship,
    required this.phone,
    this.hasConsent = true,
  });
}

class ElderSelectorButton extends StatelessWidget {
  final ElderInfo currentElder;
  final List<ElderInfo> elders;
  final ValueChanged<ElderInfo> onSelected;

  const ElderSelectorButton({
    super.key,
    required this.currentElder,
    required this.elders,
    required this.onSelected,
  });

  void _showSelectorSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: KoodeColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: KoodeColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select elder',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: KoodeColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Each elder has their own private check-in routine and care circle.',
                style: TextStyle(fontSize: 14, color: KoodeColors.secondaryText),
              ),
              const SizedBox(height: 16),
              ...elders.map((elder) {
                final isSelected = elder.id == currentElder.id;
                return Semantics(
                  label: '${elder.name}, ${elder.relationship}${isSelected ? ", currently selected" : ""}',
                  button: true,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? KoodeColors.oliveLight : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? KoodeColors.olive : KoodeColors.divider,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      leading: CircleAvatar(
                        backgroundColor: isSelected ? KoodeColors.olive : KoodeColors.surfaceVariant,
                        foregroundColor: isSelected ? Colors.white : KoodeColors.ink,
                        child: Text(
                          elder.name.isNotEmpty ? elder.name[0] : 'E',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        elder.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: isSelected ? KoodeColors.olive : KoodeColors.ink,
                        ),
                      ),
                      subtitle: Text(
                        '${elder.relationship} • ${elder.phone}',
                        style: const TextStyle(fontSize: 13, color: KoodeColors.secondaryText),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: KoodeColors.olive)
                          : const Icon(Icons.radio_button_unchecked, color: KoodeColors.divider),
                      onTap: () {
                        Navigator.pop(ctx);
                        onSelected(elder);
                      },
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Selected elder: ${currentElder.name}. Tap to change elder.',
      button: true,
      child: InkWell(
        onTap: () => _showSelectorSheet(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: KoodeColors.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: KoodeColors.cardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 10,
                backgroundColor: KoodeColors.olive,
                child: Text(
                  currentElder.name.isNotEmpty ? currentElder.name[0] : 'L',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 130),
                child: Text(
                  currentElder.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: KoodeColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down, size: 16, color: KoodeColors.secondaryText),
            ],
          ),
        ),
      ),
    );
  }
}
