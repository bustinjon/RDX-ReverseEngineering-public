# Framework parity review: can build-14's framework.jar/services.jar be trusted for the M5 lock-task getter?

Written by Claude, 2026-10-26, after the live M5 session was stopped specifically because the readiness
guard refused to trust the car's actual system files. Status: Claude's comparison is DONE below; an
independent adversarial check from Codex is pending (`CODEX-FRAMEWORK-PARITY-ADVERSARIAL-REVIEW.md`) and
should be read alongside this before acting on it. **Nothing has been applied.** The proposed code change
is in `proposed-framework-pin/`, not in the live guard.

## Why this matters
`scripts/Test-M5ArmReadiness.ps1` will not even attempt the one read-only Binder call the whole guard
depends on (`service call activity 217`, i.e. `isInLockTaskMode()`) unless the car's live
`/system/framework/framework.jar` and `/system/framework/services.jar` hash-match the exact copies that
were reviewed line-by-line when the guard was designed (build 168). The live car reports build 14. This
mismatch has been a documented, accepted "UNVERIFIED" gap since the guard was first written — today's
live session is the first time it was actually hit.

## What I did
Pulled both live files off the car (read-only `adb pull`, during the actual session, before anything was
decided), decompiled them with the project's own jadx, and diffed the three files the getter actually
touches against the already-reviewed build-168 copies in `decompiled/Framework` and `decompiled/Services`.

| File | Diff vs build 168 | What matters, specifically |
|---|---|---|
| `ActivityManagerNative.java` (Binder dispatch) | **0 lines different** | Transaction 217's case block (reads nothing but the interface token, writes no exception, writes one int) is byte-identical. |
| `ActivityManagerService.java` (synchronized wrapper) | **0 lines different** | `isInLockTaskMode()` at line 6745, delegating to `mStackSupervisor`, is byte-identical. |
| `ActivityStackSupervisor.java` (the actual owner check) | **2 lines different** (4 in unified diff) | Both differences are a `throws InterruptedException` annotation appearing/not appearing on two *unrelated* methods (`startActivityUncheckedLocked`, `doPendingActivityLaunchesLocked`), nowhere near `isInLockTaskMode()`/`mLockTaskModeTask` (line ~2515), which is byte-identical. This kind of annotation-only difference is a known decompiler artifact, not a functional change. |

**Live hashes, for the record:**
- `framework.jar`: `BCED4FA8112E2A2D1EDA2FD0007EA962718BFFC08B2B9A9D9A3529A98EE3F2D6` (5,478,600 bytes)
- `services.jar`: `53F33BED0D73584F925932B363F0B1BF554F4FF56E489D0B4BDC7B8174453F57` (2,147,202 bytes)

Both files are preserved at `C:/Users/REDACTED\.claude\jobs\6b8797e0\tmp\live-framework-check\` (framework.jar,
services.jar, and their jadx decompilation) for anyone who wants to re-check this independently; they
should be moved somewhere durable before that scratch directory is ever cleaned up.

## What I did NOT check (being honest about scope)
This review is scoped exactly to what the guard uses: the one transaction, the one service method, the one
owner field. I did not diff every class in either jar. Codex's adversarial pass was explicitly asked to (1)
re-verify every claim above independently, (2) check the underlying Binder/Parcel plumbing (`Binder.java`,
`Parcel.java`, `IBinder.java`) for anything that could matter even with identical call-site text, and (3)
do a full recursive diff of both decompiled trees and flag anything else that changed, even if it looks
irrelevant to this narrow purpose.

## Recommendation (pending Codex's review)
If Codex's independent pass does not find anything that contradicts this, I'd recommend adding build-14's
two hashes as a **second accepted pair**, not a replacement for build-168 — the guard would then accept
either build, and still refuse anything else. The proposed one-block code change is ready and tested in
isolation (`proposed-framework-pin/Test-M5ArmReadiness.proposed.ps1`, `.patch`): parses clean, and the
accept/reject logic was verified standalone (old hash accepted, new hash accepted, a wrong hash still
refused). **This is a real trust decision, not a parsing-bug fix like this afternoon's two.** It should not
be applied without your explicit yes, even though you asked me to get everything ready.

## Codex's independent review: confirms, and goes further

`CODEX-FRAMEWORK-PARITY-ADVERSARIAL-REVIEW.md` reran this check from scratch, including reading the actual
compiled DEX bytecode directly (not just the decompiled Java text), and compared every byte of both ZIP
archives. The result is stronger than my own comparison:

- **The two framework.jar files differ by exactly 88 bytes; the two services.jar files differ by exactly
  36 bytes — and every one of those bytes is a ZIP file timestamp field.** The compressed DEX payloads
  (the actual compiled code) are byte-for-byte identical. This means there is no code difference anywhere
  in either file, not just in the three files I checked.
- The 25 Java source files that DO show text differences when decompiled (including
  `com.honda.auto.diagnosticsmanager.DiagnosticsManager.java`, which looked worth a second glance given how
  central Diagnostics is to this whole investigation) are confirmed to be decompiler noise — jadx
  reconstructing the same bytecode slightly differently between runs, not a real difference. This is proven,
  not inferred: given the whole-archive binary identity above, it is mathematically certain every class's
  bytecode is identical, so these text differences cannot reflect any behavioral change.
- Codex independently re-derived the transaction-217 dispatch, the AMS getter, and the supervisor's
  `mLockTaskModeTask` check directly from the DEX instructions and confirms the same conclusion: read-only,
  no arguments, no interruptible calls, no exception path relevant here.
- Two honest qualifications, both pre-existing and equally true of the original build-168 pin (not
  something new that build-14 introduces): the parser only accepts the normal zero-exception/one-boolean
  reply shape (anything else is already refused as unknown, which is the safe direction); and "inactive"
  means the task pointer is null slightly before some unrelated async status-bar cleanup finishes, which
  doesn't affect what this getter reports.

**Conclusion: SUPPORTED, independently confirmed.** Recommend adding build-14's hashes as a second trusted
pin, for this one getter, scoped exactly as described above. Still pending: your explicit approval to apply it.
