# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

`cabsudapp` — a Flutter cab/transfer booking app (CABSUD, southern France). Targets Android + iOS; Android is the primary release target. The codebase is Flutter/Dart — there is no native Android module. "Android development" here means editing Dart code and occasionally touching `android/app/build.gradle` or `AndroidManifest.xml`.

## Commands

```bash
flutter pub get                        # install deps after pubspec changes
flutter run                            # run on attached device/emulator
flutter analyze                        # static analysis (flutter_lints)
flutter test                           # run widget tests (test/widget_test.dart)
flutter test test/widget_test.dart     # single test file
flutter build apk --release            # release APK
flutter build appbundle --release      # Play Store bundle (same as Dockerfile)
dart run flutter_launcher_icons        # regenerate launcher icons
dart run flutter_native_splash:create  # regenerate native splash
```

Containerised release build: `docker build -t cabsud .` produces the AAB at `/app/build/app/outputs/bundle/release/app-release.aab` inside the image.

## Required local configuration

- `.env` (at repo root, loaded via `flutter_dotenv` before `runApp`) must define `STRIPE_PUBLISHABLE_KEY`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`. Missing keys crash at startup (`!` unwrap in `main.dart`).
- `android/local.properties` must define `google.maps.key=...` — it's injected into `AndroidManifest.xml` via `manifestPlaceholders` in `android/app/build.gradle`. The manifest also hardcodes a Geo API key in `<meta-data>`; prefer the placeholder path for new keys.
- Release build currently signs with the **debug** keystore (`signingConfig = signingConfigs.debug` in `android/app/build.gradle`). Do not ship to Play Store without swapping this.

## Architecture

**Feature-folder layout under `lib/`** — each top-level folder is a feature/flow, not a layer:
- `authentification/` — login + signup screens (Supabase auth).
- `intro_screens/` — onboarding pages 1–6 driven by `onboarding_screen.dart`.
- `commande/` — booking flow: `commande.dart` → `trip_summary.dart` → `payment.dart` (Stripe) → `succed.dart`.
- `services/` — service catalog (airport/cruise/train transfer, car type, route, distance, contact).
- `reuse/` — shared primitives: `theme.dart` (see below), `luxury_text_field.dart`, `luxury_dropdown.dart`, `form_controller.dart`, `map_style.dart`, `isolate_helpers.dart`.
- `localization/` — hand-rolled i18n (no ARB/intl_utils).
- `home_page.dart`, `spalsh_screen.dart`, `onboarding_screen.dart`, `parametre.dart`, `custom_page_route.dart`, `main.dart` sit at the root of `lib/`.

**Startup sequence (`lib/main.dart`) is deliberate — don't reorder.**
1. `main()` awaits only the bare minimum before `runApp`: `dotenv.load`, set `Stripe.publishableKey`, `Strings.load('fr')`, `Supabase.initialize`.
2. Heavy work (Stripe `applySettings`, session restore) runs inside `addPostFrameCallback` so the first frame paints immediately. `_AppLoadingScreen` covers the gap.
3. Session restore (`_tryRestoreSession`) prefers `supabase.auth.currentSession`, falls back to `refresh_token` from `SharedPreferences`. On failure it clears both `jwt_token` and `refresh_token`.
4. A global `navigatorKey` + `onAuthStateChange` listener pushes `/home` on `signedIn` events (needed for OAuth deep-link returns).
5. Named routes exist for `/home`, `/login`, `/signin`; other navigation uses `custom_page_route.dart`.

**Theming.** `lib/reuse/theme.dart` exposes `AppTheme` — a luxury gold-on-midnight palette with spacing (`spaceXS…XL`), radii (`radiusS…XL`), and gradient helpers (`luxuryBackgroundGradient`, `subtleGoldGradient`). Many legacy color aliases (`primaryGold`, `richBlack`, `champagneGold`, etc.) resolve to the same core tokens — use the core tokens (`primary`, `background`, `foreground`) in new code.

**Localization.** `Strings` (`lib/localization/string.dart`) is a manual singleton: `Strings.load('fr' | 'en')` swaps an internal map; every string is a getter backed by `StringsFr`/`StringsEn`. Default is French. Adding a string requires: (a) getter in `string.dart`, (b) entry in both `strings_en.dart` and `strings_fr.dart`. Access at call sites via `Strings.of(context).someKey` (the `context` arg is ignored — it's just API sugar).

**Performance pattern.** Network responses are parsed off-main-thread via `lib/reuse/isolate_helpers.dart` (`parseJsonMap`, `parseJsonList`, `parseAddressSuggestions`, Google Directions parsing). When adding new JSON-heavy endpoints, route parsing through these helpers rather than calling `json.decode` inline. Recent commits (`RepaintBoundary`, reduced shadow blur, `const` pushes) show the project actively optimises rendering — preserve `const` constructors when editing widgets.

**Deep link / OAuth.** Supabase OAuth callback is wired to scheme `io.supabase.flutter://login-callback` in `AndroidManifest.xml`. Changing the scheme requires editing both the manifest intent-filter and the Supabase project's redirect URL.

**Android build specifics.** `compileSdk`/`minSdk`/`versionCode`/`versionName` come from Flutter (`flutter.*`); `targetSdk = 34`, NDK `27.2.12479018`, Java/Kotlin target 17. Release build has `minifyEnabled true` + `shrinkResources true` — if you add a reflection-based library, add Proguard rules in `android/app/proguard-rules.pro`.

## Conventions

- `analysis_options.yaml` uses stock `flutter_lints` with no customisations. Run `flutter analyze` before declaring work done; the repo's `analyze_output.txt` is stale history, not current baseline.
- Image assets are grouped by feature under `assets/` (`intro/`, `cars/`, `authnfication/`, `paiement/`, `animation/`, `lottie/`, `logo/`) and must be registered in `pubspec.yaml` to load.
- Only one widget test ships (`test/widget_test.dart`) — the project has no established test harness for auth/booking flows.
