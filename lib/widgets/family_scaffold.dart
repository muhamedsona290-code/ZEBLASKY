import 'package:flutter/material.dart';
import '../theme/koode_theme.dart';

class FamilyScaffold extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final Widget header;
  final Widget body;
  final bool hasActiveIncident;
  final bool hasPendingConcern;

  const FamilyScaffold({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.header,
    required this.body,
    this.hasActiveIncident = false,
    this.hasPendingConcern = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KoodeColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            header,
            const Divider(color: KoodeColors.divider, height: 1),
            Expanded(child: body),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: KoodeColors.surface,
          border: Border(
            top: BorderSide(color: KoodeColors.divider, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: SafeArea(
          child: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: onTabSelected,
            backgroundColor: KoodeColors.surface,
            indicatorColor: KoodeColors.oliveLight,
            elevation: 0,
            height: 64,
            destinations: [
              NavigationDestination(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.home_outlined, color: KoodeColors.secondaryText),
                    if (hasActiveIncident)
                      Positioned(
                        right: -3,
                        top: -3,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: KoodeColors.emergency,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                selectedIcon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.home_rounded, color: KoodeColors.olive),
                    if (hasActiveIncident)
                      Positioned(
                        right: -3,
                        top: -3,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: KoodeColors.emergency,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.favorite_border_rounded, color: KoodeColors.secondaryText),
                    if (hasPendingConcern)
                      Positioned(
                        right: -3,
                        top: -3,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: KoodeColors.concern,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                selectedIcon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.favorite_rounded, color: KoodeColors.olive),
                    if (hasPendingConcern)
                      Positioned(
                        right: -3,
                        top: -3,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: KoodeColors.concern,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                label: 'Wellbeing',
              ),
              const NavigationDestination(
                icon: Icon(Icons.calendar_today_outlined, color: KoodeColors.secondaryText),
                selectedIcon: Icon(Icons.calendar_month_rounded, color: KoodeColors.olive),
                label: 'Care plan',
              ),
              const NavigationDestination(
                icon: Icon(Icons.shield_outlined, color: KoodeColors.secondaryText),
                selectedIcon: Icon(Icons.shield_rounded, color: KoodeColors.olive),
                label: 'Support',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
