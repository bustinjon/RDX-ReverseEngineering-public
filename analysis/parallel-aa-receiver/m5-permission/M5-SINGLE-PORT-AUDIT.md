# M5 single-port revision independent clearance — 2026-10-23
PASS STATIC / READY FOR THE CURRENT EXPLICITLY AUTHORIZED M5 TEST ONLY.
APK SHA256 90E95C898D41C233F1F4F79BD0A8E84C28C31D78458C165489716D45F801EA30.
Version0.1.1-m5-single-port-180s/code2; min21/target22. API22 v1 signature and zipalign PASS.
Final APK independently inspected using aapt, JADX, DEXDUMP, complete DEX method/string/class inventories. Manual decompiled flow reviewed against source.
One Service .PermissionService, zero Activity, manifest permissions/receivers/intent filters/native libraries.
Exactly one requestPermission callsite; attempted=true precedes invocation; no rescheduled polling after selection. No openDevice/claimInterface/releaseInterface/controlTransfer/bulkTransfer/loadLibrary/MediaCodec/GAL/AA/AOA/root/shell/system mutation.
Existing action and m4_pass_confirmed gates retained. Exact device_name mode retained; single-port mode additionally requires explicit wait_for_target=true AND exact VID6353/PID11521 (18D1:2D01), refuses ambiguous matches, pins actual path/VID/PID before request and verifies returned identity and hasPermission.
Timeout180000ms total including discovery/dialog. Poll interval1000ms until single match, no automatic retry after request. START_NOT_STICKY. Own package external file m5-last-run.txt flushed per line; no storage permission. Nonce/package-targeted one-shot callback retained. Timeout/callback stops service, cancels pending callback, unregisters receiver, removes handlers and closes file.
SystemUI may trigger Honda foreground lifecycle effects. USB permission is expected to be device-lifetime state; after detach cannot infer earlier grant from current permission map. No claim of OEM private-state neutrality.
Historical source/manifest preserved in history/pre-single-port-20261023; old APK untouched.
