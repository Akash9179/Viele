import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/collections_repository.dart';
import '../../../core/data/profile_repository.dart';
import '../../../core/state/interactions.dart';
import '../../../core/state/profile.dart';
import '../../../core/theme/tokens.dart';

/// Public profile (frontend, mock): avatar + stats, public attribute chips
/// (weight never shown), bio, Posts / Saved tabs.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // 0 = Posts, 1 = Saved. Debug `--dart-define=TAB=1` opens on Saved.
  int _tab = const int.fromEnvironment('TAB');

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final saved = ref.watch(interactionsProvider).saved;
    final p = ref.watch(profileProvider);
    final namedCollections =
        ref.watch(namedCollectionsProvider).asData?.value ?? const [];
    final savedPosts = ref.watch(savedPostsProvider).asData?.value ?? const [];
    final savedCover = savedPosts.isEmpty ? null : savedPosts.first.imageUrl;
    final myPosts = ref.watch(myPostsProvider).asData?.value ?? const [];
    final counts = ref.watch(followCountsProvider).asData?.value;

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('@${p.username}',
                      style: t.headlineSmall?.copyWith(fontSize: 16)),
                  GestureDetector(
                    onTap: () => context.push('/settings'),
                    child: const Icon(Icons.settings_outlined,
                        size: 21, color: AppColors.ink),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Row(
                children: [
                  Container(
                    width: 78,
                    height: 78,
                    padding: const EdgeInsets.all(2.5),
                    decoration: const BoxDecoration(
                        color: AppColors.ring, shape: BoxShape.circle),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: p.avatarUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => const ColoredBox(color: AppColors.sand),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _Stat(value: '${myPosts.length}', label: 'Posts'),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            final uid =
                                Supabase.instance.client.auth.currentUser?.id;
                            if (uid == null) return;
                            context.push('/connections',
                                extra: (
                                  userId: uid,
                                  handle: '@${p.username}',
                                  tab: 0
                                ));
                          },
                          child: _Stat(
                              value: '${counts?.followers ?? 0}',
                              label: 'Followers'),
                        ),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            final uid =
                                Supabase.instance.client.auth.currentUser?.id;
                            if (uid == null) return;
                            context.push('/connections',
                                extra: (
                                  userId: uid,
                                  handle: '@${p.username}',
                                  tab: 1
                                ));
                          },
                          child: _Stat(
                              value: '${counts?.following ?? 0}',
                              label: 'Following'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name, style: t.headlineSmall),
                  Text(p.aesthetics, style: t.bodyMedium),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [for (final a in p.attributeChips) _AttrChip(a)],
                  ),
                  const SizedBox(height: 11),
                  Text(
                    p.bio,
                    style: t.bodyLarge?.copyWith(
                        fontSize: 13.5, height: 1.45, color: const Color(0xFF3D362B)),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => context.push('/edit-profile'),
                          child: Container(
                            height: 42,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                color: AppColors.ink,
                                borderRadius: BorderRadius.circular(12)),
                            child: Text('Edit profile',
                                style: t.labelLarge?.copyWith(
                                    color: AppColors.onInk,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Container(
                        width: 46,
                        height: 42,
                        decoration: BoxDecoration(
                            color: AppColors.paper,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.line)),
                        child: const Icon(Icons.share_outlined,
                            size: 18, color: AppColors.ink),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _Tabs(
              current: _tab,
              savedCount: saved.length,
              onTap: (i) => setState(() => _tab = i),
            ),
          ),
          if (_tab == 0)
            if (myPosts.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
                  child: Column(
                    children: [
                      const Icon(Icons.grid_view_rounded,
                          size: 36, color: AppColors.ink3),
                      const SizedBox(height: 12),
                      Text('No posts yet',
                          style: t.titleLarge?.copyWith(fontSize: 18)),
                      const SizedBox(height: 4),
                      Text('Share a look from the ＋ tab — it shows up here.',
                          textAlign: TextAlign.center,
                          style: t.bodyLarge?.copyWith(color: AppColors.ink2)),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(3),
                sliver: SliverMasonryGrid.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 3,
                  crossAxisSpacing: 3,
                  childCount: myPosts.length,
                  itemBuilder: (context, i) => GestureDetector(
                    onTap: () => context.push('/outfit', extra: myPosts[i]),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: AspectRatio(
                        aspectRatio: 3 / 4,
                        child: CachedNetworkImage(
                          imageUrl: myPosts[i].imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, _) =>
                              const ColoredBox(color: AppColors.sand),
                          errorWidget: (_, _, _) =>
                              const ColoredBox(color: AppColors.taupe),
                        ),
                      ),
                    ),
                  ),
                ),
              )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              sliver: SliverGrid.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.82,
                children: [
                  _CollectionCard(
                    title: 'All saved',
                    count: saved.length,
                    coverUrl: savedCover,
                    onTap: () => context.push('/collection',
                        extra: (name: 'All saved', collectionId: null)),
                  ),
                  for (final c in namedCollections)
                    _CollectionCard(
                      title: c.name,
                      count: c.count,
                      coverUrl: c.coverUrl,
                      onTap: () => context.push('/collection',
                          extra: (name: c.name, collectionId: c.id)),
                    ),
                  _NewCollectionCard(onTap: () => _newCollection(context, ref)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value, label;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(value, style: t.headlineSmall?.copyWith(fontSize: 18)),
        Text(label, style: t.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _AttrChip extends StatelessWidget {
  const _AttrChip(this.label);
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: AppColors.sand, borderRadius: BorderRadius.circular(AppRadii.pill)),
      child: Text(label,
          style: const TextStyle(
              fontFamily: AppFonts.text,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.ink)),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.current, required this.onTap, required this.savedCount});
  final int current;
  final int savedCount;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    Widget tab(int i, IconData icon, String label) {
      final on = current == i;
      return GestureDetector(
        onTap: () => onTap(i),
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(
                      color: on ? AppColors.ink : Colors.transparent, width: 2))),
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: on ? AppColors.ink : AppColors.ink3),
              const SizedBox(width: 6),
              Text(label,
                  style: t.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: on ? AppColors.ink : AppColors.ink3)),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.line))),
      child: Row(
        children: [
          tab(0, Icons.grid_view_rounded, 'Posts'),
          const SizedBox(width: 24),
          tab(1, Icons.bookmark_outline_rounded,
              savedCount == 0 ? 'Saved' : 'Saved · $savedCount'),
        ],
      ),
    );
  }
}


class _CollectionCard extends StatelessWidget {
  const _CollectionCard({
    required this.title,
    required this.count,
    required this.coverUrl,
    required this.onTap,
  });
  final String title;
  final int count;
  final String? coverUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          boxShadow: AppShadows.soft,
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (coverUrl != null)
                CachedNetworkImage(
                  imageUrl: coverUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => const ColoredBox(color: AppColors.sand),
                )
              else
                const ColoredBox(
                  color: AppColors.sand,
                  child: Center(
                      child: Icon(Icons.bookmark_border_rounded,
                          size: 30, color: AppColors.ink3)),
                ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.center,
                    colors: [Color(0xCC160F08), Color(0x00160F08)],
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 11,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontFamily: AppFonts.display,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    Text('$count ${count == 1 ? "look" : "looks"}',
                        style: TextStyle(
                            fontFamily: AppFonts.text,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.85))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewCollectionCard extends StatelessWidget {
  const _NewCollectionCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.ink3, width: 1.4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_rounded, size: 26, color: AppColors.ink2),
            const SizedBox(height: 6),
            Text('New collection',
                style: t.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600, color: AppColors.ink2)),
          ],
        ),
      ),
    );
  }
}

void _newCollection(BuildContext context, WidgetRef ref) {
  final ctl = TextEditingController();
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.canvas,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet))),
    builder: (ctx) {
      final t = Theme.of(ctx).textTheme;
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                          color: AppColors.ink3,
                          borderRadius: BorderRadius.circular(3))),
                ),
                const SizedBox(height: 14),
                Text('New collection',
                    style: t.headlineSmall?.copyWith(fontSize: 20)),
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.line)),
                  child: TextField(
                    controller: ctl,
                    autofocus: true,
                    style: t.bodyLarge,
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: 'e.g. Fall layers',
                      hintStyle: t.bodyLarge?.copyWith(color: AppColors.ink3),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final name = ctl.text.trim();
                    if (name.isNotEmpty) {
                      await ref
                          .read(collectionsRepositoryProvider)
                          .createCollection(name);
                      ref.invalidate(namedCollectionsProvider);
                    }
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                  child: Container(
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(14)),
                    child: Text('Create',
                        style: t.labelLarge?.copyWith(
                            color: AppColors.onInk,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

