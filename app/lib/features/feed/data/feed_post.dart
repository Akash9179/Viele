import 'package:flutter/foundation.dart';

/// A feed item: an outfit post stamped with its author's public attributes.
/// Mirrors the read shape returned by the `feed()` RPC (see the data-architecture
/// spec) — public fields + match%, never weight.
@immutable
class FeedPost {
  const FeedPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.initials,
    required this.aesthetic,
    required this.height,
    required this.size,
    required this.matchPct,
    required this.likes,
    required this.imageUrl,
  });

  final String id;
  final String authorId; // stable user id (real UUID once wired)
  final String authorName;
  final String initials;
  final String aesthetic;
  final String height;
  final String size;
  final int matchPct;
  final String likes;
  final String imageUrl;

  /// `aesthetic · height · size` — the public attribute line shown on cards
  /// (empty parts are dropped, since real posts may not carry a size).
  String get attributeLine =>
      [aesthetic, height, size].where((s) => s.isNotEmpty).join(' · ');
}
