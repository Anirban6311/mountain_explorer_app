# Iteration 5a — Test Review (Trek + SOS breadcrumb piggyback)

Scope: `test/unit/features/trek/**`, `test/unit/features/sos/**` (extended), `test/widget/features/trek/**`, `test/widget/features/offline_maps/offline_maps_page_test.dart`. 443 tests pass after changes (up from 411).

Findings are scored 0-100. Only items at confidence ≥80 are reported.

## Severity summary

| Severity | Count | Headline                                                                  |
| -------- | ----- | ------------------------------------------------------------------------- |
| CRITICAL | 0     |                                                                           |
| HIGH     | 3     | Cadence flip-up not tested; no regression guard on initial 120s subscribe; outbox round-trip for breadcrumbs not asserted |
| MEDIUM   | 3     | 500-row cap evicts-by-ts not distinguished from evicts-by-insert-order; bootstrap+start-Failure path uncovered; old subscription cancellation only implicit |
| LOW      | 1     | `_FakeContext` in trek_cubit_test extends `Mock` not `Fake` (minor convention drift) |

---

## HIGH

### H1. Cadence flip-up (300s → 120s) on battery recovery is not tested — confidence 95

`TrekRepositoryImpl._onPosition` (lib/features/trek/data/repositories/trek_repository_impl.dart:139-142) supports BOTH directions: low→normal AND normal→low. The test suite only covers normal→low (`battery < 20% triggers re-subscribe with 300s interval`, trek_repository_impl_test.dart:119). A future regression that drops the `else if (!shouldBeLow && isLow)` branch would silently ship.

Add a test that:
1. Starts at battery=15 (mock returns 15 first), emits a position (flips to 300s).
2. Then mocks battery to return 80 and emits another position.
3. `verify(() => location.trekPositionStream(interval: const Duration(seconds: 120), ...)).called(2);` (once at start, once at recovery).

File target: `test/unit/features/trek/data/trek_repository_impl_test.dart`.

### H2. The 120s initial subscribe is not asserted in the cadence-flip test — confidence 90

In `battery < 20% triggers re-subscribe with 300s interval` (trek_repository_impl_test.dart:119-131), only the 300s call is verified. The setUp uses `when(...interval: any(named: 'interval'))`, so the test would still pass if a refactor accidentally skipped the initial 120s subscribe and went straight to 300s. Combine with H1 by asserting both calls explicitly:

```dart
verify(() => location.trekPositionStream(
      interval: const Duration(seconds: 120), ...)).called(1);
verify(() => location.trekPositionStream(
      interval: const Duration(seconds: 300), ...)).called(1);
```

File target: `test/unit/features/trek/data/trek_repository_impl_test.dart`.

### H3. SOS outbox round-trip for `trekBreadcrumbs` is not asserted — confidence 90

`SosAlertModel.toJson` writes `trekBreadcrumbs` as a list of maps (sos_alert_model.dart:62-64). The outbox repo `enqueueAlert` JSON-encodes that, and `createFromJson` (sos_alerts_remote_data_source.dart:33-42) overwrites `createdAt` / `lastSeenAt` only — `trekBreadcrumbs` must survive untouched. Coverage today:

- `sos_alert_model_test.dart` covers `toJson` shape (lines 88-126) — does not test jsonEncode/decode round trip.
- `sos_outbox_repository_impl_test.dart` enqueue test (line 44) only asserts `decoded['uid']` — no breadcrumb assertion.

Missing assertion that:
1. Enqueueing an alert with breadcrumbs produces a payload whose JSON-decoded form preserves `trekBreadcrumbs` shape (lat/lng/ts/optional fields).
2. `createFromJson` is invoked with a payload that still contains `trekBreadcrumbs` (capture the argument and assert).

File targets: extend `test/unit/features/sos/data/sos_outbox_repository_impl_test.dart` (round-trip assertion) and add a `createFromJson` integration test using `fake_cloud_firestore` if the project pattern allows, or a `_MockRemote` capture test.

---

## MEDIUM

### M1. 500-row cap test does not distinguish "evict by ts" from "evict by insert order" — confidence 85

`trek_breadcrumbs_local_data_source_test.dart:45` inserts ts values 0..509 monotonically. Insert-order and ts-order coincide, so a buggy implementation that trimmed by `id` (insert order) instead of `ts DESC` would still pass. The DAO's correctness claim ("oldest by `ts` are dropped", trek_breadcrumbs_local_data_source.dart:7-8) is load-bearing because real position events can arrive out-of-order (cached batches, time-zone clock skew, retried inserts).

Add a test that inserts ts values in non-monotonic order (e.g., interleave high and low timestamps) so that insert order ≠ ts order, exceeds 500, and asserts the retained set is the top-500 by `ts` regardless of insertion sequence.

File target: `test/unit/features/trek/data/trek_breadcrumbs_local_data_source_test.dart`.

### M2. `bootstrap()` + permission granted + `start()` returns Failure path is not covered — confidence 85

trek_cubit.dart:65 (`await _start();`) discards the Result. If `start()` fails (e.g., UnknownError wrapping a Uuid generation failure), the cubit silently swallows the failure with no state emission on the cubit side. The path is reachable from a real cold-start. Add a test:

```dart
test('bootstrap re-issues start; on Failure stays Idle (no TrekError emitted)', ...
  await prefs.setActiveTrekSessionId('s1');
  when(() => start()).thenAnswer((_) async => const Failure<String>(UnknownError('boom')));
  ...
  expect(cubit.state, isA<TrekIdle>());
);
```

This locks down current behavior so a future change (e.g., emit `TrekError` on bootstrap failure) becomes a deliberate spec change rather than an accidental one.

File target: `test/unit/features/trek/presentation/trek_cubit_test.dart`.

### M3. Old subscription cancellation on cadence flip is only implicit — confidence 80

`TrekRepositoryImpl._subscribeStream()` calls `_positionSub?.cancel()` before re-subscribing (trek_repository_impl.dart:105). The current cadence-flip test verifies the new subscribe happens but not that the old subscription stopped. Because the test uses a `broadcast` controller, a regression that drops the cancel would still pass — but in production it would mean two `_onPosition` listeners insert duplicate breadcrumbs every event after a flip.

Direct assertion via mocktail is awkward (StreamSubscription is not mockable through `LocationService`). Indirect assertion is reliable: emit a position AFTER the flip and verify `ds.insert` is called exactly once (not twice). Today's test does emit before the flip but never after — extend the test to emit one more position post-flip and assert `verify(() => ds.insert(any())).called(2)` (once before flip + once after, NOT three).

File target: `test/unit/features/trek/data/trek_repository_impl_test.dart`.

---

## LOW

### L1. `_FakeContext extends Mock implements BuildContext` is mild convention drift — confidence 80

trek_cubit_test.dart:155 uses `class _FakeContext extends Mock implements BuildContext`, while the project convention (per the SOS / offline_maps tests) is `_FakeXyz extends Fake implements …` for stand-ins that are only needed to satisfy the type system, and `_MockXyz extends Mock implements …` for objects whose methods are stubbed. The context here is never used (permission is granted in setUp), so `Fake` is the right choice. Cosmetic; no test correctness issue.

File target: `test/unit/features/trek/presentation/trek_cubit_test.dart`.

---

## Items checked and judged OK (≥80 confidence in "no finding")

- **Cold-start resume coverage** — all three branches present (trek_cubit_test.dart:70, 78, 90).
- **`offline_maps_page_test.dart` `_MockTrekCubit` registration** — `getIt.registerSingleton(trekCubit)` does NOT pass a `dispose:` callback (offline_maps_page_test.dart:178), so `unregister<TrekCubit>()` will not call close on the mock. The production registration in `trek_module.dart:50` uses `dispose: (c) => c.close()` for the lazy-singleton factory, but a registered instance overrides that path. Behavior is correct; no flake risk.
- **`trek_toggle_button_test.dart` does not use `whenListen`** — confirmed no test in the repository uses `whenListen` (`grep -rn whenListen test/` returns no hits). The convention here is `when(() => cubit.state).thenReturn(...)` + a single `pump`. The new file is consistent with that convention. No state-transition mid-pump scenarios are covered, but no existing widget test in this repo does that either.
- **Fallback registration for `BuildContext`** — correctly registered (trek_toggle_button_test.dart:28).
- **SOS happy path attaches crumbs / fetch failure falls back to empty** — both covered (sos_repository_impl_test.dart:159, 183).
- **`under cap` and `at cap` insert behavior** — covered (trek_breadcrumbs_local_data_source_test.dart:30, 45).
- **`stop` cancels subscription / clears prefs / null-emits on stream** — covered (trek_repository_impl_test.dart:133).

---

## Validation commands

```bash
# Full suite (project convention)
flutter test

# Just the affected files
flutter test test/unit/features/trek/ test/unit/features/sos/ \
             test/widget/features/trek/ \
             test/widget/features/offline_maps/offline_maps_page_test.dart
```
