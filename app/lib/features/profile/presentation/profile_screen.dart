import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../../core/theme/tokens.dart';
import '../../feed/data/mock_feed.dart';

/// Public profile (frontend, mock): avatar + stats, public attribute chips
/// (weight never shown), bio, posts grid + Saved tab.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _attributes = ['Hourglass', "5'6\"", 'Brown hair', 'Hazel eyes'];

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('@mayachen', style: t.headlineSmall?.copyWith(fontSize: 16)),
                  const Icon(Icons.settings_outlined, size: 21, color: AppColors.ink),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Row(
                children: [
                  Container(
                    width: 78,
                    height: 78,
                    padding: const EdgeInsets.all(2.5),
                    decoration: const BoxDecoration(
                        color: AppColors.ring, shape: BoxShape.circle),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl:
                            'https://images.unsplash.com/photo-1534404483017-8743b4e935cd?w=180&h=180&fit=crop&crop=faces&q=80',
                        fit: BoxFit.cover,
                        placeholder: (_, _) => const ColoredBox(color: AppColors.sand),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  const Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _Stat(value: '24', label: 'Posts'),
                        _Stat(value: '1.2k', label: 'Followers'),
                        _Stat(value: '318', label: 'Following'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Maya Chen', style: t.headlineSmall),
                  Text('Quiet Luxury · Minimal Chic', style: t.bodyMedium),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [for (final a in _attributes) _AttrChip(a)],
                  ),
                  const SizedBox(height: 11),
                  Text(
                    'Soft neutrals, clean lines, the occasional trench. Saving looks for fall.',
                    style: t.bodyLarge?.copyWith(
                        fontSize: 13.5, height: 1.45, color: const Color(0xFF3D362B)),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: AppColors.ink,
                              borderRadius: BorderRadius.circular(12)),
                          child: Text('Edit profile',
                              style: t.labelLarge?.copyWith(
                                  color: AppColors.onInk,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Container(
                        width: 46,
                        height: 42,
                        decoration: BoxDecoration(
                            color: AppColors.paper,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.line)),
                        child: const Icon(Icons.share_outlined,
                            size: 18, color: AppColors.ink),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: _Tabs()),
          SliverPadding(
            padding: const EdgeInsets.all(3),
            sliver: SliverMasonryGrid.count(
              crossAxisCount: 3,
              mainAxisSpacing: 3,
              crossAxisSpacing: 3,
              childCount: mockFeed.length,
              itemBuilder: (context, i) => ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: CachedNetworkImage(
                    imageUrl: mockFeed[i].imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => const ColoredBox(color: AppColors.sand),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value, label;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(value, style: t.headlineSmall?.copyWith(fontSize: 18)),
        Text(label, style: t.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _AttrChip extends StatelessWidget {
  const _AttrChip(this.label);
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: AppColors.sand, borderRadius: BorderRadius.circular(AppRadii.pill)),
      child: Text(label,
          style: const TextStyle(
              fontFamily: AppFonts.text,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.ink)),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs();
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    Widget tab(IconData icon, String label, bool on) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: on ? AppColors.ink : AppColors.ink3),
              const SizedBox(width: 6),
              Text(label,
                  style: t.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: on ? AppColors.ink : AppColors.ink3)),
            ],
          ),
        );
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.line))),
      child: Row(
        children: [
          Container(
            decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.ink, width: 2))),
            child: tab(Icons.grid_view_rounded, 'Posts', true),
          ),
          const SizedBox(width: 24),
          tab(Icons.bookmark_outline_rounded, 'Saved', false),
        ],
      ),
    );
  }
}
