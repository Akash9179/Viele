import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/swipe_repository.dart';
import '../../../core/matching/match_band.dart';
import '../../../core/state/interactions.dart';
import '../../../core/state/session.dart';
import '../../../core/theme/tokens.dart';
import '../../feed/data/feed_post.dart';

/// Discover — a swipe deck of looks picked for you, one at a time. Drag right to
/// like, left to pass; the bookmark keeps it (account-gated). When the loaded
/// page is exhausted a new page is fetched (offset = consumed count). When a
/// page returns empty the real "You're all caught up" state is shown. Swipes
/// are recorded via [SwipeRepository] so the `discover_deck` RPC can exclude
/// already-seen posts and weight affinity over time. RIGHT swipe also fires
/// [interactionsProvider.toggleLike]. Guests fall back to the plain `feed` RPC
/// with no swipe history.
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 260))
    ..addListener(_tick)
    ..addStatusListener(_onAnimDone);

  Offset _drag = Offset.zero;
  Offset _from = Offset.zero;
  Offset _to = Offset.zero;
  bool _flinging = false; // true = card flies off (commit), false = spring back

  /// The accumulated deck (pages appended as the user swipes through).
  final List<FeedPost> _deck = [];

  /// How many cards the user has consumed (≤ _deck.length).
  int _consumed = 0;

  /// True while a next-page fetch is in flight.
  bool _fetching = false;

  /// True once a page came back empty — no more content to show.
  bool _exhausted = false;

  double _w = 400;

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  FeedPost? get _current =>
      (_consumed < _deck.length) ? _deck[_consumed] : null;

  FeedPost? get _next =>
      (_consumed + 1 < _deck.length) ? _deck[_consumed + 1] : null;

  // -------------------------------------------------------------------------
  // Initial load — populate _deck from the first discoverDeckProvider result.
  // -------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    // Populate deck as soon as the first provider result lands (see build).
  }

  void _seedDeckIfNeeded(List<FeedPost> firstPage) {
    if (_deck.isNotEmpty || firstPage.isEmpty) return;
    final blocked = ref.read(interactionsProvider).blocked;
    setState(() {
      _deck.addAll(firstPage.where((p) => !blocked.contains(p.authorId)));
      if (firstPage.isEmpty) _exhausted = true;
    });
  }

  // -------------------------------------------------------------------------
  // Paging
  // -------------------------------------------------------------------------

  Future<void> _fetchNextPage() async {
    if (_fetching || _exhausted) return;
    setState(() => _fetching = true);
    try {
      final blocked = ref.read(interactionsProvider).blocked;
      final repo = ref.read(swipeRepositoryProvider);
      final page = await repo.deck(limit: 20, offset: _consumed);
      final filtered = page.where((p) => !blocked.contains(p.authorId)).toList();
      setState(() {
        if (filtered.isEmpty) {
          _exhausted = true;
        } else {
          _deck.addAll(filtered);
        }
      });
    } catch (_) {
      // swallow — UI stays on current card; user can keep swiping
    } finally {
      if (mounted) setState(() => _fetching = false);
    }
  }

  // -------------------------------------------------------------------------
  // Animation
  // -------------------------------------------------------------------------

  void _tick() {
    setState(() {
      _drag = Offset.lerp(_from, _to, Curves.easeOut.transform(_anim.value))!;
    });
  }

  void _onAnimDone(AnimationStatus status) {
    if (status != AnimationStatus.completed || !_flinging) return;
    final liked = _to.dx > 0;
    final post = _current;
    if (post != null) {
      // Record swipe signal (fire-and-forget).
      ref.read(swipeRepositoryProvider).recordSwipe(post.id, right: liked);
      // RIGHT swipe also likes the post.
      if (liked) {
        ref.read(interactionsProvider.notifier).toggleLike(post.id);
      }
    }
    setState(() {
      _consumed++;
      _drag = Offset.zero;
    });
    // Prefetch next page when within 2 cards of the end.
    final remaining = _deck.length - _consumed;
    if (remaining <= 2 && !_exhausted) {
      _fetchNextPage();
    }
  }

  void _animateTo(Offset target, {required bool fling}) {
    _from = _drag;
    _to = target;
    _flinging = fling;
    _anim.forward(from: 0);
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_anim.isAnimating) return;
    setState(() => _drag += d.delta);
  }

  void _onPanEnd(DragEndDetails d) {
    if (_anim.isAnimating) return;
    final threshold = _w * 0.26;
    final vx = d.velocity.pixelsPerSecond.dx;
    if (_drag.dx > threshold || vx > 750) {
      _fling(like: true);
    } else if (_drag.dx < -threshold || vx < -750) {
      _fling(like: false);
    } else {
      _animateTo(Offset.zero, fling: false);
    }
  }

  void _fling({required bool like}) {
    if (_anim.isAnimating) return;
    _animateTo(Offset(like ? _w * 1.6 : -_w * 1.6, _drag.dy - 40), fling: true);
  }

  void _save() {
    final post = _current;
    if (post == null) return;
    requireAccount(context, ref,
        () => ref.read(interactionsProvider.notifier).toggleSave(post.id));
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    _w = MediaQuery.sizeOf(context).width;

    // Watch the first-page provider to seed the local deck.
    final deckAsync = ref.watch(discoverDeckProvider);
    deckAsync.whenData(_seedDeckIfNeeded);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.s20, 12, AppSpacing.s20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DISCOVER',
                    style: t.labelSmall?.copyWith(letterSpacing: 1.8)),
                const SizedBox(height: 3),
                Text('Picked for you', style: t.titleLarge),
                const SizedBox(height: 2),
                Text('Swipe right to like · left to pass',
                    style: t.bodyMedium?.copyWith(color: AppColors.ink2)),
              ],
            ),
          ),
          Expanded(
            child: _buildBody(context, deckAsync),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, AsyncValue<List<FeedPost>> deckAsync) {
    // First page is still loading and we have nothing seeded yet.
    if (deckAsync.isLoading && _deck.isEmpty) {
      return const _DiscoverLoading();
    }

    // First page errored and we have nothing.
    if (deckAsync.hasError && _deck.isEmpty) {
      return _DiscoverMessage(
        icon: Icons.cloud_off_rounded,
        title: "Couldn't load Discover",
        body: 'Check your connection and try again.',
        onRetry: () => ref.invalidate(discoverDeckProvider),
      );
    }

    final current = _current;

    // Deck truly exhausted — a page returned empty (or the seed was empty).
    if (_exhausted && current == null) {
      return const _DiscoverMessage(
        icon: Icons.style_rounded,
        title: "You're all caught up",
        body: 'No more looks to discover right now — check back soon.',
      );
    }

    // Still waiting for the next page to arrive.
    if (current == null) {
      return const _DiscoverLoading();
    }

    return _buildDeck(context, current);
  }

  /// The live swipe deck, built once the deck has at least one post.
  Widget _buildDeck(BuildContext context, FeedPost current) {
    final next = _next;
    final saved = ref.watch(interactionsProvider).saved.contains(current.id);

    final reach = _w * 0.26;
    final angle = (_drag.dx / _w) * 0.18;
    final likeOpacity = (_drag.dx / reach).clamp(0.0, 1.0);
    final passOpacity = (-_drag.dx / reach).clamp(0.0, 1.0);

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(AppSpacing.s20, 6, AppSpacing.s20, 6),
            child: Stack(
              children: [
                // Peek of the next card behind, slightly smaller.
                if (next != null)
                  Positioned.fill(
                    child: Transform.translate(
                      offset: const Offset(0, 16),
                      child: Transform.scale(
                        scale: 0.94,
                        child: _DiscoverCard(post: next),
                      ),
                    ),
                  ),
                // The live, draggable top card.
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => context.push('/outfit', extra: current),
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    child: Transform.translate(
                      offset: _drag,
                      child: Transform.rotate(
                        angle: angle,
                        child: _DiscoverCard(
                          post: current,
                          saved: saved,
                          onSave: _save,
                          likeOpacity: likeOpacity,
                          passOpacity: passOpacity,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.s20, 6, AppSpacing.s20, AppSpacing.s12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CircleAction(
                icon: Icons.close_rounded,
                onTap: () => _fling(like: false),
                fg: AppColors.ink,
                bg: AppColors.paper,
                border: true,
              ),
              const SizedBox(width: 30),
              _CircleAction(
                icon: Icons.favorite_rounded,
                onTap: () => _fling(like: true),
                fg: AppColors.onInk,
                bg: AppColors.match,
                big: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Centered spinner while the deck loads.
class _DiscoverLoading extends StatelessWidget {
  const _DiscoverLoading();
  @override
  Widget build(BuildContext context) => const Center(
        child: CircularProgressIndicator(
            color: AppColors.ink, strokeWidth: 2.5),
      );
}

/// Empty / error state for the deck — mirrors the Feed's message card.
class _DiscoverMessage extends StatelessWidget {
  const _DiscoverMessage(
      {required this.icon, required this.title, required this.body, this.onRetry});
  final IconData icon;
  final String title, body;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 40, 40, 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: AppColors.ink3),
          const SizedBox(height: 14),
          Text(title, style: t.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(body,
              style: t.bodyLarge?.copyWith(color: AppColors.ink2),
              textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 18),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(AppRadii.pill)),
                child: Text('Try again',
                    style: t.labelLarge?.copyWith(
                        color: AppColors.onInk, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One deck card. The top card passes [onSave] + stamp opacities; the peek card
/// behind omits them (no controls, no stamps).
class _DiscoverCard extends StatelessWidget {
  const _DiscoverCard({
    required this.post,
    this.saved = false,
    this.onSave,
    this.likeOpacity = 0,
    this.passOpacity = 0,
  });

  final FeedPost post;
  final bool saved;
  final VoidCallback? onSave;
  final double likeOpacity;
  final double passOpacity;

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
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: post.imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, _) => const ColoredBox(color: AppColors.sand),
              errorWidget: (_, _, _) => const ColoredBox(color: AppColors.taupe),
            ),
            // Bottom-up legibility gradient.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xCC160F08), Color(0x00160F08)],
                  stops: [0.0, 0.45],
                ),
              ),
            ),
            if (matchBandFor(post.matchPct) case final band?)
              Positioned(top: 12, left: 12, child: _MatchPill(band: band)),
            if (onSave != null)
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: onSave,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: Color(0xF2FCF8F1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      saved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      size: 19,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
            // Drag stamps.
            Positioned(
              top: 22,
              left: 18,
              child: Opacity(
                opacity: likeOpacity,
                child: const _Stamp(label: 'LIKE', color: AppColors.match),
              ),
            ),
            Positioned(
              top: 22,
              right: 18,
              child: Opacity(
                opacity: passOpacity,
                child: const _Stamp(label: 'PASS', color: Colors.white),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 18,
              child: _CardCaption(post: post),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardCaption extends StatelessWidget {
  const _CardCaption({required this.post});
  final FeedPost post;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.ring, width: 2),
              ),
              child: Text(
                post.initials,
                style: const TextStyle(
                  fontFamily: AppFonts.text,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF5B4F3C),
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                post.authorName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          post.attributeLine,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: AppFonts.text,
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 8),
        // "Why this matches" insight (SRS FR-DS.5).
        Container(
          padding: const EdgeInsets.fromLTRB(9, 5, 11, 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  size: 12, color: Colors.white),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  post.aesthetic.isEmpty
                      ? 'Similar build · matches your taste'
                      : 'Similar build · your ${post.aesthetic} taste',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppFonts.text,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MatchPill extends StatelessWidget {
  const _MatchPill({required this.band});
  final MatchBand band;

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
            margin: const EdgeInsets.only(right: 5),
            decoration: const BoxDecoration(
                color: AppColors.match, shape: BoxShape.circle),
          ),
          Text(
            band.label,
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

class _Stamp extends StatelessWidget {
  const _Stamp({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: label == 'LIKE' ? -0.22 : 0.22,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.display,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.onTap,
    required this.fg,
    required this.bg,
    this.big = false,
    this.border = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color fg;
  final Color bg;
  final bool big;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final size = big ? 64.0 : 58.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: border ? Border.all(color: AppColors.line, width: 1.5) : null,
          boxShadow: AppShadows.soft,
        ),
        child: Icon(icon, size: big ? 30 : 26, color: fg),
      ),
    );
  }
}
