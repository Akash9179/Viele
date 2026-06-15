import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../data/feed_post.dart';

/// A single outfit card in the masonry feed: photo bleed, match pill, bookmark,
/// and the author's public attribute line. See `docs/design.md` §5 (Match card).
class MatchCard extends StatelessWidget {
  const MatchCard({super.key, required this.post});

  final FeedPost post;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.card)),
        boxShadow: AppShadows.card,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(AppRadii.card)),
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: 0.74,
              child: CachedNetworkImage(
                imageUrl: post.imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, _) => const ColoredBox(color: AppColors.sand),
                errorWidget: (_, _, _) =>
                    const ColoredBox(color: AppColors.taupe),
              ),
            ),
            // bottom-up legibility gradient
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xA6160F08), Color(0x00160F08)],
                    stops: [0.0, 0.62],
                  ),
                ),
              ),
            ),
            Positioned(top: 11, left: 11, child: _MatchPill(pct: post.matchPct)),
            const Positioned(top: 11, right: 11, child: _SaveButton()),
            Positioned(
              left: 13,
              right: 13,
              bottom: 12,
              child: _CardMeta(post: post),
            ),
          ],
        ),
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
      padding: const EdgeInsets.fromLTRB(8, 5, 11, 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 6),
            decoration: const BoxDecoration(
              color: AppColors.match,
              shape: BoxShape.circle,
            ),
          ),
          Text(
            '$pct% match',
            style: const TextStyle(
              fontFamily: AppFonts.text,
              fontSize: 12,
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
  const _SaveButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.bookmark_border_rounded,
          size: 18, color: AppColors.ink),
    );
  }
}

class _CardMeta extends StatelessWidget {
  const _CardMeta({required this.post});
  final FeedPost post;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 27,
              height: 27,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.taupe,
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.55), width: 1.5),
              ),
              child: Text(
                post.initials,
                style: const TextStyle(
                  fontFamily: AppFonts.text,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF5B4F3C),
                ),
              ),
            ),
            const SizedBox(width: 7),
            Text(
              post.authorName,
              style: const TextStyle(
                fontFamily: AppFonts.text,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                post.attributeLine,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppFonts.text,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.88),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Text(
                '♥ ${post.likes}',
                style: const TextStyle(
                  fontFamily: AppFonts.text,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
