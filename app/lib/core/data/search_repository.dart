import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/feed/data/feed_post.dart';
import 'profile_repository.dart' show Person;

String normalizeQuery(String q) => q.trim().toLowerCase();

class SearchRepository {
  SupabaseClient get _c => Supabase.instance.client;

  Future<List<Person>> searchPeople(String q,
      {int limit = 20, int offset = 0}) async {
    if (q.isEmpty) return const [];
    final rows = (await _c.rpc('search_people',
        params: {'q': q, 'p_limit': limit, 'p_offset': offset})) as List;
    return rows.map<Person>((r) {
      final m = (r as Map).cast<String, dynamic>();
      return (
        id: m['id'] as String,
        name: (m['display_name'] ?? m['username'] ?? 'Someone') as String,
        username: (m['username'] as String?) ?? '',
        avatar: m['avatar_url'] as String?,
      );
    }).toList();
  }

  Future<List<FeedPost>> searchLooks(String q,
      {int limit = 20, int offset = 0}) async {
    if (q.isEmpty) return const [];
    final rows = (await _c.rpc('search_looks',
        params: {'q': q, 'p_limit': limit, 'p_offset': offset})) as List;
    // search_looks returns the same shape as feed(); use local mapper.
    return rows.map<FeedPost>((r) => _mapLook(r as Map)).toList();
  }

  FeedPost _mapLook(Map raw) {
    final m = raw.cast<String, dynamic>();
    final media = (m['media'] as List?) ?? const [];
    final path = media.isNotEmpty ? media.first as String : null;
    final aes = (m['aesthetics'] as List?)?.cast<String>() ?? const [];
    final name = (m['author_name'] as String?) ?? 'Someone';
    final cm = m['height_cm'];
    final inches = cm == null ? null : ((cm as num) / 2.54).round();
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return FeedPost(
      id: m['id'] as String,
      authorId: m['author_id'] as String,
      authorName: name,
      initials: parts.isEmpty
          ? '?'
          : parts.take(2).map((p) => p[0].toUpperCase()).join(),
      aesthetic: aes.isNotEmpty ? aes.first : '',
      height: inches == null ? '' : "${inches ~/ 12}'${inches % 12}\"",
      size: '',
      matchPct: 0,
      likes: ((m['likes'] as num?)?.toInt() ?? 0).toString(),
      imageUrl: path == null
          ? ''
          : _c.storage.from('post-media').getPublicUrl(path),
    );
  }
}

final searchRepositoryProvider =
    Provider<SearchRepository>((_) => SearchRepository());

/// The active search query (set by the screen, debounced there).
final searchQueryProvider =
    NotifierProvider.autoDispose<_SearchQueryNotifier, String>(
        _SearchQueryNotifier.new);

class _SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String q) => state = q;
}

final searchPeopleProvider = FutureProvider.autoDispose<List<Person>>((ref) {
  final q = normalizeQuery(ref.watch(searchQueryProvider));
  return ref.watch(searchRepositoryProvider).searchPeople(q);
});

final searchLooksProvider =
    FutureProvider.autoDispose<List<FeedPost>>((ref) {
  final q = normalizeQuery(ref.watch(searchQueryProvider));
  return ref.watch(searchRepositoryProvider).searchLooks(q);
});
