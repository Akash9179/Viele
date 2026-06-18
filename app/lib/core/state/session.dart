import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Auth/session state, backed by **Supabase Auth**. `signedIn` tracks the real
/// session (persisted across launches by supabase_flutter). Email auth is wired
/// now; Google/Apple are added once their providers are configured. Gates the
/// account-required actions (save / post) via [requireAccount].
class Session {
  const Session({this.signedIn = false});

  final bool signedIn;

  Session copyWith({bool? signedIn}) =>
      Session(signedIn: signedIn ?? this.signedIn);
}

class SessionNotifier extends Notifier<Session> {
  @override
  Session build() {
    final auth = Supabase.instance.client.auth;
    final sub = auth.onAuthStateChange.listen((data) {
      state = Session(signedIn: data.session != null);
    });
    ref.onDispose(sub.cancel);
    return Session(signedIn: auth.currentSession != null);
  }

  /// Returns null on success, or a user-facing error message. If the project
  /// requires email confirmation, sign-up succeeds but no session is created
  /// until the email is confirmed — [confirmationSent] reflects that.
  Future<({String? error, bool confirmationSent})> signUpWithEmail(
      String email, String password) async {
    try {
      final res = await Supabase.instance.client.auth
          .signUp(email: email, password: password);
      return (error: null, confirmationSent: res.session == null);
    } on AuthException catch (e) {
      return (error: e.message, confirmationSent: false);
    } catch (_) {
      return (error: 'Something went wrong. Please try again.', confirmationSent: false);
    }
  }

  /// Returns null on success, or a user-facing error message.
  Future<String?> signInWithEmail(String email, String password) async {
    try {
      await Supabase.instance.client.auth
          .signInWithPassword(email: email, password: password);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  Future<void> signOut() => Supabase.instance.client.auth.signOut();
}

final sessionProvider =
    NotifierProvider<SessionNotifier, Session>(SessionNotifier.new);

/// Gate an account-required action. If signed in, runs [action] now. Otherwise
/// opens the `/signup` flow and runs [action] only if the user signs in there.
Future<void> requireAccount(
    BuildContext context, WidgetRef ref, VoidCallback action) async {
  if (ref.read(sessionProvider).signedIn) {
    action();
    return;
  }
  await context.push('/signup');
  if (!context.mounted) return;
  if (ref.read(sessionProvider).signedIn) action();
}
