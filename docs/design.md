# Viele — Design System

| | |
|---|---|
| **Version** | 1.0 |
| **Date** | 2026-06-15 |
| **Status** | Locked direction (Akash, 2026-06-15). Source of truth for the Flutter app's visual layer; refined in-simulator. |
| **Reference** | Eugene's Home mockups; working HTML mockups in `~/.gstack/projects/Viele/designs/` (`viele-home-refined`, `viele-onboarding`, `viele-post-profile`) |
| **Related** | `docs/brand.md` (the "why"), `docs/SRS.md` (requirements), flow specs in `docs/superpowers/specs/` |

> **The memorable thing:** *"made for a body like mine."* Every choice below serves recognition and belonging — the feeling of opening the app and seeing real people built like you. The visual language is **Apple-native + editorial fashion**: it should read as a real iOS app, not a web template, with the warmth and restraint of a print fashion title. **Photography is the loudest thing on screen; the UI is quiet around it.**

---

## 1. Principles

1. **Native first.** It must look like an Apple app. Use **San Francisco** (the iOS system font), iOS controls (wheel pickers, sheets, large titles), real status bar + tab bar. Never a decorative web serif on UI.
2. **Photography leads.** Warm, low-contrast neutrals so outfit photos are the focus. Chrome recedes.
3. **One accent.** A single green "match" accent. Everything else is ink + cream. No second accent, no gradients-as-decoration.
4. **Kind by default.** Body/coloring inputs are optional, reassuring, body-neutral (see `docs/brand.md` inclusivity ethos). Never clinical or judgmental.
5. **Quiet confidence.** Generous spacing, soft shadows, restraint. Distinctive through craft, not ornament.

---

## 2. Color tokens

| Token | Hex | Role |
|---|---|---|
| `canvas` | `#F6F1E8` | App background (warm cream) |
| `paper` | `#FCF8F1` | Raised surfaces — fields, chips, tab bar |
| `sand` | `#EFE7D8` | Dividers, secondary fills, disclosure blocks |
| `taupe` | `#D9CDBA` | Deeper neutral fill |
| `ink` | `#1E1A14` | Primary text, wordmark, dark buttons, active nav (also the "espresso" used for the + button) |
| `ink-2` | `#766C5C` | Secondary text |
| `ink-3` | `#A89C88` | Meta / placeholder text |
| `line` | `#E6DCCB` | Hairline borders |
| `match` | `#2FA565` | The match accent (dot, pills, positive) |
| `match-dark` | `#1F7D4A` | Match text on light, success states |
| `ring` | `#E9C9B6` | Avatar ring (recommended row, profile) |
| `on-ink` | `#F6F1E8` | Text/icons on dark (`ink`) surfaces |
| overlay | `rgba(22,15,8,.62→0)` | Bottom-up gradient on photo cards for legible text |

**Usage rules:** `match` is reserved for matching/positive only — never decorative. Cards/photos never sit on `paper`; they bleed on `canvas`. Maintain WCAG AA: `ink` on `canvas` ≈ 13:1; `ink-2` on `canvas` ≈ 5:1 (use for secondary, not fine print under 12px on busy areas).

*Dark mode: out of scope for v1 (light only, per direction). Tokens are structured so a dark theme can map later.*

---

## 3. Typography — San Francisco (native)

**Family:** the system font. iOS/Flutter render **SF Pro** automatically. Web mockups use `-apple-system, "SF Pro Display", "SF Pro Text", system-ui`. **No Inter/Roboto/decorative serif anywhere in UI.**

| Style | Size / Weight / Tracking | Use |
|---|---|---|
| Large Title | 30–34 · 800 · -0.03em | Wordmark "Viele", onboarding question titles |
| Title | 24 · 700 · -0.025em | Section headlines ("Outfits on people like you") |
| Headline | 18 · 800 · -0.02em | Profile name, sheet titles, stats |
| Body | 15 · 400 · 0 | Captions, copy |
| Callout | 14 · 600 · 0 | Card name, buttons |
| Subhead | 13 · 500 · 0 | Attribute lines, secondary |
| Footnote | 12 · 500 · 0 | Meta, reassurance |
| Label (caps) | 10–11 · 700 · +0.22em · uppercase | Eyebrows ("FOR YOU", "CURATED FEED", field labels) |

iOS large-title behavior (collapses to inline title on scroll) where the platform offers it.

---

## 4. Spacing, radius, elevation, motion

- **Spacing scale (pt):** 4 · 8 · 12 · 16 · 20 · 24 · 32. Screen horizontal margin = **20**. Card gap in masonry = **12–13**.
- **Radius:** cards **20**, sheets **26** (top corners), fields/chips-rect **12–14**, pills **999**, avatars **50%**.
- **Elevation:** soft, warm-tinted only. Card: `0 14px 30px -16px rgba(40,28,14,.40)`. Field/raised: `0 4px 14px -6px rgba(33,28,22,.18)`. No hard/black shadows.
- **Motion:** restraint. Page-load staggered rise (`opacity 0→1`, `translateY 10→0`, ~0.6s, cubic-bezier(.2,.7,.2,1), stagger ~80ms). Standard transitions 200–300ms ease-out. Wheel picker uses native momentum. One well-orchestrated load beats scattered micro-animations.

---

## 5. Components

- **Match card (Feed):** photo bleed, radius 20, bottom-up overlay gradient. Top-left **match pill** (white 94% opacity, blur, `match` dot + `NN% match`). Top-right **bookmark** (white circle). Bottom: avatar (27px, ring) + name (Callout, white) + row: `aesthetic · height · size` (Subhead, white 88%) and `♥ count`.
- **Match pill:** `rgba(255,255,255,.94)` + backdrop blur, `match` dot 8px, ink text, pill radius. (On dark editorial contexts, an ink pill with `match` dot also valid.)
- **Filter chips:** pill, `paper` + `line` border, `ink-2` text; **active** = `ink` fill, `on-ink` text. Horizontal scroll.
- **Recommended-people avatar:** 62px, `ring` 2.5px padding ring, 2px `canvas` inner border; name (Subhead) + `NN%` (`ink-2`) below.
- **Bottom tab bar:** `paper` 95% + blur, `line` top border, 5 slots — Home · Discover · **＋** · Catwalk · Profile. Labels = Label-caps 9px. Inactive `ink-3`, active `ink`. **Center ＋** = 52–54px `ink` circle, `canvas` glyph, lifted -7px. *(v1 shows all 5 slots; Discover + Catwalk route to "coming soon" — see SRS §9 3-tab scope.)*
- **Buttons:** Primary = `ink` fill / `on-ink`, radius 14, 15px/600. Ghost = transparent / `ink-2`. Outline = 1.5px `ink`. Apple = `#000`/white + logo. Google = white + `line` + logo.
- **Fields:** `paper` + `line`, radius 12, 13px padding, 15px text; placeholder `ink-3`; trailing chevron `›` for tap-to-open. **Public/Private tags** inline on labels: Public = `#E7F2EA`/`match-dark`; Private = `sand`/`ink-2`.
- **Wheel picker (height):** native iOS look — `paper` panel radius 14, 152px tall, center selection band (`line` top/bottom, faint ink tint), top/bottom fade mask; selected value `ink` 22/700, others `ink-3` 20. Columns ft/in (+ cm toggle pills). **Flutter:** `CupertinoPicker`.
- **Option list (hair/eye color):** rows with 24px color swatch + name (Body) + radio; selected name bold, radio `match`-filled. Scrollable.
- **Skin-tone swatches:** 46px circles, faint border; selected = `ink` outline ring with offset. Monk-10 values in §7.
- **Silhouette options:** card grid, ink/`ink-2` silhouette SVG + body-neutral label; selected = `ink` border + `paper` fill.
- **Sheet (modal):** `canvas`, top radius 26, grab handle `ink-3`, dim scrim `rgba(20,15,8,.34)`. Used for the post gate + pickers.
- **Status bar:** real iOS (time + cellular/wifi/battery), tinted to surface ink.

---

## 6. Flutter mapping (implementation notes)

- **Font:** rely on the platform default (SF on iOS). Do **not** bundle Inter/Roboto. For Android parity, SF isn't available — use the system default there (Roboto) or bundle SF-substitute later; design targets iOS-first.
- **Theme:** build a `ThemeData` (Material 3 off or tuned) with a `ColorScheme` from §2, plus a `CupertinoTheme` for native controls. Define a `TextTheme` from §3. Centralize tokens in a `VieleTokens`/`AppColors` Dart file — never hard-code hex in widgets.
- **Native controls:** `CupertinoPicker` (height wheel), `showModalBottomSheet` with radius 26 (sheets), `CupertinoSliverNavigationBar` or custom large-title for the feed header.
- **Cards:** `ClipRRect` radius 20 + `DecoratedBox` gradient overlay; masonry via `flutter_staggered_grid_view` (pin version, commit lockfile per CLAUDE.md).
- **Images:** `cached_network_image` with `paper` placeholder + fade-in; respect signed URLs (data-architecture spec).
- **Motion:** `flutter_animate` or implicit animations for the staggered load.

---

## 7. Taxonomies (the real option sets)

**Skin tone — Monk 10-tone (ordinal 1→10, light→deep):**
`#f6ede4 · #f3e7db · #f7ead0 · #eadaba · #d7bd96 · #a07e56 · #825c43 · #604134 · #3a312a · #292420`

**Body silhouette — standard fashion-industry names + descriptor** (women set; men set parallel: Rectangle · Triangle · Trapezoid · Oval · Inverted Triangle):
Hourglass "balanced, defined waist" · Pear "fuller hips" · Rectangle "straight up and down" · Apple / Round "fuller midsection" · Inverted Triangle "broader shoulders" · **Not sure / skip**. Paired with refined line-art croquis (`SilhouetteIcon`). *Optional, reassuring, non-prescriptive (see brand inclusivity ethos).*

**Hair color (expanded):** Black · Dark brown · Brown · Light brown · Auburn · Red / ginger · Blonde · Platinum · Gray / silver · Colored / dyed.

**Eye color (expanded):** Dark brown · Brown · Hazel · Amber · Blue · Green · Gray.

**Aesthetics (starter taxonomy, extensible):** Quiet Luxury · Off-Duty · Minimal Chic · Romantic · Streetwear · Dark Academia · Soft Girl · Classic · Athleisure · Y2K. (Authoritative list = SRS Appendix 11.2.)

---

## 8. Imagery direction

Real, body-diverse people in real outfits; warm natural light; relatable-not-idealized (the anti-catalog). Full-figure or 3/4 framing so silhouette reads. Minimal heavy filtering. Avoid stocky/posed studio sterility and gradient/placeholder fills. See `docs/brand.md` for the full photography brief.

---

## 9. Out of scope (v1)

Dark mode; Discover-swipe + Catwalk visual systems (V2 surfaces, 3-tab nav only at v1); custom illustrated silhouettes (using simple SVG/icon stand-ins until illustration commissioned); a custom-drawn wordmark/logo (SF wordmark for now — see brand doc); motion beyond the load choreography.
