# Mountain Explorer

A Flutter app for discovering hill stations, tracking the weather on the trail, and sharing trip stories with other trekkers. Built on **Clean Architecture + MVVM (BLoC/Cubit)** with Firebase as the backend.

<p align="center">
  <img alt="Flutter 3.29" src="https://img.shields.io/badge/Flutter-3.29-02569B?logo=flutter&logoColor=white">
  <img alt="Dart 3.7" src="https://img.shields.io/badge/Dart-3.7-0175C2?logo=dart&logoColor=white">
  <img alt="Architecture" src="https://img.shields.io/badge/Architecture-Clean%20%2B%20MVVM-5C6BC0">
  <img alt="State" src="https://img.shields.io/badge/State-flutter__bloc-13B9FD">
  <img alt="Tests" src="https://img.shields.io/badge/tests-243%2F243%20passing-3DDC84">
  <img alt="Analyzer" src="https://img.shields.io/badge/flutter%20analyze-clean-3DDC84">
</p>

---

## Table of contents

1. [Features](#features)
2. [Screenshots](#screenshots)
3. [Architecture](#architecture)
4. [Tech stack](#tech-stack)
5. [Project structure](#project-structure)
6. [Getting started](#getting-started)
7. [Configuration](#configuration)
8. [Running the app](#running-the-app)
9. [Testing](#testing)
10. [Firestore security rules](#firestore-security-rules)
11. [Troubleshooting](#troubleshooting)
12. [Architecture decisions](#architecture-decisions)
13. [Roadmap](#roadmap)
14. [Contributing](#contributing)
15. [License](#license)

---

## Features

### Authentication
- Email / password sign-up with verification email
- Google Sign-In (Android)
- Anonymous ("Continue as guest") sign-in
- Password reset via email
- Verified-email gate for writing to the community
- Centralised `AuthCubit` exposes auth state app-wide; page-level cubits (`LoginCubit`, `SignupCubit`, `ForgotPasswordCubit`, `VerifyEmailCubit`) hold form state

### Mountains + Weather + Search
- Firestore-backed mountain catalogue with bundled JSON fallback for offline / unseeded projects
- Responsive carousel with cached network images
- Per-mountain weather fetched in parallel from OpenWeatherMap with a 5s per-request timeout
- Local-filter search over name + description
- Per-user "liked" mountains stored at `users/{uid}/private/likedMountains` via Firestore transactions

### Community
- Real-time feed streaming from `posts/` (ordered by `pTime desc`)
- Create post with image picker + `flutter_image_compress` (quality 70, 2 MB hard cap)
- Owner-only edit (title/description) and delete
- Like / unlike any post (atomic `arrayUnion` / `arrayRemove`)
- Nested comments subcollection with real-time stream and owner-only delete
- Orphaned-image cleanup if the Firestore write fails after a Storage upload

### Checklist
- Per-user packing list at `users/{uid}/checklist/{itemId}`
- Add / toggle / delete, 120-char limit
- Guests see a "Sign up to save your checklist" CTA

### App-wide
- Onboarding shown only on first launch (`shared_preferences`-gated)
- Bottom-nav shell with Home / Mountains / Community / Profile + drawer
- Polished navigation: `context.push()` for sub-screens, `canPop → pop` after-save, Android system-back switches tabs before exiting, iOS edge-swipe-back on every pushed route
- Material 3 theme with Montserrat typography and an "Alpine" palette
- 9 reusable widgets in `lib/shared/widgets/` (`AppButton`, `AppTextField`, `AppPasswordField`, `AppCard`, `FeatureCard`, `LoadingOverlay`, `EmptyState`, `ErrorView`, `ThemedAppBar`)

---

## Screenshots

<table>
  <tr>
    <td><img src="https://github.com/Anirban6311/mountain_explorer_app/assets/107030944/c3f23c2a-8393-44f9-aa93-4bbc17c62f87" alt="Onboarding" width="45%"></td>
    <td><img src="https://github.com/Anirban6311/mountain_explorer_app/assets/107030944/dfaf50d6-5fe5-486c-b121-db94ef0def96" alt="Home" width="45%"></td>
  </tr>
  <tr>
    <td><img src="https://github.com/Anirban6311/mountain_explorer_app/assets/107030944/8daaf14a-ccb4-40f1-b0cf-5db5d4593dc1" alt="Mountains carousel" width="45%"></td>
    <td><img src="https://github.com/Anirban6311/mountain_explorer_app/assets/107030944/fa7c5e72-d843-497e-9bba-67f4ce38b301" alt="Mountain detail with weather" width="45%"></td>
  </tr>
  <tr>
    <td><img src="https://github.com/Anirban6311/mountain_explorer_app/assets/107030944/767e238f-d607-4e8d-a5b5-843b71402e4c" alt="Search" width="45%"></td>
    <td><img src="https://github.com/Anirban6311/mountain_explorer_app/assets/107030944/25cce279-2893-40ce-a70f-a375749fbde2" alt="Liked mountains" width="45%"></td>
  </tr>
  <tr>
    <td><img src="https://github.com/Anirban6311/mountain_explorer_app/assets/107030944/3a021004-c553-4272-b708-1393ca459217" alt="Community feed" width="45%"></td>
    <td><img src="https://github.com/Anirban6311/mountain_explorer_app/assets/107030944/46936bc6-14c3-40dd-a34e-c35a9aced2b1" alt="Post detail" width="45%"></td>
  </tr>
  <tr>
    <td><img src="https://github.com/Anirban6311/mountain_explorer_app/assets/107030944/51558456-b97f-43f9-aa3e-9c22e8f0dd46" alt="Create post" width="45%"></td>
    <td><img src="https://github.com/Anirban6311/mountain_explorer_app/assets/107030944/34f22808-2bec-4efc-8339-92bf503ad3f9" alt="Checklist" width="45%"></td>
  </tr>
  <tr>
    <td><img src="https://github.com/Anirban6311/mountain_explorer_app/assets/107030944/9ae9d7d7-5c43-4e17-8585-e7a14c0bafcc" alt="Profile" width="45%"></td>
  </tr>
</table>

---

## Architecture

Every feature is a Clean Architecture **slice** with three layers:

```
features/<feature>/
├── domain/           # Pure Dart. Zero Flutter / Firebase imports.
│   ├── entities/     # Value objects (Equatable)
│   ├── repositories/ # Abstract contracts
│   └── usecases/     # Single-method classes with `call()`
├── data/             # Only layer that touches Firebase / http
│   ├── models/       # fromFirestore / fromJson factories
│   ├── datasources/  # Thin wrappers over SDKs; throw raw exceptions
│   └── repositories/ # impl that maps exceptions to `AppError`
├── presentation/
│   ├── cubit/        # flutter_bloc Cubits + sealed state classes
│   ├── view/         # Pages that consume cubits
│   └── widgets/      # Feature-local widgets
└── di/<feature>_module.dart    # get_it registrations
```

### Error handling

All repository / use-case methods return a hand-rolled sealed `Result<T>`:

```dart
sealed class Result<T> {}
class Success<T> extends Result<T> { final T value; }
class Failure<T> extends Result<T> { final AppError error; }
```

Exceptions are caught at the repository boundary and mapped to a sealed `AppError` hierarchy (`NetworkError`, `AuthError`, `PermissionError`, `NotFoundError`, `ValidationError`, `CancelledError`, `UnknownError`). The UI never sees a Firebase or HTTP exception type.

### State management

- **App-wide cubits** (registered as `lazySingleton` in `getIt`, exposed via `BlocProvider.value`): `AuthCubit`, `FeedCubit`, `MountainsCubit`, `ChecklistCubit`.
- **Page cubits** (registered as `factory`): `LoginCubit`, `SignupCubit`, `CreatePostCubit`, `EditPostCubit`, `PostDetailCubit`, …
- States are **sealed classes** (`Loading | Loaded | Error | …`) rendered via `switch` expressions — the compiler enforces exhaustive handling.

### Navigation

`go_router` with a single `GoRouter` instance. Declarative redirects in `lib/app/router/app_router.dart` enforce:
- Onboarding-not-seen users → `/onboarding`
- Unauthenticated users → `/login` (except auth pages)
- `NeedsVerification` users → `/verify-email` (but auth pages stay accessible as an escape hatch)
- Anonymous users blocked from `/community/new` and `/community/post/:id/edit`
- Unverified users on community-write routes → `/verify-email`

Sub-screens use `context.push()` for a swipe-back-capable stack; root destinations (after login, after signup, onboarding exit) use `context.go()` to replace. Android system back on a non-Home tab switches to Home before exiting.

---

## Tech stack

| Area | Library |
|------|---------|
| UI | Flutter 3.29, Material 3 |
| State | `flutter_bloc`, `equatable`, `bloc_test` |
| Routing | `go_router` |
| DI | `get_it` |
| Auth | `firebase_auth`, `google_sign_in` |
| Database | `cloud_firestore` |
| Storage | `firebase_storage` |
| Networking | `http` |
| Env | `flutter_dotenv` |
| Images | `cached_network_image`, `image_picker`, `flutter_image_compress` |
| Fonts | `google_fonts` (Montserrat) |
| Misc | `shared_preferences`, `intl`, `carousel_slider` |
| Testing | `flutter_test`, `bloc_test`, `mocktail` |

---

## Project structure

```
lib/
├── app/
│   ├── app.dart                    # MaterialApp.router + BlocProvider
│   └── router/
│       ├── app_router.dart         # GoRouter + guard matrix
│       └── routes.dart             # Route path constants
├── core/
│   ├── di/injector.dart            # get_it singleton + module registration
│   ├── env/env.dart                # flutter_dotenv wrapper
│   ├── errors/
│   │   ├── app_error.dart          # Sealed AppError hierarchy
│   │   └── result.dart             # Sealed Result<T> = Success | Failure
│   ├── storage/app_prefs.dart      # shared_preferences wrapper
│   ├── theme/
│   │   ├── app_colors.dart
│   │   ├── app_typography.dart
│   │   ├── app_spacing.dart
│   │   ├── app_radius.dart
│   │   └── app_theme.dart
│   └── utils/logger.dart           # dart:developer wrapper
├── features/
│   ├── auth/                       # Email / Google / Anonymous + verification
│   ├── checklist/                  # Per-user packing list
│   ├── community/                  # Feed, post detail, create/edit, comments, likes
│   ├── home/                       # Bottom-nav shell + profile
│   ├── mountains/                  # List + search + likes
│   ├── onboarding/                 # First-launch slides
│   └── weather/                    # OpenWeatherMap client
├── shared/widgets/                 # Reusable UI primitives
├── firebase_options.dart           # Currently Android-only; run `flutterfire configure` for more
└── main.dart                       # Bootstrap: dotenv → Firebase → DI → runApp
test/
├── unit/                           # UseCase, repository, cubit tests
└── widget/                         # Shared-widget tests
firestore.rules                     # Authored but not auto-deployed
.env.example                        # Template for secrets
```

---

## Getting started

### Prerequisites

- **Flutter** 3.29.x (check `.tool-versions` or run `flutter --version`)
- **Dart** 3.7.x (bundled with Flutter)
- **Android Studio** or **VS Code** with the Flutter extension
- A **Firebase project** — the current `android/app/google-services.json` points at `btack-5f03e`; you can reuse it for dev or swap in your own (see [Configuration](#configuration))
- An **OpenWeatherMap** API key (free tier works) — https://openweathermap.org/api
- For Google Sign-In (optional): the Android app's SHA-1 fingerprint registered in Firebase Console

### Clone and bootstrap

```bash
git clone https://github.com/Anirban6311/mountain_explorer_app.git
cd mountain_explorer_app
flutter pub get
```

### Secrets

Copy the template and fill it in:

```bash
cp .env.example .env
```

Then edit `.env`:

```dotenv
OPENWEATHER_API_KEY=your_openweathermap_api_key_here

# Optional — only required for Google Sign-In on Android.
# Find in Firebase Console → Project settings → Your apps → Android app
# (after registering SHA-1 and enabling the Google provider), or in the
# updated google-services.json as the entry with "client_type": 3.
GOOGLE_SIGN_IN_SERVER_CLIENT_ID=
```

> `.env` is in `.gitignore`. **Do not commit it.**

---

## Configuration

### Firebase project setup

The app is pre-wired to the demo Firebase project `btack-5f03e` (Android only). If you're pointing at your own project, do this:

1. Create a project in [Firebase Console](https://console.firebase.google.com/).
2. **Authentication → Sign-in method** — enable:
   - Email/Password
   - Anonymous
   - Google (optional; requires SHA-1 + OAuth client — see below)
3. **Firestore Database** — create a database in production mode; import the provided `firestore.rules` via `firebase deploy --only firestore:rules`.
4. **Storage** — enable default bucket; the app uploads post images to `posts/{uid}/{timestamp}.jpg`.
5. **Add an Android app** with package name `com.example.monuments_app` (or change the `applicationId` in `android/app/build.gradle` to your own).
6. Download the generated `google-services.json` into `android/app/`.
7. Regenerate `lib/firebase_options.dart`:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   This adds iOS / macOS / web options if you target those platforms.

### Enabling Google Sign-In

1. Get your debug SHA-1:
   ```bash
   cd android && ./gradlew signingReport
   ```
2. Paste the SHA-1 into Firebase Console → Project settings → Your Android app → "Add fingerprint".
3. Enable Google in Authentication → Sign-in method.
4. Download the updated `google-services.json` and replace `android/app/google-services.json`.
5. In the new JSON, find the `oauth_client` entry with `"client_type": 3` and copy its `client_id`.
6. Set it in `.env`:
   ```dotenv
   GOOGLE_SIGN_IN_SERVER_CLIENT_ID=...apps.googleusercontent.com
   ```
7. `flutter clean && flutter run`.

### Seeding the Mountains collection

The app falls back to `assets/hill_station.json` automatically if the Firestore `mountains` collection is empty, so you can run without seeding. To populate Firestore, write a one-shot Dart script (or use the Firebase Console import) with the following document shape per mountain:

```jsonc
{
  "name": "Shimla",
  "imageUrl": "https://...",
  "description": "Popular hill station...",
  "region": "Himachal Pradesh"  // optional
}
```

---

## Running the app

### Debug build

```bash
flutter run
```

Hot-reload works for Dart code; after changing `google-services.json` or `.env`, do a full stop + `flutter run` (hot-restart is not enough).

### Release build

```bash
flutter build apk --release          # Android APK
flutter build appbundle --release    # Android App Bundle for Play
flutter build ios --release          # iOS (requires flutterfire configure)
```

> **Security note**: `.env` is currently bundled as a Flutter asset, which means any key inside (including `OPENWEATHER_API_KEY`) ships inside the APK. For production, move secrets behind `--dart-define`, a Cloud Function proxy, or Firebase Remote Config.

---

## Testing

```bash
# Everything
flutter test

# Or split by layer
flutter test test/unit           # ~230 tests (domain, data, cubits, router)
flutter test test/widget         # shared-widget tests

# Lints + analyzer
flutter analyze
```

Current coverage highlights:

| Layer | What's tested |
|------|---------------|
| Domain | Every UseCase: happy + at least one `Failure(AppError)` path |
| Data | Repository impls: Firebase error-code → `AppError` mapping, validation, orphan-image cleanup on post-create failure |
| Presentation | Every Cubit via `bloc_test`: state transitions, stream lifecycle, uid re-subscribe |
| Routing | 30+ tests covering the full `resolveRedirect` matrix (every `AuthState` × every path) |
| Shared widgets | Render + interaction tests for all 9 primitives |

Mocking is done with `mocktail`. There are no Firestore-emulator or integration tests — SDK calls are tested by mocking the abstract data-source interface.

---

## Firestore security rules

The rules in [`firestore.rules`](firestore.rules) enforce:

- `mountains/**` — any signed-in user can read; writes denied (use the out-of-band seed flow)
- `users/{uid}/**` — self-only read + write
- `posts/{postId}`
  - Read: any signed-in user
  - Create: email-verified user; required fields + length checks
  - Update (owner): only `pTitle` / `pDescription` / `likes` may change
  - Update (any user): only `likes` may change, and only by ±1 entry equal to the caller's UID
  - Delete: owner only
- `posts/{postId}/comments/{commentId}`
  - Read: any signed-in user
  - Create: email-verified user; text 1–500 chars
  - Delete: comment author only
  - Update: denied (comments are append-only)

Deploy with:

```bash
firebase deploy --only firestore:rules
```

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| "Continue as guest" → *Authentication failed* | Anonymous provider not enabled in Firebase Console | Enable it under Authentication → Sign-in method |
| "Continue with Google" → *Something went wrong* | `GOOGLE_SIGN_IN_SERVER_CLIENT_ID` missing, or Android SHA-1 not registered, or Google provider not enabled | Follow [Enabling Google Sign-In](#enabling-google-sign-in) |
| "Create account" → *This sign-in method is not enabled* | Email/Password provider disabled | Enable it in Firebase Console |
| Weather chips don't appear | `OPENWEATHER_API_KEY` missing, invalid, or rate-limited | Check `.env`; watch the `[app.error]` log line |
| iOS / macOS / web app crashes at launch with `UnsupportedError` | `firebase_options.dart` is Android-only | Run `flutterfire configure` to generate multi-platform options |
| Firestore operations fail with *Not allowed* after deploying rules | You deployed `firestore.rules` but some documents don't match the new schema | Check the field names listed in the rules match what the code writes |

Run with verbose logging and grep for `[app.error]` to see raw Firebase error codes:

```bash
flutter run --verbose
```

---

## Architecture decisions

A few non-obvious calls worth highlighting:

### 1. Hand-rolled `Result<T>` instead of `dartz`

`dartz` / `fpdart` would give the same shape but pull in functional-programming abstractions the rest of the codebase doesn't use. A 20-line sealed class gives us 95% of the value.

### 2. App-wide cubit for mountains, factory cubits for forms

`MountainsCubit` holds the mountains list, likes stream, and session-cached weather — all expensive to recreate. It's a `lazySingleton` with a `dispose` hook so drawer navigation and deep-links reuse the same instance. Form-level cubits (`LoginCubit`, `CreatePostCubit`) are factories because their state is per-page and should die with the page.

### 3. Error mapping table that doesn't leak enumeration signals

`_mapFirebaseAuthException` in `auth_repository_impl.dart` collapses `user-not-found` and `wrong-password` into a single "Invalid email or password" message. Without this, an attacker can probe whether a given email has an account.

### 4. Asset fallback for mountains

`FirestoreMountainsRemoteDataSource` falls back to `assets/hill_station.json` on **both** empty collection **and** error. This keeps guest browse working offline and without requiring a seed script to run before the first launch.

### 5. Parallel weather fetch with per-call timeout

The mountains list triggers N weather requests in parallel. Each has a 5 s `Timeout`, so one slow or hung city can't wedge the pipeline. Failures are silently skipped — the card renders without the temp chip.

### 6. Orphan Storage cleanup on post create

`PostsRepositoryImpl.createPost` uploads the image first, then writes the Firestore doc. If the doc write fails, it fires a best-effort `deleteByUrl` on the orphaned Storage object so we don't accumulate dead objects over time.

### 7. Router guards are a pure function

`AppRouter.resolveRedirect(prefs, authState, path)` has no Flutter or go_router dependencies and is unit-tested exhaustively. The go_router adapter is a 3-line wrapper.

---

## Roadmap

The refactor shipped in 5 iterations; everything below is complete:

- [x] **Iteration 1** — Foundation (theme, routing, DI, shared widgets, error/result scaffolding, onboarding gate)
- [x] **Iteration 2** — Auth (email/Google/anonymous + verification, route guards)
- [x] **Iteration 3** — Mountains / weather / search (Firestore + asset fallback, per-user likes, responsive UI, legacy home replaced)
- [x] **Iteration 4** — Community (Firestore migration from RTDB, image compression, owner-only edit/delete, comments, security rules)
- [x] **Iteration 5** — Checklist, final legacy cleanup, pubspec trim, GetX removed, pure-Flutter onboarding

Possible future work:
- [ ] iOS / web configuration via `flutterfire configure`
- [ ] Move `OPENWEATHER_API_KEY` out of the Flutter asset bundle
- [ ] Integration / end-to-end tests with Firebase emulator suite
- [ ] Anonymous → email account-upgrade flow (`linkWithCredential`)
- [ ] Push notifications for comment replies
- [ ] Dark theme

---

## Contributing

1. Fork and clone.
2. `flutter pub get`.
3. Create a branch: `git checkout -b feature/your-change`.
4. Match the existing architecture — new features live under `lib/features/<feature>/` with the same domain/data/presentation/di shape.
5. Tests first (TDD) — every UseCase and Cubit must ship with at least a happy-path and a failure-path test.
6. `flutter analyze` must be clean and `flutter test` must be green.
7. Open a PR with a description of what changed and which iteration scope it fits.

---

## License

This project is provided as-is for educational and portfolio purposes. See [LICENSE](LICENSE) if present, or open an issue to clarify usage rights.
