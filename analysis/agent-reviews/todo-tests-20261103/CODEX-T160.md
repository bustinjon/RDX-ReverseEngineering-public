1. **Files inspected:** `PROJECT-RULES.md`, `AGENTS.md`; T160/T150 source comparisons; T160 `BundleTests.java`; T70 strip/overlay and `RESULT.md`; T80 `RESULT.md`; canonical `BootBlockerService.java`.
   Path shorthand: `B=analysis/test-prep/todo-tests-20261103/builds`; `S=B/T160-bundle/source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper`.

2. **Files changed:** none.

3. **Commands run:** read-only `Get-Content`, `rg`, `Get-ChildItem`, `Get-FileHash`, `Compare-Object`, `fc.exe /N`, arithmetic checks. Python unavailable; initial FC paths and one arithmetic expression failed; corrected commands succeeded.

4. **Tests run and results:** no builds or executable tests run. Reviewed `B/T160-bundle/BundleTests.java`; arithmetic confirmed cutoff 1190.4, fallback (652.8,360), main buttons/text 83/24 px, Developer 59/20 px.

5. **Findings:**
   - **1 — BLOCKER:** session teardown drops the final strip UP. This is inherited shutdown ordering, newly relevant with scrolling enabled. Minimize, strip exit, main-area press takeover, steady-cursor isolation, and stuck-watch minimization otherwise look correct. No removed Pacer/track/settle references found.
   - **2 — OK:** 1177 is below 1190.4; 1870 is above it. Fallback y=360 avoids the top edge. Valid large-pane anchors retain T71 behavior, including their original y.
   - **3 — OK, source-level:** blackout defaults OFF; no dependency on its service was found. Persistent boot initiation remains independent and unchanged.
   - **4 — OK, static:** main has 12 items; Developer has 16. Sizing fits the stated 720 px budget. Schema 160 enables SIDE_SCROLL and disables BOOT_BLACKOUT; migration also resets existing switches to defaults.

6. **Primary evidence:**
   - **1:** `S/AaSessionService.java:1152–1155` disables sending/closes transport before overlay STOP at `1197–1200`; touchscreen delivery returns when not running at `529–530`. Overlay teardown calls strip release at `S/AaOverlayService.java:1031–1033,1074`. Thus its UP cannot reach the phone through this path.
   - **1, other paths:** `S/ScrollStrip.java:47–85`; `S/AaOverlayService.java:324–339,609–625,895,244–253`. Session options are captured at `S/AaSessionService.java:405`; T140 logic is unchanged from T150.
   - **2:** `S/ScrollStrip.java:20–21,41–44`; `B/T80-bundle/RESULT.md:12`; T71’s partial car result is `B/T70-bundle/RESULT.md:10`. FC showed only comments/constants/anchor fallback differ from T71.
   - **3:** `S/BootBlockerReceiver.java:38–43`; `S/AppSettings.java:38–40,98`; `S/PersistentBootService.java:23–28,45–54`; media-bind boot entry at `S/AaMediaSourceService.java:130`. Canonical `analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/BootBlockerService.java:31–60,63–104` only manages its temporary overlay.
   - **4:** `S/SettingsActivity.java:135–176,237–270,297–313`; `S/AppSettings.java:43,52–65,124`. Developer arithmetic budget: `59×8+150+72=694≤720`.

7. **Assumptions:** layout/anchor calculations use the supplied 1920×720 active geometry.

8. **Unresolved uncertainties:** phone cleanup of a held touch after transport closure is **UNKNOWN**. Exact pane boundary, rendered layout, and live scrolling remain **UNKNOWN**; the two anchors establish consistency, not boundary calibration.

9. **Exact diff summary:** no reviewer edits. Both source trees contain 36 files; five differ: AaOverlayService, AppSettings, BootBlockerReceiver, ScrollStrip, SettingsActivity.

10. **Preservation checks:** read-only operations only; no Git, network, devices, builds, or credential/private-test material accessed. T160 ScrollStrip SHA-256: `F5BC2B2AD4882F76CD080E2660496FB13672DD2A4A4DD35A518F0C4A048C3E4E`.

**Verdict: NOT READY — release held touches before disabling touchscreen delivery and closing the transport.**