import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/profile_repository.dart';
import '../../../core/state/interactions.dart';
import '../../../core/theme/tokens.dart';
import '../data/feed_repository.dart';
import 'widgets/match_card.dart';

/// The Feed / Home wedge. Layout per Eugene's mockup + `docs/design.md`:
/// header → recommended-people row → match-ranked masonry.
/// Blocked authors are filtered out (FR-SG.8).
/// Uses [pagedFeedProvider] for infinite-scroll pagination.
class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 600) {
      ref.read(pagedFeedProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final blocked = ref.watch(interactionsProvider).blocked;
    final feedAsync = ref.watch(pagedFeedProvider);
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppColors.ink,
        onRefresh: () => ref.read(pagedFeedProvider.notifier).refresh(),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(child: _AppHeader()),
            const SliverToBoxAdapter(child: _RecommendedRow()),
            const SliverToBoxAdapter(child: _CuratedHeader()),
            ...feedAsync.when(
              loading: () => const [SliverToBoxAdapter(child: _FeedLoading())],
              error: (e, _) => [
                SliverToBoxAdapter(
                    child: _FeedMessage(
                  icon: Icons.cloud_off_rounded,
                  title: "Couldn't load your feed",
                  body: 'Check your connection and try again.',
                  onRetry: () => ref.invalidate(pagedFeedProvider),
                )),
              ],
              data: (paged) {
                final posts = paged.posts
                    .where((p) => !blocked.contains(p.authorId))
                    .toList();
                if (posts.isEmpty) {
                  return const [
                    SliverToBoxAdapter(
                        child: _FeedMessage(
                      icon: Icons.checkroom_rounded,
                      title: 'No looks yet',
                      body:
                          'Be the first to post a look — tap ＋ to share your outfit.',
                    )),
                  ];
                }
                return [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.s20,
                        AppSpacing.s12, AppSpacing.s20, AppSpacing.s24),
                    sliver: SliverMasonryGrid.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 13,
                      crossAxisSpacing: 13,
                      childCount: posts.length,
                      itemBuilder: (context, i) => MatchCard(post: posts[i]),
                    ),
                  ),
                  if (paged.loading)
                    const SliverToBoxAdapter(child: _BottomSpinner()),
                ];
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomSpinner extends StatelessWidget {
  const _BottomSpinner();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
            child: CircularProgressIndicator(
                color: AppColors.ink, strokeWidth: 2)),
      );
}

class _FeedLoading extends StatelessWidget {
  const _FeedLoading();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.only(top: 80),
        child: Center(
            child: CircularProgressIndicator(color: AppColors.ink, strokeWidth: 2.5)),
      );
}

class _FeedMessage extends StatelessWidget {
  const _FeedMessage(
      {required this.icon, required this.title, required this.body, this.onRetry});
  final IconData icon;
  final String title, body;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 70, 40, 0),
      child: Column(
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

class _AppHeader extends StatelessWidget {
  const _AppHeader();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s20, 10, AppSpacing.s20, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text('Viele',
                style: t.displayLarge?.copyWith(fontSize: 32)),
          ),
          _CircleIcon(
              icon: Icons.search_rounded,
              onTap: () => context.push('/search')),
        ],
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.paper,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.line),
        ),
        child: Icon(icon, size: 18, color: AppColors.ink),
      ),
    );
  }
}

class _RecommendedRow extends ConsumerWidget {
  const _RecommendedRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final people = ref.watch(recommendedPeopleProvider).asData?.value
        ?? const <RecommendedPerson>[];
    // Until real recommendations arrive (or if there are none), show nothing —
    // never a fake or empty row.
    if (people.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.s20, 14, AppSpacing.s20, 0),
          child: Text('RECOMMENDED',
              style: t.labelSmall?.copyWith(letterSpacing: 2.2)),
        ),
        // Intrinsic-height horizontal row (sizes to content — no fixed height,
        // so no overflow and no wasted vertical space before the next section).
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(AppSpacing.s20, 10, AppSpacing.s20, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < people.length; i++) ...[
                if (i > 0) const SizedBox(width: 15),
                GestureDetector(
                  onTap: () => context.push('/user', extra: (
                    id: people[i].id,
                    name: people[i].name,
                    avatar: people[i].avatar ?? '',
                    pct: people[i].matchPct,
                  )),
                  child: SizedBox(
                    width: 60,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          padding: const EdgeInsets.all(2.5),
                          decoration: const BoxDecoration(
                            color: AppColors.ring,
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: people[i].avatar == null
                                ? _PersonInitials(name: people[i].name)
                                : CachedNetworkImage(
                                    imageUrl: people[i].avatar!,
                                    fit: BoxFit.cover,
                                    placeholder: (_, _) =>
                                        const ColoredBox(color: AppColors.sand),
                                    errorWidget: (_, _, _) =>
                                        _PersonInitials(name: people[i].name),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(people[i].name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.bodyMedium?.copyWith(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Initials circle for a recommended person with no avatar set.
class _PersonInitials extends StatelessWidget {
  const _PersonInitials({required this.name});
  final String name;
  @override
  Widget build(BuildContext context) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final initials = parts.isEmpty
        ? '?'
        : parts.take(2).map((p) => p[0].toUpperCase()).join();
    return Container(
      color: AppColors.sand,
      alignment: Alignment.center,
      child: Text(initials,
          style: const TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 18,
              color: AppColors.ink2)),
    );
  }
}

class _CuratedHeader extends StatelessWidget {
  const _CuratedHeader();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s20, 14, AppSpacing.s20, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Outfits on people like you', style: t.titleLarge),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(right: 6),
                decoration: const BoxDecoration(
                    color: AppColors.match, shape: BoxShape.circle),
              ),
              Text('Ranked by how well they match you',
                  style: t.bodyMedium?.copyWith(color: AppColors.ink2)),
            ],
          ),
        ],
      ),
    );
  }
}
