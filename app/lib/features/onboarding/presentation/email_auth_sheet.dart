import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/state/session.dart';
import '../../../core/theme/tokens.dart';

/// Email sign-up / sign-in sheet (Supabase Auth). Returns `true` when a session
/// is established (caller then continues the pending action). Google/Apple are
/// separate (configured later). [ref] is passed from the caller so the sheet can
/// reach [sessionProvider].
Future<bool?> showEmailAuth(BuildContext context, WidgetRef ref,
    {required bool signUp}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.canvas,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet))),
    builder: (_) => _EmailAuthSheet(authRef: ref, signUp: signUp),
  );
}

class _EmailAuthSheet extends StatefulWidget {
  const _EmailAuthSheet({required this.authRef, required this.signUp});
  final WidgetRef authRef;
  final bool signUp;

  @override
  State<_EmailAuthSheet> createState() => _EmailAuthSheetState();
}

class _EmailAuthSheetState extends State<_EmailAuthSheet> {
  late bool _signUp = widget.signUp;
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _busy = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final pass = _pass.text;
    if (email.isEmpty || !email.contains('@') || pass.length < 6) {
      setState(() =>
          _error = 'Enter a valid email and a password of at least 6 characters.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    final notifier = widget.authRef.read(sessionProvider.notifier);
    if (_signUp) {
      final r = await notifier.signUpWithEmail(email, pass);
      if (!mounted) return;
      if (r.error != null) {
        setState(() {
          _busy = false;
          _error = r.error;
        });
        return;
      }
      if (r.confirmationSent) {
        setState(() {
          _busy = false;
          _signUp = false;
          _info = 'Check your email to confirm your address, then sign in.';
        });
        return;
      }
      if (mounted) Navigator.of(context).pop(true);
    } else {
      final err = await notifier.signInWithEmail(email, pass);
      if (!mounted) return;
      if (err != null) {
        setState(() {
          _busy = false;
          _error = err;
        });
        return;
      }
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
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
              const SizedBox(height: 16),
              Text(_signUp ? 'Create your account' : 'Welcome back',
                  style: t.headlineSmall?.copyWith(fontSize: 22)),
              const SizedBox(height: 16),
              _input(_email, 'Email',
                  keyboard: TextInputType.emailAddress, autofocus: true),
              const SizedBox(height: 12),
              _input(_pass, 'Password', obscure: true),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: t.bodyMedium?.copyWith(color: const Color(0xFFD64545))),
              ],
              if (_info != null) ...[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.mark_email_unread_outlined,
                        size: 16, color: AppColors.matchDark),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(_info!,
                            style: t.bodyMedium
                                ?.copyWith(color: AppColors.matchDark))),
                  ],
                ),
              ],
              const SizedBox(height: 18),
              GestureDetector(
                onTap: _busy ? null : _submit,
                child: Opacity(
                  opacity: _busy ? 0.6 : 1,
                  child: Container(
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(14)),
                    child: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.2, color: AppColors.onInk))
                        : Text(_signUp ? 'Create account' : 'Sign in',
                            style: t.labelLarge?.copyWith(
                                color: AppColors.onInk,
                                fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                            _signUp = !_signUp;
                            _error = null;
                            _info = null;
                          }),
                  child: Text(
                    _signUp
                        ? 'Already have an account? Sign in'
                        : "New here? Create an account",
                    style: t.bodyLarge?.copyWith(
                        color: AppColors.ink2, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _input(TextEditingController c, String hint,
      {bool obscure = false,
      bool autofocus = false,
      TextInputType? keyboard}) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line)),
      child: TextField(
        controller: c,
        obscureText: obscure,
        autofocus: autofocus,
        keyboardType: keyboard,
        autocorrect: false,
        enableSuggestions: !obscure,
        style: t.bodyLarge,
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          hintText: hint,
          hintStyle: t.bodyLarge?.copyWith(color: AppColors.ink3),
        ),
      ),
    );
  }
}
