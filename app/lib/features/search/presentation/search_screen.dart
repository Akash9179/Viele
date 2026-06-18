import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/state/interactions.dart';
import '../../../core/theme/tokens.dart';
import '../../feed/data/mock_feed.dart';
import '../../onboarding/data/onboarding_data.dart';

/// Search (route `/search`). Find people, aesthetics, and looks. Frontend mock:
/// people + looks from `mockFeed`, aesthetics from the onboarding taxonomy.
/// Empty query shows discovery (browse aesthetics + people to follow); typing
/// shows sectioned results. Blocked authors are excluded.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

/// Debug-only: prefill the query for screenshots (`--dart-define=Q=Quiet`).
const _kQuery = String.fromEnvironment('Q');

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctl = TextEditingController(text: _kQuery);
  String _q = _kQuery;

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  void _setQuery(String v) => setState(() => _q = v);

  List<({String id, String name, String avatar})> _people(Set<String> blocked) {
    final seen = <String>{};
    final out = <({String id, String name, String avatar})>[];
    for (final p in mockFeed) {
      if (blocked.contains(p.authorId)) continue;
      if (seen.add(p.authorId)) {
        out.add((id: p.authorId, name: p.authorName, avatar: p.imageUrl));
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final blocked = ref.watch(interactionsProvider).blocked;
    final q = _q.trim().toLowerCase();
    final people = _people(blocked);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            _searchBar(),
            Expanded(
              child: q.isEmpty
                  ? _discovery(people)
                  : _results(q, people, blocked),
            ),
          ],
        ),
      ),
    );
  }

  // ── Search bar ─────────────────────────────────────────────────────────────

  Widget _searchBar() {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 18, color: AppColors.ink),
          ),
          Expanded(
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(AppRadii.pill),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded,
                      size: 19, color: AppColors.ink3),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _ctl,
                      autofocus: true,
                      onChanged: _setQuery,
                      style: t.bodyLarge,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText: 'People, aesthetics, looks',
                        hintStyle:
                            t.bodyLarge?.copyWith(color: AppColors.ink3),
                      ),
                    ),
                  ),
                  if (_q.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _ctl.clear();
                        _setQuery('');
                      },
                      child: const Icon(Icons.cancel_rounded,
                          size: 18, color: AppColors.ink3),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty-query discovery ────────────────────────────────────────────────────

  Widget _discovery(List<({String id, String name, String avatar})> people) {
    final t = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        _sectionLabel('Browse aesthetics'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: [
            for (final a in aesthetics)
              GestureDetector(
                onTap: () {
                  _ctl.text = a.name;
                  _setQuery(a.name);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Text(a.name,
                      style: t.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600, color: AppColors.ink)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 26),
        _sectionLabel('People to discover'),
        const SizedBox(height: 4),
        for (final p in people)
          _PersonRow(id: p.id, name: p.name, avatar: p.avatar),
      ],
    );
  }

  // ── Results ───────────────────────────────────────────────────────────────

  Widget _results(String q, List<({String id, String name, String avatar})> people,
      Set<String> blocked) {
    final t = Theme.of(context).textTheme;
    final matchedPeople =
        people.where((p) => p.name.toLowerCase().contains(q)).toList();
    final matchedAesthetics =
        aesthetics.where((a) => a.name.toLowerCase().contains(q)).toList();
    final matchedLooks = mockFeed
        .where((p) =>
            !blocked.contains(p.authorId) &&
            (p.aesthetic.toLowerCase().contains(q) ||
                p.authorName.toLowerCase().contains(q)))
        .toList();

    if (matchedPeople.isEmpty &&
        matchedAesthetics.isEmpty &&
        matchedLooks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off_rounded,
                  size: 38, color: AppColors.ink3),
              const SizedBox(height: 12),
              Text('No results for "$_q"',
                  style: t.titleLarge?.copyWith(fontSize: 18),
                  textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text('Try a name, an aesthetic, or a style word.',
                  textAlign: TextAlign.center,
                  style: t.bodyLarge?.copyWith(color: AppColors.ink2)),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        if (matchedAesthetics.isNotEmpty) ...[
          _sectionLabel('Aesthetics'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [
              for (final a in matchedAesthetics)
                GestureDetector(
                  onTap: () {
                    _ctl.text = a.name;
                    _setQuery(a.name);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    child: Text(a.name,
                        style: t.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.onInk)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 22),
        ],
        if (matchedPeople.isNotEmpty) ...[
          _sectionLabel('People'),
          const SizedBox(height: 4),
          for (final p in matchedPeople)
            _PersonRow(id: p.id, name: p.name, avatar: p.avatar),
          const SizedBox(height: 18),
        ],
        if (matchedLooks.isNotEmpty) ...[
          _sectionLabel('Looks · ${matchedLooks.length}'),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 3 / 4,
            children: [
              for (final p in matchedLooks)
                GestureDetector(
                  onTap: () => context.push('/outfit', extra: p),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                        imageUrl: p.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, _) =>
                            const ColoredBox(color: AppColors.sand)),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _sectionLabel(String s) => Text(s.toUpperCase(),
      style: Theme.of(context)
          .textTheme
          .labelSmall
          ?.copyWith(letterSpacing: 1.2));
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
              decoration: const BoxDecoration(
                  color: AppColors.ring, shape: BoxShape.circle),
              child: ClipOval(
                child: CachedNetworkImage(
                    imageUrl: avatar,
                    fit: BoxFit.cover,
                    placeholder: (_, _) =>
                        const ColoredBox(color: AppColors.sand)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style:
                          t.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
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
