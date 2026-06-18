import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/collections_repository.dart';
import '../../../core/theme/tokens.dart';
import '../../feed/data/feed_post.dart';

/// A single collection's outfits (route `/collection`). `extra` =
/// `({String name, String? collectionId})`. When [collectionId] is null it
/// shows "All saved" (the default collection). Posts load from Supabase.
class CollectionDetailScreen extends ConsumerWidget {
  const CollectionDetailScreen(
      {super.key, required this.name, this.collectionId});

  final String name;
  final String? collectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final async = collectionId == null
        ? ref.watch(savedPostsProvider)
        : ref.watch(collectionPostsProvider(collectionId!));
    final count = async.asData?.value.length;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 18, color: AppColors.ink),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: t.headlineSmall?.copyWith(fontSize: 18)),
                      Text(
                          count == null
                              ? '—'
                              : '$count ${count == 1 ? "look" : "looks"}',
                          style: t.bodySmall?.copyWith(color: AppColors.ink2)),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.line),
            Expanded(
              child: async.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.ink, strokeWidth: 2.5)),
                error: (_, _) => _empty(t,
                    icon: Icons.cloud_off_rounded,
                    title: "Couldn't load this collection",
                    body: 'Check your connection and try again.'),
                data: (posts) => posts.isEmpty
                    ? _empty(t,
                        icon: Icons.bookmark_border_rounded,
                        title: 'Nothing here yet',
                        body:
                            'Save outfits into this collection to see them here.')
                    : _grid(context, posts),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _grid(BuildContext context, List<FeedPost> posts) => CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(3),
            sliver: SliverMasonryGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childCount: posts.length,
              itemBuilder: (context, i) => GestureDetector(
                onTap: () => context.push('/outfit', extra: posts[i]),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: AspectRatio(
                    aspectRatio: i.isEven ? 3 / 4 : 4 / 5,
                    child: CachedNetworkImage(
                      imageUrl: posts[i].imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => const ColoredBox(color: AppColors.sand),
                      errorWidget: (_, _, _) =>
                          const ColoredBox(color: AppColors.taupe),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );

  Widget _empty(TextTheme t,
          {required IconData icon, required String title, required String body}) =>
      Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 38, color: AppColors.ink3),
              const SizedBox(height: 12),
              Text(title, style: t.titleLarge?.copyWith(fontSize: 18)),
              const SizedBox(height: 4),
              Text(body,
                  textAlign: TextAlign.center,
                  style: t.bodyLarge?.copyWith(color: AppColors.ink2)),
            ],
          ),
        ),
      );
}
