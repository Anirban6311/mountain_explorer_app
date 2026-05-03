---
name: Outbox sqflite plaintext carryover
description: SOS outbox stores the full alert payload (lat/lng, phones, email, last-50 trek crumbs) as plain JSON in sqflite, with AndroidManifest allowBackup default true
type: project
---

`SosOutboxRepositoryImpl.enqueueAlert` writes `jsonEncode(SosAlertModel.toJson(alert))` into the `sos_outbox.payload_json` column. The DB is plain `sqflite`, not `sqflite_sqlcipher`. `AndroidManifest.xml` does NOT set `android:allowBackup="false"` — `adb backup` and rooted-device extraction yield plaintext.

**Why:** Originally raised as Iter 5a H1 (TASK_SECURITY.md). Iter 5b did not change the outbox layer, so the finding remains open. Re-confirm by re-reading `lib/features/sos/data/datasources/sos_outbox_local_data_source.dart` and `android/app/src/main/AndroidManifest.xml` — both unchanged in 5b.

**How to apply:** When reviewing any future SOS-related diff, re-grep the outbox files for the at-rest hardening (sqflite_sqlcipher import + allowBackup attribute). Treat as carryover risk; do not re-report at HIGH unless the diff *widens* exposure (e.g. adds a new sensitive field to the payload). Iter 5b's diff did not widen — same payload shape as 5a.
