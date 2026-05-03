---
name: pubspec name is basic_crud_flutter
description: The Flutter package name in pubspec.yaml is `basic_crud_flutter`, not `mountain_explorer_app` — all `package:` imports use that name.
type: project
---

`pubspec.yaml` line 1 declares `name: basic_crud_flutter`, so imports look like `import 'package:basic_crud_flutter/app/router/app_router.dart';` even though the repo directory is `mountain_explorer_app`.

**Why:** vestige from the earlier project name; hasn't been renamed because it'd churn every test file.

**How to apply:** when suggesting new imports or grepping for usage, use `basic_crud_flutter`, not the directory name. If the user proposes renaming the package, flag that it's a cross-cutting change touching every test and any generated file referencing the package.
