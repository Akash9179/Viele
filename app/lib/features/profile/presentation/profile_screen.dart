import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';

import '../../../core/state/interactions.dart';
import '../../../core/theme/tokens.dart';
import '../../feed/data/feed_post.dart';
import '../../feed/data/mock_feed.dart';

/// Public profile (frontend, mock): avatar + stats, public attribute chips
/// (weight never shown), bio, Posts / Saved tabs.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _tab = 0; // 0 = Posts, 1 = Saved
  static const _attributes = ['Hourglass', "5'6\"", 'Brown hair', 'Hazel eyes'];

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final saved = ref.watch(interactionsProvider).saved;
    final List<FeedPost> posts = _tab == 0
        ? mockFeed
        : mockFeed.where((p) => saved.contains(p.id)).toList();

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
                  GestureDetector(
                    onTap: () => _openSettings(context),
                    child: const Icon(Icons.settings_outlined,
                        size: 21, color: AppColors.ink),
                  ),
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
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _Stat(value: '${mockFeed.length}', label: 'Posts'),
                        const _Stat(value: '1.2k', label: 'Followers'),
                        const _Stat(value: '318', label: 'Following'),
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
                        child: GestureDetector(
                          onTap: () => _openEditProfile(context),
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
          SliverToBoxAdapter(
            child: _Tabs(
              current: _tab,
              savedCount: saved.length,
              onTap: (i) => setState(() => _tab = i),
            ),
          ),
          if (posts.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
                child: Column(
                  children: [
                    const Icon(Icons.bookmark_border_rounded,
                        size: 38, color: AppColors.ink3),
                    const SizedBox(height: 12),
                    Text('Nothing saved yet',
                        style: t.titleLarge?.copyWith(fontSize: 18)),
                    const SizedBox(height: 4),
                    Text('Tap the bookmark on any outfit to keep it here.',
                        textAlign: TextAlign.center,
                        style: t.bodyLarge?.copyWith(color: AppColors.ink2)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(3),
              sliver: SliverMasonryGrid.count(
                crossAxisCount: 3,
                mainAxisSpacing: 3,
                crossAxisSpacing: 3,
                childCount: posts.length,
                itemBuilder: (context, i) => GestureDetector(
                  onTap: () => context.push('/outfit', extra: posts[i]),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: AspectRatio(
                      aspectRatio: 3 / 4,
                      child: CachedNetworkImage(
                        imageUrl: posts[i].imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => const ColoredBox(color: AppColors.sand),
                      ),
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
  const _Tabs({required this.current, required this.onTap, required this.savedCount});
  final int current;
  final int savedCount;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    Widget tab(int i, IconData icon, String label) {
      final on = current == i;
      return GestureDetector(
        onTap: () => onTap(i),
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(
                      color: on ? AppColors.ink : Colors.transparent, width: 2))),
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
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.line))),
      child: Row(
        children: [
          tab(0, Icons.grid_view_rounded, 'Posts'),
          const SizedBox(width: 24),
          tab(1, Icons.bookmark_outline_rounded,
              savedCount == 0 ? 'Saved' : 'Saved · $savedCount'),
        ],
      ),
    );
  }
}

void _openSettings(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.canvas,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet))),
    builder: (ctx) {
      final t = Theme.of(ctx).textTheme;
      Widget row(IconData icon, String label, {Color? color}) => ListTile(
            leading: Icon(icon, size: 21, color: color ?? AppColors.ink),
            title: Text(label, style: t.bodyLarge?.copyWith(color: color ?? AppColors.ink)),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.ink3),
            onTap: () => Navigator.of(ctx).pop(),
          );
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                    color: AppColors.ink3, borderRadius: BorderRadius.circular(3))),
            const SizedBox(height: 6),
            row(Icons.person_outline_rounded, 'Account'),
            row(Icons.lock_outline_rounded, 'Privacy & data'),
            row(Icons.notifications_none_rounded, 'Notifications'),
            row(Icons.help_outline_rounded, 'Help & guidelines'),
            row(Icons.logout_rounded, 'Sign out', color: const Color(0xFFD64545)),
            const SizedBox(height: 12),
          ],
        ),
      );
    },
  );
}

void _openEditProfile(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.canvas,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet))),
    builder: (ctx) {
      final t = Theme.of(ctx).textTheme;
      Widget field(String label, String value, {bool priv = false}) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(label.toUpperCase(), style: t.labelSmall),
                  Text(priv ? 'Private' : 'Public',
                      style: t.bodySmall?.copyWith(
                          color: priv ? AppColors.ink2 : AppColors.matchDark,
                          fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.line)),
                  child: Text(value, style: t.bodyLarge),
                ),
              ],
            ),
          );
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                        color: AppColors.ink3, borderRadius: BorderRadius.circular(3))),
              ),
              const SizedBox(height: 14),
              Text('Edit profile', style: t.headlineSmall?.copyWith(fontSize: 20)),
              const SizedBox(height: 16),
              field('Name', 'Maya Chen'),
              field('Bio', 'Soft neutrals, clean lines, the occasional trench.'),
              field('Height', "5'6\""),
              field('Weight', 'Not shown', priv: true),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                child: Container(
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: AppColors.ink, borderRadius: BorderRadius.circular(14)),
                  child: Text('Save changes',
                      style: t.labelLarge?.copyWith(
                          color: AppColors.onInk, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
