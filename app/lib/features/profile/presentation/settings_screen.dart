import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/state/interactions.dart';
import '../../../core/state/session.dart';
import '../../../core/theme/tokens.dart';
import '../../feed/data/mock_feed.dart';

/// Settings — a real, full-screen settings surface (route `/settings`). Grouped
/// iOS-style sections per the locked design system. Includes the privacy
/// essentials the MVP requires: **data export** and **account deletion**
/// (CLAUDE.md privacy rules / SRS data lifecycle), plus blocked accounts,
/// notification prefs, and sign out. Frontend-only: actions are mocked with the
/// real copy/flows; wiring to Supabase comes later.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notifLikes = true;
  bool _notifFollows = true;
  bool _notifPosts = false;

  void _signOut() {
    ref.read(sessionProvider.notifier).signOut();
    context.go('/onboarding');
  }

  void _requestExport() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.canvas,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet))),
      builder: (ctx) => _ConfirmSheet(
        icon: Icons.download_rounded,
        title: 'Export your data',
        body:
            "We'll prepare a file with your profile, posts, saved looks, and activity, "
            'and email it to maya@email.com within 48 hours.',
        cta: 'Request export',
        onConfirm: () {
          Navigator.of(ctx).pop();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.ink,
            content: Text("Export requested — we'll email you a copy."),
          ));
        },
      ),
    );
  }

  void _deleteAccount() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.canvas,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet))),
      builder: (ctx) => _ConfirmSheet(
        icon: Icons.warning_amber_rounded,
        iconColor: _danger,
        title: 'Delete account',
        body:
            'This permanently deletes your profile, posts, saved looks, follows, and '
            'matches. It cannot be undone.',
        cta: 'Delete my account',
        destructive: true,
        onConfirm: () {
          Navigator.of(ctx).pop();
          _signOut();
        },
      ),
    );
  }

  void _openBlocked() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const _BlockedAccountsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(title: 'Settings', onBack: () => context.pop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 28),
                children: [
                  _Group(title: 'Account', children: [
                    _NavRow(
                        icon: Icons.alternate_email_rounded,
                        label: 'Email',
                        value: 'maya@email.com'),
                    _NavRow(
                        icon: Icons.lock_outline_rounded,
                        label: 'Change password',
                        onTap: () {}),
                  ]),
                  _Group(title: 'Privacy & data', children: [
                    _NavRow(
                        icon: Icons.block_rounded,
                        label: 'Blocked accounts',
                        onTap: _openBlocked),
                    _NavRow(
                        icon: Icons.download_rounded,
                        label: 'Export my data',
                        onTap: _requestExport),
                    _NavRow(
                        icon: Icons.privacy_tip_outlined,
                        label: 'Privacy policy',
                        onTap: () {}),
                  ]),
                  _Group(title: 'Notifications', children: [
                    _ToggleRow(
                        icon: Icons.favorite_border_rounded,
                        label: 'Likes on your posts',
                        value: _notifLikes,
                        onChanged: (v) => setState(() => _notifLikes = v)),
                    _ToggleRow(
                        icon: Icons.person_add_alt_1_outlined,
                        label: 'New followers',
                        value: _notifFollows,
                        onChanged: (v) => setState(() => _notifFollows = v)),
                    _ToggleRow(
                        icon: Icons.auto_awesome_outlined,
                        label: 'New matched looks',
                        value: _notifPosts,
                        onChanged: (v) => setState(() => _notifPosts = v)),
                  ]),
                  _Group(title: 'About', children: [
                    _NavRow(
                        icon: Icons.shield_outlined,
                        label: 'Community guidelines',
                        onTap: () {}),
                    _NavRow(
                        icon: Icons.help_outline_rounded,
                        label: 'Help & support',
                        onTap: () {}),
                  ]),
                  _Group(children: [
                    _NavRow(
                        icon: Icons.logout_rounded,
                        label: 'Sign out',
                        showChevron: false,
                        onTap: _signOut),
                  ]),
                  _Group(children: [
                    _NavRow(
                        icon: Icons.delete_outline_rounded,
                        label: 'Delete account',
                        danger: true,
                        showChevron: false,
                        onTap: _deleteAccount),
                  ]),
                  const SizedBox(height: 8),
                  Center(
                    child: Text('Viele · v1.0.0',
                        style: t.bodySmall?.copyWith(color: AppColors.ink3)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _danger = Color(0xFFD64545);

// ── Top bar ─────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.onBack});
  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18, color: AppColors.ink),
            ),
          ),
          Text(title, style: t.headlineSmall?.copyWith(fontSize: 17)),
        ],
      ),
    );
  }
}

// ── Grouped list primitives ───────────────────────────────────────────────────

class _Group extends StatelessWidget {
  const _Group({this.title, required this.children});
  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(const Divider(
            height: 1, thickness: 1, color: AppColors.line, indent: 48));
      }
      rows.add(children[i]);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s20, 18, AppSpacing.s20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(title!.toUpperCase(),
                  style: t.labelSmall?.copyWith(letterSpacing: 1.4)),
            ),
          ],
          Container(
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(AppRadii.chip),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(children: rows),
          ),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.icon,
    required this.label,
    this.value,
    this.onTap,
    this.danger = false,
    this.showChevron = true,
  });

  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback? onTap;
  final bool danger;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final color = danger ? _danger : AppColors.ink;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: t.bodyLarge?.copyWith(
                      color: color, fontWeight: FontWeight.w500)),
            ),
            if (value != null)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(value!,
                    style: t.bodyMedium?.copyWith(color: AppColors.ink2)),
              ),
            if (showChevron)
              const Icon(Icons.chevron_right_rounded,
                  size: 20, color: AppColors.ink3),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 12, 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.ink),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
          ),
          CupertinoSwitch(
            value: value,
            activeTrackColor: AppColors.match,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// ── Confirm sheet (export / delete) ───────────────────────────────────────────

class _ConfirmSheet extends StatelessWidget {
  const _ConfirmSheet({
    required this.icon,
    required this.title,
    required this.body,
    required this.cta,
    required this.onConfirm,
    this.destructive = false,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String body;
  final String cta;
  final VoidCallback onConfirm;
  final bool destructive;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final accent = destructive ? _danger : AppColors.ink;
    return SafeArea(
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
            const SizedBox(height: 18),
            Icon(icon, size: 30, color: iconColor ?? AppColors.ink),
            const SizedBox(height: 12),
            Text(title, style: t.headlineSmall?.copyWith(fontSize: 21)),
            const SizedBox(height: 8),
            Text(body,
                style: t.bodyLarge?.copyWith(color: AppColors.ink2, height: 1.45)),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onConfirm,
              child: Container(
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: accent, borderRadius: BorderRadius.circular(14)),
                child: Text(cta,
                    style: t.labelLarge?.copyWith(
                        color: AppColors.onInk, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                height: 50,
                alignment: Alignment.center,
                child: Text('Cancel',
                    style: t.labelLarge?.copyWith(
                        color: AppColors.ink2, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Blocked accounts ──────────────────────────────────────────────────────────

class _BlockedAccountsScreen extends ConsumerWidget {
  const _BlockedAccountsScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    // blocked is a set of author ids — resolve to display names for the list.
    String nameFor(String id) {
      for (final p in mockFeed) {
        if (p.authorId == id) return p.authorName;
      }
      return id;
    }

    final blocked = [
      for (final id in ref.watch(interactionsProvider).blocked)
        (id: id, name: nameFor(id)),
    ];
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
                title: 'Blocked accounts',
                onBack: () => Navigator.of(context).pop()),
            if (blocked.isEmpty)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.block_rounded,
                            size: 38, color: AppColors.ink3),
                        const SizedBox(height: 12),
                        Text("You haven't blocked anyone",
                            style: t.titleLarge?.copyWith(fontSize: 18)),
                        const SizedBox(height: 4),
                        Text('Blocked accounts can\'t see your profile or posts.',
                            textAlign: TextAlign.center,
                            style: t.bodyLarge?.copyWith(color: AppColors.ink2)),
                      ],
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.s20, 12, AppSpacing.s20, 24),
                  itemCount: blocked.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final name = blocked[i].name;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.paper,
                        borderRadius: BorderRadius.circular(AppRadii.chip),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                                color: AppColors.taupe, shape: BoxShape.circle),
                            child: Text(
                              name.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                  fontFamily: AppFonts.text,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF5B4F3C)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(name,
                                style: t.bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                          ),
                          GestureDetector(
                            onTap: () => ref
                                .read(interactionsProvider.notifier)
                                .unblock(blocked[i].id),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(AppRadii.pill),
                                  border: Border.all(color: AppColors.ink)),
                              child: Text('Unblock',
                                  style: t.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.ink)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
