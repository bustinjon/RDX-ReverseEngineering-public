# M5 / M6 USB permission strategy — 2026-10-25

**M5 permission does not provide a supported transferable grant to a separate M6 package. M6 must check/request its own exact-attachment permission after a reviewed M5 PASS. Frozen M5 remains unchanged.**

Local target evidence: `decompiled/Services/sources/com/android/server/usb/UsbSettingsManager.java`, lines818–833: hasPermission uses Binder.getCallingUid and the device-name→UID map. Lines967–978 grant a UID for that device name; lines618–620 remove the device grant map on detach. `UsbService` lines163–186 routes the calling user/UID. Public `UsbManager.requestPermission`, framework lines112–117, supplies the caller package. Neither a matching APK signer nor an application-chosen package string transfers another UID's grant. The UID1000/disabled-dialog special paths are not our ordinary-app design.

The single-port cable swap itself detaches the phone and invalidates the attachment grant. Even a consolidated same-package harness would need a fresh exact-device grant after detach/re-enumeration. Never depend on UID allocation/reuse or device-path reuse. M5's frozen retry targets18D1:2D01 **accessory mode**, whereas M6's allowed initial candidates are22D9:2769 or22D9:2765 **normal mode**. M5 proves that the ordinary-app permission path worked for its observed target; it does not prove permission timing or availability for M6's normal-mode identity.

|Strategy|Assessment|
|---|---|
|Separate M5/M6 packages|Preferred. Preserves the exact frozen M5 APK, isolates transfers/audits/journals/cleanup. Requires M6's own normal request/check.|
|Replace M5 with consolidated milestones|Changes frozen artifact and increases scope; detach still invalidates grants. Not selected.|
|Same project sharedUserId|Unnecessary lifecycle/signing/UID complexity; would not solve detach or normal/accessory identity changes. Not selected.|
|Honda/system/shared privileged UID|Forbidden and unnecessary for this experiment.|

Future flow, only after M5 review and separate M6 authorization: verify signed M5 evidence → select exactly one reviewed normal identity/generation → check M6's own hasPermission → if false, persist intent and request once with unique run nonce/package-scoped PendingIntent → operator manually ALLOW → validate nonce/device/attachment/callback and fresh hasPermission → open once → bounded AOA-only sequence. Deny/dismiss/timeout/stale callback never opens the device. Permission loss or generation change ends the run; there is no retry/reopen. Already granted permission skips the request but is rechecked before opening and every control transfer.

M4 observed Honda switch the phone in about0.75seconds in one sequence. A human permission dialog may lose that race. If Honda switches first, stop INCONCLUSIVE; do not disable Honda, manipulate preferences, claim interfaces or compete through retries. The implementation has no built-in inter-string sleep; it schedules bounded actionable steps promptly and polls waiting states at500ms. This is not a timing guarantee or evidence of exclusive ownership.

M5 authorization proof is **not a USB permission** and **not M6 authorization**. It is canonical signed review metadata plus SHA256 binding to the actual retrieved evidence bundle and exact A22E…8F40 artifact. The project review key is the independent local development identity; it is not a Honda/TLS credential. A manual boolean alone cannot create M5PassProof. Production loads the pinned public certificate from APK assets; no caller-provided verification key or synthetic proof intent is accepted. Host tests use a separate ephemeral test key/in-memory proof only. No real PASS proof was issued.

The frozen M6 APK has an additional unconditional **LIVE-DISABLED** block. No flag/intent/environment/debug option can activate it. A future separately reviewed activation release is a small explicit release task, not authorization granted by this offline work. See [frozen record](M6-AOA-FROZEN.md) and [future workflow](M6-FUTURE-LIVE-CHECKLIST.md).
