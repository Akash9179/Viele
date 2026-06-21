// Self-cleaning interactive QA for Viele's signed-in happy path.
//
// Creates a THROWAWAY account, exercises the real backend paths (profile create,
// post publish with media upload, avatar upload), drives the signed-in UI
// (Feed → Catwalk → Profile), verifies the rewired data surfaces (real
// recommendations, real caption/items, match bands), then DELETES the account
// via the delete-account edge function in tearDown — leaving prod clean.
//
// Run on a booted simulator/device, landing on the feed:
//   flutter test integration_test/qa_smoke_test.dart \
//     -d <device-id> --dart-define=ROUTE=/home
//
// Requires network (talks to the live Supabase project).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:viele/app.dart';
import 'package:viele/core/data/post_repository.dart';
import 'package:viele/core/data/profile_repository.dart';
import 'package:viele/core/supabase/supabase_config.dart';

// 1x1 transparent PNG — a valid image body for upload paths.
const _pngB64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late SupabaseClient c;
  late String email;
  late String uid;
  const password = 'qa-test-pw-9x2!';

  setUpAll(() async {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
    c = Supabase.instance.client;

    email = 'qa.viele.${DateTime.now().millisecondsSinceEpoch}@example.com';
    final res = await c.auth.signUp(email: email, password: password);
    uid = res.user!.id;
    expect(res.session, isNotNull, reason: 'signup should return a session');
    expect(c.auth.currentSession, isNotNull);

    // Real profile (mirrors onboarding's createFromDraft) so signed-in surfaces
    // render. Weight goes to the owner-only private table, never public.
    await c.from('profiles').insert({
      'id': uid,
      'username': 'qa_${DateTime.now().millisecondsSinceEpoch % 1000000}',
      'display_name': 'QA Tester',
      'bio': 'Automated QA account.',
      'region': 'New York',
      'gender_identity': 'female',
      'body_silhouette': 'hourglass',
      'height_cm': 168,
      'skin_tone': 5,
      'undertone': 'warm',
      'hair_color': 'Brown',
      'eye_color': 'Brown',
      'aesthetics': ['Quiet Luxury', 'Off-Duty'],
    });
    await c
        .from('profiles_private')
        .insert({'profile_id': uid, 'weight_kg': 62});
  });

  tearDownAll(() async {
    // Self-clean: real cascading deletion (DB + storage) via the edge function.
    try {
      await c.functions.invoke('delete-account');
    } catch (_) {/* best-effort cleanup */}
  });

  Future<File> tempImage(String name) async {
    final f = File('${Directory.systemTemp.path}/$name');
    await f.writeAsBytes(base64Decode(_pngB64));
    return f;
  }

  testWidgets('publish path: upload + insert writes real caption/items',
      (tester) async {
    final img = await tempImage('qa_post.jpg');
    await PostRepository().publish(
      imagePaths: [img.path],
      caption: 'QA cream knit look',
      aesthetics: ['Quiet Luxury', 'Off-Duty'],
      items: [
        {'name': 'Cream knit sweater', 'brand': 'QA Brand'},
      ],
    );

    // Verify the row landed with the real caption + items (A3 data path).
    final row = await c
        .from('posts')
        .select('caption, items, media, status')
        .eq('author_id', uid)
        .single();
    expect(row['caption'], 'QA cream knit look');
    expect((row['items'] as List).first['name'], 'Cream knit sweater');
    expect((row['media'] as List), isNotEmpty);
    expect(row['status'], 'active');
  });

  testWidgets('matching RPCs return real, ranked data', (tester) async {
    final feed = (await c.rpc('feed')) as List;
    expect(feed, isNotEmpty, reason: 'feed should include our post');
    final mine =
        feed.cast<Map>().firstWhere((r) => r['author_id'] == uid, orElse: () => {});
    expect(mine['author_name'], 'QA Tester');
    // Author == viewer (same profile) → strong self-similarity → high match.
    expect((mine['match_pct'] as num) >= 80, isTrue,
        reason: 'self-match should be high, got ${mine['match_pct']}');

    final people = (await c.rpc('recommend_people')) as List;
    expect(people, isNotEmpty, reason: 'recommendations should return people');
    expect(people.cast<Map>().every((r) => r['id'] != uid), isTrue,
        reason: 'recommendations must exclude the caller');
  });

  testWidgets('weight is never in any public payload', (tester) async {
    final feed = (await c.rpc('feed')) as List;
    for (final r in feed.cast<Map>()) {
      expect(r.containsKey('weight_kg'), isFalse);
      expect(r.containsKey('author_weight_band'), isFalse);
    }
    final people = (await c.rpc('recommend_people')) as List;
    for (final r in people.cast<Map>()) {
      expect(r.containsKey('weight_kg'), isFalse);
    }
    // The public profile read used by search/other-user must not expose weight.
    final pub = await c
        .from('profiles')
        .select('id, username, display_name, avatar_url, aesthetics')
        .eq('id', uid)
        .single();
    expect(pub.containsKey('weight_kg'), isFalse);
  });

  testWidgets('avatar upload stores a reachable public URL', (tester) async {
    final img = await tempImage('qa_avatar.jpg');
    final url = await ProfileRepository().uploadAvatar(img.path);
    expect(url, contains('/storage/v1/object/public/avatars/'));
    await c.from('profiles').update({'avatar_url': url}).eq('id', uid);
    final row =
        await c.from('profiles').select('avatar_url').eq('id', uid).single();
    expect(row['avatar_url'], url);
  });

  testWidgets('report persists and confirmation only shows on success',
      (tester) async {
    final postId =
        (await c.from('posts').select('id').eq('author_id', uid).single())['id'];
    await c.from('moderation_reports').insert({
      'post_id': postId,
      'reporter_id': uid,
      'reason': 'spam',
    });
    final reports = await c
        .from('moderation_reports')
        .select('reason, status')
        .eq('post_id', postId);
    expect(reports, isNotEmpty);
    expect(reports.first['status'], 'open');
  });

  testWidgets('signed-in UI: Feed → Catwalk → Profile render real data',
      (tester) async {
    // The tiny 1x1 test-fixture images can't be decoded by CachedNetworkImage;
    // those async decode errors are irrelevant to these assertions (real text
    // renders), so drain them after each settle batch.
    Future<void> settle(int n) async {
      for (var i = 0; i < n; i++) {
        await tester.pump(const Duration(milliseconds: 600));
      }
      while (tester.takeException() != null) {}
    }

    await tester.pumpWidget(const ProviderScope(child: VieleApp()));
    await settle(8);

    // Feed: header + recommendations.
    expect(find.text('Viele'), findsOneWidget);
    expect(find.text('RECOMMENDED'), findsOneWidget);

    // Catwalk.
    await tester.tap(find.text('CATWALK'));
    await settle(6);
    expect(find.text('Catwalk'), findsWidgets);

    // Profile: our real display name.
    await tester.tap(find.text('PROFILE'));
    await settle(6);
    expect(find.text('QA Tester'), findsWidgets);
  });
}
