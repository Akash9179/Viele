import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/matching/match_band.dart';
import '../../../core/state/interactions.dart';
import '../../../core/state/session.dart';
import '../../../core/theme/tokens.dart';
import '../../feed/data/feed_post.dart';
import '../../feed/data/feed_repository.dart';

/// Catwalk — the planned home for **rising creators**: profiles that are growing
/// fast / performing exceptionally, surfaced and promoted here. Not built yet.
///
/// The current implementation below is a placeholder runway of match-ranked
/// looks; it is intentionally sealed behind a frosted "coming soon" overlay
/// ([_ComingSoonOverlay]) so it is not testable in this TestFlight build. The
/// real growth/leaderboard feature replaces this content later.
class CatwalkScreen extends ConsumerWidget {
  const CatwalkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final feed = ref.watch(feedProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Stack(
        children: [
          // Work in progress — kept rendering for the teaser, but fully
          // non-interactive (AbsorbPointer) and hidden behind the glass.
          AbsorbPointer(
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Catwalk',
                      style: t.headlineMedium?.copyWith(fontSize: 26)),
                  const SizedBox(height: 2),
                  Text('Looks on people built like you',
                      style: t.bodyMedium?.copyWith(color: AppColors.ink2)),
                ],
              ),
            ),
            Expanded(
              child: feed.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2)),
                error: (_, _) => Center(
                  child: Text("Couldn't load the runway.",
                      style: t.bodyMedium?.copyWith(color: AppColors.ink2)),
                ),
                data: (posts) {
                  if (posts.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                            'No looks yet — be the first to post one.',
                            textAlign: TextAlign.center,
                            style: t.bodyLarge?.copyWith(color: AppColors.ink2)),
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(feedProvider),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                      itemCount: posts.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 18),
                      itemBuilder: (context, i) => _RunwayCard(post: posts[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
              ),
            ),
          const Positioned.fill(child: _ComingSoonOverlay()),
        ],
      ),
    );
  }
}

/// Frosted-glass "coming soon" seal over the work-in-progress Catwalk. Blurs the
/// content behind it and (with the AbsorbPointer wrapper) makes the whole surface
/// non-interactive — so it can't be tested in this TestFlight build.
class _ComingSoonOverlay extends StatelessWidget {
  const _ComingSoonOverlay();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          color: AppColors.canvas.withValues(alpha: 0.62),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.line),
                ),
                child: const Icon(Icons.trending_up_rounded,
                    size: 28, color: AppColors.ink),
              ),
              const SizedBox(height: 18),
              Text('Catwalk', style: t.headlineMedium?.copyWith(fontSize: 26)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(AppRadii.pill)),
                child: Text('Coming soon',
                    style: t.bodyMedium?.copyWith(
                        color: AppColors.onInk, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 14),
              Text(
                'A spotlight on rising creators — the people growing fastest on '
                'Viele. We’re still building it.',
                textAlign: TextAlign.center,
                style: t.bodyLarge?.copyWith(color: AppColors.ink2, height: 1.45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single full-width runway look: hero photo with match badge + save, author
/// caption below. Tap opens the outfit detail.
class _RunwayCard extends ConsumerWidget {
  const _RunwayCard({required this.post});
  final FeedPost post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final saved = ref.watch(interactionsProvider).saved.contains(post.id);
    final band = matchBandFor(post.matchPct);
    return GestureDetector(
      onTap: () => context.push('/outfit', extra: post),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(20)),
              boxShadow: AppShadows.soft,
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(20)),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 0.82,
                    child: CachedNetworkImage(
                      imageUrl: post.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, _) =>
                          const ColoredBox(color: AppColors.sand),
                      errorWidget: (_, _, _) =>
                          const ColoredBox(color: AppColors.taupe),
                    ),
                  ),
                  if (band != null)
                    Positioned(top: 12, left: 12, child: _Pill(label: band.label)),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => requireAccount(context, ref, () {
                        ref
                            .read(interactionsProvider.notifier)
                            .toggleSave(post.id);
                      }),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                            saved
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            size: 19,
                            color: AppColors.ink),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                    color: AppColors.taupe, shape: BoxShape.circle),
                child: Text(post.initials,
                    style: const TextStyle(
                        fontFamily: AppFonts.text,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF5B4F3C))),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodyLarge?.copyWith(
                            fontSize: 14.5, fontWeight: FontWeight.w700)),
                    if (post.attributeLine.isNotEmpty)
                      Text(post.attributeLine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              t.bodyMedium?.copyWith(color: AppColors.ink2)),
                  ],
                ),
              ),
              Text('♥ ${post.likes}',
                  style: t.bodyMedium?.copyWith(color: AppColors.ink2)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 5, 11, 5),
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
            margin: const EdgeInsets.only(right: 6),
            decoration: const BoxDecoration(
                color: AppColors.match, shape: BoxShape.circle),
          ),
          Text(label,
              style: const TextStyle(
                  fontFamily: AppFonts.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink)),
        ],
      ),
    );
  }
}
