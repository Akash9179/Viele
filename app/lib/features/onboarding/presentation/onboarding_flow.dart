import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../feed/data/mock_feed.dart';
import '../data/onboarding_data.dart';
import 'widgets/silhouette_icon.dart';

/// The value-first onboarding flow (frontend-only; selections held in memory).
/// teaser (body chart → aesthetics → silhouette → skin tone) → wow feed →
/// account → basics → finish profile. See `docs/superpowers/specs/2026-06-09-
/// onboarding-flow-design.md` + `docs/brand.md` (inclusivity ethos).
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

/// Debug-only: jump to a step for screenshots (`--dart-define=START=n`).
const _kStartStep = int.fromEnvironment('START');

class _OnboardingFlowState extends State<OnboardingFlow> {
  late final _page = PageController(initialPage: _kStartStep);
  int _index = _kStartStep;

  // Selections (in-memory only).
  BodyTypeSet _bodyType = BodyTypeSet.women;
  final Set<String> _aesthetics = {'Quiet Luxury', 'Off-Duty', 'Dark Academia'};
  SilhouetteShape? _silhouette = SilhouetteShape.hourglass;
  int? _skinTone = 3;
  String _hair = 'Brown';
  String _eye = 'Hazel';
  String _height = "5'6\"";

  static const _last = 8;

  void _next() {
    if (_index >= _last) {
      context.go('/home');
      return;
    }
    setState(() => _index++);
    _page.animateToPage(_index,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
  }

  void _back() {
    if (_index == 0) return;
    setState(() => _index--);
    _page.animateToPage(_index,
        duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _page,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _Welcome(onStart: _next, onHaveAccount: () => context.go('/home')),
          _Teaser(
            step: 1,
            title: 'Which body chart fits you?',
            subtitle:
                'Just picks which silhouette options to show. Not the same as gender — that\'s optional later.',
            onContinue: _next,
            onBack: _back,
            child: _BodyTypeChoice(
              value: _bodyType,
              onChanged: (v) => setState(() => _bodyType = v),
            ),
          ),
          _Teaser(
            step: 2,
            eyebrow: 'Your taste · pick 3+',
            title: 'What are you drawn to?',
            onContinue: _aesthetics.length >= 3 ? _next : null,
            ctaLabel: 'Continue · ${_aesthetics.length} selected',
            onBack: _back,
            child: _AestheticsGrid(
              selected: _aesthetics,
              onToggle: (name) => setState(() {
                _aesthetics.contains(name)
                    ? _aesthetics.remove(name)
                    : _aesthetics.add(name);
              }),
            ),
          ),
          _Teaser(
            step: 3,
            eyebrow: 'Your shape · optional',
            title: 'Which feels closest?',
            subtitle:
                'No better or worse — every shape is welcome. Tap the one that feels right, or skip.',
            reassure: 'Used only to match you. Change or remove it anytime.',
            onContinue: _next,
            onBack: _back,
            onSkip: _next,
            child: _SilhouetteGrid(
              value: _silhouette,
              onChanged: (v) => setState(() => _silhouette = v),
            ),
          ),
          _Teaser(
            step: 4,
            eyebrow: 'Your coloring · optional',
            title: 'What\'s your skin tone?',
            subtitle:
                'Tap the closest — we match on warmth and depth, never an exact value, so there\'s no wrong answer.',
            reassure: 'Helps show looks that flatter your coloring. Adjustable anytime.',
            ctaLabel: 'See my feed →',
            onContinue: _next,
            onBack: _back,
            onSkip: _next,
            child: _SkinToneRow(
              value: _skinTone,
              onChanged: (v) => setState(() => _skinTone = v),
            ),
          ),
          _Wow(onContinue: _next),
          _Account(onContinue: _next),
          _Basics(onContinue: _next),
          _Finish(
            height: _height,
            hair: _hair,
            eye: _eye,
            onHeight: (v) => setState(() => _height = v),
            onHair: (v) => setState(() => _hair = v),
            onEye: (v) => setState(() => _eye = v),
            onDone: () => context.go('/home'),
            onSkip: () => context.go('/home'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Shared building blocks
// ─────────────────────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(label,
              style: const TextStyle(
                fontFamily: AppFonts.text,
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                color: AppColors.onInk,
              )),
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.step});
  final int step; // 1..4
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s24, 8, AppSpacing.s24, 0),
      child: Row(
        children: [
          for (var i = 1; i <= 4; i++) ...[
            if (i > 1) const SizedBox(width: 5),
            Expanded(
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: i <= step ? AppColors.ink : AppColors.line,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Standard teaser step: optional progress, back/skip, title block, content, CTA.
class _Teaser extends StatelessWidget {
  const _Teaser({
    required this.step,
    required this.title,
    required this.child,
    required this.onContinue,
    required this.onBack,
    this.subtitle,
    this.eyebrow,
    this.reassure,
    this.ctaLabel = 'Continue',
    this.onSkip,
  });

  final int step;
  final String title;
  final String? subtitle;
  final String? eyebrow;
  final String? reassure;
  final String ctaLabel;
  final Widget child;
  final VoidCallback? onContinue;
  final VoidCallback onBack;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 18, color: AppColors.ink),
              ),
              if (onSkip != null)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.s16),
                  child: GestureDetector(
                    onTap: onSkip,
                    child: Text('Skip',
                        style: t.bodyLarge?.copyWith(
                            color: AppColors.ink2, fontWeight: FontWeight.w600)),
                  ),
                ),
            ],
          ),
          _Progress(step: step),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.s24, 16, AppSpacing.s24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(eyebrow ?? 'Tell us about you',
                    style: t.labelSmall?.copyWith(letterSpacing: 1.8)),
                const SizedBox(height: 8),
                Text(title, style: t.displayLarge?.copyWith(fontSize: 26)),
                if (subtitle != null) ...[
                  const SizedBox(height: 7),
                  Text(subtitle!, style: t.bodyLarge?.copyWith(color: AppColors.ink2)),
                ],
              ],
            ),
          ),
          Expanded(child: SingleChildScrollView(child: child)),
          if (reassure != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.s24, 0, AppSpacing.s24, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lock_outline_rounded,
                      size: 15, color: AppColors.match),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(reassure!,
                          style: t.bodySmall?.copyWith(color: AppColors.ink2))),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.s24, 4, AppSpacing.s24, AppSpacing.s20),
            child: _PrimaryButton(label: ctaLabel, onTap: onContinue),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Steps
// ─────────────────────────────────────────────────────────────────────────

class _Welcome extends StatelessWidget {
  const _Welcome({required this.onStart, required this.onHaveAccount});
  final VoidCallback onStart;
  final VoidCallback onHaveAccount;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl:
              'https://images.unsplash.com/photo-1534404483017-8743b4e935cd?w=820&h=1400&fit=crop&q=80',
          fit: BoxFit.cover,
          placeholder: (_, _) => const ColoredBox(color: AppColors.sand),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [AppColors.canvas, Color(0x80F6F1E8), Color(0x00F6F1E8)],
              stops: [0.16, 0.40, 0.62],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.s24, 0, AppSpacing.s24, AppSpacing.s24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('VIELE',
                    style: t.labelSmall?.copyWith(
                        fontSize: 13, letterSpacing: 3, color: AppColors.ink2)),
                const SizedBox(height: 6),
                Text('Outfits on people built like you.',
                    style: t.displayLarge?.copyWith(fontSize: 34, height: 1.05)),
                const SizedBox(height: 12),
                Text(
                  'See real looks worn by people with your shape, coloring, and aesthetic — in about a minute. No account needed.',
                  style: t.bodyLarge?.copyWith(color: const Color(0xFF4A4236)),
                ),
                const SizedBox(height: 22),
                _PrimaryButton(label: 'Find my style', onTap: onStart),
                const SizedBox(height: 4),
                Center(
                  child: TextButton(
                    onPressed: onHaveAccount,
                    child: Text('I already have an account',
                        style: t.bodyLarge?.copyWith(
                            color: AppColors.ink2, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BodyTypeChoice extends StatelessWidget {
  const _BodyTypeChoice({required this.value, required this.onChanged});
  final BodyTypeSet value;
  final ValueChanged<BodyTypeSet> onChanged;

  @override
  Widget build(BuildContext context) {
    const items = [
      (BodyTypeSet.women, 'Women', 'Hourglass, pear, rectangle…'),
      (BodyTypeSet.men, 'Men', 'Athletic, triangle, oval…'),
      (BodyTypeSet.both, 'Show me both', 'Draw from every shape'),
    ];
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s24, 22, AppSpacing.s24, 0),
      child: Column(
        children: [
          for (final it in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => onChanged(it.$1),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: value == it.$1 ? Colors.white : AppColors.paper,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: value == it.$1 ? AppColors.ink : AppColors.line,
                        width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(it.$2,
                                style: t.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w700, fontSize: 16)),
                            const SizedBox(height: 2),
                            Text(it.$3, style: t.bodyMedium),
                          ],
                        ),
                      ),
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: value == it.$1 ? AppColors.ink : Colors.transparent,
                          border: Border.all(
                              color: value == it.$1 ? AppColors.ink : AppColors.line,
                              width: 1.5),
                        ),
                        child: value == it.$1
                            ? const Icon(Icons.check, size: 14, color: AppColors.onInk)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AestheticsGrid extends StatelessWidget {
  const _AestheticsGrid({required this.selected, required this.onToggle});
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s24, 18, AppSpacing.s24, 0),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.6,
        children: [
          for (final a in aesthetics)
            GestureDetector(
              onTap: () => onToggle(a.name),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: aestheticImages[a.name]!,
                      fit: BoxFit.cover,
                      color: Colors.black.withValues(alpha: 0.14),
                      colorBlendMode: BlendMode.darken,
                      placeholder: (_, _) => const ColoredBox(color: AppColors.sand),
                    ),
                    Positioned(
                      left: 9,
                      bottom: 8,
                      child: Text(a.name,
                          style: const TextStyle(
                            fontFamily: AppFonts.text,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          )),
                    ),
                    if (selected.contains(a.name))
                      Positioned(
                        top: 7,
                        right: 7,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                              color: AppColors.match, shape: BoxShape.circle),
                          child: const Icon(Icons.check, size: 12, color: Colors.white),
                        ),
                      ),
                    if (selected.contains(a.name))
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.ink, width: 3),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SilhouetteGrid extends StatelessWidget {
  const _SilhouetteGrid({required this.value, required this.onChanged});
  final SilhouetteShape? value;
  final ValueChanged<SilhouetteShape> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s24, 20, AppSpacing.s24, 0),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 11,
        crossAxisSpacing: 11,
        childAspectRatio: 1.18,
        children: [
          for (final s in SilhouetteShape.values)
            GestureDetector(
              onTap: () => onChanged(s),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: value == s ? Colors.white : AppColors.paper,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: value == s ? AppColors.ink : AppColors.line,
                      width: 1.5),
                ),
                child: Row(
                  children: [
                    SilhouetteIcon(shape: s, selected: value == s),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(silhouetteLabels[s]!,
                              style: t.bodyLarge?.copyWith(
                                  fontSize: 14.5,
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(silhouetteDescriptors[s]!,
                              style: t.bodySmall?.copyWith(
                                  color: AppColors.ink2, height: 1.2)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SkinToneRow extends StatelessWidget {
  const _SkinToneRow({required this.value, required this.onChanged});
  final int? value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s24, 26, AppSpacing.s24, 0),
      child: Wrap(
        spacing: 12,
        runSpacing: 14,
        alignment: WrapAlignment.center,
        children: [
          for (var i = 0; i < monkTones.length; i++)
            GestureDetector(
              onTap: () => onChanged(i),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: monkTones[i],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black.withValues(alpha: 0.06), width: 2),
                  boxShadow: value == i
                      ? const [
                          BoxShadow(color: AppColors.ink, spreadRadius: 2.5, blurRadius: 0)
                        ]
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Wow extends StatelessWidget {
  const _Wow({required this.onContinue});
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SafeArea(
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.s20, 12, AppSpacing.s20, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CURATED FOR YOU',
                          style: t.labelSmall?.copyWith(letterSpacing: 1.8)),
                      const SizedBox(height: 3),
                      Text('Outfits on people like you', style: t.titleLarge),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.s20, 10, AppSpacing.s20, 100),
                sliver: SliverGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.7,
                  children: [
                    for (final p in mockFeed.take(4))
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                                imageUrl: p.imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, _) =>
                                    const ColoredBox(color: AppColors.sand)),
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(7, 3, 9, 3),
                                decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.95),
                                    borderRadius: BorderRadius.circular(999)),
                                child: Text('${p.matchPct}%',
                                    style: const TextStyle(
                                        fontFamily: AppFonts.text,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.ink)),
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
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: GestureDetector(
              onTap: onContinue,
              child: Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                    color: AppColors.ink, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.bookmark_border_rounded,
                          size: 16, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tap save to keep a look',
                              style: t.bodyLarge?.copyWith(
                                  color: AppColors.onInk,
                                  fontWeight: FontWeight.w600)),
                          Text('Free — we\'ll set up your account then',
                              style: t.bodySmall?.copyWith(
                                  color: const Color(0xB3F6F1E8))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Account extends StatelessWidget {
  const _Account({required this.onContinue});
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    Widget btn(String label, Color bg, Color fg, {IconData? icon, Border? border}) {
      return GestureDetector(
        onTap: onContinue,
        child: Container(
          height: 52,
          margin: const EdgeInsets.only(bottom: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: bg, borderRadius: BorderRadius.circular(15), border: border),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 18, color: fg), const SizedBox(width: 8)],
              Text(label,
                  style: TextStyle(
                      fontFamily: AppFonts.text,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: fg)),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.s24, 24, AppSpacing.s24, AppSpacing.s24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('KEEP YOUR STYLE', style: t.labelSmall?.copyWith(letterSpacing: 1.8)),
            const SizedBox(height: 8),
            Text('Save your looks &\nget your matches',
                style: t.displayLarge?.copyWith(fontSize: 28)),
            const SizedBox(height: 7),
            Text('Your style profile carries over. One tap.',
                style: t.bodyLarge?.copyWith(color: AppColors.ink2)),
            const Spacer(),
            btn('Continue with Apple', Colors.black, Colors.white, icon: Icons.apple),
            btn('Continue with Google', Colors.white, const Color(0xFF1F1F1F),
                icon: Icons.g_mobiledata_rounded,
                border: Border.all(color: AppColors.line)),
            btn('Sign up with email', AppColors.canvas, AppColors.ink,
                border: Border.all(color: AppColors.ink, width: 1.5)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                  color: AppColors.sand, borderRadius: BorderRadius.circular(12)),
              child: Text.rich(
                TextSpan(children: [
                  const TextSpan(text: 'Your style profile (shape, height, coloring, aesthetic) is '),
                  TextSpan(text: 'public', style: t.bodySmall?.copyWith(fontWeight: FontWeight.w700, color: AppColors.ink)),
                  const TextSpan(text: ' and shown with your posts. '),
                  TextSpan(text: 'Weight stays private', style: t.bodySmall?.copyWith(fontWeight: FontWeight.w700, color: AppColors.ink)),
                  const TextSpan(text: ' — used only to improve matches.'),
                ]),
                style: t.bodySmall?.copyWith(color: AppColors.ink2, height: 1.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Basics extends StatelessWidget {
  const _Basics({required this.onContinue});
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return _FieldsScaffold(
      eyebrow: 'ALMOST THERE',
      title: 'Set up your profile',
      onCta: onContinue,
      ctaLabel: 'Continue',
      children: [
        _ReadonlyField(label: 'Name', tag: _Tag.public, value: 'Maya Chen'),
        _ReadonlyField(
            label: 'Username', tag: _Tag.public, value: '@mayachen', trailingOk: true),
        _ReadonlyField(label: 'Region', tag: _Tag.public, value: 'Select (optional)', muted: true),
      ],
    );
  }
}

class _Finish extends StatelessWidget {
  const _Finish({
    required this.height,
    required this.hair,
    required this.eye,
    required this.onHeight,
    required this.onHair,
    required this.onEye,
    required this.onDone,
    required this.onSkip,
  });

  final String height, hair, eye;
  final ValueChanged<String> onHeight, onHair, onEye;
  final VoidCallback onDone, onSkip;

  @override
  Widget build(BuildContext context) {
    return _FieldsScaffold(
      eyebrow: 'A FEW MORE · SHARPENS MATCHES',
      title: 'Finish your profile',
      onCta: onDone,
      ctaLabel: 'Done',
      onSkip: onSkip,
      children: [
        _TapField(
            label: 'Height',
            tag: _Tag.public,
            value: height,
            onTap: () => _openHeightWheel(context, height, onHeight)),
        _TapField(
            label: 'Hair',
            tag: _Tag.public,
            value: hair,
            swatch: hairColors.firstWhere((c) => c.name == hair).swatch,
            onTap: () => _openColorList(context, 'Hair color', hairColors, hair, onHair)),
        _TapField(
            label: 'Eyes',
            tag: _Tag.public,
            value: eye,
            swatch: eyeColors.firstWhere((c) => c.name == eye).swatch,
            onTap: () => _openColorList(context, 'Eye color', eyeColors, eye, onEye)),
        _ReadonlyField(
            label: 'Weight', tag: _Tag.private, value: 'Add (optional)', muted: true),
      ],
    );
  }
}

// ── Field scaffolding ──────────────────────────────────────────────────────

enum _Tag { public, private }

class _FieldsScaffold extends StatelessWidget {
  const _FieldsScaffold({
    required this.eyebrow,
    required this.title,
    required this.children,
    required this.onCta,
    required this.ctaLabel,
    this.onSkip,
  });
  final String eyebrow, title, ctaLabel;
  final List<Widget> children;
  final VoidCallback onCta;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (onSkip != null)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.s16, top: 4),
                child: GestureDetector(
                  onTap: onSkip,
                  child: Text('Skip for now',
                      style: t.bodyLarge?.copyWith(
                          color: AppColors.ink2, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                AppSpacing.s24, onSkip == null ? 24 : 8, AppSpacing.s24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(eyebrow, style: t.labelSmall?.copyWith(letterSpacing: 1.6)),
                const SizedBox(height: 8),
                Text(title, style: t.displayLarge?.copyWith(fontSize: 26)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.s24, 18, AppSpacing.s24, 0),
              child: Column(children: children),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.s24, 4, AppSpacing.s24, AppSpacing.s20),
            child: _PrimaryButton(label: ctaLabel, onTap: onCta),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, required this.tag});
  final String label;
  final _Tag tag;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final pub = tag == _Tag.public;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label.toUpperCase(),
            style: t.labelSmall?.copyWith(letterSpacing: 0.8)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
              color: pub ? const Color(0xFFE7F2EA) : AppColors.sand,
              borderRadius: BorderRadius.circular(6)),
          child: Text(pub ? 'Public' : 'Private · match only',
              style: TextStyle(
                  fontFamily: AppFonts.text,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: pub ? AppColors.matchDark : AppColors.ink2)),
        ),
      ],
    );
  }
}

class _ReadonlyField extends StatelessWidget {
  const _ReadonlyField({
    required this.label,
    required this.tag,
    required this.value,
    this.muted = false,
    this.trailingOk = false,
  });
  final String label, value;
  final _Tag tag;
  final bool muted, trailingOk;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label: label, tag: tag),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line)),
            child: Row(
              children: [
                Expanded(
                  child: Text(value,
                      style: t.bodyLarge?.copyWith(
                          color: muted ? AppColors.ink3 : AppColors.ink)),
                ),
                if (trailingOk)
                  const Text('✓ available',
                      style: TextStyle(
                          fontFamily: AppFonts.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.match))
                else if (muted)
                  const Icon(Icons.chevron_right_rounded, color: AppColors.ink3),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TapField extends StatelessWidget {
  const _TapField({
    required this.label,
    required this.tag,
    required this.value,
    required this.onTap,
    this.swatch,
  });
  final String label, value;
  final _Tag tag;
  final VoidCallback onTap;
  final Color? swatch;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label: label, tag: tag),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.line)),
              child: Row(
                children: [
                  if (swatch != null) ...[
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(color: swatch, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 9),
                  ],
                  Expanded(child: Text(value, style: t.bodyLarge)),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.ink3),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pickers (native iOS controls) ───────────────────────────────────────────

void _openHeightWheel(BuildContext context, String current, ValueChanged<String> onPick) {
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
          padding: const EdgeInsets.fromLTRB(AppSpacing.s24, 10, AppSpacing.s24, AppSpacing.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                        color: AppColors.ink3, borderRadius: BorderRadius.circular(3))),
              ),
              const SizedBox(height: 14),
              Text('Your height', style: t.displayLarge?.copyWith(fontSize: 21)),
              const SizedBox(height: 4),
              Text('Scroll to set it. Public on your profile.', style: t.bodyMedium),
              SizedBox(
                height: 170,
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(initialItem: 1),
                        itemExtent: 40,
                        onSelectedItemChanged: (i) => feet = 4 + i,
                        children: const [Text('4 ft'), Text('5 ft'), Text('6 ft')],
                      ),
                    ),
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(initialItem: 6),
                        itemExtent: 40,
                        onSelectedItemChanged: (i) => inches = i,
                        children: [for (var i = 0; i < 12; i++) Text('$i in')],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _PrimaryButton(
                  label: 'Set height',
                  onTap: () {
                    onPick("$feet'$inches\"");
                    Navigator.of(ctx).pop();
                  }),
            ],
          ),
        ),
      );
    },
  );
}

void _openColorList(BuildContext context, String title, List<ColorOption> options,
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
                    color: AppColors.ink3, borderRadius: BorderRadius.circular(3))),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(title, style: t.displayLarge?.copyWith(fontSize: 21))),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
                children: [
                  for (final c in options)
                    GestureDetector(
                      onTap: () {
                        onPick(c.name);
                        Navigator.of(ctx).pop();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: AppColors.line))),
                        child: Row(
                          children: [
                            Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                    color: c.swatch, shape: BoxShape.circle)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(c.name,
                                  style: t.bodyLarge?.copyWith(
                                      fontWeight: c.name == current
                                          ? FontWeight.w700
                                          : FontWeight.w400)),
                            ),
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: c.name == current ? AppColors.match : Colors.transparent,
                                border: Border.all(
                                    color: c.name == current ? AppColors.match : AppColors.line,
                                    width: 1.5),
                              ),
                            ),
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
