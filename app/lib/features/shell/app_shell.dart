import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';

/// The bottom-tab scaffold: Home · Discover · ＋ · Catwalk · Profile.
/// v1 shows all five slots; Discover + Catwalk route to "coming soon" (V2 scope,
/// SRS §9). The center ＋ opens Post compose.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _items = [
    (icon: Icons.home_outlined, label: 'HOME'),
    (icon: Icons.explore_outlined, label: 'DISCOVER'),
    (icon: Icons.add, label: ''), // center +
    (icon: Icons.bookmark_outline_rounded, label: 'CATWALK'),
    (icon: Icons.person_outline_rounded, label: 'PROFILE'),
  ];

  void _onTap(int i) {
    if (i == 2) {
      navigationShell.goBranch(2); // Post
      return;
    }
    navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _VieleTabBar(
        currentIndex: navigationShell.currentIndex,
        onTap: _onTap,
        items: _items,
      ),
    );
  }
}

class _VieleTabBar extends StatelessWidget {
  const _VieleTabBar({
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  final int currentIndex;
  final void Function(int) onTap;
  final List<({IconData icon, String label})> items;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < items.length; i++)
                if (i == 2)
                  _CenterButton(onTap: () => onTap(2))
                else
                  _TabItem(
                    icon: items[i].icon,
                    label: items[i].label,
                    active: currentIndex == i,
                    onTap: () => onTap(i),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.ink : AppColors.ink3;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppFonts.text,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterButton extends StatelessWidget {
  const _CenterButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: AppColors.ink,
              shape: BoxShape.circle,
              boxShadow: AppShadows.card,
            ),
            child: const Icon(Icons.add, size: 24, color: AppColors.onInk),
          ),
        ),
      ),
    );
  }
}
