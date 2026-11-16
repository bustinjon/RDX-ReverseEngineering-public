# CLAUDE RECONCILES — T340 "choose the main phone on the car" (Codex review 2026-11-13)

Core safety property CONFIRMED by Codex: setup mode (no main phone) never takes over a phone or touches Honda
(no force-stop, VBUS reset, permission request, or AOAP switch). No direct takeover counterexample found across tick,
handleAttached, AUTO_GRANTED, ATTACH_BROADCAST, permission callback, LAUNCH, sticky restarts, AttachReceiver,
tryDirectGrant. Direct SET_MAIN/LIST/RENAME require DUMP (exported service permission); Settings reaches them in-process.
No rename shell-injection path. Six findings, all robustness/usability (P2/P3), none a security hole.

New APK after fixes: C3317BFDEF99DDC0B5248C4119FA42DD286491FA8AE35779DE51ADCFF03AA760 (versionName 0.9-T340, 277 checks).

## Disposition

- **F1 (list poisoning via exported UsbAttachActivity) — FIXED.** `rememberDevice` now resolves the device from
  `usbManager.getDeviceList()` by device name and reads identity (serial/vid/pid/class/product) from that live object,
  ignoring anything not currently reported as connected. A fabricated device forwarded through the exported activity is
  no longer recorded. (UsbHelperService.rememberDevice.)
- **F2 (wrong/stale pick, no on-car correction) — FIXED.** (a) `SET_MAIN_PHONE` now requires the chosen serial to be
  currently connected (`isConnectedSerial`), so a stale history entry or absent serial cannot be selected. (b) New
  `usb.CLEAR_MAIN_PHONE` action + a Settings "Clear main phone (start over)" button return to setup mode on the car with
  no laptop (stops wireless, clears phoneSerial/extras/mainDisabled/legacy, re-polls). Non-phone over-filtering NOT added
  (phones enumerate as varied classes; over-filtering risks rejecting real phones) — the presence check + on-car undo
  cover the practical risk.
- **F3 (discovery gap after handoff/stopped helper) — PARTIALLY FIXED.** `LIST_DEVICES` now enumerates currently
  connected devices before listing, so a device plugged in while a session was active or the helper was stopped is
  picked up when the installer asks. Not changed: recording during an active AA session's `tick` early-return (that path
  must not disturb a running session); adding a second phone mid-session remains an installer-time list refresh.
- **F4 (wireless restore gap on cold no-main-phone restart) — FIXED.** The no-main-phone daily/sticky skip now calls
  `restoreScans()` + `restoreStation()` before `stopSelf()`, matching the boot restore, so leftover paused networks /
  slowed scans are put back.
- **F5 (old null-serial legacy installs silently become setup mode) — ACCEPTED, no code change.** No real install is
  null-serial-legacy: the installer always configures a main phone via `CONFIGURE_HONDA_NEVER` with a serial; the old
  `CONFIGURE_LEGACY` any-phone mode was never shipped to an owner. The migration fails closed re Honda. If a legacy
  install is ever found, the owner completes on-car setup once. Documented, not blocking.
- **F6 ("last plugged in" is approximate) — ACCEPTED.** The owner asked for a most-recent-plugin indicator; the car
  clock is unreliable so no timestamps. The marker is best-effort (newest history entry); good enough to tell devices
  apart. Not presented as exact ordering.

## Unresolved (live-only, for the car test)
- Honda's actual DUMP enforcement, USB descriptor availability, other-brand AOAP behavior, SharedPreferences write
  latency — all UNKNOWN from static review; verify on the car.
- Settings layout is non-scrolling: confirm the setup hint + device list + new "Clear main phone" button fit on screen.
