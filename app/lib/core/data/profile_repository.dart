import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/feed/data/feed_post.dart';
import '../../features/feed/data/feed_repository.dart';
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
}

final profileRepositoryProvider =
    Provider<ProfileRepository>((_) => ProfileRepository());

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
