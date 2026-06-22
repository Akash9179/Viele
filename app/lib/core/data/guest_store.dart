import 'package:shared_preferences/shared_preferences.dart';

/// On-device persistence of a guest's interactions so they survive relaunch.
/// Migrated to the server (and cleared) when the guest creates an account.
class GuestStore {
  static const _kLiked = 'guest_liked';
  static const _kSaved = 'guest_saved';
  static const _kFollowing = 'guest_following';

  Future<({Set<String> liked, Set<String> saved, Set<String> following})> load() async {
    final p = await SharedPreferences.getInstance();
    return (
      liked: (p.getStringList(_kLiked) ?? const []).toSet(),
      saved: (p.getStringList(_kSaved) ?? const []).toSet(),
      following: (p.getStringList(_kFollowing) ?? const []).toSet(),
    );
  }

  Future<void> setLiked(Set<String> v) async =>
      (await SharedPreferences.getInstance()).setStringList(_kLiked, v.toList());
  Future<void> setSaved(Set<String> v) async =>
      (await SharedPreferences.getInstance()).setStringList(_kSaved, v.toList());
  Future<void> setFollowing(Set<String> v) async =>
      (await SharedPreferences.getInstance()).setStringList(_kFollowing, v.toList());

  Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kLiked);
    await p.remove(_kSaved);
    await p.remove(_kFollowing);
  }
}
