# Next isolated Maps-focus test

User: "Ok build the next test". Offline preparation only; no current device connection is asserted or authorized by this request.

Reuse the existing 21037 Maps-only APK with exactly one changed production method versus the car-tested D1A29 baseline. Do not rebuild an identical APK or add media, HUD, input or sensor changes. Package a conveniently named byte-identical candidate and preparation/collection entry points. Reuse fixed launcher runtime, status normalization and short-path pulls; keep the working launcher's default APK, files and saved recovery records unchanged.

Next live comparison: recover the preceding working-launcher session; install/prepare Maps-only candidate with helper and auto-clicker plus capture arming; check manual Diagnostics before phone connection; only after that pass test two Maps routes for at least 90 seconds. Save logs and clean up afterward. No milestone advancement or readiness bypass.

Acceptance: pinned APK/source inventory, only GalReceiver difference from baseline, copied preflight unchanged, generated scripts parse, offline CurrentSource plan passes, recovery precondition and manual Diagnostics gate explicit. All old APKs, guards, project Java and working launcher preserved. No ADB/key/Git operation during preparation.
