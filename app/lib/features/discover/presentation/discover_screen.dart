import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/state/interactions.dart';
import '../../../core/state/session.dart';
import '../../../core/theme/tokens.dart';
import '../../feed/data/feed_post.dart';
import '../../feed/data/mock_feed.dart';

/// Discover — a swipe deck of looks picked for you, one at a time. Drag right to
/// like, left to pass; the bookmark keeps it (account-gated). Endless supply by
/// looping the deck. A V2 surface (SRS §4.3, FR-DS.1/3/4) pulled forward and
/// built to the locked design system (`docs/design.md`). Frontend-only: swipes
/// toggle in-memory likes; real preference learning wires in later.
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
  int _index = 0;
  double _w = 400;

  /// Deck minus any blocked authors (FR-SG.8). Falls back to the full list if
  /// everything is blocked (keeps the mock from going empty).
  List<FeedPost> get _deck {
    final blocked = ref.read(interactionsProvider).blocked;
    final d = mockFeed.where((p) => !blocked.contains(p.authorId)).toList();
    return d.isEmpty ? mockFeed : d;
  }

  FeedPost get _current => _deck[_index % _deck.length];
  FeedPost get _next => _deck[(_index + 1) % _deck.length];

  void _tick() {
    setState(() {
      _drag = Offset.lerp(_from, _to, Curves.easeOut.transform(_anim.value))!;
    });
  }

  void _onAnimDone(AnimationStatus status) {
    if (status != AnimationStatus.completed || !_flinging) return;
    final liked = _to.dx > 0;
    if (liked) {
      ref.read(interactionsProvider.notifier).toggleLike(_current.id);
    }
    setState(() {
      _index++;
      _drag = Offset.zero;
    });
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
    requireAccount(context, ref,
        () => ref.read(interactionsProvider.notifier).toggleSave(post.id));
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    _w = MediaQuery.sizeOf(context).width;
    final saved = ref.watch(interactionsProvider).saved.contains(_current.id);

    final reach = _w * 0.26;
    final angle = (_drag.dx / _w) * 0.18;
    final likeOpacity = (_drag.dx / reach).clamp(0.0, 1.0);
    final passOpacity = (-_drag.dx / reach).clamp(0.0, 1.0);

    return SafeArea(
      child: Column(
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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s20, 6, AppSpacing.s20, 6),
              child: Stack(
                children: [
                  // Peek of the next card behind, slightly smaller.
                  Positioned.fill(
                    child: Transform.translate(
                      offset: const Offset(0, 16),
                      child: Transform.scale(
                        scale: 0.94,
                        child: _DiscoverCard(post: _next),
                      ),
                    ),
                  ),
                  // The live, draggable top card.
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () => context.push('/outfit', extra: _current),
                      onPanUpdate: _onPanUpdate,
                      onPanEnd: _onPanEnd,
                      child: Transform.translate(
                        offset: _drag,
                        child: Transform.rotate(
                          angle: angle,
                          child: _DiscoverCard(
                            post: _current,
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
            Positioned(top: 12, left: 12, child: _MatchPill(pct: post.matchPct)),
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
                  'Similar build · your ${post.aesthetic} taste',
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
  const _MatchPill({required this.pct});
  final int pct;

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
            '$pct% match',
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
