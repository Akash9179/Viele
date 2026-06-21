import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The signed-in user's own profile, backed by the `profiles` row. Loaded on
/// launch and written on Edit Profile save. Weight is intentionally NOT here —
/// it's private/matching-only (`profiles_private`) and never displayed.
class Profile {
  const Profile({
    this.name = '',
    this.username = '',
    this.bio = '',
    this.region = '',
    this.aesthetics = '',
    this.height = '',
    this.shape = '',
    this.hair = '',
    this.eye = '',
    this.avatarUrl =
        'https://images.unsplash.com/photo-1534404483017-8743b4e935cd?w=180&h=180&fit=crop&crop=faces&q=80',
  });

  final String name;
  final String username;
  final String bio;
  final String region;
  final String aesthetics;
  final String height;
  final String shape;
  final String hair;
  final String eye;
  final String avatarUrl;

  /// Public attribute chips shown on the profile (weight never appears).
  List<String> get attributeChips => [
        if (shape.isNotEmpty) shape,
        if (height.isNotEmpty) height,
        if (hair.isNotEmpty) '$hair hair',
        if (eye.isNotEmpty) '$eye eyes',
      ];

  Profile copyWith({
    String? name,
    String? username,
    String? bio,
    String? region,
    String? aesthetics,
    String? height,
    String? shape,
    String? hair,
    String? eye,
    String? avatarUrl,
  }) =>
      Profile(
        name: name ?? this.name,
        username: username ?? this.username,
        bio: bio ?? this.bio,
        region: region ?? this.region,
        aesthetics: aesthetics ?? this.aesthetics,
        height: height ?? this.height,
        shape: shape ?? this.shape,
        hair: hair ?? this.hair,
        eye: eye ?? this.eye,
        avatarUrl: avatarUrl ?? this.avatarUrl,
      );
}

// body_silhouette DB enum <-> display label.
const _silToLabel = {
  'hourglass': 'Hourglass',
  'pear': 'Pear',
  'rectangle': 'Rectangle',
  'apple': 'Apple / Round',
  'inverted_triangle': 'Inverted Triangle',
};
final _labelToSil = {for (final e in _silToLabel.entries) e.value: e.key};

String _heightDisplay(Object? cm) {
  if (cm == null) return '';
  final inches = ((cm as num) / 2.54).round();
  return "${inches ~/ 12}'${inches % 12}\"";
}

int? _heightToCm(String h) {
  final m = RegExp(r"(\d+)'(\d+)").firstMatch(h);
  if (m == null) return null;
  return ((int.parse(m.group(1)!) * 12 + int.parse(m.group(2)!)) * 2.54).round();
}

class ProfileNotifier extends Notifier<Profile> {
  SupabaseClient get _c => Supabase.instance.client;

  @override
  Profile build() {
    _load();
    return const Profile();
  }

  Future<void> _load() async {
    final uid = _c.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final r = await _c
          .from('profiles')
          .select(
              'username,display_name,bio,region,aesthetics,height_cm,body_silhouette,hair_color,eye_color,avatar_url')
          .eq('id', uid)
          .maybeSingle();
      if (r == null) return;
      state = Profile(
        name: (r['display_name'] ?? '') as String,
        username: (r['username'] ?? '') as String,
        bio: (r['bio'] ?? '') as String,
        region: (r['region'] ?? '') as String,
        aesthetics:
            ((r['aesthetics'] as List?)?.cast<String>() ?? const []).join(' · '),
        height: _heightDisplay(r['height_cm']),
        shape: _silToLabel[r['body_silhouette']] ?? '',
        hair: (r['hair_color'] ?? '') as String,
        eye: (r['eye_color'] ?? '') as String,
        avatarUrl: (r['avatar_url'] as String?) ?? const Profile().avatarUrl,
      );
    } catch (_) {
      // keep defaults on load failure
    }
  }

  /// Persists a new avatar URL (after upload). Optimistic with revert on error.
  Future<String?> updateAvatar(String url) async {
    final prev = state;
    state = state.copyWith(avatarUrl: url);
    final uid = _c.auth.currentUser?.id;
    if (uid == null) return null;
    try {
      await _c.from('profiles').update({'avatar_url': url}).eq('id', uid);
      return null;
    } catch (_) {
      state = prev;
      return "Couldn't update your photo.";
    }
  }

  /// Persists edits to the `profiles` row. Returns null on success or a
  /// user-facing error (e.g. username taken).
  Future<String?> save(Profile p) async {
    final prev = state;
    state = p; // optimistic
    final uid = _c.auth.currentUser?.id;
    if (uid == null) return null;
    try {
      await _c.from('profiles').update({
        'display_name': p.name,
        'username': p.username,
        'bio': p.bio,
        'region': p.region,
        'aesthetics':
            p.aesthetics.split('·').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
        if (_heightToCm(p.height) != null) 'height_cm': _heightToCm(p.height),
        if (_labelToSil[p.shape] != null) 'body_silhouette': _labelToSil[p.shape],
        'hair_color': p.hair,
        'eye_color': p.eye,
      }).eq('id', uid);
      return null;
    } on PostgrestException catch (e) {
      state = prev;
      return e.code == '23505'
          ? 'That username is taken.'
          : "Couldn't save changes.";
    } catch (_) {
      state = prev;
      return "Couldn't save changes.";
    }
  }
}

final profileProvider =
    NotifierProvider<ProfileNotifier, Profile>(ProfileNotifier.new);
