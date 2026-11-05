1. **Files inspected:** `AGENTS.md`, `PROJECT-RULES.md`, `analysis/agent-reviews/todo-tests-20261103/CODEX-BATCH3.md`; scoped candidate sources/manifests, baseline hashes, saved test outputs, caller sources, `CarTest.Core.ps1`, and local decompiled Android permission/media implementations.

Path aliases: `R=analysis/test-prep/todo-tests-20261103`; `C38/C39/C41/C43=R/builds/<corresponding candidate>/source/analysis/parallel-aa-receiver`; `H=usb-helper/source/com/rdx/fullscreen/usbhelper`; `P=src/com/google/android/projection/protocol`; `L=analysis/parallel-aa-receiver`.

2. **Files changed:** none.

3. **Commands run:** read-only `Get-Content`, `Get-ChildItem`, `rg`, `Select-Object`; Node filesystem/SHA-256 checks; attempted PowerShell parser inspection; an in-memory diagnostic-predicate check. No reviewed script was executed.

4. **Tests run and results:** candidate hashes **16/16 PASS**, baseline hashes **12/12 PASS**, baseline absence declarations **4/4 PASS**. Initial checker misinterpreted absence markers; corrected results above. Parser inspection was blocked by constrained language mode. Saved outputs report T38 **6**, T41 **11**, T43 **24** passing checks; these were inspected, not rerun.

5. **Findings and verdicts:** readiness covers this source review only; it authorizes no live action.

| Candidate | Finding status | Verdict |
|---|---|---|
| T38 | DPI finding **FIXED** | READY FOR CAR TEST |
| T39 | Browser gate/button flag **FIXED**; playback lifecycle **NOT FIXED** | NOT READY |
| T41 | Permission gate and extra-phone clearing **FIXED** | READY FOR CAR TEST |
| T43 | Remaining-object retention **FIXED**; narrower recovery scope **ACCEPTED** | READY FOR CAR TEST |

6. **Primary evidence for each finding:**

- **T38 — FIXED:** `C38/P/VideoSink.java:27` stores `layoutDpi`; `:47` reports it for configuration 0. Configuration 1 still reports its negotiated `143` at `:33`, `:48`.
- **T39 browser access — FIXED:** `C39/H/AaMediaSourceService.java:42` checks UID ownership; `:47` requires SYSTEM/UPDATED_SYSTEM; `:73` rejects other clients. This suffices for ordinary non-system browser clients under the supplied Honda system-app premise. It trusts all qualifying system apps.
- **T39 playback lifecycle — NOT FIXED:** state refresh occurs only at service creation, forwarding, and root requests (`AaMediaSourceService.java:33`, `:64`, `:74`). After PLAYING is published, AA shutdown changes `running=false` (`C39/H/AaSessionService.java:624`) without refreshing playback state. PLAYING can remain stale; the media session also remains active (`AaMediaSourceService.java:34`).
- **T39 media-button flag — FIXED:** only `FLAG_HANDLES_TRANSPORT_CONTROLS` remains (`AaMediaSourceService.java:26`).
- **T39 remaining third-party control — ACCEPTED platform-authorized exception:** an enabled notification listener can obtain active-session controllers without browsing. Evidence: `decompiled/Services/sources/com/android/server/media/MediaSessionService.java:355`, `:376`, `:661`; controller next/previous have no further caller gate in `MediaSessionRecord.java:1148`. Candidate callbacks then forward keys (`AaMediaSourceService.java:28`). Thus the system-app check does **not** establish Honda-only control.
- **T39 inherited exposure:** the unprotected exported AA session service still accepts STOP (`C39/usb-helper/AndroidManifest.xml:33`; `C39/H/AaSessionService.java:122`). This is an existing disruption path, not a regression introduced by these fixes.
- **T41 — FIXED:** DUMP protects the exported helper (`C41/usb-helper/AndroidManifest.xml:25`); CONFIGURE removes `extraSerials` (`C41/H/UsbHelperService.java:128`).
- **T41 callers — no source-level break found:** runner uses shell (`tools/car-test/CarTest.Core.ps1:66`, `:238`). UsbAttachActivity constructs a fixed AUTO_GRANTED intent (`L/H/UsbAttachActivity.java:36`); PersistentBootService starts the helper internally (`R/builds/T30-persistent/source/L/H/PersistentBootService.java:38`, with `L` expanded as above). Same-app callers pass before permission checks (`decompiled/Framework/sources/android/app/ActivityManager.java:1423`). `rg 'startService|UsbHelperService'` found no calls in `L/H/HelperActivity.java` or `L/H/OverlayTestService.java`.
- **T43 — FIXED:** failed audio-worker checks now prevent destruction of sensor/input/video/receiver and the “released cleanly” log (`C43/H/AaSessionService.java:653`, `:656`). Freeze detection is explicitly excluded (`R/builds/T43-self-recovery/test.json:17`, `:20`).
- **T43 residual — ACCEPTED for this scope:** AudioSink still calls nativeShutdown after a failed join (`C43/P/AudioSink.java:113`). Its playback worker contains no protocol JNI calls (`:178–219`); runtime/native safety remains **UNKNOWN**.
- **Add-Phone — requested checks FIXED:** actual file is `R/tools/Add-Phone.ps1:13`. Residual diagnostic weakness: the predicate accepts exit 0 plus “Starting service” even when output also contains an error; the in-memory counterexample returned `True`. API22 host/remote exit-status divergence is documented at `tools/car-test/CarTest.Core.ps1:63`.

7. **Assumptions:** candidates overlay the supplied baseline; Honda clients are system apps and shell holds DUMP, as supplied. Privileged/development DUMP grants and enabled notification listeners are trusted operator-authorized access.

8. **Unresolved uncertainties:** live DPI acceptance, Honda routing/deduplication, native termination, installed APK parity, and actual caller execution are **UNKNOWN**. No new regression from the fixes was established; the residual issues above remain.

9. **Exact diff summary:** none; review made no changes.

10. **Preservation checks performed:** baseline/candidate manifest checks passed as reported. No device, ADB, build, Git, network, credential/private-material access, or frozen-artifact modification occurred. Whole-workspace preservation was not independently established.