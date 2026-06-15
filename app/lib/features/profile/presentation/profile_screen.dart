import 'package:flutter/material.dart';
import '../../../core/widgets/placeholder_screen.dart';

/// Profile — full build (public attributes, posts grid, collections) is next.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Profile',
      subtitle: 'Your public profile and posts land next.',
      icon: Icons.person_outline_rounded,
    );
  }
}
