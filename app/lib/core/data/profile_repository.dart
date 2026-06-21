import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/feed/data/feed_post.dart';
import '../../features/feed/data/feed_repository.dart';
import '../state/interactions.dart';
import '../state/onboarding_draft.dart';

/// Reads/writes the signed-in user's profile against Supabase. Slice-2 scope:
/// create the profile from the teaser draft + signup details. Weight goes to the
/// owner-only `profiles_private` (never the public `profiles`).
class ProfileRepository {
  SupabaseClient get _c => Supabase.instance.client;

  /// True if a `profiles` row already exists for the signed-in user (e.g. an
  /// existing user signed in rather than signing up).
  Future<bool> currentUserHasProfile() async {
    final uid = _c.auth.currentUser?.id;
    if (uid == null) return false;
    final row =
        await _c.from('profiles').select('id').eq('id', uid).maybeSingle();
    return row != null;
  }

  /// Create the profile from the teaser [draft] + signup fields. Throws a
  /// [PostgrestException] (code 23505) if the username is taken.
  Future<void> createFromDraft({
    required OnboardingDraft draft,
    required String username,
    required String displayName,
    String? region,
    required String hairColor,
    required String eyeColor,
  }) async {
    final uid = _c.auth.currentUser!.id;
    await _c.from('profiles').insert({
      'id': uid,
      'username': username,
      'display_name': displayName,
      if (region != null && region.isNotEmpty) 'region': region,
      'hair_color': hairColor,
      'eye_color': eyeColor,
      ...draft.publicProfileFields(),
    });
    await _c.from('profiles_private').upsert({
      'profile_id': uid,
      'weight_kg': draft.weightKg,
    });
  }

  /// Uploads [filePath] as the signed-in user's avatar (upserted to
  /// avatars/{uid}/avatar.jpg) and returns a cache-busted public URL.
  Future<String> uploadAvatar(String filePath) async {
    final uid = _c.auth.currentUser!.id;
    final bytes = await File(filePath).readAsBytes();
    final objectPath = '$uid/avatar.jpg';
    // Replace, don't upsert: Storage rejects upsert uploads under owner-prefixed
    // RLS, so delete the old object first (no-op if absent), then insert.
    try {
      await _c.storage.from('avatars').remove([objectPath]);
    } catch (_) {/* nothing to remove */}
    await _c.storage.from('avatars').uploadBinary(
          objectPath,
          bytes,
          fileOptions: const FileOptions(upsert: false, contentType: 'image/jpeg'),
        );
    final base = _c.storage.from('avatars').getPublicUrl(objectPath);
    // Bust CachedNetworkImage's URL-keyed cache so the new photo shows at once.
    return '$base?u=${DateTime.now().millisecondsSinceEpoch}';
  }
}

final profileRepositoryProvider =
    Provider<ProfileRepository>((_) => ProfileRepository());

/// A person in the people directory (Search). Public profile fields only —
/// never weight. [avatar] may be null (no avatar set yet → initials fallback).
typedef Person = ({String id, String name, String username, String? avatar});

/// People to discover / search — public profiles, excluding the signed-in user.
/// The `profiles_select` RLS policy already hides anyone who has blocked the
/// caller; the client also drops locally-blocked authors at render time.
final peopleProvider = FutureProvider.autoDispose<List<Person>>((ref) async {
  final c = Supabase.instance.client;
  final uid = c.auth.currentUser?.id;
  final rows = await c
      .from('profiles')
      .select('id, username, display_name, avatar_url')
      .order('created_at', ascending: false)
      .limit(50);
  return rows
      .where((r) => r['id'] != uid)
      .map<Person>((r) => (
            id: r['id'] as String,
            name: (r['display_name'] ?? r['username'] ?? 'Someone') as String,
            username: (r['username'] as String?) ?? '',
            avatar: r['avatar_url'] as String?,
          ))
      .toList();
});

/// The signed-in user's own posts (newest first).
final myPostsProvider = FutureProvider.autoDispose<List<FeedPost>>((ref) async {
  final c = Supabase.instance.client;
  final uid = c.auth.currentUser?.id;
  if (uid == null) return [];
  final rows = await c
      .from('posts')
      .select('id,author_id,aesthetics,media,author_snapshot')
      .eq('author_id', uid)
      .eq('status', 'active')
      .order('created_at', ascending: false);
  return rows.map<FeedPost>((r) => feedPostFromPostRow(r, c)).toList();
});

/// Follower / following counts for the signed-in user.
final followCountsProvider =
    FutureProvider.autoDispose<({int followers, int following})>((ref) async {
  final c = Supabase.instance.client;
  final uid = c.auth.currentUser?.id;
  if (uid == null) return (followers: 0, following: 0);
  final followers =
      await c.from('follows').select('follower_id').eq('followee_id', uid);
  final following =
      await c.from('follows').select('followee_id').eq('follower_id', uid);
  return (
    followers: (followers as List).length,
    following: (following as List).length
  );
});

// body_silhouette DB enum -> display label (mirrors core/state/profile.dart).
const _silToLabel = {
  'hourglass': 'Hourglass',
  'pear': 'Pear',
  'rectangle': 'Rectangle',
  'apple': 'Apple / Round',
  'inverted_triangle': 'Inverted Triangle',
};

String _heightDisplay(Object? cm) {
  if (cm == null) return '';
  final inches = ((cm as num) / 2.54).round();
  return "${inches ~/ 12}'${inches % 12}\"";
}

/// Another user's public profile bundle — public fields only (never weight),
/// real follower/following/post counts, and the chips shown under their name.
typedef OtherProfile = ({
  String name,
  String username,
  String bio,
  String aesthetics, // ' · '-joined; '' if none
  List<String> chips,
  String? avatar,
  int posts,
  int followers,
  int following,
});

/// Public profile for [userId]. The `profiles_select` RLS policy hides anyone
/// who has blocked the caller (returns null → caller shows a not-found state).
final otherProfileProvider =
    FutureProvider.autoDispose.family<OtherProfile?, String>((ref, userId) async {
  final c = Supabase.instance.client;
  final r = await c
      .from('profiles')
      .select(
          'username,display_name,bio,aesthetics,height_cm,body_silhouette,hair_color,eye_color,avatar_url')
      .eq('id', userId)
      .maybeSingle();
  if (r == null) return null;

  final postRows = await c
      .from('posts')
      .select('id')
      .eq('author_id', userId)
      .eq('status', 'active');
  final followers =
      await c.from('follows').select('follower_id').eq('followee_id', userId);
  final following =
      await c.from('follows').select('followee_id').eq('follower_id', userId);

  final shape = _silToLabel[r['body_silhouette']] ?? '';
  final height = _heightDisplay(r['height_cm']);
  final hair = (r['hair_color'] ?? '') as String;
  final eye = (r['eye_color'] ?? '') as String;

  return (
    name: (r['display_name'] ?? r['username'] ?? 'Someone') as String,
    username: (r['username'] as String?) ?? '',
    bio: (r['bio'] ?? '') as String,
    aesthetics:
        ((r['aesthetics'] as List?)?.cast<String>() ?? const []).join(' · '),
    chips: [
      if (shape.isNotEmpty) shape,
      if (height.isNotEmpty) height,
      if (hair.isNotEmpty) '$hair hair',
      if (eye.isNotEmpty) '$eye eyes',
    ],
    avatar: r['avatar_url'] as String?,
    posts: (postRows as List).length,
    followers: (followers as List).length,
    following: (following as List).length,
  );
});

Future<List<Person>> _peopleByIds(SupabaseClient c, List<String> ids) async {
  if (ids.isEmpty) return const [];
  final rows = await c
      .from('profiles')
      .select('id, username, display_name, avatar_url')
      .inFilter('id', ids);
  return rows
      .map<Person>((r) => (
            id: r['id'] as String,
            name: (r['display_name'] ?? r['username'] ?? 'Someone') as String,
            username: (r['username'] as String?) ?? '',
            avatar: r['avatar_url'] as String?,
          ))
      .toList();
}

/// A recommended person ("people like you") with their similarity match%.
typedef RecommendedPerson = ({
  String id,
  String name,
  String username,
  String? avatar,
  int matchPct,
});

/// "People like you" — real profiles ranked by Gower similarity to the caller
/// (`recommend_people` RPC). Powers the Feed RECOMMENDED row and Catwalk.
final recommendedPeopleProvider =
    FutureProvider.autoDispose<List<RecommendedPerson>>((ref) async {
  final c = Supabase.instance.client;
  final rows = (await c.rpc('recommend_people')) as List;
  return rows.map<RecommendedPerson>((r) {
    final m = (r as Map).cast<String, dynamic>();
    final name = (m['display_name'] ?? m['username'] ?? 'Someone') as String;
    return (
      id: m['id'] as String,
      name: name,
      username: (m['username'] as String?) ?? '',
      avatar: m['avatar_url'] as String?,
      matchPct: (m['match_pct'] as num?)?.toInt() ?? 0,
    );
  }).toList();
});

/// The signed-in user's blocked accounts, resolved to real profiles (name +
/// avatar) for the Settings → Blocked accounts list.
final blockedPeopleProvider =
    FutureProvider.autoDispose<List<Person>>((ref) async {
  final ids = ref.watch(interactionsProvider).blocked.toList();
  return _peopleByIds(Supabase.instance.client, ids);
});

/// People who follow [userId].
final followersProvider =
    FutureProvider.autoDispose.family<List<Person>, String>((ref, userId) async {
  final c = Supabase.instance.client;
  final rows =
      await c.from('follows').select('follower_id').eq('followee_id', userId);
  final ids = (rows as List).map((r) => r['follower_id'] as String).toList();
  return _peopleByIds(c, ids);
});

/// People [userId] follows.
final followingProvider =
    FutureProvider.autoDispose.family<List<Person>, String>((ref, userId) async {
  final c = Supabase.instance.client;
  final rows =
      await c.from('follows').select('followee_id').eq('follower_id', userId);
  final ids = (rows as List).map((r) => r['followee_id'] as String).toList();
  return _peopleByIds(c, ids);
});

/// Public posts authored by [userId] (newest first) for their profile grid.
final userPostsProvider =
    FutureProvider.autoDispose.family<List<FeedPost>, String>((ref, userId) async {
  final c = Supabase.instance.client;
  final rows = await c
      .from('posts')
      .select('id,author_id,aesthetics,media,author_snapshot')
      .eq('author_id', userId)
      .eq('status', 'active')
      .order('created_at', ascending: false);
  return rows.map<FeedPost>((r) => feedPostFromPostRow(r, c)).toList();
});
