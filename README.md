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
Other defines: `START` (onboarding step), `Q` (search query), `SHEET`, `TAB`, `SCROLL`,
`EMPTY`. No credentials are committed.

## Project layout
```
Viele/
├── app/                     # Flutter app
│   ├── lib/
│   │   ├── app.dart         # routes (go_router) + shell tabs
│   │   ├── core/            # supabase config, theme, shared state, matching
│   │   └── features/        # feed, discover, post, profile, search, onboarding, …
│   └── ios/                 # iOS project (bundle id io.suryavanshi.viele)
├── supabase/
│   ├── migrations/          # schema + RLS (0001–0006)
│   └── seed_demo.sql        # demo authors + posts
└── docs/                    # SRS, decision log, design system, matching design
```

## TestFlight (iOS)
Not yet automated (no fastlane/CI). The app is configured under bundle id
**`io.suryavanshi.viele`** and Apple Developer team **`XHQRLPSVMY`** with automatic
signing.

First-time setup (one-time, by the Apple-account owner):
1. Create the app record on **App Store Connect** for `io.suryavanshi.viele`.
2. Add additional uploaders to the App Store Connect team (role **App Manager**).

Build + upload:
```bash
cd app
flutter build ipa
# upload the .ipa via Transporter.app, or:
xcrun altool --upload-app -f build/ios/ipa/*.ipa -t ios -u <apple-id> -p <app-specific-password>
```
To publish under a **different** Apple account, change `PRODUCT_BUNDLE_IDENTIFIER` and
`DEVELOPMENT_TEAM` in `app/ios/Runner.xcodeproj` and create a matching App Store Connect
record.

## Prompts for a coding agent (Claude Code)

Copy-paste prompts for driving the app with an AI coding agent. The TestFlight ones
assume the manual Apple-account prerequisites below are already done.

**Manual prerequisites (one-time, can't be done by the agent):**
1. App Store Connect app record exists for `io.suryavanshi.viele`.
2. You have access to team `XHQRLPSVMY` (invited as *App Manager*), or you've switched
   the bundle id + team to your own account.
3. Xcode is signed into an Apple ID with access to that team (Xcode → Settings → Accounts).
4. **Transporter** installed (Mac App Store) and signed in with that Apple ID (a 2FA
   app-specific password from appleid.apple.com may be needed).

**1 — Clone & run locally:**
> Clone https://github.com/Akash9179/Viele and read README.md and CLAUDE.md first. Run `flutter doctor` to check my toolchain, then get the Flutter app in app/ running on the iOS simulator: `cd app && flutter pub get && flutter run`. It uses a committed publishable Supabase key, so no env/secrets setup is needed. Once it's up, let me create an account through onboarding to test the full flow.

**2 — Build a signed TestFlight IPA:**
> Build a signed iOS release IPA of the Viele app (in app/) for TestFlight. Bundle id is io.suryavanshi.viele, Apple team XHQRLPSVMY, automatic signing; my Xcode is signed into an Apple ID with access to that team. First bump the build number in app/pubspec.yaml (the +N in `version: 1.0.0+N`) to the next unused integer — App Store Connect rejects duplicate build numbers. Then run `flutter build ipa`; if signing/export options are needed, create the right ExportOptions.plist (method: app-store-connect) and re-run. When it succeeds, show me the path to the .ipa (build/ios/ipa/*.ipa) and confirm it's signed. Don't upload it yourself — I'll do that in Transporter.

**3 — Upload via Transporter** (the agent can't drive the GUI — it hands off and guides):
> The signed .ipa is built. Walk me through uploading it to TestFlight using the Transporter app step by step: (1) tell me the exact path to the .ipa and reveal it in Finder; (2) guide me through opening Transporter, signing in with my Apple ID (note if I need an app-specific password), adding the .ipa, letting it validate, then Deliver; (3) tell me what to expect afterwards (processing time in App Store Connect → TestFlight, the export-compliance question, adding testers). If validation fails, read the error and tell me exactly what to fix.

**Alt — publish to a *different / personal* Apple account** (instead of the configured
`io.suryavanshi.viele` / team `XHQRLPSVMY`): you need your own paid Apple Developer
Program membership, a bundle id under your own reverse-domain, and an App Store Connect
record for it. Keep the signing changes local — **don't commit/push them**.
> I want to publish the Viele app (in app/) to MY OWN personal TestFlight, not the account it's currently configured for. I have my own paid Apple Developer Program membership and Xcode is signed into my Apple ID. (1) Look up my Team ID from my signed-in Xcode account and help me pick a bundle id under my own reverse-domain (e.g. com.<myname>.viele). (2) Change DEVELOPMENT_TEAM and PRODUCT_BUNDLE_IDENTIFIER in app/ios/Runner.xcodeproj to mine — keep these changes LOCAL only, do NOT commit or push them. (3) Remind me to create an App Store Connect app record for that bundle id before uploading. (4) Bump the build number in app/pubspec.yaml (+N), then run `flutter build ipa` (method app-store-connect); fix any signing/export issues and re-run until I get a signed .ipa. (5) Then walk me through uploading via Transporter step by step and what to expect in TestFlight afterward.

Notes: export compliance is pre-handled (`ITSAppUsesNonExemptEncryption=false`), so the
"Missing Compliance" prompt should auto-resolve. After "Delivered," the build takes
~5–15 min to appear in TestFlight. The build points at the **shared live Supabase**, so
testers' accounts/posts are real in that project.

## Known issues (in progress)
- **Stale-session auth:** a returning user whose access token has expired can be silently
  treated as anonymous server-side (flat/no match scores, writes would fail). A **fresh
  sign-up/sign-in works fine** — only stale sessions are affected.
- A few read surfaces (Recommended row, other-user profile) still use mock data.
