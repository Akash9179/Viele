import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/state/interactions.dart';
import '../../../core/theme/tokens.dart';
import '../../feed/data/mock_feed.dart';

/// Followers / Following lists (route `/connections`). Opened by tapping the
/// stats on the profile; `extra` = initial tab (0 followers, 1 following).
/// Frontend mock: people derived from the feed authors; Follow toggles the
/// shared interactions state.
class ConnectionsScreen extends ConsumerStatefulWidget {
  const ConnectionsScreen({super.key, this.handle = '@mayachen', this.initialTab = 0});

  final String handle;
  final int initialTab;

  @override
  ConsumerState<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends ConsumerState<ConnectionsScreen> {
  late int _tab = widget.initialTab;

  // Mock people from the feed authors (deduped by id).
  late final List<({String id, String name, String avatar})> _followers =
      _people();
  late final List<({String id, String name, String avatar})> _following =
      _people().reversed.toList();

  List<({String id, String name, String avatar})> _people() {
    final seen = <String>{};
    final out = <({String id, String name, String avatar})>[];
    for (final p in mockFeed) {
      if (seen.add(p.authorId)) {
        out.add((id: p.authorId, name: p.authorName, avatar: p.imageUrl));
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final people = _tab == 0 ? _followers : _following;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 18, color: AppColors.ink),
                    ),
                  ),
                  Text(widget.handle,
                      style: t.headlineSmall?.copyWith(fontSize: 17)),
                ],
              ),
            ),
            // Tabs
            Row(
              children: [
                _tabBtn('Followers · ${_followers.length}', 0),
                _tabBtn('Following · ${_following.length}', 1),
              ],
            ),
            const Divider(height: 1, color: AppColors.line),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                itemCount: people.length,
                itemBuilder: (context, i) => _PersonRow(
                    id: people[i].id,
                    name: people[i].name,
                    avatar: people[i].avatar),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabBtn(String label, int i) {
    final t = Theme.of(context).textTheme;
    final on = _tab == i;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _tab = i),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(
                    color: on ? AppColors.ink : Colors.transparent, width: 2)),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: t.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: on ? AppColors.ink : AppColors.ink3)),
        ),
      ),
    );
  }
}

class _PersonRow extends ConsumerWidget {
  const _PersonRow({required this.id, required this.name, required this.avatar});
  final String id, name, avatar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final following = ref.watch(interactionsProvider).following.contains(id);
    final handle = '@${name.toLowerCase().replaceAll(' ', '')}';
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/user',
          extra: (id: id, name: name, avatar: avatar, pct: null)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              padding: const EdgeInsets.all(2),
              decoration:
                  const BoxDecoration(color: AppColors.ring, shape: BoxShape.circle),
              child: ClipOval(
                child: CachedNetworkImage(
                    imageUrl: avatar,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => const ColoredBox(color: AppColors.sand)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                  Text(handle,
                      style: t.bodyMedium?.copyWith(color: AppColors.ink2)),
                ],
              ),
            ),
            GestureDetector(
              onTap: () =>
                  ref.read(interactionsProvider.notifier).toggleFollow(id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: following ? AppColors.paper : AppColors.ink,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  border: following ? Border.all(color: AppColors.line) : null,
                ),
                child: Text(following ? 'Following' : 'Follow',
                    style: t.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: following ? AppColors.ink2 : AppColors.onInk)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
