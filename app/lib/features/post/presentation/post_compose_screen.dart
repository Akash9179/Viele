import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../feed/data/mock_feed.dart';

/// Single-screen Post compose (frontend, mock). Photos · caption · prefilled
/// aesthetics · lightweight item rows · public visibility (v1, Eugene). Publish
/// fires the required-to-post gate (height + hair + eye) then returns home.
/// See `docs/superpowers/specs/2026-06-15-post-flow-design.md`.
class PostComposeScreen extends StatelessWidget {
  const PostComposeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
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
                  onTap: () => _openPostGate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
                    decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(AppRadii.pill)),
                    child: Text('Share',
                        style: t.labelLarge?.copyWith(
                            color: AppColors.onInk, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.line),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
              children: [
                _Photos(),
                const _Label('Caption'),
                TextField(
                  maxLines: null,
                  style: t.bodyLarge?.copyWith(fontSize: 14.5, height: 1.4),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: 'Cream knit + tailored trousers — my go-to for…',
                    hintStyle: t.bodyLarge?.copyWith(
                        fontSize: 14.5, color: AppColors.ink3, height: 1.4),
                  ),
                ),
                const _Label('Aesthetics · from your profile'),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    _chip('Quiet Luxury', on: true),
                    _chip('Minimal', on: true),
                    _chip('+ add', on: false),
                  ],
                ),
                const _Label('Items'),
                const _ItemRow(name: 'Cropped knit sweater', sub: 'COS · link added'),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  child: Row(
                    children: [
                      const Icon(Icons.add, size: 17, color: AppColors.ink2),
                      const SizedBox(width: 8),
                      Text('Add item · name, brand, link',
                          style: t.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600, fontSize: 13.5)),
                    ],
                  ),
                ),
                const _Label('Visibility'),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.circular(AppRadii.field),
                      border: Border.all(color: AppColors.line)),
                  child: Row(
                    children: [
                      const Icon(Icons.public_rounded, size: 19, color: AppColors.match),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Public',
                                style: t.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w700, fontSize: 14)),
                            Text('Anyone can discover this — that\'s how matching works in v1.',
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

  Widget _chip(String label, {required bool on}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: on ? AppColors.ink : AppColors.paper,
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

class _Photos extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget thumb(String url, double w, double h) => ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
              imageUrl: url,
              width: w,
              height: h,
              fit: BoxFit.cover,
              placeholder: (_, _) => const ColoredBox(color: AppColors.sand)),
        );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            thumb(mockFeed[0].imageUrl, 118, 158),
            Positioned(
              left: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                    color: const Color(0xB3140F08),
                    borderRadius: BorderRadius.circular(AppRadii.pill)),
                child: const Text('Cover',
                    style: TextStyle(
                        fontFamily: AppFonts.text,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        Column(
          children: [
            thumb(mockFeed[3].imageUrl, 74, 75),
            const SizedBox(height: 8),
            Container(
              width: 74,
              height: 75,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                    color: AppColors.ink3,
                    width: 1.5,
                    style: BorderStyle.solid),
              ),
              child: const Icon(Icons.add, color: AppColors.ink2),
            ),
          ],
        ),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.name, required this.sub});
  final String name, sub;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.line))),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
                color: AppColors.sand, borderRadius: BorderRadius.circular(9)),
            child: const Icon(Icons.checkroom_rounded, size: 17, color: AppColors.ink2),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: t.bodyLarge?.copyWith(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                Text(sub, style: t.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.north_east_rounded, size: 15, color: AppColors.ink3),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 18, 0, 8),
      child: Text(text.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.2)),
    );
  }
}

/// Required-to-post gate: height + hair + eye before publishing.
void _openPostGate(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.canvas,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet))),
    builder: (ctx) {
      final t = Theme.of(ctx).textTheme;
      Widget seg(List<String> opts, int sel) => Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (var i = 0; i < opts.length; i++)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                  decoration: BoxDecoration(
                    color: i == sel ? AppColors.ink : AppColors.paper,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: i == sel ? AppColors.ink : AppColors.line),
                  ),
                  child: Text(opts[i],
                      style: TextStyle(
                          fontFamily: AppFonts.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: i == sel ? AppColors.onInk : AppColors.ink2)),
                ),
            ],
          );
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
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
              Text('One quick thing before you post',
                  style: t.headlineSmall?.copyWith(fontSize: 20)),
              const SizedBox(height: 6),
              Text(
                  'Posts are stamped with your shape & coloring so they match the right people. We just need three:',
                  style: t.bodyMedium),
              const SizedBox(height: 16),
              Text('HEIGHT', style: t.labelSmall),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                    color: AppColors.paper,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.line)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("5'6\"", style: t.bodyLarge),
                    Text('tap to scroll ›',
                        style: t.bodyMedium?.copyWith(color: AppColors.ink3)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text('HAIR', style: t.labelSmall),
              const SizedBox(height: 6),
              seg(const ['Black', 'Brown', 'Blonde', 'Red', 'Gray'], 1),
              const SizedBox(height: 14),
              Text('EYES', style: t.labelSmall),
              const SizedBox(height: 6),
              seg(const ['Brown', 'Hazel', 'Blue', 'Green'], 1),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Navigator.of(ctx).pop();
                  ctx.go('/home');
                },
                child: Container(
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: AppColors.ink, borderRadius: BorderRadius.circular(14)),
                  child: Text('Save & publish',
                      style: t.labelLarge?.copyWith(
                          color: AppColors.onInk, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
