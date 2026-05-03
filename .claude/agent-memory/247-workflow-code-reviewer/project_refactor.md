---
name: Clean Architecture + MVVM refactor
description: Ongoing refactor of the Flutter mountain-explorer app; iteration 1 is foundation (DI, router, theme, shared widgets). Old screens live under lib/Screens and are being migrated.
type: project
---

The mountain-explorer app is being refactored from ad-hoc GetX navigation to Clean Architecture + MVVM. Iteration 1 (reviewed 2026-04-17) landed the foundation: `lib/app/` (MaterialApp + GoRouter), `lib/core/` (di, env, errors, storage, theme, utils), `lib/shared/widgets/`, plus unit/widget tests under `test/unit` and `test/widget`.

**Why:** to decouple navigation from controllers, move secrets out of source, and establish a Result/AppError-based error contract before feature modules are rebuilt.

**How to apply:**
- Legacy screens in `lib/Screens/` (PascalCase folder, mixed casing files) are referenced from the new router as `Routes.legacyHome` / `Routes.legacyScreenOne` — treat them as temporary; new work goes under `lib/features/<feature>/` when iterations 2+ start.
- `OnboardingController` still takes `BuildContext` — flagged as iteration-2 cleanup, not a blocker.
- Firebase is Android-only right now (`lib/firebase_options.dart` throws for iOS/macOS/web). Running `flutterfire configure` is an explicit follow-up.
