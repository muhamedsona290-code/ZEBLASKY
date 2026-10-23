import 'package:flutter/material.dart';
import '../theme/koode_theme.dart';
import 'elder_selector.dart';

class FamilyHeader extends StatelessWidget {
  final ElderInfo currentElder;
  final List<ElderInfo> elders;
  final ValueChanged<ElderInfo> onElderSelected;
  final VoidCallback onSwitchRole;
  final VoidCallback onOpenSettings;
  final int unreadNotificationsCount;

  const FamilyHeader({
    super.key,
    required this.currentElder,
    required this.elders,
    required this.onElderSelected,
    required this.onSwitchRole,
    required this.onOpenSettings,
    this.unreadNotificationsCount = 0,
  });

  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: KoodeColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Family Notifications',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: KoodeColors.ink,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: KoodeColors.oliveLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Private & Protected',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: KoodeColors.olive,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Only urgent escalations and routine check-in confirmations are shared here.',
                style: TextStyle(fontSize: 13, color: KoodeColors.secondaryText),
              ),
              const SizedBox(height: 16),
              _notificationTile(
                title: 'Morning Check-in: All is well',
                subtitle: '${currentElder.name} answered food & medicines on time.',
                time: 'Today, 8:32 AM',
                icon: Icons.check_circle_outline,
                color: KoodeColors.sage,
              ),
              _notificationTile(
                title: 'Daily reminder scheduled',
                subtitle: 'Evening medication check scheduled for 7:00 PM.',
                time: 'Yesterday, 7:00 PM',
                icon: Icons.alarm,
                color: KoodeColors.olive,
              ),
              _notificationTile(
                title: 'Care Circle Active',
                subtitle: '3 trusted responders registered for rapid response.',
                time: '2 days ago',
                icon: Icons.shield_outlined,
                color: KoodeColors.secondaryText,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _notificationTile({
    required String title,
    required String subtitle,
    required String time,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KoodeColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: KoodeColors.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13, color: KoodeColors.secondaryText),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(fontSize: 11, color: KoodeColors.secondaryText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAccountMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: KoodeColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                'Caregiver Account',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: KoodeColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Logged in as Meera (Primary Family Admin)',
                style: TextStyle(fontSize: 14, color: KoodeColors.secondaryText),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.tune, color: KoodeColors.olive),
                title: const Text('Check-in & System Settings', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Customize questions, schedule & elder phone'),
                onTap: () {
                  Navigator.pop(ctx);
                  onOpenSettings();
                },
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.swap_horiz, color: KoodeColors.olive),
                title: const Text('Switch App Role', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Switch between Elder and Family phone'),
                onTap: () {
                  Navigator.pop(ctx);
                  onSwitchRole();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Koode Wordmark
          Semantics(
            header: true,
            label: 'Koode Family App',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: KoodeColors.olive,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'കൂടെ Koode',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Elder Selector
          ElderSelectorButton(
            currentElder: currentElder,
            elders: elders,
            onSelected: onElderSelected,
          ),
          const Spacer(),
          // Notifications Action
          Semantics(
            label: 'Notifications, ${unreadNotificationsCount > 0 ? "$unreadNotificationsCount unread" : "no unread"}',
            button: true,
            child: IconButton(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_outlined, color: KoodeColors.olive, size: 24),
                  if (unreadNotificationsCount > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: KoodeColors.emergency,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$unreadNotificationsCount',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
              tooltip: 'Notifications',
              onPressed: () => _showNotificationsSheet(context),
            ),
          ),
          // Account & Options Action
          Semantics(
            label: 'Caregiver profile and menu',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.account_circle_outlined, color: KoodeColors.olive, size: 26),
              tooltip: 'Account & Settings',
              onPressed: () => _showAccountMenu(context),
            ),
          ),
        ],
      ),
    );
  }
}
