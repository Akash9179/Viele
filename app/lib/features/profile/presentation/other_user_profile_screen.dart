import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';

import '../../../core/matching/match_band.dart';
import '../../../core/state/interactions.dart';
import '../../../core/theme/tokens.dart';
import '../../feed/data/mock_feed.dart';
import '../../moderation/presentation/moderation_actions.dart';

/// Another user's public profile — opened from the Recommended row or a post
/// author. Same layout as the self profile but with Follow instead of Edit.
class OtherUserProfileScreen extends ConsumerWidget {
  const OtherUserProfileScreen({
    super.key,
    required this.userId,
    required this.name,
    required this.avatarUrl,
    this.matchPct,
  });

  final String userId;
  final String name;
  final String avatarUrl;
  final int? matchPct;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final following = ref.watch(interactionsProvider).following.contains(userId);
    final handle = '@${name.toLowerCase().replaceAll(' ', '')}';
    final band = matchPct == null ? null : matchBandFor(matchPct!);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const BackButton(color: AppColors.ink),
        title: Text(handle, style: t.headlineSmall?.copyWith(fontSize: 16)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz_rounded, color: AppColors.ink),
            onPressed: () => _openUserOverflow(context, ref, userId, name, handle),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Row(
                children: [
                  Container(
                    width: 78,
                    height: 78,
                    padding: const EdgeInsets.all(2.5),
                    decoration:
                        const BoxDecoration(color: AppColors.ring, shape: BoxShape.circle),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: avatarUrl,
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
                        _Stat(value: '6', label: 'Posts'),
                        _Stat(value: '4.8k', label: 'Followers'),
                        _Stat(value: '210', label: 'Following'),
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
                  Row(
                    children: [
                      Text(name, style: t.headlineSmall),
                      if (band != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                              color: const Color(0xFFE7F2EA),
                              borderRadius: BorderRadius.circular(AppRadii.pill)),
                          child: Text(band.label,
                              style: t.bodySmall?.copyWith(
                                  color: AppColors.matchDark,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ],
                  ),
                  Text('Quiet Luxury · Off-Duty', style: t.bodyMedium),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      for (final a in const ['Hourglass', "5'7\"", 'Blonde hair', 'Blue eyes'])
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                              color: AppColors.sand,
                              borderRadius: BorderRadius.circular(AppRadii.pill)),
                          child: Text(a,
                              style: const TextStyle(
                                  fontFamily: AppFonts.text,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 11),
                  Text('Tonal dressing, good tailoring, and a soft spot for trench coats.',
                      style: t.bodyLarge?.copyWith(
                          fontSize: 13.5, height: 1.45, color: const Color(0xFF3D362B))),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () =>
                        ref.read(interactionsProvider.notifier).toggleFollow(userId),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: following ? AppColors.paper : AppColors.ink,
                        borderRadius: BorderRadius.circular(12),
                        border: following ? Border.all(color: AppColors.line) : null,
                      ),
                      child: Text(following ? 'Following' : 'Follow',
                          style: t.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: following ? AppColors.ink2 : AppColors.onInk)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(3),
            sliver: SliverMasonryGrid.count(
              crossAxisCount: 3,
              mainAxisSpacing: 3,
              crossAxisSpacing: 3,
              childCount: mockFeed.length,
              itemBuilder: (context, i) => GestureDetector(
                onTap: () => context.push('/outfit', extra: mockFeed[i]),
                child: ClipRRect(
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

void _openUserOverflow(BuildContext context, WidgetRef ref, String userId,
    String name, String handle) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.canvas,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet))),
    builder: (ctx) {
      final t = Theme.of(ctx).textTheme;
      Widget row(IconData icon, String label,
              {Color? color, required VoidCallback onTap}) =>
          ListTile(
            leading: Icon(icon, color: color ?? AppColors.ink, size: 21),
            title: Text(label,
                style: t.bodyLarge?.copyWith(color: color ?? AppColors.ink)),
            onTap: onTap,
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
            const SizedBox(height: 8),
            row(Icons.flag_outlined, 'Report $handle',
                color: const Color(0xFFD64545), onTap: () {
              Navigator.of(ctx).pop();
              showReportSheet(context, subject: handle);
            }),
            row(Icons.block_rounded, 'Block $name',
                color: const Color(0xFFD64545), onTap: () {
              Navigator.of(ctx).pop();
              confirmBlock(context, ref, userId: userId, name: name, onBlocked: () {
                if (Navigator.of(context).canPop()) Navigator.of(context).pop();
              });
            }),
            const SizedBox(height: 12),
          ],
        ),
      );
    },
  );
}
