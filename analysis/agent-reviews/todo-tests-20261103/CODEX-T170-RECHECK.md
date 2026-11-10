**Verdict: NOT READY.** A replug can still leave the previous session’s nudge eligible during delayed initialization.

1. **Files inspected:** `PROJECT-RULES.md`, `AGENTS.md`, `analysis/agent-reviews/todo-tests-20261103/CODEX-T170.md`; T170 sources below, `AppSettings.java`; T160 P/I hashes.
   `J = analysis/test-prep/todo-tests-20261103/builds/T170-bundle/source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper`; W/A/S/P/I = `J/{WirelessProbeService,AaSessionService,SettingsActivity,PermissionClickService,InputEvents}.java`.
2. **Files changed:** none.
3. **Commands run:** read-only `Get-Content`, `rg`, `Get-FileHash`, and output formatting.
4. **Tests run and results:** static recheck only; P/I SHA-256 values match T160 exactly. No builds or runtime tests.
5. **Findings — each previous BLOCKER/SHOULD-FIX:**
   - **REMOVED — Hidden Developer menu:** swap controls removed from Settings; P/I match T160. `S:237`.
   - **REMOVED — Wrong Apple CarPlay node:** swap automation removed; same evidence.
   - **REMOVED — Stalled swap/retries:** swap automation removed; same evidence.
   - **REMOVED — Diagnostics lock-task exit:** swap entry removed; same evidence.
   - **REMOVED — Helper off/open failure:** swap launch removed; same evidence.
   - **REMOVED — Connected-phone USB switch:** swap controls removed; same evidence.
   - **NOT FIXED — Honda HFP/call safety:** `linkUp` remains logging only; call mode is rechecked before connect. Acceptable as an explicitly selected experiment risk, but call preservation is UNKNOWN. `W:124`, `W:144`, `W:152`.
   - **FIXED — Stop/deadline race:** tracked socket, shutdown close, cancellation recheck and independent deadline implemented. `W:150`, `W:152`, `W:154`, `W:532`.
   - **FIXED — Stale peer at announce/SDP:** announce clears the address; receiver reads the current request address. Startup timing caveat below. `A:816`, `W:95`, `W:102`.
   - **NOT FIXED — Session/variant consistency:** variant snapshot is fixed (`W:214`), but operator Stop still schedules an ended-session nudge (`A:415`, `A:1157`, `W:196`). Replug cancellation remains delayed until protocol initialization (`A:680`, `W:229`).
   - **NOT FIXED — Developer fit:** fewer controls, but minimum heights and wrapping columns remain; rendered fit is UNKNOWN. `S:237`, `S:298`, `S:303`, `S:311`.
6. **Primary evidence for verdict:** new AA session becomes active at `A:399`, then waits asynchronously for its surface (`A:411`, `A:429`, `A:459`). Before `A:680` increments the probe generation, the old five-second nudge (`W:79`, `W:203`) can pass `W:137` using the previous peer. This is a source-supported counterexample, not an observed runtime result.
7. **Assumptions:** parked experiment and explicit Nudge selection are the revised acceptance scope; default variant is Secure (`J/AppSettings.java:78`).
8. **Unresolved uncertainties:** live timing, HFP/call effects, rendered fit and installed-artifact parity are UNKNOWN.
9. **Exact diff summary:** none authored.
10. **Preservation checks performed:** before/after SHA-256 values unchanged for W/A/S/P/I. No Git, network, device, credential/private-material access, builds or milestone actions; frozen artifacts untouched.