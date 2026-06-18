import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/catwalk/presentation/catwalk_screen.dart';
import 'features/discover/presentation/discover_screen.dart';
import 'features/feed/data/feed_post.dart';
import 'features/feed/data/mock_feed.dart';
import 'features/feed/presentation/feed_screen.dart';
import 'features/feed/presentation/outfit_detail_screen.dart';
import 'features/onboarding/presentation/onboarding_flow.dart';
import 'features/post/presentation/post_compose_screen.dart';
import 'features/profile/presentation/collection_detail_screen.dart';
import 'features/profile/presentation/connections_screen.dart';
import 'features/profile/presentation/edit_profile_screen.dart';
import 'features/profile/presentation/other_user_profile_screen.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'features/profile/presentation/settings_screen.dart';
import 'features/search/presentation/search_screen.dart';
import 'features/shell/app_shell.dart';

final _rootKey = GlobalKey<NavigatorState>();

/// Debug-only initial route for screenshots (`--dart-define=ROUTE=/profile`).
const _kInitialRoute = String.fromEnvironment('ROUTE', defaultValue: '/onboarding');

final _router = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: _kInitialRoute,
  routes: [
    GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingFlow()),
    GoRoute(
      path: '/signup',
      parentNavigatorKey: _rootKey,
      builder: (_, _) => const SignupFlow(),
    ),
    GoRoute(
      path: '/settings',
      parentNavigatorKey: _rootKey,
      builder: (_, _) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/search',
      parentNavigatorKey: _rootKey,
      builder: (_, _) => const SearchScreen(),
    ),
    GoRoute(
      path: '/edit-profile',
      parentNavigatorKey: _rootKey,
      builder: (_, _) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/connections',
      parentNavigatorKey: _rootKey,
      builder: (_, state) {
        final e = state.extra as ({String handle, int tab})?;
        return ConnectionsScreen(
            handle: e?.handle ?? '@mayachen', initialTab: e?.tab ?? 0);
      },
    ),
    GoRoute(
      path: '/collection',
      parentNavigatorKey: _rootKey,
      builder: (_, state) {
        final e = state.extra as ({String name, String? collectionId})?;
        return CollectionDetailScreen(
            name: e?.name ?? 'Collection', collectionId: e?.collectionId);
      },
    ),
    GoRoute(
      path: '/outfit',
      parentNavigatorKey: _rootKey,
      builder: (_, state) =>
          OutfitDetailScreen(post: (state.extra as FeedPost?) ?? mockFeed.first),
    ),
    GoRoute(
      path: '/user',
      parentNavigatorKey: _rootKey,
      builder: (_, state) {
        final u =
            state.extra as ({String id, String name, String avatar, int? pct})?;
        return OtherUserProfileScreen(
          userId: u?.id ?? 'u1',
          name: u?.name ?? 'Mara',
          avatarUrl: u?.avatar ??
              'https://images.unsplash.com/photo-1534404483017-8743b4e935cd?w=180&h=180&fit=crop&crop=faces&q=80',
          matchPct: u?.pct,
        );
      },
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppShell(navigationShell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/home', builder: (_, _) => const FeedScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/discover', builder: (_, _) => const DiscoverScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/post', builder: (_, _) => const PostComposeScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/catwalk', builder: (_, _) => const CatwalkScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
        ]),
      ],
    ),
  ],
);

class VieleApp extends StatelessWidget {
  const VieleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Viele',
      debugShowCheckedModeBanner: false,
      theme: buildVieleTheme(),
      routerConfig: _router,
    );
  }
}
