import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'feed_post.dart';

/// Reads the personalized feed from the `feed()` RPC (public+active posts the
/// caller can see, ranked by attribute match%). Maps rows → [FeedPost] and
/// resolves media to public URLs (the `post-media` bucket is public in v1).
class FeedRepository {
  SupabaseClient get _c => Supabase.instance.client;

  Future<List<FeedPost>> fetch() async {
    final rows = (await _c.rpc('feed')) as List;
    return rows.map((r) {
      final m = r as Map<String, dynamic>;
      final media = (m['media'] as List?) ?? const [];
      final path = media.isNotEmpty ? media.first as String : null;
      final aesthetics = (m['aesthetics'] as List?)?.cast<String>() ?? const [];
      final name = (m['author_name'] as String?) ?? 'Someone';
      return FeedPost(
        id: m['id'] as String,
        authorId: m['author_id'] as String,
        authorName: name,
        initials: _initials(name),
        aesthetic: aesthetics.isNotEmpty ? aesthetics.first : '',
        height: _heightDisplay(m['height_cm']),
        size: '',
        matchPct: (m['match_pct'] as num?)?.toInt() ?? 0,
        likes: _likes(m['likes']),
        imageUrl:
            path == null ? '' : _c.storage.from('post-media').getPublicUrl(path),
      );
    }).toList();
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  static String _heightDisplay(Object? cm) {
    if (cm == null) return '';
    final inches = ((cm as num) / 2.54).round();
    return "${inches ~/ 12}'${inches % 12}\"";
  }

  static String _likes(Object? n) {
    final v = (n as num?)?.toInt() ?? 0;
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return '$v';
  }
}

/// Map a raw `posts` row (id, author_id, aesthetics, media, author_snapshot) →
/// [FeedPost]. Used by profile/collections grids (which don't show match%/likes).
FeedPost feedPostFromPostRow(dynamic row, SupabaseClient c) {
  final m = row as Map<String, dynamic>;
  final snap = (m['author_snapshot'] as Map?) ?? const {};
  final media = (m['media'] as List?) ?? const [];
  final path = media.isNotEmpty ? media.first as String : null;
  final aes = (m['aesthetics'] as List?)?.cast<String>() ?? const [];
  final name = (snap['display_name'] ?? snap['username'] ?? 'Someone') as String;
  final cm = snap['height_cm'];
  final inches = cm == null ? null : ((cm as num) / 2.54).round();
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  return FeedPost(
    id: m['id'] as String,
    authorId: m['author_id'] as String,
    authorName: name,
    initials:
        parts.isEmpty ? '?' : parts.take(2).map((p) => p[0].toUpperCase()).join(),
    aesthetic: aes.isNotEmpty ? aes.first : '',
    height: inches == null ? '' : "${inches ~/ 12}'${inches % 12}\"",
    size: '',
    matchPct: 0,
    likes: '',
    imageUrl: path == null ? '' : c.storage.from('post-media').getPublicUrl(path),
  );
}

/// A shoppable item tagged on a post.
typedef ShopItem = ({String name, String brand});

/// Full detail for a single post not carried in the lean feed payload —
/// caption, all tagged aesthetics, and shoppable items. Read directly from the
/// `posts` row (RLS already gates to public+active posts the caller can see).
typedef PostDetail = ({
  String caption,
  List<String> aesthetics,
  List<ShopItem> items,
});

final postDetailProvider =
    FutureProvider.autoDispose.family<PostDetail, String>((ref, postId) async {
  final c = Supabase.instance.client;
  final r = await c
      .from('posts')
      .select('caption, aesthetics, items')
      .eq('id', postId)
      .maybeSingle();
  if (r == null) {
    return (caption: '', aesthetics: const <String>[], items: const <ShopItem>[]);
  }
  final items = ((r['items'] as List?) ?? const [])
      .map<ShopItem>((e) {
        final m = (e as Map).cast<String, dynamic>();
        return (
          name: (m['name'] ?? '') as String,
          brand: (m['brand'] ?? '') as String,
        );
      })
      .where((it) => it.name.isNotEmpty)
      .toList();
  return (
    caption: (r['caption'] ?? '') as String,
    aesthetics: (r['aesthetics'] as List?)?.cast<String>() ?? const <String>[],
    items: items,
  );
});

final feedRepositoryProvider = Provider<FeedRepository>((_) => FeedRepository());

/// The feed list. Auto-disposes; invalidate to refresh (pull-to-refresh / after
/// posting).
final feedProvider = FutureProvider.autoDispose<List<FeedPost>>(
    (ref) => ref.watch(feedRepositoryProvider).fetch());
