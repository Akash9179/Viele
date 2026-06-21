import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/profile_repository.dart';
import '../../../core/state/interactions.dart';
import '../../../core/theme/tokens.dart';

/// Followers / Following lists (route `/connections`). Opened by tapping the
/// stats on a profile; `extra` carries the [userId] whose connections to show,
/// the display [handle], and the initial tab (0 followers, 1 following).
/// Backed by the real `follows` graph.
class ConnectionsScreen extends ConsumerStatefulWidget {
  const ConnectionsScreen({
    super.key,
    required this.userId,
    this.handle = '',
    this.initialTab = 0,
  });

  final String userId;
  final String handle;
  final int initialTab;

  @override
  ConsumerState<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends ConsumerState<ConnectionsScreen> {
  late int _tab = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final followers = ref.watch(followersProvider(widget.userId));
    final following = ref.watch(followingProvider(widget.userId));
    final current = _tab == 0 ? followers : following;

    String count(AsyncValue<List<Person>> a) => '${a.asData?.value.length ?? 0}';

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
                _tabBtn('Followers · ${count(followers)}', 0),
                _tabBtn('Following · ${count(following)}', 1),
              ],
            ),
            const Divider(height: 1, color: AppColors.line),
            Expanded(
              child: current.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2)),
                error: (_, _) => Center(
                  child: Text("Couldn't load this list.",
                      style: t.bodyMedium?.copyWith(color: AppColors.ink2)),
                ),
                data: (people) {
                  if (people.isEmpty) {
                    return Center(
                      child: Text(
                          _tab == 0 ? 'No followers yet' : 'Not following anyone yet',
                          style: t.bodyMedium?.copyWith(color: AppColors.ink2)),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: people.length,
                    itemBuilder: (context, i) => _PersonRow(person: people[i]),
                  );
                },
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
  const _PersonRow({required this.person});
  final Person person;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final following =
        ref.watch(interactionsProvider).following.contains(person.id);
    final handle = person.username.isNotEmpty
        ? '@${person.username}'
        : '@${person.name.toLowerCase().replaceAll(' ', '')}';
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/user',
          extra: (
            id: person.id,
            name: person.name,
            avatar: person.avatar ?? '',
            pct: null
          )),
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
                child: person.avatar == null
                    ? _Initials(name: person.name)
                    : CachedNetworkImage(
                        imageUrl: person.avatar!,
                        fit: BoxFit.cover,
                        placeholder: (_, _) =>
                            const ColoredBox(color: AppColors.sand),
                        errorWidget: (_, _, _) => _Initials(name: person.name),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(person.name,
                      style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                  Text(handle,
                      style: t.bodyMedium?.copyWith(color: AppColors.ink2)),
                ],
              ),
            ),
            GestureDetector(
              onTap: () =>
                  ref.read(interactionsProvider.notifier).toggleFollow(person.id),
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

class _Initials extends StatelessWidget {
  const _Initials({required this.name});
  final String name;
  @override
  Widget build(BuildContext context) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final initials = parts.isEmpty
        ? '?'
        : parts.take(2).map((p) => p[0].toUpperCase()).join();
    return Container(
      color: AppColors.sand,
      alignment: Alignment.center,
      child: Text(initials,
          style: const TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 15,
              color: AppColors.ink2)),
    );
  }
}
