# T270 reconciliation (Claude, 2026-11-09)

Final build: T270-bundle 0DD9FE9CD8E1F17CC600A20708325BFA4A3B50B75404AAA1E100B45AFCD5069A, PASS 249 bundle checks.

Contents:
- 1.5-s media pre-buffer (guidance excluded)
- body/incoming stall logging
- PHONE_STATE / HFP-lost logging (READ_PHONE_STATE)
- AutoSave of logcat after stalls >= 3 s, HFP loss or call state

CODEX-T270.md: no blocker; six SHOULD-FIXes, all fixed:
- the pre-buffer timer starts only when audio is queued
- every queue clear resets the cushion
- body stalls also auto-save
- HFP-lost requires our peer and previous state connected
- unified retention (10 files)
- empty saves fail without pruning
- the manifest comment corrected

Accepted: a busy save consumes the 2-min allowance; delayed closures hold the application context only. Loop stopped.
