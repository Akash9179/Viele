import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../../core/theme/tokens.dart';
import '../data/mock_feed.dart';
import 'widgets/match_card.dart';

/// The Feed / Home wedge. Layout per Eugene's mockup + `docs/design.md`:
/// header → filter chips → recommended-people row → curated masonry.
class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: _AppHeader()),
          const SliverToBoxAdapter(child: _FilterChips()),
          const SliverToBoxAdapter(child: _RecommendedRow()),
          const SliverToBoxAdapter(child: _CuratedHeader()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.s20, AppSpacing.s12, AppSpacing.s20, AppSpacing.s24),
            sliver: SliverMasonryGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 13,
              crossAxisSpacing: 13,
              childCount: mockFeed.length,
              itemBuilder: (context, i) => MatchCard(post: mockFeed[i]),
            ),
          ),
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
          const _CircleIcon(icon: Icons.search_rounded),
          const SizedBox(width: 10),
          const _CircleIcon(icon: Icons.notifications_none_rounded, dot: true),
        ],
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({required this.icon, this.dot = false});
  final IconData icon;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.paper,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.line),
          ),
          child: Icon(icon, size: 18, color: AppColors.ink),
        ),
        if (dot)
          Positioned(
            top: 9,
            right: 10,
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: AppColors.match,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.paper, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}

class _FilterChips extends StatefulWidget {
  const _FilterChips();
  @override
  State<_FilterChips> createState() => _FilterChipsState();
}

class _FilterChipsState extends State<_FilterChips> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(AppSpacing.s20, 12, AppSpacing.s20, 4),
        itemCount: feedChips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 9),
        itemBuilder: (context, i) {
          final on = i == _selected;
          return GestureDetector(
            onTap: () => setState(() => _selected = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 9),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on ? AppColors.ink : AppColors.paper,
                borderRadius: BorderRadius.circular(AppRadii.pill),
                border: Border.all(color: on ? AppColors.ink : AppColors.line),
              ),
              child: Text(
                feedChips[i],
                style: TextStyle(
                  fontFamily: AppFonts.text,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: on ? AppColors.onInk : AppColors.ink2,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RecommendedRow extends StatelessWidget {
  const _RecommendedRow();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.s20, 14, AppSpacing.s20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('RECOMMENDED',
                  style: t.labelSmall?.copyWith(letterSpacing: 2.2)),
              Text('See all',
                  style: t.bodyMedium?.copyWith(color: AppColors.ink3)),
            ],
          ),
        ),
        // Intrinsic-height horizontal row (sizes to content — no fixed height,
        // so no overflow and no wasted vertical space before the next section).
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(AppSpacing.s20, 10, AppSpacing.s20, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < mockRecommended.length; i++) ...[
                if (i > 0) const SizedBox(width: 15),
                SizedBox(
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
                          child: CachedNetworkImage(
                            imageUrl: mockRecommended[i].avatar,
                            fit: BoxFit.cover,
                            placeholder: (_, _) =>
                                const ColoredBox(color: AppColors.sand),
                          ),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(mockRecommended[i].name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.bodyMedium?.copyWith(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w600)),
                    ],
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
              Text('94% average match',
                  style: t.bodyMedium?.copyWith(color: AppColors.ink2)),
            ],
          ),
        ],
      ),
    );
  }
}
