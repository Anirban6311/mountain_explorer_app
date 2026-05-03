# Iteration 5a — Security Review

Scope: background location tracking + SOS GPS-trail attachment.
Methodology: confidence-scored findings, only those rated >= 80 reported.

---

## CRITICAL

### C1. Firestore rules do not validate `trekBreadcrumbs` shape, type, or size on `sos_alerts/create`  (confidence: 95)

- File: `firestore.rules` lines 92-113
- File: `lib/features/sos/data/models/sos_alert_model.dart` lines 32-35, 62-64

Behavior. The `sos_alerts` create rule requires `keys().hasAll([...])` but the
required-keys list does NOT include `trekBreadcrumbs`, AND the rule does NOT
use `keys().hasOnly([...])` to constrain the document to a known shape. As a
result a malicious or compromised client can write a `trekBreadcrumbs` array
of arbitrary size (e.g. 10,000 entries) or arbitrary content (objects with
extra fields beyond `ts/lat/lng/accuracy/altitude/battery`), and Firestore
will accept it. Even non-malicious clients on a future build could regress
the cap silently.

Impact.
- Storage / billing DoS: any signed-in non-anonymous account can inflate
  document size up to Firestore's per-doc ~1 MiB limit on every alert.
  Trail-only growth is the largest variable in the doc.
- Garbage data injection alongside legitimate fields means responders /
  future read paths cannot trust the trail.
- The owner-only update rule prevents post-create tampering by anyone but
  also prevents the owner from cleaning up their own bad data
  (`delete: if false` and update is restricted to `status`/`lastSeenAt`).
  Junk on create is therefore permanent.

Fix.
1. In the create rule add explicit shape constraints, e.g.:
   `&& (!('trekBreadcrumbs' in request.resource.data)
        || (request.resource.data.trekBreadcrumbs is list
            && request.resource.data.trekBreadcrumbs.size() <= 50))`
2. Prefer `keys().hasOnly([... full known field list ...])` so unknown
   top-level keys are rejected. Today an attacker can add any extra field
   with arbitrary content alongside `trekBreadcrumbs`.

---

## HIGH

### H1. SOS outbox payload (lat/lng trail, phones, emails) stored in plaintext sqflite  (confidence: 92)

- File: `lib/features/sos/data/datasources/sos_outbox_local_data_source.dart`
  lines 56-69 (`payload_json` column, plain text)
- File: `lib/core/storage/local_db.dart` lines 22-72 (uses `package:sqflite`,
  not `sqflite_sqlcipher`)
- File: `lib/features/sos/data/models/sos_alert_model.dart` `toJson()`
  serializes uid, lat/lng, contact name+phone, userEmail, and up to 50 GPS
  breadcrumbs into the JSON column

`pubspec.yaml` declares only `sqflite: ^2.3.3+1`. There is no sqlcipher
dependency, no key derivation, and no documented privacy-risk
acknowledgement for the outbox.

Impact.
- On a rooted Android device or via `adb backup` (allowBackup default is
  true since the manifest does not set `android:allowBackup="false"`), the
  outbox DB is readable. The DB contains a near-complete trek trail plus
  emergency-contact phone numbers and the user's email — exactly the data
  the disclosure screen tells the user is "sent to your contacts," not
  "kept in the clear on your phone."
- iOS data-protection class for the file defaults to
  `NSFileProtectionCompleteUntilFirstUserAuthentication`, which is OK
  while the device is locked but not first-unlocked; a backup extracted
  from an unlocked phone is plaintext.

Fix.
- Switch outbox storage to `sqflite_sqlcipher` with a key stored via
  `flutter_secure_storage`. Or, at minimum, set
  `android:allowBackup="false"` on `<application>` in
  `AndroidManifest.xml` and document the residual privacy risk in the
  disclosure copy.
- Independently: confirm the retry-success delete path actually removes
  the outbox row so the plaintext trail is not retained after delivery.

### H2. iOS background-location consent path is non-functional — disclosure promises behavior the build cannot deliver  (confidence: 93)

- File: `ios/Runner/Info.plist` line 52 (comment: "UIBackgroundModes
  intentionally deferred to Iteration 5")
- File: `lib/core/services/location_service.dart` lines 232-237
  (`_buildTrekSettings` returns `AppleSettings` with no background-mode
  marker; `UIBackgroundModes: location` is not declared)
- File: `lib/core/consent/background_location_disclosure_page.dart` lines
  54-79 (text promises "even when the app is in the background or your
  screen is off")

Behavior. The disclosure screen tells the user the trek records "even
when the app is in the background or your screen is off," but the iOS
build does NOT declare `UIBackgroundModes: [location]` in `Info.plist`.
On iOS, without that key, the position stream is suspended once the app
enters background. The user is asked to grant `Always` location based on
a description that the iOS binary cannot honour — a misleading
permission request.

Impact.
- Privacy / regulatory: requesting
  `NSLocationAlwaysAndWhenInUseUsageDescription` for a behavior the
  binary cannot perform is a textbook App Store Guideline 5.1.1 risk and
  a deceptive consent under GDPR Art. 5(1)(a) ("transparency"). The
  Info.plist comment acknowledges App Store review risk for declaring
  `location` mode prematurely, but the code path that *consumes* the
  always-permission has now been shipped without the matching
  declaration.
- Functional: SOS alerts dispatched on iOS while screen is off will have
  zero or near-zero breadcrumbs in the Firestore document — exactly the
  scenario the trail was designed for.

Fix. Either (a) add `UIBackgroundModes: [location]` to `Info.plist` in
this iteration alongside the runtime code, or (b) hide the trek "Start"
control on iOS until 5b is shipped, AND change the disclosure copy not
to promise background recording on iOS.

### H3. No TTL / retention / user-redaction path for `sos_alerts` documents (incl. 50 GPS breadcrumbs)  (confidence: 90)

- File: `firestore.rules` line 112 (`allow delete: if false`)
- File: `firestore.rules` lines 104-111 (update is restricted to
  `status` and `lastSeenAt` only — owner cannot null out
  `trekBreadcrumbs` or `lat`/`lng`)
- No scheduled Cloud Function, no Firestore TTL policy referenced
  anywhere in the repo

Behavior. Once an SOS alert is written, the owner has no way to delete
it, redact the trail, or expire it. The rule explicitly forbids `delete`
and pins the updatable field set to `['status','lastSeenAt']`. There is
no Firestore TTL configuration documented for the `createdAt` field.
The trail is effectively immortal sensitive PII.

Impact.
- GDPR Art. 17 ("right to erasure"): the user has no in-app way to
  honour their own erasure request. A support workflow would have to
  involve privileged backend deletion which is undocumented and which
  the rules also forbid for any caller.
- A leaked Firebase service-account credential or a future rules
  regression on read exposes the entire historical trail of every user
  who has ever fired SOS.

Fix.
1. Configure a Firestore TTL policy on `sos_alerts.createdAt` (e.g.
   30 days for non-active alerts) — see
   https://firebase.google.com/docs/firestore/ttl. Document the policy
   in this repo.
2. Loosen the update rule to allow the owner to clear
   `trekBreadcrumbs`, `lat`, `lng` (e.g. to `[]` / `null`) when `status`
   transitions to `cancelled` or `resolved`. Or allow `delete` for the
   owner once `status != 'active'`.
3. The disclosure screen should mention the retention window so consent
   is informed.

---

## MEDIUM

### M1. Disclosure-screen gating depends solely on OS permission state — user can grant `Always` outside the app and never see the disclosure  (confidence: 85)

- File: `lib/features/trek/presentation/cubit/trek_cubit.dart` lines 75-95

Behavior. `start()` shows the disclosure ONLY when
`_location.hasBackgroundPermission()` returns false. If the user grants
`Always` location through the OS Settings app (e.g. while exploring
permissions for another reason, or after a previous denial), the next
trek start sees `hasPerm == true` and skips the disclosure entirely.
There is no persisted `prefs.hasSeenBackgroundLocationDisclosure` flag.

Impact. Google Play's "Location permissions: prominent disclosure" policy
requires the in-app disclosure to be shown *before* the OS permission
prompt AND before the feature first runs. Today the codebase satisfies
the former (only because `requestBackgroundPermission` is invoked in
`start()` right after the disclosure), but a user who arrived at
`Always` out-of-band has had no in-app prominent disclosure before the
first recording. Risk of Play Store policy strike.

Fix. Persist a boolean
(`AppPrefs.hasAcceptedBackgroundLocationDisclosure`) set to true on
`Allow` from the disclosure page. In `TrekCubit.start()`, gate on
`(hasPerm && hasAccepted)` rather than just `hasPerm`. Same for
`bootstrap()` — currently it can resume a trek session that pre-existed
the disclosure flag's introduction.

### M2. `bootstrap()` resumes a trek session without re-confirming consent state  (confidence: 82)

- File: `lib/features/trek/presentation/cubit/trek_cubit.dart` lines 48-66

Behavior. On app cold-start, if `AppPrefs.activeTrekSessionId` is set
and `hasBackgroundPermission()` is true, `bootstrap()` calls `_start()`
directly with no foreground check and no disclosure re-confirmation. If
the user revokes-then-regrants location in OS Settings between
sessions, or transfers the device to a family member, the trek will
silently resume on launch and write breadcrumbs.

Impact. Edge-case privacy: a user who killed the app expecting trek to
stop gets background recording resumed automatically on next cold-start
without any visible UI prompt.

Fix. On `bootstrap()`, if `hasBackgroundPermission()` is true but the
app has been backgrounded for >N hours, surface a "Resume trek?" prompt
rather than auto-resuming. Or stop persisting `activeTrekSessionId`
across full app kills.

---

## Residual / not-yet-tested security assumptions

- The `Routes.backgroundLocationConsent` page returns `true` only via the
  "Allow" button (verified in
  `background_location_disclosure_page.dart` lines 86-88). `PopScope`
  prevents dismissal returning anything other than `false` (lines 25-29).
  This part of the flow is sound.
- No `Logger`, `developer.log`, `debugPrint`, or `print` calls were found
  in `lib/features/trek/`, `lib/features/sos/`, or
  `lib/core/services/location_service.dart`. Lat/lng is not leaked to
  device logs in the new code. Verified by repository-wide grep.
- `ACCESS_BACKGROUND_LOCATION` is consumed by exactly one call site —
  `TrekRepositoryImpl._subscribeStream` via `trekPositionStream`.
  Verified by grep for `trekPositionStream` and `hasBackgroundPermission`.
  No other feature bypasses the consent gate.
- The `sos_alerts` update rule correctly prevents non-owner tampering
  with the trail (`uid` immutable, fields pinned to
  `status`+`lastSeenAt`). Trail tampering by the owner post-create is
  also blocked, which is a double-edged sword (see H3).
- The `createFromJson` outbox-replay path
  (`sos_alerts_remote_data_source.dart` lines 33-42) writes whatever
  JSON is in the outbox row. If an attacker with on-device root tampers
  with `payload_json` before retry, rule C1 still permits the write.
  Tightening C1 also closes this.
- No Firestore TTL policy is discoverable in code; if one exists in the
  Firebase console it is undocumented. Treat H3 as open until verified.
