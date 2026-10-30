> CURRENT STATUS — 2026-10-23 after live access: M4 PASS. M5 INCONCLUSIVE due timing, zero requests/callbacks; M5 cleanly removed. No more phone tests until later tonight. See M5-LIVE-TEST-RESULTS.md and the newest dated section below. Earlier M4-pending/0.1.0/45sec statements are historical.

# M5 — BUILT BUT DO NOT RUN BEFORE LIVE M4 PASS

2026-10-23 continuation. Previous source-only plan is preserved in M5-USB-PERMISSION-TEST-before-clips-foundation.md. No installation or permission request performed. Next live milestone remains **M4 ONLY**.

## Artifact

Package com.rdx.fullscreen.m5permission; version0.1.0-M4-PASS-REQUIRED/code1; min21/target22.
APK m5-permission/build/20261023-112129-849/rdx-m5-permission-0.1.0-M4-PASS-REQUIRED-development.apk.
SHA256 757726DE360D466ACE5F7C12A90DE5B4377F2BD19D8D4BD8C13879967FDE95C8.
Development signer SHA256 c001f59b25081ddfc73937155ca3580717e817c45c66e68b9e059737b0b28831.
V1/API22 signature/zip alignment/aapt/JADX/DEXDUMP/reference/source/manual-flow checks PASS. One headless Service .PermissionService, no requested permissions/shared UID/manifest receivers/filters/Activities/native/assets. See m5-permission/M5-INDEPENDENT-AUDIT.md.

## Hard gate and finite behavior

Explicit operator action REQUEST_ONCE_AFTER_M4_PASS, acknowledgment m4_pass_confirmed=true, exact known device_name/vendor_id/product_id. It enumerates and verifies that exact current device; null service/absent/mismatched device or missing gate stops without requesting. Already-authorized returns without request. Otherwise one requestPermission call; active duplicate starts ignored; attempted latch prevents another request in the Service lifetime; callback validates nonce/path/VID/PID/hasPermission;45sec timeout/no retry/START_NOT_STICKY. Stop cancels PendingIntent/unregisters callback/removes timers.

The acknowledgment flag is not proof M4 passed. Operator must provide real M4 evidence and obtain separate M5 authorization. No openDevice/claim/release/control/bulk/reset/AOA/GAL/AA/media/native/root/default handler/OEM manipulation exists. No automatic USB/boot/install start. Constructor/installation alone cannot request permission.

## Future commands only — NOT part of NEXT-LIVE-TEST

After live M4 PASS, review exact device identity and authorize M5 separately. Set $Serial and $Apk to verified values; use the audited hash. Install normally with no -r. Then:

[Code block omitted from public report; see authored source where available.]

Choose normal system permission UI only. Do not change always-use/default association. Monitor RDX.M5, SystemUI, ActivityManager, APP_LAUNCHED/GalPrefs and detector logs. M5 is not lifecycle-neutral: SystemUI may resume and factory may react independently. Callback permission flag alone is insufficient; same-device actual grant/current inventory must agree. A grant is not an interface claim.

Denial/missing dialog/lock-task refusal/detach/timeout/crash/identity mismatch means STOP, not privileged grant or retry. PendingIntent cancellation does not necessarily dismiss a SystemUI dialog already shown or undo a later grant. Close it through normal UI, record state and normally detach phone. Verify own package/process absence; do not claim uninstall restores all USB/OEM history. No hidden MANAGE_USB route or stock suppression.

## 2026-10-23 actual M5 single-port session — INCONCLUSIVE, cleaned up

This dated result supersedes earlier next-M4/no-install statements above without rewriting them. M4 is PASS. User separately authorized M5; old0.1.0 could not select an absent phone before the cable swap. New0.1.1-m5-single-port-180s/code2 was built and independently audited/manual-flow reviewed before install. APK build/20261023-173344-965/rdx-m5-permission-0.1.1-m5-single-port-180s-development.apk (relative to m5-permission/), SHA25690E95C898D41C233F1F4F79BD0A8E84C28C31D78458C165489716D45F801EA30, same signer/min21/target22. See M5-SINGLE-PORT-AUDIT.md inside m5-permission/ and M5-LIVE-TEST-RESULTS.md.

The actual Service starts with REQUEST_ONCE_AFTER_M4_PASS, m4_pass_confirmed=true, wait_for_target=true, vendor_id6353,product_id11521. Deferred mode only accepts the exact18D1:2D01, refuses multiple matches, pins actual path before at most one request. Exact supplied device_name mode remains. Total180sec timeout,1sec polling, START_NOT_STICKY, own flushed external m5-last-run.txt, no new manifest permission. No open/claim/transfer/AOA/native/media/Honda control. No Activity.

UID10050/untrusted_app,172 passive samples; START17:35:16.889, TIMEOUT17:38:16.933. Phone first system attach17:42:58.732 (22D9:2769), Honda accessory18D1:2D01 at17:42:59.481. No overlap: ZERO requestPermission invocations/callbacks, target permission UNMEASURED. User saw no prompt, regular Honda AA connected. This is timing-INCONCLUSIVE, not grant denial. Own file survived/retrieved normally through /sdcard alias. No repeated test. User ended phone tests until later tonight.

M5 uninstall Success; package/process/code/private data/own external/temp install APK absent. Factory AA package/APK bytes and geometry preserved; private runtime/preferences equality not claimed. Captured window contained no FATAL/ANR/AVC. Detector installation event observed, not suppressed. Live access ended17:48:25 EDT and no more ADB followed. A10-minute retry was proposed but not authorized/built/run. Next offline work: adequate bounded deadline + operator-ready procedure; next live candidate: separately authorized corrected M5 only. M6 remains disabled/unexecuted.
