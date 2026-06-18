import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/profile_repository.dart';
import '../../../core/state/onboarding_draft.dart';
import '../../../core/state/session.dart';
import '../../../core/theme/tokens.dart';
import '../../feed/data/mock_feed.dart';
import '../data/onboarding_data.dart';
import 'email_auth_sheet.dart';
import 'widgets/silhouette_icon.dart';

/// The value-first onboarding flow (frontend-only; selections held in memory).
/// Just the teaser: body chart → aesthetics → silhouette → height → weight →
/// skin tone → undertone → drop straight into the live feed (no account).
/// Signing up is deferred to the first save/post — see [SignupFlow]. Refs:
/// `docs/superpowers/specs/2026-06-09-onboarding-flow-design.md` + `docs/brand.md`.
class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

/// Debug-only: jump to a step for screenshots (`--dart-define=START=n`).
const _kStartStep = int.fromEnvironment('START');

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  late final _page = PageController(initialPage: _kStartStep);
  int _index = _kStartStep;

  // Selections (in-memory only). The not-logged-in setup steps start unset so
  // people make a real choice — no skip, no implicit default (feedback 2026-06-16).
  BodyTypeSet _bodyType = BodyTypeSet.women;
  final Set<String> _aesthetics = {'Quiet Luxury', 'Off-Duty', 'Dark Academia'};
  SilhouetteShape? _silhouette;
  int? _skinTone;
  Undertone? _undertone;
  // Height (public) + weight (private, match-only) — collected in setup. Weight
  // is required here but never shown publicly (see docs/memory.md 2026-06-16).
  int _heightFeet = 5;
  int _heightInches = 6;
  int _weightLb = 150;
  static const _last = 7;

  void _next() {
    if (_index >= _last) {
      // Snapshot the anonymous teaser answers so they migrate into the profile
      // when/if the user creates an account later (SignupFlow reads this).
      ref.read(onboardingDraftProvider.notifier).set(OnboardingDraft(
            bodyType: _bodyType,
            aesthetics: _aesthetics.toList(),
            silhouette: _silhouette,
            skinToneIndex: _skinTone,
            undertone: _undertone,
            heightFeet: _heightFeet,
            heightInches: _heightInches,
            weightLb: _weightLb,
          ));
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
          _Welcome(
            onStart: _next,
            onHaveAccount: () async {
              final ok = await showEmailAuth(context, ref, signUp: false);
              if (ok == true && context.mounted) context.go('/home');
            },
          ),
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
            eyebrow: 'Your shape',
            title: 'Which feels closest?',
            subtitle:
                'No better or worse — every shape is welcome. Tap the one that feels right.',
            reassure: 'Used only to match you. Change it anytime.',
            onContinue: _silhouette != null ? _next : null,
            onBack: _back,
            child: _SilhouetteGrid(
              value: _silhouette,
              onChanged: (v) => setState(() => _silhouette = v),
            ),
          ),
          _Teaser(
            step: 4,
            eyebrow: 'Your measurements',
            title: 'How tall are you?',
            subtitle: 'Helps us put outfits on people built like you.',
            onContinue: _next,
            onBack: _back,
            child: _HeightWheel(
              feet: _heightFeet,
              inches: _heightInches,
              onChanged: (f, i) => setState(() {
                _heightFeet = f;
                _heightInches = i;
              }),
            ),
          ),
          _Teaser(
            step: 5,
            eyebrow: 'Your measurements',
            title: 'And your weight?',
            subtitle: 'Used only to sharpen your matches.',
            reassure: 'Private — matching only. Never shown on your profile.',
            onContinue: _next,
            onBack: _back,
            child: _WeightWheel(
              lb: _weightLb,
              onChanged: (v) => setState(() => _weightLb = v),
            ),
          ),
          _Teaser(
            step: 6,
            eyebrow: 'Your coloring',
            title: 'What\'s your skin tone?',
            subtitle:
                'Tap the closest — we match on closeness, never an exact value, so there\'s no wrong answer.',
            reassure: 'Tip: hold it next to your jaw or inner wrist in natural light.',
            onContinue: _skinTone != null ? _next : null,
            onBack: _back,
            child: _SkinToneRow(
              value: _skinTone,
              onChanged: (v) => setState(() => _skinTone = v),
            ),
          ),
          _Teaser(
            step: 7,
            eyebrow: 'Your coloring',
            title: 'And your undertone?',
            subtitle:
                'The other half of a good color match — it\'s why people at the same depth suit different palettes.',
            reassure: 'Check your inner-wrist veins: greenish leans warm, bluish leans cool.',
            ctaLabel: 'See my feed →',
            onContinue: _undertone != null ? _next : null,
            onBack: _back,
            child: _UndertoneChoice(
              value: _undertone,
              onChanged: (v) => setState(() => _undertone = v),
            ),
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
  final int step; // 1..7
  static const _total = 7;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s24, 8, AppSpacing.s24, 0),
      child: Row(
        children: [
          for (var i = 1; i <= _total; i++) ...[
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

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18, color: AppColors.ink),
            ),
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
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s24, 24, AppSpacing.s24, 0),
      child: Column(
        children: [
          Wrap(
            spacing: 13,
            runSpacing: 15,
            alignment: WrapAlignment.center,
            children: [
              for (var i = 0; i < monkTones.length; i++)
                GestureDetector(
                  onTap: () => onChanged(i),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: monkTones[i],
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.black.withValues(alpha: 0.06), width: 2),
                      boxShadow: value == i
                          ? const [
                              BoxShadow(color: AppColors.ink, spreadRadius: 3, blurRadius: 0)
                            ]
                          : null,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 22),
          // Confirm strip — shows the chosen tone larger so people can verify.
          if (value != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: monkTones[value!],
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.black.withValues(alpha: 0.08), width: 2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your tone · ${value! + 1} of 10',
                            style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 1),
                        Text('Tap a lighter or deeper swatch to fine-tune.',
                            style: t.bodySmall),
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
}

class _UndertoneChoice extends StatelessWidget {
  const _UndertoneChoice({required this.value, required this.onChanged});
  final Undertone? value;
  final ValueChanged<Undertone> onChanged;

  static const _cue = <Undertone, List<Color>>{
    Undertone.warm: [Color(0xFFE7C9A0), Color(0xFFD8A56A)],
    Undertone.cool: [Color(0xFFCBD4DE), Color(0xFFA9B7C6)],
    Undertone.neutral: [Color(0xFFE0D6C4), Color(0xFFBFC2BE)],
  };

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s24, 22, AppSpacing.s24, 0),
      child: Column(
        children: [
          for (final u in Undertone.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: GestureDetector(
                onTap: () => onChanged(u),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: value == u ? Colors.white : AppColors.paper,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: value == u ? AppColors.ink : AppColors.line,
                        width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: _cue[u]!),
                          border: Border.all(
                              color: Colors.black.withValues(alpha: 0.06)),
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(undertoneLabels[u]!,
                                style: t.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w700, fontSize: 16)),
                            const SizedBox(height: 1),
                            Text(undertoneHints[u]!, style: t.bodyMedium),
                          ],
                        ),
                      ),
                      if (value == u)
                        const Icon(Icons.check_circle_rounded,
                            color: AppColors.match, size: 22),
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

/// Account creation, shown when a guest tries to save or post (pushed as the
/// `/signup` route). Reuses the [_Account] → [_Basics] → [_Finish] screens.
/// Choosing a provider flips [sessionProvider]; the caller then completes the
/// pending action (e.g. applies the save the guest just tapped).
class SignupFlow extends ConsumerStatefulWidget {
  const SignupFlow({super.key});

  @override
  ConsumerState<SignupFlow> createState() => _SignupFlowState();
}

class _SignupFlowState extends ConsumerState<SignupFlow> {
  final _page = PageController();
  int _index = 0;
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _region = TextEditingController();
  String _hair = 'Brown';
  String _eye = 'Hazel';
  bool _saving = false;

  static const _last = 2;
  bool _debugAuthShown = false;

  void _next() {
    if (_index >= _last) {
      _complete();
      return;
    }
    // Leaving Basics (step 1) requires a username.
    if (_index == 1 && _username.text.trim().isEmpty) {
      _toast('Pick a username to continue.');
      return;
    }
    setState(() => _index++);
    _page.animateToPage(_index,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
  }

  /// Email tapped → real Supabase auth sheet. On success continue to basics.
  Future<void> _emailSignup() async {
    final ok = await showEmailAuth(context, ref, signUp: true);
    if (ok == true && mounted) _next();
  }

  /// Google/Apple aren't configured yet (need provider + native setup).
  void _oauthSoon() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      content: Text('Apple & Google sign-in are coming soon — use email for now.'),
    ));
  }

  void _toast(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        content: Text(msg),
      ));

  /// Finish: persist the profile (teaser draft + signup fields) then close so
  /// the pending save/post can complete. Skips creation if a profile already
  /// exists (e.g. an existing user signed in via the sheet).
  Future<void> _complete() async {
    if (_saving) return;
    final username = _username.text.trim();
    if (username.isEmpty) {
      _toast('Pick a username to continue.');
      return;
    }
    setState(() => _saving = true);
    final repo = ref.read(profileRepositoryProvider);
    try {
      if (!await repo.currentUserHasProfile()) {
        await repo.createFromDraft(
          draft: ref.read(onboardingDraftProvider),
          username: username,
          displayName: _name.text.trim().isEmpty ? username : _name.text.trim(),
          region: _region.text.trim(),
          hairColor: _hair,
          eyeColor: _eye,
        );
      }
      if (mounted) _close();
    } on PostgrestException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast(e.code == '23505'
          ? 'That username is taken — try another.'
          : "Couldn't save your profile. Please try again.");
      if (_index != 1) {
        setState(() => _index = 1);
        _page.jumpToPage(1);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast("Couldn't save your profile. Please try again.");
    }
  }

  void _close() {
    if (context.canPop()) context.pop();
  }

  @override
  void dispose() {
    _page.dispose();
    _name.dispose();
    _username.dispose();
    _region.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Debug-only: `--dart-define=AUTH=email` auto-opens the email sheet for
    // screenshots.
    if (const String.fromEnvironment('AUTH') == 'email' && !_debugAuthShown) {
      _debugAuthShown = true;
      Future.delayed(const Duration(milliseconds: 400), () {
        if (context.mounted) showEmailAuth(context, ref, signUp: true);
      });
    }
    return Scaffold(
      body: PageView(
        controller: _page,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _Account(onEmail: _emailSignup, onOAuth: _oauthSoon, onClose: _close),
          _Basics(
            name: _name,
            username: _username,
            region: _region,
            onContinue: _next,
          ),
          _Finish(
            hair: _hair,
            eye: _eye,
            saving: _saving,
            onHair: (v) => setState(() => _hair = v),
            onEye: (v) => setState(() => _eye = v),
            onDone: _complete,
            onSkip: _complete,
          ),
        ],
      ),
    );
  }
}

class _Account extends StatelessWidget {
  const _Account(
      {required this.onEmail, required this.onOAuth, this.onClose});
  final VoidCallback onEmail;
  final VoidCallback onOAuth;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final imgs = [for (final p in mockFeed) p.imageUrl];
    final col0 = [imgs[0], imgs[3], imgs[1]];
    final col1 = [imgs[4], imgs[2], imgs[5]];
    final col2 = [imgs[2], imgs[0], imgs[4]];
    Widget btn(String label, Color bg, Color fg,
        {IconData? icon, Border? border, required VoidCallback onTap}) {
      return GestureDetector(
        onTap: onTap,
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
            if (onClose != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: onClose,
                  child: const Icon(Icons.close_rounded,
                      size: 24, color: AppColors.ink2),
                ),
              ),
            Text('KEEP YOUR STYLE', style: t.labelSmall?.copyWith(letterSpacing: 1.8)),
            const SizedBox(height: 8),
            Text('Save your looks,\nkeep your matches',
                style: t.displayLarge?.copyWith(fontSize: 28)),
            const SizedBox(height: 7),
            Text('Your style profile is ready — make an account to keep it.',
                style: t.bodyLarge?.copyWith(color: AppColors.ink2)),
            const SizedBox(height: 18),
            Expanded(
              child: ShaderMask(
                shaderCallback: (rect) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black,
                    Colors.black,
                    Colors.transparent
                  ],
                  stops: [0.0, 0.13, 0.86, 1.0],
                ).createShader(rect),
                blendMode: BlendMode.dstIn,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        child: _MarqueeColumn(
                            images: col0, down: true, seconds: 24, itemHeight: 132)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _MarqueeColumn(
                            images: col1, down: false, seconds: 29, itemHeight: 132)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _MarqueeColumn(
                            images: col2, down: true, seconds: 21, itemHeight: 132)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            btn('Continue with Apple', Colors.black, Colors.white,
                icon: Icons.apple, onTap: onOAuth),
            btn('Continue with Google', Colors.white, const Color(0xFF1F1F1F),
                icon: Icons.g_mobiledata_rounded,
                border: Border.all(color: AppColors.line),
                onTap: onOAuth),
            btn('Sign up with email', AppColors.canvas, AppColors.ink,
                border: Border.all(color: AppColors.ink, width: 1.5),
                onTap: onEmail),
            const SizedBox(height: 4),
            Center(
              child: Text.rich(
                TextSpan(children: [
                  const TextSpan(text: 'Your style profile is public · '),
                  TextSpan(
                      text: 'weight stays private',
                      style: t.bodySmall
                          ?.copyWith(fontWeight: FontWeight.w700, color: AppColors.ink2)),
                ]),
                textAlign: TextAlign.center,
                style: t.bodySmall?.copyWith(color: AppColors.ink3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A seamlessly-looping vertical marquee of outfit photos. Columns drift up or
/// down continuously (alternating direction) for gentle, premium motion.
class _MarqueeColumn extends StatefulWidget {
  const _MarqueeColumn({
    required this.images,
    required this.down,
    required this.seconds,
    required this.itemHeight,
  });
  final List<String> images;
  final bool down;
  final int seconds;
  final double itemHeight;

  @override
  State<_MarqueeColumn> createState() => _MarqueeColumnState();
}

class _MarqueeColumnState extends State<_MarqueeColumn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(seconds: widget.seconds),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const gap = 8.0;
    final setHeight = widget.images.length * (widget.itemHeight + gap);

    Widget tile(String url) => Padding(
          padding: const EdgeInsets.only(bottom: gap),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: CachedNetworkImage(
              imageUrl: url,
              height: widget.itemHeight,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (_, _) => const ColoredBox(color: AppColors.sand),
            ),
          ),
        );

    // Two stacked copies so the loop is seamless.
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final u in widget.images) tile(u),
        for (final u in widget.images) tile(u),
      ],
    );

    return ClipRect(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final v = _c.value;
          final dy = widget.down ? (v - 1) * setHeight : -v * setHeight;
          return Transform.translate(offset: Offset(0, dy), child: child);
        },
        // OverflowBox lets the looping column exceed the slot height without a
        // RenderFlex overflow; ClipRect clips the visible window.
        child: OverflowBox(
          minHeight: 0,
          maxHeight: double.infinity,
          alignment: Alignment.topCenter,
          child: content,
        ),
      ),
    );
  }
}

class _Basics extends StatelessWidget {
  const _Basics({
    required this.name,
    required this.username,
    required this.region,
    required this.onContinue,
  });
  final TextEditingController name, username, region;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return _FieldsScaffold(
      eyebrow: 'ALMOST THERE',
      title: 'Set up your profile',
      onCta: onContinue,
      ctaLabel: 'Continue',
      children: [
        _InputField(label: 'Name', controller: name, hint: 'Your name'),
        _InputField(
            label: 'Username', controller: username, hint: 'username', prefix: '@'),
        _InputField(
            label: 'Region', controller: region, hint: 'Add your region (optional)'),
      ],
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField(
      {required this.label, required this.controller, this.hint, this.prefix});
  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? prefix;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label: label),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line)),
            child: Row(
              children: [
                if (prefix != null)
                  Text(prefix!,
                      style: t.bodyLarge?.copyWith(color: AppColors.ink2)),
                Expanded(
                  child: TextField(
                    controller: controller,
                    autocorrect: false,
                    style: t.bodyLarge,
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: hint,
                      hintStyle: t.bodyLarge?.copyWith(color: AppColors.ink3),
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
}

class _Finish extends StatelessWidget {
  const _Finish({
    required this.hair,
    required this.eye,
    required this.saving,
    required this.onHair,
    required this.onEye,
    required this.onDone,
    required this.onSkip,
  });

  final String hair, eye;
  final bool saving;
  final ValueChanged<String> onHair, onEye;
  final VoidCallback onDone, onSkip;

  @override
  Widget build(BuildContext context) {
    return _FieldsScaffold(
      eyebrow: 'A FEW MORE · SHARPENS MATCHES',
      title: 'Finish your profile',
      onCta: onDone,
      ctaLabel: saving ? 'Saving…' : 'Done',
      onSkip: saving ? null : onSkip,
      children: [
        _TapField(
            label: 'Hair',
            value: hair,
            swatch: hairColors.firstWhere((c) => c.name == hair).swatch,
            onTap: () => _openColorList(context, 'Hair color', hairColors, hair, onHair)),
        _TapField(
            label: 'Eyes',
            value: eye,
            swatch: eyeColors.firstWhere((c) => c.name == eye).swatch,
            onTap: () => _openColorList(context, 'Eye color', eyeColors, eye, onEye)),
      ],
    );
  }
}

// ── Field scaffolding ──────────────────────────────────────────────────────

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
  const _FieldLabel({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label.toUpperCase(),
            style: t.labelSmall?.copyWith(letterSpacing: 0.8)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
              color: const Color(0xFFE7F2EA),
              borderRadius: BorderRadius.circular(6)),
          child: const Text('Public',
              style: TextStyle(
                  fontFamily: AppFonts.text,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.matchDark)),
        ),
      ],
    );
  }
}

class _TapField extends StatelessWidget {
  const _TapField({
    required this.label,
    required this.value,
    required this.onTap,
    this.swatch,
  });
  final String label, value;
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
          _FieldLabel(label: label),
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

// ── Inline measurement wheels (native iOS pickers) ──────────────────────────

/// Height as feet + inches. Stateful so the scroll controllers persist across
/// parent rebuilds (avoids the wheel snapping back mid-scroll).
class _HeightWheel extends StatefulWidget {
  const _HeightWheel({
    required this.feet,
    required this.inches,
    required this.onChanged,
  });
  final int feet, inches;
  final void Function(int feet, int inches) onChanged;

  @override
  State<_HeightWheel> createState() => _HeightWheelState();
}

class _HeightWheelState extends State<_HeightWheel> {
  late int _feet = widget.feet;
  late int _inches = widget.inches;
  late final _ftCtl = FixedExtentScrollController(initialItem: _feet - 4);
  late final _inCtl = FixedExtentScrollController(initialItem: _inches);

  @override
  void dispose() {
    _ftCtl.dispose();
    _inCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final style = t.titleLarge?.copyWith(fontWeight: FontWeight.w600);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s24, 12, AppSpacing.s24, 0),
      child: SizedBox(
        height: 196,
        child: Row(
          children: [
            Expanded(
              child: CupertinoPicker(
                scrollController: _ftCtl,
                itemExtent: 42,
                onSelectedItemChanged: (i) {
                  _feet = 4 + i;
                  widget.onChanged(_feet, _inches);
                },
                children: [
                  for (var f = 4; f <= 6; f++)
                    Center(child: Text('$f ft', style: style)),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                scrollController: _inCtl,
                itemExtent: 42,
                onSelectedItemChanged: (i) {
                  _inches = i;
                  widget.onChanged(_feet, _inches);
                },
                children: [
                  for (var i = 0; i < 12; i++)
                    Center(child: Text('$i in', style: style)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Weight in pounds. Private (matching only) — see the step's reassure note.
class _WeightWheel extends StatefulWidget {
  const _WeightWheel({required this.lb, required this.onChanged});
  final int lb;
  final ValueChanged<int> onChanged;

  @override
  State<_WeightWheel> createState() => _WeightWheelState();
}

class _WeightWheelState extends State<_WeightWheel> {
  static const _min = 80;
  static const _max = 350;
  late int _lb = widget.lb;
  late final _ctl = FixedExtentScrollController(initialItem: _lb - _min);

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final style = t.titleLarge?.copyWith(fontWeight: FontWeight.w600);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s24, 12, AppSpacing.s24, 0),
      child: SizedBox(
        height: 196,
        child: CupertinoPicker(
          scrollController: _ctl,
          itemExtent: 42,
          onSelectedItemChanged: (i) {
            _lb = _min + i;
            widget.onChanged(_lb);
          },
          children: [
            for (var w = _min; w <= _max; w++)
              Center(child: Text('$w lb', style: style)),
          ],
        ),
      ),
    );
  }
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
