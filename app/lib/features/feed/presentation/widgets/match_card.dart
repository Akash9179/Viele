import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/state/interactions.dart';
import '../../../../core/theme/tokens.dart';
import '../../data/feed_post.dart';

/// A masonry feed card. The **photo is the hero** — only the match badge and
/// save sit on the image; author name, attributes, and likes live in a clean
/// caption below it. Tap opens the outfit detail. See `docs/design.md` §5.
class MatchCard extends ConsumerWidget {
  const MatchCard({super.key, required this.post});

  final FeedPost post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(interactionsProvider).saved.contains(post.id);
    return GestureDetector(
      onTap: () => context.push('/outfit', extra: post),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(18)),
              boxShadow: AppShadows.soft,
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(18)),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 0.72,
                    child: CachedNetworkImage(
                      imageUrl: post.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, _) =>
                          const ColoredBox(color: AppColors.sand),
                      errorWidget: (_, _, _) =>
                          const ColoredBox(color: AppColors.taupe),
                    ),
                  ),
                  Positioned(
                      top: 10, left: 10, child: _MatchPill(pct: post.matchPct)),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _SaveButton(
                      saved: saved,
                      onTap: () => ref
                          .read(interactionsProvider.notifier)
                          .toggleSave(post.id),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          _Caption(post: post),
        ],
      ),
    );
  }
}

class _MatchPill extends StatelessWidget {
  const _MatchPill({required this.pct});
  final int pct;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 4, 10, 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.only(right: 5),
            decoration: const BoxDecoration(
              color: AppColors.match,
              shape: BoxShape.circle,
            ),
          ),
          Text(
            '$pct%',
            style: const TextStyle(
              fontFamily: AppFonts.text,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.saved, required this.onTap});
  final bool saved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          shape: BoxShape.circle,
        ),
        child: Icon(saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            size: 17, color: AppColors.ink),
      ),
    );
  }
}

/// Clean caption beneath the photo — dark text on canvas, never on the image.
class _Caption extends StatelessWidget {
  const _Caption({required this.post});
  final FeedPost post;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.taupe,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  post.initials,
                  style: const TextStyle(
                    fontFamily: AppFonts.text,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF5B4F3C),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  post.authorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppFonts.text,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Expanded(
                child: Text(
                  post.attributeLine,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppFonts.text,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink2,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '♥ ${post.likes}',
                style: const TextStyle(
                  fontFamily: AppFonts.text,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
