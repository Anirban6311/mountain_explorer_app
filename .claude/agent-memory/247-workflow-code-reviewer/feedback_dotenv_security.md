---
name: flutter_dotenv assets leak keys into release binaries
description: Flag any API key loaded via flutter_dotenv's asset-bundling approach as a security issue — the key ships inside the compiled APK/IPA and is trivially extractable.
type: feedback
---

When `.env` is listed under `flutter.assets` in `pubspec.yaml` and loaded via `dotenv.load(fileName: '.env')`, the file is bundled as a regular asset in the release binary. Anyone with the APK can unzip and read it.

**Why:** this project chose `flutter_dotenv` to keep the OpenWeather key out of source control, but the `.env` listed at `pubspec.yaml:66` gets shipped to users anyway. Keys leak this way routinely — OpenWeather free-tier keys extracted from apps are a known abuse pattern.

**How to apply:** whenever reviewing code that uses `flutter_dotenv` for anything more sensitive than "which backend URL to call in dev", flag it as HIGH severity with these options in order of preference:
1. Server-side proxy that holds the key (best).
2. `--dart-define` + `String.fromEnvironment` so CI injects per-build (still extractable, but easier to rotate).
3. Platform secure storage for user-derived tokens (not applicable to bake-in API keys).
Do not accept "it's in .gitignore so it's safe" — gitignore protects the repo, not the binary.
