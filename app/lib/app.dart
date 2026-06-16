import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/catwalk/presentation/catwalk_screen.dart';
import 'features/discover/presentation/discover_screen.dart';
import 'features/feed/presentation/feed_screen.dart';
import 'features/onboarding/presentation/onboarding_flow.dart';
import 'features/post/presentation/post_compose_screen.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'features/shell/app_shell.dart';

final _rootKey = GlobalKey<NavigatorState>();

/// Debug-only initial route for screenshots (`--dart-define=ROUTE=/profile`).
const _kInitialRoute = String.fromEnvironment('ROUTE', defaultValue: '/onboarding');

final _router = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: _kInitialRoute,
  routes: [
    GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingFlow()),
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
