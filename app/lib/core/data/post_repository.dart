import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Creates posts: uploads media to the private `post-media` bucket under the
/// owner-prefixed path the RLS policy requires (`posts/{uid}/{postId}/{n}` →
/// `foldername[2] = auth.uid()`), then inserts `posts` (+ `posts_private` weight
/// band). Stamps the author's public attributes into `author_snapshot` at
/// publish time. Weight stays private (only a coarse band is stored, server-side
/// table with no client SELECT policy).
class PostRepository {
  SupabaseClient get _c => Supabase.instance.client;

  Future<void> publish({
    required List<String> imagePaths,
    required String caption,
    required List<String> aesthetics,
    required List<Map<String, String>> items,
  }) async {
    final uid = _c.auth.currentUser!.id;
    final postId = const Uuid().v4();

    // Author public snapshot (shown with the post; feeds matching later).
    final snapshot = await _c
        .from('profiles')
        .select(
            'username,display_name,avatar_url,body_silhouette,height_cm,skin_tone,undertone,hair_color,eye_color,aesthetics')
        .eq('id', uid)
        .single();
    final priv = await _c
        .from('profiles_private')
        .select('weight_kg')
        .eq('profile_id', uid)
        .maybeSingle();

    final media = <String>[];
    for (var i = 0; i < imagePaths.length; i++) {
      final objectName = 'posts/$uid/$postId/$i.jpg';
      await _c.storage.from('post-media').upload(
            objectName,
            File(imagePaths[i]),
            fileOptions:
                const FileOptions(contentType: 'image/jpeg', upsert: true),
          );
      media.add(objectName);
    }

    await _c.from('posts').insert({
      'id': postId,
      'author_id': uid,
      'caption': caption,
      'aesthetics': aesthetics,
      'items': items,
      'media': media,
      'visibility': 'public',
      'author_snapshot': snapshot,
    });

    final kg = priv?['weight_kg'] as num?;
    await _c.from('posts_private').insert({
      'post_id': postId,
      if (kg != null) 'author_weight_band': (kg / 5).floor(),
    });
  }
}

final postRepositoryProvider = Provider<PostRepository>((_) => PostRepository());
