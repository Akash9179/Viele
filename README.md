# Viele

Personalized fashion-discovery mobile app — matches users to outfits, creators, and
clothing based on their body type, complexion, and aesthetic. Core promise:
**"outfits on people like you."**

- **Engineering rules & decisions:** [`CLAUDE.md`](CLAUDE.md)
- **Requirements (source of truth):** [`docs/SRS.md`](docs/SRS.md)
- **Decision log:** [`docs/memory.md`](docs/memory.md)
- **Matching algorithm design:** [`docs/matching-algorithm.md`](docs/matching-algorithm.md)

## Stack
| Layer | Choice |
|---|---|
| Mobile app (this repo, `app/`) | **Flutter** (iOS + Android) |
| Backend | **Supabase** — Postgres + RLS, Auth, Storage, Realtime, pgvector |
| Admin (not scaffolded yet) | React web super-admin |

## Prerequisites
- **Flutter SDK** (Dart **≥ 3.12**) — verify with `flutter doctor`
- **Xcode** + an iOS Simulator (for iOS)
- **CocoaPods** (`sudo gem install cocoapods`) — `flutter run` handles `pod install`

## Run locally
The app connects to the shared live Supabase backend through a **committed publishable
key** (`app/lib/core/supabase/supabase_config.dart`). **No `.env` or secrets setup is
needed.**

```bash
git clone https://github.com/Akash9179/Viele.git
cd Viele/app
flutter pub get
flutter run            # pick an iOS simulator when prompted
```

Then create an account through onboarding to try the full flow (feed, discover, post,
profile, search).

> ⚠️ **Shared database.** Local runs read/write the same live Supabase project as
> everyone else — you'll see existing demo data, and accounts/posts you create are real
> in that shared project. Fine for founder demos; just don't treat it as a scratch DB.

## Common commands
Run from `app/`:
```bash
flutter analyze        # static analysis — kept clean, must pass before commit
flutter test           # unit/widget tests
flutter run            # run on simulator/device
flutter build ipa      # release build for TestFlight (see below)
```

Debug screenshot hooks (all off by default), e.g. land directly on a screen:
```bash
flutter run --dart-define=ROUTE=/discover
flutter run --dart-define=ROUTE=/home --dart-define=DEVLOGIN='email|password'  # auto sign-in
```
Other defines: `START` (onboarding step), `Q` (search query), `SHEET`, `TAB`, `SCROLL`.
No credentials are committed.

## Project layout
```
Viele/
├── app/                     # Flutter app
│   ├── lib/
│   │   ├── app.dart         # routes (go_router) + shell tabs
│   │   ├── core/            # supabase config, theme, shared state, matching
│   │   └── features/        # feed, discover, post, profile, search, onboarding, …
│   └── ios/                 # iOS project
├── supabase/
│   ├── migrations/          # schema + RLS (0001–0006)
│   └── seed_demo.sql        # demo authors + posts
└── docs/                    # SRS, decision log, design system, matching design
```

## TestFlight (iOS)
Not yet automated (no fastlane/CI). Publish under **your own** Apple Developer account.

First-time setup (one-time, yours to do):
1. A paid **Apple Developer Program** membership (Individual is fine — $99/yr).
2. Point the project at your account: set `PRODUCT_BUNDLE_IDENTIFIER` (a bundle id under
   your own reverse-domain, e.g. `com.<you>.viele`) and `DEVELOPMENT_TEAM` (your Team ID)
   in `app/ios/Runner.xcodeproj`. Keep these **local — don't commit/push** them.
3. Create the matching app record on **App Store Connect** for that bundle id.
4. Install **Transporter** (Mac App Store), signed into your Apple ID.

Build + upload:
```bash
cd app
flutter build ipa     # produces build/ios/ipa/*.ipa
```
Then upload the `.ipa` with the **Transporter** app (the supported path — drag in, validate,
Deliver). `xcrun altool --upload-app` also works from the CLI but is deprecated, so
Transporter is recommended.

## Prompts for a coding agent (Claude Code)

Copy-paste prompts for driving the app with an AI coding agent.

**1 — Clone & run locally** (no Apple account needed — runs on the simulator, or your own
device with a free Apple ID):
> Clone https://github.com/Akash9179/Viele and read README.md and CLAUDE.md first. Run `flutter doctor` to check my toolchain, then get the Flutter app in app/ running on the iOS simulator: `cd app && flutter pub get && flutter run`. It uses a committed publishable Supabase key, so no env/secrets setup is needed. Once it's up, let me create an account through onboarding to test the full flow.

**2 — Publish to your own TestFlight.** Prerequisites you do by hand first: a paid Apple
Developer Program membership (Individual, $99/yr), and **Transporter** installed + signed
into your Apple ID. The agent handles the project + build; you do the App Store Connect
record + the Transporter upload it walks you through.
> I want to publish the Viele app (in app/) to my own TestFlight. I have a paid Apple Developer Program membership and Xcode is signed into my Apple ID. (1) Look up my Team ID from my signed-in Xcode account and help me pick a bundle id under my own reverse-domain (e.g. com.<myname>.viele). (2) Set DEVELOPMENT_TEAM and PRODUCT_BUNDLE_IDENTIFIER in app/ios/Runner.xcodeproj to mine — keep these changes LOCAL only, do NOT commit or push them. (3) Remind me to create an App Store Connect app record for that bundle id before uploading. (4) Bump the build number in app/pubspec.yaml (the +N in `version: 1.0.0+N`) to the next integer, then run `flutter build ipa` (method app-store-connect); fix any signing/export-options issues and re-run until I get a signed .ipa, then show me its path (build/ios/ipa/*.ipa). (5) Then walk me through uploading via the Transporter app step by step — path to the .ipa, sign in (note if I need an app-specific password), validate, Deliver — and what to expect in TestFlight afterward. If validation fails, read the error and tell me exactly what to fix.

Notes: export compliance is pre-handled (`ITSAppUsesNonExemptEncryption=false`), so the
"Missing Compliance" prompt should auto-resolve. After "Delivered," the build takes
~5–15 min to appear in TestFlight. The build points at the **shared live Supabase**, so
testers' accounts/posts are real in that project.

## Known issues (in progress)
- **Stale-session auth:** a returning user whose access token has expired can be silently
  treated as anonymous server-side (flat/no match scores, writes would fail). A **fresh
  sign-up/sign-in works fine** — only stale sessions are affected.
- A few read surfaces (Recommended row, other-user profile) still use mock data.
