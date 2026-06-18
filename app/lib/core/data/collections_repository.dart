import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/feed/data/feed_post.dart';
import '../../features/feed/data/feed_repository.dart';
import '../state/interactions.dart';

/// Saves + named collections, backed by `collections` / `collection_items`.
/// The bookmark ("save") is membership in a per-user default collection named
/// [defaultName]; named collections are everything else. Posts in a collection
/// are resolved from `posts` (author info comes from the stamped
/// `author_snapshot`). Media uses public URLs (post-media is public in v1).
class CollectionsRepository {
  static const defaultName = 'Saved';
  SupabaseClient get _c => Supabase.instance.client;
  String? get _uid => _c.auth.currentUser?.id;

  /// Named collections (excludes the default "Saved"), with item count + cover.
  Future<List<CollectionSummary>> namedCollections() async {
    final uid = _uid;
    if (uid == null) return [];
    final rows = await _c
        .from('collections')
        .select('id,name,collection_items(post_id)')
        .eq('owner_id', uid)
        .neq('name', defaultName)
        .order('created_at');
    final out = <CollectionSummary>[];
    for (final r in rows) {
      final items = (r['collection_items'] as List?) ?? const [];
      final firstPostId = items.isNotEmpty
          ? (items.first as Map)['post_id'] as String
          : null;
      out.add(CollectionSummary(
        id: r['id'] as String,
        name: r['name'] as String,
        count: items.length,
        coverUrl: firstPostId == null ? null : await _coverFor(firstPostId),
      ));
    }
    return out;
  }

  Future<String?> _coverFor(String postId) async {
    final p = await _c
        .from('posts')
        .select('media')
        .eq('id', postId)
        .maybeSingle();
    final media = (p?['media'] as List?) ?? const [];
    if (media.isEmpty) return null;
    return _c.storage.from('post-media').getPublicUrl(media.first as String);
  }

  Future<void> createCollection(String name) async {
    final uid = _uid;
    if (uid == null || name.trim().isEmpty) return;
    await _c.from('collections').insert({'owner_id': uid, 'name': name.trim()});
  }

  /// FeedPosts for a set of post ids (used by "All saved" + collection detail).
  Future<List<FeedPost>> postsByIds(Iterable<String> ids) async {
    final list = ids.toList();
    if (list.isEmpty) return [];
    final rows = await _c
        .from('posts')
        .select('id,author_id,aesthetics,media,author_snapshot')
        .inFilter('id', list);
    return rows.map<FeedPost>((r) => feedPostFromPostRow(r, _c)).toList();
  }

  Future<List<FeedPost>> postsInCollection(String collectionId) async {
    final items = await _c
        .from('collection_items')
        .select('post_id')
        .eq('collection_id', collectionId);
    return postsByIds([for (final r in items) r['post_id'] as String]);
  }

}

class CollectionSummary {
  const CollectionSummary(
      {required this.id,
      required this.name,
      required this.count,
      required this.coverUrl});
  final String id;
  final String name;
  final int count;
  final String? coverUrl;
}

final collectionsRepositoryProvider =
    Provider<CollectionsRepository>((_) => CollectionsRepository());

/// Named collections for the Saved tab.
final namedCollectionsProvider =
    FutureProvider.autoDispose<List<CollectionSummary>>(
        (ref) => ref.watch(collectionsRepositoryProvider).namedCollections());

/// The signed-in user's saved posts (the default collection's items).
final savedPostsProvider = FutureProvider.autoDispose<List<FeedPost>>((ref) {
  final repo = ref.watch(collectionsRepositoryProvider);
  // Re-fetch when the saved set changes.
  ref.watch(interactionsProvider.select((s) => s.saved));
  return repo.postsByIds(ref.read(interactionsProvider).saved);
});

/// Posts inside a specific collection.
final collectionPostsProvider = FutureProvider.autoDispose
    .family<List<FeedPost>, String>((ref, collectionId) =>
        ref.watch(collectionsRepositoryProvider).postsInCollection(collectionId));
