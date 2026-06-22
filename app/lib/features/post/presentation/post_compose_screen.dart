import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/data/post_repository.dart';
import '../../../core/theme/tokens.dart';
import '../../feed/data/feed_repository.dart';
import '../../onboarding/data/onboarding_data.dart';

/// Single-screen Post compose. Real photo capture (gallery + camera) → upload to
/// the private `post-media` Storage bucket + insert `posts`/`posts_private` via
/// [PostRepository]. Big cover preview + cover selection · on-photo item tagging
/// · caption + selectable aesthetics · item rows · public visibility (v1).
/// Video is V2 (per the approved spec) — not offered here.
class PostComposeScreen extends ConsumerStatefulWidget {
  const PostComposeScreen({super.key});

  @override
  ConsumerState<PostComposeScreen> createState() => _PostComposeScreenState();
}

class _Item {
  const _Item(this.name, this.brand);
  final String name;
  final String brand;
}

/// Debug-only: start the compose list scrolled, for screenshots
/// (`--dart-define=SCROLL=520`). Defaults to 0 (top).
const _kScroll = int.fromEnvironment('SCROLL');

class _PostComposeScreenState extends ConsumerState<PostComposeScreen> {
  late final _scroll =
      ScrollController(initialScrollOffset: _kScroll.toDouble());
  final _picker = ImagePicker();
  final _caption = TextEditingController();

  final List<String> _media = []; // local file paths
  int _cover = 0;
  final Set<String> _aesthetics = {'Quiet Luxury', 'Off-Duty'};
  final List<_Item> _items = [];
  bool _saving = false;

  void _setCover(int i) => setState(() => _cover = i);

  void _removeMedia(int i) {
    setState(() {
      _media.removeAt(i);
      if (_cover >= _media.length) _cover = math.max(0, _media.length - 1);
    });
  }

  Future<void> _addPhotos() async {
    try {
      final picked = await _picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1440,
        maxHeight: 1440,
      );
      if (picked.isEmpty) return;
      setState(() {
        _media.addAll(picked.map((x) => x.path));
        _cover = _media.length - picked.length;
      });
    } catch (_) {
      _toast("Couldn't open your photos.");
    }
  }

  Future<void> _takePhoto() async {
    try {
      final x = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1440,
        maxHeight: 1440,
      );
      if (x == null) return;
      setState(() {
        _media.add(x.path);
        _cover = _media.length - 1;
      });
    } catch (_) {
      _toast("Couldn't open the camera.");
    }
  }

  void _tagItems() =>
      _openAddItem(context, (item) => setState(() => _items.add(item)));

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        content: Text(m),
      ));

  Future<void> _publish() async {
    if (_saving) return;
    if (_media.isEmpty) return _toast('Add at least one photo.');
    if (_aesthetics.isEmpty) return _toast('Pick at least one aesthetic.');
    setState(() => _saving = true);
    // Cover photo goes first.
    final ordered = [
      _media[_cover],
      for (var i = 0; i < _media.length; i++)
        if (i != _cover) _media[i],
    ];
    try {
      await ref.read(postRepositoryProvider).publish(
            imagePaths: ordered,
            caption: _caption.text.trim(),
            aesthetics: _aesthetics.toList(),
            items: [
              for (final it in _items) {'name': it.name, 'brand': it.brand}
            ],
          );
      if (!mounted) return;
      ref.invalidate(feedProvider); // show the new post in the feed
      _toast('Posted! ✨');
      context.go('/home');
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast("Couldn't publish your post. Please try again.");
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _caption.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final canShare = _media.isNotEmpty && !_saving;
    return SafeArea(
      child: Column(
        children: [
          // Nav bar
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => context.go('/home'),
                  child: Text('Cancel',
                      style: t.bodyLarge?.copyWith(color: AppColors.ink2)),
                ),
                Text('New post', style: t.headlineSmall?.copyWith(fontSize: 16)),
                GestureDetector(
                  onTap: canShare ? _publish : null,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                        color: canShare ? AppColors.ink : AppColors.ink3,
                        borderRadius: BorderRadius.circular(AppRadii.pill)),
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.onInk))
                        : Text('Share',
                            style: t.labelLarge?.copyWith(
                                color: AppColors.onInk,
                                fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.line),
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                if (_media.isEmpty)
                  _emptyHero(t)
                else ...[
                  _coverPreview(t),
                  const SizedBox(height: 12),
                  _thumbStrip(),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      _media.length > 1
                          ? 'This is your cover — tap a photo below to change it'
                          : 'This is how your look appears in the feed',
                      style: t.bodySmall?.copyWith(color: AppColors.ink3),
                    ),
                  ),
                ],

                // Caption — its own section.
                _SectionCard(
                  label: 'Caption',
                  child: TextField(
                    controller: _caption,
                    maxLines: null,
                    minLines: 2,
                    style: t.bodyLarge?.copyWith(fontSize: 14.5, height: 1.45),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText:
                          'Cream knit + tailored trousers — my go-to for grey days…',
                      hintStyle: t.bodyLarge?.copyWith(
                          fontSize: 14.5, color: AppColors.ink3, height: 1.45),
                    ),
                  ),
                ),

                // Aesthetics — selectable (≥1 required).
                _SectionCard(
                  label: 'Aesthetics',
                  trailing: '${_aesthetics.length} selected',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final a in aesthetics)
                        GestureDetector(
                          onTap: () => setState(() {
                            _aesthetics.contains(a.name)
                                ? _aesthetics.remove(a.name)
                                : _aesthetics.add(a.name);
                          }),
                          child: _chip(a.name,
                              on: _aesthetics.contains(a.name)),
                        ),
                    ],
                  ),
                ),

                // Items — tied to the photo tags.
                _SectionCard(
                  label: 'Items in this look',
                  trailing: _items.isEmpty ? null : '${_items.length} tagged',
                  child: Column(
                    children: [
                      for (final it in _items)
                        _ItemRow(name: it.name, brand: it.brand),
                      GestureDetector(
                        onTap: _tagItems,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: EdgeInsets.only(top: _items.isEmpty ? 0 : 10),
                          child: Row(
                            children: [
                              const Icon(Icons.add_circle_outline_rounded,
                                  size: 18, color: AppColors.ink),
                              const SizedBox(width: 8),
                              Text('Add an item · name, brand, link',
                                  style: t.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.5,
                                      color: AppColors.ink)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Visibility (v1 = public only).
                _SectionCard(
                  label: 'Visibility',
                  child: Row(
                    children: [
                      const Icon(Icons.public_rounded,
                          size: 20, color: AppColors.match),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Public',
                                style: t.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w700, fontSize: 14)),
                            Text(
                                "Anyone can discover this look — it's how we match you to people like you.",
                                style: t.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: AppColors.sand,
                      borderRadius: BorderRadius.circular(AppRadii.field)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lock_outline_rounded,
                          size: 15, color: AppColors.ink2),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your shape, height & coloring show with this post. Weight stays private. Posting agrees to the Community Guidelines.',
                          style: t.bodySmall?.copyWith(height: 1.45),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty state (no media yet) ─────────────────────────────────────────────

  Widget _emptyHero(TextTheme t) {
    Widget btn(IconData icon, String label, bool filled, VoidCallback onTap) {
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: filled ? AppColors.ink : AppColors.canvas,
              borderRadius: BorderRadius.circular(12),
              border:
                  filled ? null : Border.all(color: AppColors.ink, width: 1.4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    size: 18, color: filled ? AppColors.onInk : AppColors.ink),
                const SizedBox(width: 8),
                Text(label,
                    style: TextStyle(
                        fontFamily: AppFonts.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: filled ? AppColors.onInk : AppColors.ink)),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 4 / 5,
          child: DottedSurface(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 66,
                    height: 66,
                    decoration: const BoxDecoration(
                        color: AppColors.sand, shape: BoxShape.circle),
                    child: const Icon(Icons.add_a_photo_outlined,
                        size: 27, color: AppColors.ink2),
                  ),
                  const SizedBox(height: 16),
                  Text('Add your first look',
                      style: t.headlineSmall?.copyWith(fontSize: 20)),
                  const SizedBox(height: 6),
                  Text(
                    'Outfits on people built like you start here. Add a photo from your library or take one now.',
                    textAlign: TextAlign.center,
                    style: t.bodyLarge?.copyWith(
                        fontSize: 13.5, color: AppColors.ink2, height: 1.45),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      btn(Icons.photo_library_outlined, 'Add photo', true,
                          _addPhotos),
                      const SizedBox(width: 10),
                      btn(Icons.photo_camera_outlined, 'Camera', false,
                          _takePhoto),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lightbulb_outline_rounded,
                size: 14, color: AppColors.ink3),
            const SizedBox(width: 7),
            Flexible(
              child: Text('Full-length shots help people see the fit.',
                  style: t.bodySmall?.copyWith(color: AppColors.ink3)),
            ),
          ],
        ),
      ],
    );
  }

  // ── Big cover preview (how the post looks) ─────────────────────────────────

  Widget _coverPreview(TextTheme t) {
    const spots = [
      Alignment(-0.35, 0.15),
      Alignment(0.4, -0.25),
      Alignment(0.1, 0.55),
      Alignment(-0.45, -0.45),
    ];

    return AspectRatio(
      aspectRatio: 4 / 5,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.card)),
          boxShadow: AppShadows.card,
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(AppRadii.card)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(File(_media[_cover]), fit: BoxFit.cover),
              for (var i = 0; i < math.min(_items.length, spots.length); i++)
                Align(alignment: spots[i], child: const _TagPin()),
              Positioned(top: 12, left: 12, child: _badge('COVER')),
              Positioned(
                right: 12,
                bottom: 12,
                child: GestureDetector(
                  onTap: _tagItems,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                        color: const Color(0xF2140F08),
                        borderRadius: BorderRadius.circular(AppRadii.pill)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_offer_outlined,
                            size: 15, color: Colors.white),
                        SizedBox(width: 6),
                        Text('Tag items',
                            style: TextStyle(
                                fontFamily: AppFonts.text,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
            color: const Color(0xCC140F08),
            borderRadius: BorderRadius.circular(AppRadii.pill)),
        child: Text(text,
            style: const TextStyle(
                fontFamily: AppFonts.text,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: Colors.white)),
      );

  // ── Thumbnail strip: pick cover, remove, add photo/camera ──────────────────

  Widget _thumbStrip() {
    return SizedBox(
      height: 78,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (var i = 0; i < _media.length; i++) _thumb(i),
          _addTile(Icons.photo_library_outlined, 'Photo', _addPhotos),
          const SizedBox(width: 10),
          _addTile(Icons.photo_camera_outlined, 'Camera', _takePhoto),
        ],
      ),
    );
  }

  Widget _thumb(int i) {
    final isCover = i == _cover;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () => _setCover(i),
        child: SizedBox(
          width: 62,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isCover ? AppColors.ink : AppColors.line,
                      width: isCover ? 2 : 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: SizedBox(
                    width: 62,
                    height: 78,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(File(_media[i]), fit: BoxFit.cover),
                        if (isCover)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              color: const Color(0xCC140F08),
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: const Text('Cover',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontFamily: AppFonts.text,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -6,
                right: -6,
                child: GestureDetector(
                  onTap: () => _removeMedia(i),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.canvas, width: 1.5),
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 12, color: AppColors.onInk),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _addTile(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 62,
        height: 78,
        child: DottedSurface(
          radius: 12,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 19, color: AppColors.ink2),
              const SizedBox(height: 4),
              Text(label,
                  style: const TextStyle(
                      fontFamily: AppFonts.text,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink2)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, {required bool on}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: on ? AppColors.ink : AppColors.canvas,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: on ? null : Border.all(color: AppColors.line),
        ),
        child: Text(label,
            style: TextStyle(
              fontFamily: AppFonts.text,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: on ? AppColors.onInk : AppColors.ink2,
            )),
      );
}

// ── Reusable pieces ───────────────────────────────────────────────────────────

/// A labeled, visually distinct section block (paper card) — keeps caption /
/// aesthetics / items from blending into one flat list.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.label, required this.child, this.trailing});
  final String label;
  final String? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 8),
            child: Row(
              children: [
                Text(label.toUpperCase(),
                    style: t.labelSmall?.copyWith(letterSpacing: 1.2)),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  Text(trailing!,
                      style: t.bodySmall?.copyWith(color: AppColors.ink3)),
                ],
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(AppRadii.chip),
              border: Border.all(color: AppColors.line),
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// Solid-bordered surface for empty/add affordances.
class DottedSurface extends StatelessWidget {
  const DottedSurface(
      {super.key, required this.child, this.radius = AppRadii.card});
  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.ink3, width: 1.4),
      ),
      child: child,
    );
  }
}

class _TagPin extends StatelessWidget {
  const _TagPin();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        shape: BoxShape.circle,
        boxShadow: AppShadows.soft,
      ),
      child: const Icon(Icons.local_offer_rounded,
          size: 12, color: AppColors.ink),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.name, required this.brand});
  final String name, brand;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.line))),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
                color: AppColors.sand, borderRadius: BorderRadius.circular(9)),
            child: const Icon(Icons.checkroom_rounded,
                size: 17, color: AppColors.ink2),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: t.bodyLarge?.copyWith(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                Text(brand.isEmpty ? 'Add brand · link' : brand,
                    style: t.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.drag_indicator_rounded,
              size: 17, color: AppColors.ink3),
        ],
      ),
    );
  }
}

/// Add-item sheet — name + brand (+ link).
void _openAddItem(BuildContext context, ValueChanged<_Item> onAdd) {
  final nameCtl = TextEditingController();
  final brandCtl = TextEditingController();
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.canvas,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet))),
    builder: (ctx) {
      final t = Theme.of(ctx).textTheme;
      Widget field(String label, TextEditingController c, String hint) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(), style: t.labelSmall),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                    color: AppColors.paper,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.line)),
                child: TextField(
                  controller: c,
                  style: t.bodyLarge,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: hint,
                    hintStyle: t.bodyLarge?.copyWith(color: AppColors.ink3),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
          );
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
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
                Text('Tag an item', style: t.headlineSmall?.copyWith(fontSize: 20)),
                const SizedBox(height: 4),
                Text('Help people shop the look.', style: t.bodyMedium),
                const SizedBox(height: 16),
                field('Item', nameCtl, 'e.g. Cropped knit sweater'),
                field('Brand · link', brandCtl, 'e.g. COS · cos.com/…'),
                GestureDetector(
                  onTap: () {
                    final name = nameCtl.text.trim();
                    if (name.isNotEmpty) onAdd(_Item(name, brandCtl.text.trim()));
                    Navigator.of(ctx).pop();
                  },
                  child: Container(
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(14)),
                    child: Text('Add item',
                        style: t.labelLarge?.copyWith(
                            color: AppColors.onInk, fontWeight: FontWeight.w700)),
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
