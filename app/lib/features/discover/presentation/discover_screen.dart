import 'package:flutter/material.dart';
import '../../../core/widgets/placeholder_screen.dart';

/// Discover (swipe) — V2 surface. Tab visible in v1 per Eugene's mockups, but
/// the swipe deck is deferred (SRS §9 / FR-DS.*).
class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Discover is on the way',
      subtitle: 'Swipe through looks picked for you, one at a time. Coming soon.',
      icon: Icons.explore_outlined,
    );
  }
}
