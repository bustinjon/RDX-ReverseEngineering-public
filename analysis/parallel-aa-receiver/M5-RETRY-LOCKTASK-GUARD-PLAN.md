# Frozen M5 retry — pre-arm lock-task guard

**OFFLINE PREPARED; no live readiness verdict issued.** Latest M5 is INCONCLUSIVE because Diagnostics blocked SystemUI UsbPermissionActivity. Permission API path REACHED; permission availability UNRESOLVED. [Exact reconstruction](M5-LOCKTASK-LIVE-FAILURE-RECONSTRUCTION.md). No APK/source change, rebuild, permission retry or enumeration reselection is needed.

## Predicate and policy

`M5_ARM_ALLOWED` requires all of the following:

1. Explicit serial00000000, exact recorded build14 RDX fingerprint, Android5.1.1/API22/armeabi-v7a.
2. The installed APK hashes to frozen A22E96490B9557AFF022893A8B8B7A08BB13CEC236E52704CDDAFA90A8EE8F40; expected package/code3/version0.2.0-m5-single-port-300s, ordinary UID.
3. INSTALL provenance: M5 absent from full normal package-manager `-u` inventory before install; exact successful normal installation; matching UID/install timestamps/boot UUID/run/serial/hash; `stopped=true`, `notLaunched=true`, installed/unhidden. Hashed host provenance is checked against current package state. It is not a signed device attestation.
4. No M5 or other project process/service; no other project package, including M6/projection/qualifier. M7 has no separate installed package in this project. Missing/unrecognized package/process/service output refuses.
5. Both framework binary hashes match the reviewed dispatch/implementation pair before the fixed read-only lock getter. Both getter replies in every snapshot say inactive; unknown/exception/hash mismatch refuses.
6. Honda Home uniquely resumed/focused in activity and window snapshots, same task throughout. Diagnostics or transient/mismatched focus refuses.
7. Baseline display real1920×720/density160/rotation0/ON; overscan screen1339×720, restricted1920×720, stable1339×720/system1920×720 match saved evidence. Only dumpsys is used by readiness; no display command mutation.
8. CHECK A, intermediate samples, CHECK B span at least **5 seconds**, at most2s between sample starts; each critical snapshot takes at most2s. Default polling delay400ms. All observations must pass; one unsafe/unknown sample ends that invocation without resetting the timer to conceal a transition.
9. At the actual ARM boundary, final critical sample age is at most2s. Run/serial/frozen hash/schema/sample count match. Check again after saving the one-shot ARM intent; an expired check stops without issuing ARM.

Five seconds is **CLEAN POLICY**, conservatively longer than the observed1.895s late exit. It is not a framework guarantee or proof of continuously unchanged state between polls. Optional checker duration can only increase to15s; no value below5 is accepted. Snapshot freshness, polling-gap and20s overall observation bounds are clean safety policy. A slow/unsupported target refuses rather than silently weakening these bounds. Future performance can only be assessed during a separately authorized session.

Fresh never-launched state is deliberately stricter than the previous LIST_RESULTS workflow. It establishes zero M5 execution/requests/private journals for this normal fresh installation without attempting to read private data or start a status Service. **Do not run LIST_RESULTS before this guard.** A previously launched installation is refused; preserve its evidence and review a fresh installation through normal authorized stages. Do not manually edit the proof file or force-stop an app to manufacture freshness. Zero runs is an inference from verified fresh state and the audited no-autostart APK, not a private-file read.

This distinction has saved target support: ActiveServices unstops the package before Service launch; Settings clears `notLaunched` during that transition. The original installed dump has both fresh flags true; the actual post-LIST_RESULTS dump has both false. The pure parser accepts the former and rejects the latter in a separate saved-evidence probe. Thus an unarmed cached M5 process from a harmless status call is still intentionally insufficient for this stricter guard.

## Tools and result contract

[Checker](../../scripts/Test-M5ArmReadiness.ps1), [pure parsers](../../tools/m5/M5ArmReadiness.ps1), [offline tests](../../tools/m5/Test-M5ArmReadinessOffline.ps1), [future staged runner](../../tools/m5/Invoke-M5FutureSession.ps1).

Future read-only invocation, **not executed in this session**:

[Code block omitted from public report; see authored source where available.]

Checker stdout is `READY_TO_ARM` or `NOT_READY_TO_ARM: <explicit reasons>`. Fresh output directory required. `readiness.json` schema1 contains result/reasons, UTC, host monotonic start/creation/final-sample times, duration, serial/run ID/frozen hash/sample count and inference limitations. `commands.json` records exact argument arrays/serial/times/exit/timeout and per-command raw stdout/stderr files; `samples.json` preserves parsed source snapshots. No ready result from this offline test suite is accepted as a live precheck.

ARM always invokes the checker internally, using the fixed prepared ADB path and a fresh output directory. No supplied result-file option, force/ignore/skip/debug bypass or cached precheck can authorize ARM. PREPARE remains host-only. INSTALL records fresh-install provenance. RETRIEVE records scoped permission-UI evidence; a repeated UI block conservatively forces INCONCLUSIVE. The frozen app's one-shot behavior is unchanged.

## Future operator workflow

1. Obtain separate M5-only authorization; laptop connected, phone disconnected. PREPARE/INSTALL only frozen M5 and capture baseline. Do not enter another test or alter factory apps.
2. Exit Diagnostics with its ordinary RETURN controls until Honda Home. No USB-mode toggle, force-stop, settings change, `am lock-task`, automated input or reboot.
3. Prepare unlocked awake phone/cable and screen visibility before ARM. Laptop and phone share one port. Do all preparation before the internal checker starts.
4. ARM runs slow identity/APK/framework verification first, then the five-second A/intermediate/B observation window. A refusal means **no swap and no ARM**. Framework mismatch requires a narrow read-only review of the pulled binaries, not a bypass. This live getter/latency path is still untested.
5. If READY is current, ARM immediately invokes the frozen Service once. Existing short initial ARMED/domain confirmation remains; no new post-arm diagnostics were added. Immediately unplug laptop and plug phone into the same port. The successful16.753s physical swap is retained; do not spend that interval in Diagnostics.
6. If standard M5 permission UI appears, manually ALLOW. No Always/default handler selection. Stock AA/accessory mode is not proof of grant.
7. After the bounded run, disconnect phone/reconnect laptop; retrieve/hash journal and logs before normal uninstall/postcheck; **STOP**. Do not arm again or reselect a device.

No safe phone-free USB-permission canary was established. Directly launching internal UsbPermissionActivity or forging extras is excluded. An unrelated permission/settings Activity would neither prove this path nor meet the side-effect requirements. The guard proves observed environmental conditions only, not that a later dialog must appear.

## Evidence and verdicts

Search current-run logs for SystemUI `.usb.UsbPermissionActivity` START, lock-task violation, ActivityManager/WindowManager rejection and SecurityException. The extractor scopes to matching M5 ARMED→SERVICE_END when those markers remain in logcat; missing markers require broader manual review, never inferred success. Old rejection logs outside that run are excluded when scope is established. Full raw logs are always preserved.

PASS still requires one request, accepted nonce/device-validated callback, granted and verified `hasPermission=true`. Complete demonstrated restriction may support FAIL after review. No callback, UI block, transition/setup ambiguity, disappearance, missing evidence or timeout is INCONCLUSIVE. A returned SDK call is not a grant. Device re-enumeration still ends the selected M5 run without retry.

## Validation and limitations

Seven saved input fixtures cover real Diagnostics/Home/window/display/package data and the rejection log. Synthetic Parcel replies are explicitly labeled; there is **no saved successful live getter reply**. Fake-time0.5/1.9/2/3s are refused and5s allowed only with all other conditions. Randomized1000-case corpus seed20261025 combines lock/unknown/foreground/M5/process/inventory/display/timing failures with an independent accept/refuse oracle. The exact results are stored with the [session](m5-locktask-guard-20261025-195507/).

No vehicle, phone, physical USB, ADB, permission UI, control transfer, M6/M7 or detector cleanup was executed. This preparation is not a current `READY_TO_ARM` result. M5 remains frozen; M6 remains disabled. The next live action requires car + phone and separate M5 retry authorization.
