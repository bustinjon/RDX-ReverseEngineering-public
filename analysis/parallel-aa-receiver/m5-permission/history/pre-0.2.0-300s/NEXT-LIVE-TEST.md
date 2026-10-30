# Next live test — M5 timing retry, not authorized now

Updated2026-10-23 after live M5 attempt and verified cleanup. **M4 PASS; M5 INCONCLUSIVE; M6 NOT AUTHORIZED.** User ended phone tests until later tonight. Live access ended17:48:25 EDT; no more ADB in this session. Both M4 and M5 packages were removed.

[Final M5 results](M5-LIVE-TEST-RESULTS.md), [raw evidence and validation](m5-live-20261023-173401-872/), [M4 PASS](M4-LIVE-TEST-RESULTS.md). Historical pre-M5 next-step plan preserved in NEXT-LIVE-TEST-after-M4-before-M5-20261023.md.

## What happened

M5 UID10050/untrusted_app ended at17:38:16.933. Phone first appeared17:42:58.732, then Honda switched22D9:2769→18D1:2D01 at17:42:59.481. The phone was over4min late for the180sec window. Zero permission requests/callbacks; target hasPermission unmeasured. No dialog was expected once M5 had already ended. No platform permission denial was demonstrated.

Current audited M5 is0.1.1-m5-single-port-180s, SHA90E95C898D41C233F1F4F79BD0A8E84C28C31D78458C165489716D45F801EA30, under m5-permission/build/20261023-173344-965/. It supports explicitly gated deferred unique18D1:2D01 selection, path pinning, one permission request max, own durable result file. It does not open/claim/transfer/AOA. Its180sec timer was inadequate for this actual7min42sec setup. Do not blindly start this build and repeat the same timing failure.

## Next OFFLINE preparation

Prepare a minimal longer bounded M5 wait (proposed10min), independently audit final APK and preserve this historical revision. Keep action/M4 acknowledgment/exact18D1:2D01/unique match/pinned path/one-shot nonce callback gates, own result persistence and all prohibited APIs absent. No active USB transport. Confirm operator readiness before starting and announce exact local/UTC deadline. The proposed10-minute revision has not been built and no retry was performed.

## Future LIVE scope — requires a new explicit instruction

M5 permission-only retry. Laptop/ADB and phone cannot coexist. Phone initially disconnected; capture concise baseline; install only exact audited M5; verify ordinary UID; arm only observed18D1:2D01. Verify WAITING then immediately instruct mode/cable swap. Watch normal M5 permission UI; only user may Allow, without default/permanent handler. At most one request, no opening afterward. Allow adequate time, reconnect, retrieve own /sdcard/Android/data/com.rdx.fullscreen.m5permission/files/m5-last-run.txt before uninstall, capture framework/Honda timeline and clean up. Do not interpret absent dialog or detached-device permission map as proof of denial. Stop on unexpected active behavior, crash, ambiguous target or identity mismatch.

No M6, AOA, interface ownership, GAL/TLS/AA protocol, decoder, fullscreen, input or display changes. No stock-AA suppression. Detector APK acquisition remains a separate read-only candidate, not implicitly added to a phone retry. No Honda private preference restoration.

## Preserved state

M5 uninstall/process/code/private/external/temp-APK absence verified. Factory AA exact package dump/APK hash and WM/display geometry unchanged. Normal Honda phone/lifecycle events occurred; private-data equality is not claimed. The detector logged M5 installation; no detector bypass or acquisition was performed.
