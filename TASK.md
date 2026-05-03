# Iteration 3 Code Review — Mountains / Weather / Home

Scope: `lib/features/mountains/**`, `lib/features/weather/**`, `lib/features/home/**`, router + DI changes, legacy file deletions, new tests. 179/179 tests passing, analyzer clean for refactor scope. Findings below are limited to confidence >= 80 (plus a handful of noteworthy mediums/lows).

Clean-Arch boundaries verified: `lib/features/{mountains,weather}/domain/**` has zero imports of `flutter`, `firebase`, `http`, or `cloud_firestore` (only `equatable` + `core/errors`). Data layer owns all I/O. Router resolver correctly redirects `Unauthenticated` at `/mountains/search` (and every other new route) to `/login`, since none of them are in `_authRoutes`.

---

## CRITICAL

### C1. OPENWEATHER_API_KEY is shipped inside the app binary (confidence 95, Security)
`pubspec.yaml:67` still declares `- .env` under `flutter.assets`, and `lib/core/env/env.dart:14` reads `OPENWEATHER_API_KEY` from `dotenv`. Iteration 3 is the first iteration that actually *uses* this value at runtime (`lib/features/weather/di/weather_module.dart:17` wires it into `OpenWeatherMapRemoteDataSource`), so the pre-existing Iter-1 bundling debt is now actively shipping a live third-party API key in every release APK/IPA. Anyone can `unzip` the release and recover it. OpenWeatherMap free-tier keys are low-impact per-key, but this also sets the precedent for any future secret added to the same file.

Fix forward: move weather calls behind an authenticated Cloud Function / Firebase Callable that holds the key server-side; or at minimum restrict the key by bundle id and rotate it. Remove the `- .env` asset line and load secrets via `--dart-define` at build time or a runtime-fetched config. Tracked separately in `TASK_SECURITY.md`.

---

## HIGH

### H1. `MountainsRepositoryImpl.toggleLike` classifies errors by string matching (confidence 90, Bug risks / Code quality)
`lib/features/mountains/data/repositories/mountains_repository_impl.dart:39-43` does `e.toString().contains('permission-denied')` to pick `PermissionError` vs `UnknownError`. Firestore throws `FirebaseException` with a structured `.code == 'permission-denied'`; the string check silently breaks if Firebase ever changes its `toString()` format, and it also matches any exception whose message happens to contain that substring (false positives for logged messages, stack traces, nested causes).

Fix:
```dart
} on FirebaseException catch (e) {
  if (e.code == 'permission-denied') {
    return Failure<void>(PermissionError('Not allowed.', cause: e));
  }
  return Failure<void>(UnknownError('Failed to update like.', cause: e));
}
```
Importing `cloud_firestore` into the data layer is fine — the datasources already do.

### H2. `FirestoreMountainsRemoteDataSource.getMountains` has no error fallback, only an empty-collection fallback (confidence 85, Architecture / Bug risks)
`lib/features/mountains/data/datasources/mountains_remote_data_source.dart:25-31` falls back to the bundled asset **only** when `snap.docs.isEmpty`. Any Firestore error (offline, permission-denied, quota exceeded) propagates and the repository converts it to `UnknownError`, leaving the user on a generic error view even though a perfectly good bundled seed list ships on-device. The class-level doc on line 10 calls the asset a "fallback," so the intent contradicts the behavior. Offline users in particular see an error screen where the old GetX code surfaced content.

Fix:
```dart
Future<List<MountainModel>> getMountains() async {
  try {
    final snap = await _db.collection('mountains').get();
    if (snap.docs.isNotEmpty) {
      return snap.docs.map(MountainModel.fromFirestore).toList();
    }
  } catch (_) {
    // fall through to bundled asset
  }
  return _loadFromAsset();
}
```
Log the swallowed exception via the injected `Logger` so silent Firestore failures remain observable.

### H3. `MountainsCubit._prefetchWeather` is serial O(N) with no timeout (confidence 80, Performance)
`lib/features/mountains/presentation/cubit/mountains_cubit.dart:56-74` awaits weather one city at a time. For the bundled ~20-station list a single slow OpenWeatherMap response (p99 2–3s on mobile) stalls *all* subsequent chip renders behind it, so the last card can be weather-less for 60+ seconds on a poor connection. There is no per-request timeout — `http.Client` defaults are indefinite — so one hung socket wedges the prefetch pipeline until the cubit closes.

Serial is defensible only as rate-limiting, but OpenWeatherMap free tier is 60 req/min, easily absorbing 20 parallel. Recommend:
- `await Future.wait(cities.map(_prefetchOne))` with bounded concurrency (e.g., 5 via a simple semaphore), **and**
- wrap each `_getWeatherForCity` in `.timeout(const Duration(seconds: 5))` at the datasource.

At minimum add a timeout — today one hung socket halts everything.

### H4. Two live `MountainsCubit` instances + full reload on every drawer tap (confidence 85, Performance / Architecture)
`lib/features/home/presentation/view/home_shell.dart:27-39` creates a `MountainsCubit` via `getIt<MountainsCubit>()` (registered as `registerFactory` at `lib/features/mountains/di/mountains_module.dart:43`, so a fresh instance on every call) and calls `load()`. The drawer's "Liked mountains" entry (`home_shell.dart:131-133`) does `context.go(Routes.likedMountains)`, which under go_router *replaces* the top route — HomeShell is disposed, its cubit closed, and `app_router.dart:124-128` immediately builds a brand-new `MountainsCubit`, triggering another Firestore fetch + N weather HTTP calls. The same round-trip happens on the return journey. Home → Drawer → Liked → back pays ~40 weather requests and 2 Firestore reads for data that was already in memory.

Fix: change `mountains_module.dart:43` to `registerLazySingleton<MountainsCubit>` (same instance across routes), and guard `load()` with `if (state is MountainsLoaded && !force) return;`. The standalone `/mountains` and `/liked-mountains` routes should then read the shared cubit rather than recreate it.

### H5. Cold-start deep-link during `AuthInitial`/`AuthLoading` leaks an empty uid into Firestore (confidence 80, Bug risks)
`lib/app/router/app_router.dart:45-48` returns `null` (no redirect) for `AuthInitial`/`AuthLoading`. On a cold-start deep-link to `/liked-mountains` (or `/mountains`), the route's builder runs *before* AuthCubit has emitted its first Authenticated/Unauthenticated state: `_uidFromAuth` (line 167) falls through to `''`, and `MountainsCubit.load(uid: '')` → `_subscribeToLiked('')` → `_db.collection('users').doc('').collection('private').doc('likedMountains')`, which Firestore rejects with `invalid-argument` (empty path segment). The user sees an error banner on the very first frame of a deep-link.

Fix: have the resolver keep the user on `/` (or a splash route) while auth is loading, and render a `CircularProgressIndicator` at `/` until AuthCubit resolves. Alternatively, guard `MountainsCubit.load` against an empty uid and stay in `MountainsLoading` until a real one arrives.

---

## MEDIUM

### M1. `toggleLike` uses `arrayUnion/arrayRemove` inside a transaction after already reading the array — redundant (confidence 70, Code quality)
`lib/features/mountains/data/datasources/liked_mountains_remote_data_source.dart:36-53` runs a transaction that reads `mountainIds`, decides add vs remove, then uses `FieldValue.arrayUnion`/`arrayRemove` sentinels with `SetOptions(merge: true)`. The sentinels are race-safe, but the transaction's `txn.get` already gives the authoritative list — a plain `txn.set(ref, {'mountainIds': newList}, SetOptions(merge: true))` would be equivalent, simpler, and remove the cognitive overhead of reasoning about sentinel semantics inside a transaction. Current code is correct, just over-engineered.

### M2. `_prefetchWeather` ignores mountain-list changes between request start and merge (confidence 65, Bug risks)
`mountains_cubit.dart:64-71` awaits, then casts `state` back to `MountainsLoaded`. If a concurrent `load()` replaces the mountain list while the HTTP call is in flight, the fetched weather for "Shimla" is still merged into the new state even if "Shimla" is no longer present. The UI reads `state.weatherByCity[mountain.name]`, so the orphan entry is harmless memory; it never renders. Not a correctness bug today but fragile if `load()` ever becomes parameterized by region or filter.

### M3. `_prefetchWeather` can race with its own re-entrancy (confidence 65, Bug risks)
If `load()` is called twice (e.g., the retry button in `lib/features/mountains/presentation/view/mountains_page.dart:46-48`), two `_prefetchWeather` loops run concurrently. They dedup via `weatherByCity.containsKey`, but both can issue the same HTTP call for the same city if both observe the pre-populated state simultaneously. Symptom: 2× OpenWeatherMap traffic during retries. Fix: track a generation counter on the cubit and abort the older loop when a new `load()` starts.

---

## LOW

- `home_shell.dart:24-43` creates `HomeCubit` with the `BlocProvider` factory while `MountainsCubit` is pulled from `getIt` — inconsistent provider strategy, harmless but noisy.
- `mountain_search_cubit.dart:14-28` rebuilds `MountainSearchState` on every keystroke with no debouncing. Fine for ~20 mountains; flag if the source ever becomes paginated.
- `weather_model.dart:16-20` assumes `json['main']['temp']` exists; an unexpected payload throws a raw `TypeError` that the repository's bare `catch (e)` converts to `UnknownError("Weather fetch failed.")` rather than a more specific NetworkError. UX is fine, classification is lossy.
- Legacy `lib/Screens/Community/*` still compiles but is unreachable — the dangling imports and `firebase_database` coupling are tech-debt that will bite if they linger past Iter 4.

---

## Iteration 3 verdict

**Fix-forward** — ship Iteration 3; block only on C1 (rotate + scope the API key before the next public release) and file H1/H2/H4/H5 as follow-up tasks. No correctness-blocking bugs in the hot path; 179 tests green and Clean-Arch boundaries are honored.
