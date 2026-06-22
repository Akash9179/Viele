import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/feed/data/feed_post.dart';

class SwipeRepository {
  SupabaseClient get _c => Supabase.instance.client;

  /// Records a swipe for the signed-in user (no-op for guests — no history).
  Future<void> recordSwipe(String postId, {required bool right}) async {
    final uid = _c.auth.currentUser?.id;
    if (uid == null) return;
    await _c.from('swipes').upsert({
      'user_id': uid, 'post_id': postId, 'direction': right ? 'right' : 'left',
    });
  }

  Future<List<FeedPost>> deck({int limit = 20, int offset = 0}) async {
    final uid = _c.auth.currentUser?.id;
    // Guests have no swipe history → fall back to the standard ranked feed.
    final rpc = uid == null ? 'feed' : 'discover_deck';
    final rows = (await _c.rpc(rpc, params: {'p_limit': limit, 'p_offset': offset})) as List;
    return rows.map<FeedPost>((r) => _map(r as Map)).toList();
  }

  FeedPost _map(Map raw) {
    final m = raw.cast<String, dynamic>();
    final media = (m['media'] as List?) ?? const [];
    final path = media.isNotEmpty ? media.first as String : null;
    final aes = (m['aesthetics'] as List?)?.cast<String>() ?? const [];
    final name = (m['author_name'] as String?) ?? 'Someone';
    final cm = m['height_cm'];
    final inches = cm == null ? null : ((cm as num) / 2.54).round();
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return FeedPost(
      id: m['id'] as String, authorId: m['author_id'] as String, authorName: name,
      initials: parts.isEmpty ? '?' : parts.take(2).map((p) => p[0].toUpperCase()).join(),
      aesthetic: aes.isNotEmpty ? aes.first : '',
      height: inches == null ? '' : "${inches ~/ 12}'${inches % 12}\"",
      size: '', matchPct: (m['match_pct'] as num?)?.toInt() ?? 0,
      likes: ((m['likes'] as num?)?.toInt() ?? 0).toString(),
      imageUrl: path == null ? '' : _c.storage.from('post-media').getPublicUrl(path),
    );
  }
}

final swipeRepositoryProvider = Provider<SwipeRepository>((_) => SwipeRepository());

final discoverDeckProvider =
    FutureProvider.autoDispose<List<FeedPost>>((ref) => ref.watch(swipeRepositoryProvider).deck());
