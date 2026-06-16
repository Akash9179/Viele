import 'package:flutter/material.dart';
import '../../../core/widgets/placeholder_screen.dart';

/// Catwalk — V2 surface. Tab visible in v1 per Eugene's mockups, deferred build.
class CatwalkScreen extends StatelessWidget {
  const CatwalkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Catwalk is on the way',
      subtitle: 'A runway of standout looks from people built like you. Coming soon.',
      icon: Icons.auto_awesome_outlined,
    );
  }
}
