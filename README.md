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

## Known issues (in progress)
- **Stale-session auth:** a returning user whose access token has expired can be silently
  treated as anonymous server-side (flat/no match scores, writes would fail). A **fresh
  sign-up/sign-in works fine** — only stale sessions are affected.
- A few read surfaces (Recommended row, other-user profile) still use mock data.
