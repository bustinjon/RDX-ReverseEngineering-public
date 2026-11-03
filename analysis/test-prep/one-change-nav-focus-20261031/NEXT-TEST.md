# First isolated candidate: Maps navigation focus

Prepared only; not installed. Use candidate.json, not latest-build.txt (which still points to the larger media candidate).

APK: analysis/parallel-aa-receiver/usb-helper/build/20261031-142134-610/rdx-usb-helper-v6h-nav-focus-a.apk

SHA-256: 21037DC393FCD162499589254D745DD0904A326BD7E5A33D69CF3FC69BFA4084

Only production difference from the successful rollback baseline: navigationFocusCallback preserves a valid requested native/projected focus state instead of always replying native. Existing numeric logging/invalid-value checks accompany that callback. No input/media/volume fixes are included.

## First gate: Diagnostics access

An authorized live operator must install/verify the pinned candidate while keeping helper and permission auto-clicker stopped, phone unplugged and accessibility at the recorded baseline. Preserve normal target/readiness checks. The baseline installer is pinned to D1A29 and must not be run unchanged to install this candidate. This agent may not run ADB under AGENTS.md.

Try the same manual three-button Diagnostics entry, then return normally to Home. Record result and full passive key trace if available. If entry fails, stop and capture evidence; do not stack another change or switch to the phone.

This matches the successful rollback's stopped-helper state. It does not reproduce the earlier failed candidate's armed-helper state. A stopped-helper pass alone cannot clear startup, permission-clicker or lifecycle behavior as possible causes. Reinstallation remains a transient-state confounder.

## Later route check, only after the live lead approves its scope

If Diagnostics access passes, use the existing Maps-only preparation and collection design linked in analysis/test-prep/maps-nav-focus-20261031/NEXT-TEST.md. Keep this same APK throughout. Check manual shortcut access separately after helper activation so activation is not silently conflated with the APK swap. No milestone is authorized or advanced by this document.

At the actual phone handoff, repeat all connection instructions from that canonical plan. The route comparison is two routes left active for at least 90 seconds each, with no media-button/Spotify experiments interleaved. Record focus request/reply values and actual route cancellation times. Missing focus requests or absent runtime evidence make the causal result UNKNOWN.

Do not test or add volume HUD, track controls, touchpad changes or other fixes in this candidate. Keep Git publication paused.
