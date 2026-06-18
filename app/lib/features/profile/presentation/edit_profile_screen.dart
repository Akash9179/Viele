import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/state/profile.dart';
import '../../../core/theme/tokens.dart';
import '../../onboarding/data/onboarding_data.dart';

/// Full-screen Edit Profile (route `/edit-profile`). Replaces the old sheet.
/// Editable public fields (name, username, bio, region) + attributes with
/// Public/Private badges; weight is private/matching-only and shown as such,
/// never edited here for display. Saves to [profileProvider] so the Profile tab
/// reflects changes.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final Profile _p = ref.read(profileProvider);
  late final _name = TextEditingController(text: _p.name);
  late final _username = TextEditingController(text: _p.username);
  late final _bio = TextEditingController(text: _p.bio);
  late final _region = TextEditingController(text: _p.region);

  late String _height = _p.height;
  late String _shape = _p.shape;
  late String _hair = _p.hair;
  late String _eye = _p.eye;

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _bio.dispose();
    _region.dispose();
    super.dispose();
  }

  bool _saving = false;

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final err = await ref.read(profileProvider.notifier).save(_p.copyWith(
          name: _name.text.trim(),
          username: _username.text.trim().replaceAll('@', ''),
          bio: _bio.text.trim(),
          region: _region.text.trim(),
          height: _height,
          shape: _shape,
          hair: _hair,
          eye: _eye,
        ));
    if (!mounted) return;
    if (err != null) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        content: Text(err),
      ));
      return;
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Text('Cancel',
                        style: t.bodyLarge?.copyWith(color: AppColors.ink2)),
                  ),
                  Text('Edit profile',
                      style: t.headlineSmall?.copyWith(fontSize: 17)),
                  GestureDetector(
                    onTap: _save,
                    child: Text('Save',
                        style: t.bodyLarge?.copyWith(
                            color: AppColors.ink, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.line),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                children: [
                  // Avatar
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          padding: const EdgeInsets.all(2.5),
                          decoration: const BoxDecoration(
                              color: AppColors.ring, shape: BoxShape.circle),
                          child: ClipOval(
                            child: Image.network(_p.avatarUrl, fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Change photo',
                            style: t.bodyLarge?.copyWith(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  _field('Name', _name, public: true),
                  _field('Username', _username, public: true, prefix: '@'),
                  _field('Bio', _bio, public: true, lines: 3),
                  _field('Region', _region,
                      public: true, hint: 'Add your region (optional)'),

                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(left: 2, bottom: 8),
                    child: Text('ATTRIBUTES · USED TO MATCH YOU',
                        style: t.labelSmall?.copyWith(letterSpacing: 1.2)),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.circular(AppRadii.chip),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Column(
                      children: [
                        _attrRow('Height', _height, public: true, onTap: () {
                          _pickHeight(context, _height,
                              (v) => setState(() => _height = v));
                        }),
                        _divider(),
                        _attrRow('Body shape', _shape, public: true, onTap: () {
                          _pickFromList(context, 'Body shape',
                              silhouetteLabels.values.toList(), _shape,
                              (v) => setState(() => _shape = v));
                        }),
                        _divider(),
                        _attrRow('Hair', _hair, public: true, onTap: () {
                          _pickFromList(
                              context,
                              'Hair color',
                              hairColors.map((c) => c.name).toList(),
                              _hair,
                              (v) => setState(() => _hair = v));
                        }),
                        _divider(),
                        _attrRow('Eyes', _eye, public: true, onTap: () {
                          _pickFromList(
                              context,
                              'Eye color',
                              eyeColors.map((c) => c.name).toList(),
                              _eye,
                              (v) => setState(() => _eye = v));
                        }),
                        _divider(),
                        _attrRow('Weight', 'Private · matching only',
                            public: false, muted: true, onTap: null),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() => const Divider(
      height: 1, thickness: 1, color: AppColors.line, indent: 14, endIndent: 14);

  Widget _field(String label, TextEditingController c,
      {required bool public, String? prefix, String? hint, int lines = 1}) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 6),
            child: Row(
              children: [
                Text(label.toUpperCase(),
                    style: t.labelSmall?.copyWith(letterSpacing: 1.0)),
                const SizedBox(width: 8),
                _Badge(public: public),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line)),
            child: Row(
              children: [
                if (prefix != null)
                  Text(prefix, style: t.bodyLarge?.copyWith(color: AppColors.ink2)),
                Expanded(
                  child: TextField(
                    controller: c,
                    maxLines: lines,
                    minLines: 1,
                    style: t.bodyLarge,
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: hint,
                      hintStyle:
                          t.bodyLarge?.copyWith(color: AppColors.ink3),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _attrRow(String label, String value,
      {required bool public, bool muted = false, VoidCallback? onTap}) {
    final t = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 92,
              child: Text(label,
                  style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
            ),
            Expanded(
              child: Text(value,
                  style: t.bodyLarge?.copyWith(
                      color: muted ? AppColors.ink3 : AppColors.ink)),
            ),
            _Badge(public: public),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded,
                  size: 20, color: AppColors.ink3),
            ],
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.public});
  final bool public;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
          color: public ? const Color(0xFFE7F2EA) : AppColors.sand,
          borderRadius: BorderRadius.circular(6)),
      child: Text(public ? 'Public' : 'Private',
          style: TextStyle(
              fontFamily: AppFonts.text,
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: public ? AppColors.matchDark : AppColors.ink2)),
    );
  }
}

// ── Pickers ───────────────────────────────────────────────────────────────────

void _pickFromList(BuildContext context, String title, List<String> options,
    String current, ValueChanged<String> onPick) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.canvas,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet))),
    builder: (ctx) {
      final t = Theme.of(ctx).textTheme;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                    color: AppColors.ink3,
                    borderRadius: BorderRadius.circular(3))),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(title,
                      style: t.headlineSmall?.copyWith(fontSize: 20))),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final o in options)
                    InkWell(
                      onTap: () {
                        onPick(o);
                        Navigator.of(ctx).pop();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 14),
                        child: Row(
                          children: [
                            Expanded(
                                child: Text(o,
                                    style: t.bodyLarge?.copyWith(
                                        fontWeight: o == current
                                            ? FontWeight.w700
                                            : FontWeight.w400))),
                            if (o == current)
                              const Icon(Icons.check_rounded,
                                  color: AppColors.match, size: 20),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      );
    },
  );
}

void _pickHeight(
    BuildContext context, String current, ValueChanged<String> onPick) {
  var feet = 5;
  var inches = 6;
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.canvas,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet))),
    builder: (ctx) {
      final t = Theme.of(ctx).textTheme;
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
              const SizedBox(height: 14),
              Text('Your height',
                  style: t.headlineSmall?.copyWith(fontSize: 20)),
              SizedBox(
                height: 170,
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoPicker(
                        scrollController:
                            FixedExtentScrollController(initialItem: 1),
                        itemExtent: 40,
                        onSelectedItemChanged: (i) => feet = 4 + i,
                        children: const [
                          Center(child: Text('4 ft')),
                          Center(child: Text('5 ft')),
                          Center(child: Text('6 ft')),
                        ],
                      ),
                    ),
                    Expanded(
                      child: CupertinoPicker(
                        scrollController:
                            FixedExtentScrollController(initialItem: 6),
                        itemExtent: 40,
                        onSelectedItemChanged: (i) => inches = i,
                        children: [
                          for (var i = 0; i < 12; i++)
                            Center(child: Text('$i in')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  onPick('$feet\'$inches"');
                  Navigator.of(ctx).pop();
                },
                child: Container(
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(14)),
                  child: Text('Set height',
                      style: t.labelLarge?.copyWith(
                          color: AppColors.onInk,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
