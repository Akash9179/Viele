import 'package:flutter_riverpod/flutter_riverpod.dart';

/// In-memory interaction state for the demo (saves / likes / follows).
/// Persists while the app is open; resets on restart. Real persistence arrives
/// when we wire Supabase (likes/collections/follows tables).
class Interactions {
  const Interactions({
    this.saved = const {},
    this.liked = const {},
    this.following = const {},
  });

  final Set<String> saved; // post ids
  final Set<String> liked; // post ids
  final Set<String> following; // author names (mock key)

  Interactions copyWith({
    Set<String>? saved,
    Set<String>? liked,
    Set<String>? following,
  }) =>
      Interactions(
        saved: saved ?? this.saved,
        liked: liked ?? this.liked,
        following: following ?? this.following,
      );
}

class InteractionsNotifier extends Notifier<Interactions> {
  @override
  Interactions build() => const Interactions();

  Set<String> _toggle(Set<String> set, String id) {
    final next = {...set};
    next.contains(id) ? next.remove(id) : next.add(id);
    return next;
  }

  void toggleSave(String postId) =>
      state = state.copyWith(saved: _toggle(state.saved, postId));
  void toggleLike(String postId) =>
      state = state.copyWith(liked: _toggle(state.liked, postId));
  void toggleFollow(String author) =>
      state = state.copyWith(following: _toggle(state.following, author));
}

final interactionsProvider =
    NotifierProvider<InteractionsNotifier, Interactions>(InteractionsNotifier.new);
