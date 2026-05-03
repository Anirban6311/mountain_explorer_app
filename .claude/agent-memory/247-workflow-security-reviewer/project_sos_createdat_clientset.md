---
name: SOS rule createdAt is client-settable
description: firestore.rules sos_alerts create whitelists createdAt without pinning to request.time, so a malicious client can pre-date or future-date the doc
type: project
---

The `match /sos_alerts/{alertId}` create rule lists `createdAt` in both `keys().hasAll(...)` and `keys().hasOnly(...)` but does NOT enforce `request.resource.data.createdAt == request.time` (or `is timestamp`).

**Why:** The `SosRepositoryImpl` always writes `FieldValue.serverTimestamp()` via `SosAlertModel.toMap`, so the legitimate path is fine. But the rule does not enforce server-time semantics. A tampered or future-build client could write `createdAt: Timestamp(now - 7h)` and the EC-3 cold-start `FlushExpiredAlerts` query (`createdAt < now - 6h`) would treat a brand-new alert as already expired (or vice versa, by writing a far-future timestamp to make the alert un-flushable).

**How to apply:** Whenever reviewing rule changes that touch `sos_alerts` create or `findExpiredActiveIds`/`markTimedOut`, recommend tightening to `request.resource.data.createdAt == request.time`. Same applies to `lastSeenAt` if the rule pattern is reused. Also relevant for any future rule that filters by createdAt server-side (e.g. TTL policy).
