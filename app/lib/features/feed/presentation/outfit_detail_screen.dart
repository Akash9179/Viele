import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/matching/match_band.dart';
import '../../../core/state/interactions.dart';
import '../../../core/state/session.dart';
import '../../../core/theme/tokens.dart';
import '../../moderation/presentation/moderation_actions.dart';
import '../data/feed_post.dart';

/// Debug-only: auto-open a moderation sheet for screenshots
/// (`--dart-define=SHEET=report` or `=block`).
const _kSheet = String.fromEnvironment('SHEET');
bool _debugSheetShown = false;

/// Outfit detail — opened by tapping a feed card. Photo, author + public
/// attributes, caption, aesthetics, shoppable items, and live actions
/// (like / save / follow / share, overflow → report/block).
class OutfitDetailScreen extends ConsumerWidget {
  const OutfitDetailScreen({super.key, required this.post});

  final FeedPost post;

  // Mock "shop the look" rows for the demo.
  static const _items = [
    (name: 'Cropped knit sweater', brand: 'COS'),
    (name: 'Pleated wool trousers', brand: 'Aritzia'),
    (name: 'Leather belt', brand: 'Massimo Dutti'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final inter = ref.watch(interactionsProvider);
    final saved = inter.saved.contains(post.id);
    final liked = inter.liked.contains(post.id);
    final following = inter.following.contains(post.authorId);

    if (_kSheet.isNotEmpty && !_debugSheetShown) {
      _debugSheetShown = true;
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!context.mounted) return;
        if (_kSheet == 'report') {
          showReportSheet(context, subject: 'this post', postId: post.id);
        } else if (_kSheet == 'block') {
          confirmBlock(context, ref, userId: post.authorId, name: post.authorName);
        }
      });
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              children: [
                AspectRatio(
                  aspectRatio: 0.8,
                  child: CachedNetworkImage(
                    imageUrl: post.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => const ColoredBox(color: AppColors.sand),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _RoundBtn(
                          icon: Icons.arrow_back_ios_new_rounded,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                        _RoundBtn(
                          icon: Icons.more_horiz_rounded,
                          onTap: () => _openOverflow(context, ref, post.id,
                              post.authorId, post.authorName),
                        ),
                      ],
                    ),
                  ),
                ),
                if (matchBandFor(post.matchPct) case final band?)
                  Positioned(
                    left: 14,
                    bottom: 14,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(8, 5, 12, 5),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(AppRadii.pill)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: const BoxDecoration(
                                color: AppColors.match, shape: BoxShape.circle)),
                        Text(band.label,
                            style: const TextStyle(
                                fontFamily: AppFonts.text,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink)),
                      ]),
                    ),
                  ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // author + follow
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => context.push('/user', extra: (
                            id: post.authorId,
                            name: post.authorName,
                            avatar: post.imageUrl,
                            pct: post.matchPct,
                          )),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                    color: AppColors.taupe, shape: BoxShape.circle),
                                child: Text(post.initials,
                                    style: const TextStyle(
                                        fontFamily: AppFonts.text,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF5B4F3C))),
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(post.authorName,
                                        style: t.headlineSmall?.copyWith(fontSize: 16)),
                                    Text(post.aesthetic, style: t.bodyMedium),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _FollowButton(
                        following: following,
                        onTap: () => ref
                            .read(interactionsProvider.notifier)
                            .toggleFollow(post.authorId),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // public attribute chips
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      for (final a in [post.aesthetic, post.height, 'Size ${post.size}', 'Hourglass'])
                        _AttrChip(a),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // actions
                  Row(
                    children: [
                      _Action(
                        icon: liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        label: post.likes,
                        active: liked,
                        onTap: () => ref.read(interactionsProvider.notifier).toggleLike(post.id),
                      ),
                      const SizedBox(width: 22),
                      _Action(
                        icon: saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        label: saved ? 'Saved' : 'Save',
                        active: saved,
                        onTap: () => requireAccount(context, ref,
                            () => ref.read(interactionsProvider.notifier).toggleSave(post.id)),
                      ),
                      const Spacer(),
                      _RoundBtn(
                        icon: Icons.ios_share_rounded,
                        light: true,
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Cream knit + tailored trousers — my go-to ‘quiet luxury’ uniform for grey days. Kept the palette tonal and let the tailoring do the talking.',
                    style: t.bodyLarge?.copyWith(fontSize: 14.5, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  Text('SHOP THE LOOK',
                      style: t.labelSmall?.copyWith(letterSpacing: 1.6)),
                  const SizedBox(height: 6),
                  for (final it in _items) _ItemRow(name: it.name, brand: it.brand),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  const _RoundBtn({required this.icon, required this.onTap, this.light = false});
  final IconData icon;
  final VoidCallback onTap;
  final bool light;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        margin: const EdgeInsets.only(top: 6),
        decoration: BoxDecoration(
          color: light
              ? AppColors.paper
              : Colors.white.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          border: light ? Border.all(color: AppColors.line) : null,
        ),
        child: Icon(icon, size: 18, color: AppColors.ink),
      ),
    );
  }
}

class _FollowButton extends StatelessWidget {
  const _FollowButton({required this.following, required this.onTap});
  final bool following;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: following ? AppColors.paper : AppColors.ink,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: following ? Border.all(color: AppColors.line) : null,
        ),
        child: Text(
          following ? 'Following' : 'Follow',
          style: TextStyle(
            fontFamily: AppFonts.text,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: following ? AppColors.ink2 : AppColors.onInk,
          ),
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
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
    final color = active ? AppColors.ink : AppColors.ink;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Icon(icon, size: 23, color: icon == Icons.favorite_rounded ? const Color(0xFFD64545) : color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontFamily: AppFonts.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink)),
        ],
      ),
    );
  }
}

class _AttrChip extends StatelessWidget {
  const _AttrChip(this.label);
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
          color: AppColors.sand, borderRadius: BorderRadius.circular(AppRadii.pill)),
      child: Text(label,
          style: const TextStyle(
              fontFamily: AppFonts.text,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.ink)),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.name, required this.brand});
  final String name, brand;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.line))),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: AppColors.sand, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.checkroom_rounded, size: 18, color: AppColors.ink2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: t.bodyLarge?.copyWith(
                        fontSize: 14.5, fontWeight: FontWeight.w600)),
                Text(brand, style: t.bodyMedium),
              ],
            ),
          ),
          const Icon(Icons.north_east_rounded, size: 16, color: AppColors.ink3),
        ],
      ),
    );
  }
}

void _openOverflow(BuildContext context, WidgetRef ref, String postId,
    String authorId, String author) {
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
            row(Icons.flag_outlined, 'Report post',
                color: const Color(0xFFD64545), onTap: () {
              Navigator.of(ctx).pop();
              showReportSheet(context, subject: 'this post', postId: postId);
            }),
            row(Icons.block_rounded, 'Block $author',
                color: const Color(0xFFD64545), onTap: () {
              Navigator.of(ctx).pop();
              confirmBlock(context, ref, userId: authorId, name: author, onBlocked: () {
                if (Navigator.of(context).canPop()) Navigator.of(context).pop();
              });
            }),
            row(Icons.link_rounded, 'Copy link',
                onTap: () => Navigator.of(ctx).pop()),
            const SizedBox(height: 12),
          ],
        ),
      );
    },
  );
}
