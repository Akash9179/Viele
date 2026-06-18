import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/supabase/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    // Publishable client key (RLS-scoped, safe to ship). Not service_role.
    publishableKey: SupabaseConfig.publishableKey,
  );
  // Debug-only: auto sign-in for screenshots of signed-in flows. Pass creds via
  // `--dart-define=DEVLOGIN=email|password` (no credentials committed to source).
  const devLogin = String.fromEnvironment('DEVLOGIN');
  if (devLogin.contains('|')) {
    final parts = devLogin.split('|');
    try {
      await Supabase.instance.client.auth
          .signInWithPassword(email: parts[0], password: parts[1]);
    } catch (_) {}
  }
  runApp(const ProviderScope(child: VieleApp()));
}
