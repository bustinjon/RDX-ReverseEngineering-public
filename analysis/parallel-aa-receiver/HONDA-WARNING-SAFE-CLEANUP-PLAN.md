# Safe project-artifact cleanup plan — NOT EXECUTED

**This phase is read-only. M5 remains installed/unarmed. No cleanup, reboot or detector change is authorized by this document.**

Current evidence finds only fresh M5 installed; the other six manifest-confirmed project package names and five known historical upload APKs are absent. No additional package/file removal is presently justified. The detector's true-only history bit can produce a warning after every boot even with no current research apps. Removing M5 therefore cannot be promised to clear the warning. [Analysis](HONDA-WARNING-DETECTOR-STATIC-ANALYSIS.md).

## Future order, only after separately authorized M5 arm/test

1. Keep this phase's evidence and frozen M5 hash. Do not arm automatically or substitute/rebuild the APK.
2. After a later explicit M5 arm, phone interval and laptop reconnection: retrieve logs before dump, reconstruct the durable journal, verify chunk/token/length/SHA256, run verdict analysis and hash all evidence. No automatic second permission request/test.
3. Only after successful evidence preservation, normally uninstall **com.rdx.fullscreen.m5permission**, without `-k`. Use the existing reviewed M5 helper stages. Inspect actual stage outputs; never treat an evidence failure as permission to discard the app's private journal.
4. Verify package/path/process absence and ordinary uninstall guarantees. Recheck factory Honda AA APK/hash/signer and display geometry. Do not claim Honda private-data equality.
5. Re-inventory the seven exact package names. If another clearly attributable project package appears, preserve package/version/UID/path/hash first; only an authorized normal uninstall may remove it. Do not remove unrelated third-party or Honda software.
6. If a future exact project staging APK is found, record path/hash and match it to the project inventory before proposing one exact file removal. None is found now; **no `rm` command is warranted**. Do not recursively clean tmp/sdcard/cache directories or ordinary evidence files.
7. If warning remains with project packages/files absent, STOP cleanup. The code supports a historical latch. Do not clear detector data, edit preferences, disable/stop/uninstall it, patch signatures/whitelists, touch package-manager internals or manually delete ART caches. No such commands are prepared.
8. A normal restart requires a later explicit user decision. It is not performed or requested now, and code predicts historical warning can recur after restart.

## Exact existing future helper sequence (not run here)

[Code block omitted from public report; see authored source where available.]

The cleanup helper performs M5 UNINSTALL and preservation POSTCHECK. The underlying normal removal is `adb -s 00000000 uninstall com.rdx.fullscreen.m5permission`; no `-k`, no detector operation. **Do not execute it during the present pre-M5 phase.**

Do not use the detector's “Remove all” button for project cleanup: it iterates its own in-memory list, potentially including software outside the explicit project scope, and does not reset its history bit anyway. Normal Dismiss only closes the current dialog; it does not erase history.

M6/M7 remain disabled/not authorized. Safe cleanup is removal of our confirmed artifacts, not suppression of Honda's detection mechanism. No permitted cleanup currently establishes a way to remove a detector-persisted historical warning.
