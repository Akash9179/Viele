import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/guest_store.dart';

/// Interaction state (saves / likes / follows / blocks). Likes, follows and
/// blocks persist to Supabase for signed-in users (loaded on launch; optimistic
/// writes with revert-on-error). Guests get in-memory-only behaviour (the funnel
/// nudges them to sign up at save/post). Saves are still in-memory pending the
/// collections wiring.
class Interactions {
  const Interactions({
    this.saved = const {},
    this.liked = const {},
    this.following = const {},
    this.blocked = const {},
  });

  final Set<String> saved; // post ids
  final Set<String> liked; // post ids
  final Set<String> following; // author ids
  final Set<String> blocked; // author ids — their content is hidden

  Interactions copyWith({
    Set<String>? saved,
    Set<String>? liked,
    Set<String>? following,
    Set<String>? blocked,
  }) =>
      Interactions(
        saved: saved ?? this.saved,
        liked: liked ?? this.liked,
        following: following ?? this.following,
        blocked: blocked ?? this.blocked,
      );
}

class InteractionsNotifier extends Notifier<Interactions> {
  SupabaseClient get _c => Supabase.instance.client;
  String? get _uid => _c.auth.currentUser?.id;
  String? _defaultCol; // cached id of the default "Saved" collection
  final _guest = GuestStore();

  @override
  Interactions build() {
    _load(); // fire-and-forget; updates state when it returns
    return const Interactions();
  }

  /// Get-or-create the user's default "Saved" collection (bookmarks live here).
  Future<String?> _ensureDefaultCol(String uid) async {
    if (_defaultCol != null) return _defaultCol;
    final existing = await _c
        .from('collections')
        .select('id')
        .eq('owner_id', uid)
        .eq('name', 'Saved')
        .maybeSingle();
    _defaultCol = existing != null
        ? existing['id'] as String
        : (await _c
            .from('collections')
            .insert({'owner_id': uid, 'name': 'Saved'})
            .select('id')
            .single())['id'] as String;
    return _defaultCol;
  }

  Future<void> _load() async {
    final uid = _uid;
    if (uid == null) {
      try {
        final g = await _guest.load();
        state = state.copyWith(
          liked: g.liked,
          saved: g.saved,
          following: g.following,
        );
      } catch (_) {
        // leave in-memory state as-is on a load failure
      }
      return;
    }
    try {
      final likes = await _c.from('likes').select('post_id').eq('user_id', uid);
      final follows =
          await _c.from('follows').select('followee_id').eq('follower_id', uid);
      final blocks =
          await _c.from('blocks').select('blocked_id').eq('blocker_id', uid);
      final cid = await _ensureDefaultCol(uid);
      final saves = await _c
          .from('collection_items')
          .select('post_id')
          .eq('collection_id', cid!);
      state = state.copyWith(
        saved: {for (final r in saves) r['post_id'] as String},
        liked: {for (final r in likes) r['post_id'] as String},
        following: {for (final r in follows) r['followee_id'] as String},
        blocked: {for (final r in blocks) r['blocked_id'] as String},
      );
    } catch (_) {
      // leave in-memory state as-is on a load failure
    }
  }

  Set<String> _toggle(Set<String> set, String id) {
    final next = {...set};
    next.contains(id) ? next.remove(id) : next.add(id);
    return next;
  }

  Future<void> toggleSave(String postId) async {
    final had = state.saved.contains(postId);
    state = state.copyWith(saved: _toggle(state.saved, postId)); // optimistic
    final uid = _uid;
    if (uid == null) {
      // guest: persist to device so saves survive relaunch
      await _guest.setSaved(state.saved);
      return;
    }
    try {
      final cid = await _ensureDefaultCol(uid);
      if (had) {
        await _c
            .from('collection_items')
            .delete()
            .match({'collection_id': cid!, 'post_id': postId});
      } else {
        await _c
            .from('collection_items')
            .insert({'collection_id': cid!, 'post_id': postId});
      }
    } catch (_) {
      state = state.copyWith(saved: _toggle(state.saved, postId)); // revert
    }
  }

  Future<void> toggleLike(String postId) async {
    final had = state.liked.contains(postId);
    state = state.copyWith(liked: _toggle(state.liked, postId)); // optimistic
    final uid = _uid;
    if (uid == null) {
      // guest: persist to device so likes survive relaunch
      await _guest.setLiked(state.liked);
      return;
    }
    try {
      if (had) {
        await _c.from('likes').delete().match({'user_id': uid, 'post_id': postId});
      } else {
        await _c.from('likes').insert({'user_id': uid, 'post_id': postId});
      }
    } catch (_) {
      state = state.copyWith(liked: _toggle(state.liked, postId)); // revert
    }
  }

  Future<void> toggleFollow(String authorId) async {
    final had = state.following.contains(authorId);
    state = state.copyWith(following: _toggle(state.following, authorId));
    final uid = _uid;
    if (uid == null) {
      // guest: persist to device so follows survive relaunch
      await _guest.setFollowing(state.following);
      return;
    }
    try {
      if (had) {
        await _c
            .from('follows')
            .delete()
            .match({'follower_id': uid, 'followee_id': authorId});
      } else {
        await _c
            .from('follows')
            .insert({'follower_id': uid, 'followee_id': authorId});
      }
    } catch (_) {
      state = state.copyWith(following: _toggle(state.following, authorId));
    }
  }

  Future<void> block(String authorId) async {
    if (state.blocked.contains(authorId)) return;
    state = state.copyWith(blocked: {...state.blocked, authorId});
    final uid = _uid;
    if (uid == null) return;
    try {
      await _c.from('blocks').insert({'blocker_id': uid, 'blocked_id': authorId});
    } catch (_) {
      state = state.copyWith(blocked: {...state.blocked}..remove(authorId));
    }
  }

  Future<void> unblock(String authorId) async {
    if (!state.blocked.contains(authorId)) return;
    state = state.copyWith(blocked: {...state.blocked}..remove(authorId));
    final uid = _uid;
    if (uid == null) return;
    try {
      await _c
          .from('blocks')
          .delete()
          .match({'blocker_id': uid, 'blocked_id': authorId});
    } catch (_) {
      state = state.copyWith(blocked: {...state.blocked, authorId});
    }
  }
}

final interactionsProvider =
    NotifierProvider<InteractionsNotifier, Interactions>(InteractionsNotifier.new);
