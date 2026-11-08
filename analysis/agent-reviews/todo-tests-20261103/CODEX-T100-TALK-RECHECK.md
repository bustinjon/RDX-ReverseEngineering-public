**READY FOR CAR TEST** — source-review verdict for the scoped parked test; no live action authorized.

Path aliases:
`B=analysis/test-prep/todo-tests-20261103/builds/T100-bundle`
`H=B/source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper`
`R=C:/Users/REDACTED/AppData/Local/Temp/rdx-t100`

1. **Files inspected:** PROJECT-RULES.md, AGENTS.md, prior CODEX-T100-TALK.md; B/BundleTests.java; H/{InputEvents,AaSessionService,AaOverlayService,AaMediaSourceService,AppSettings}.java; bundled InputSource.java; Honda sources cited below.
2. **Files changed:** none.
3. **Commands run:** read-only Get-Content and rg; in-memory JavaScript branch models. No Git, network, builds or device commands.
4. **Tests/results:** prior mixed-key counterexample now ends with both keys released; 3,375 modeled paired-pulse cases produced zero final imbalances. TalkGate boundary model passed. Java/Android tests were not executed.
5. **Findings:**
   - **1 — OK:** per-key windows/releases and session reset fix the demonstrated held-key defect. With complete paired releases, no remaining held-key counterexample found. Lost or failed UP delivery remains **UNKNOWN**.
   - **2 — SHOULD-FIX:** accepted takeover design, default-off switch, dismiss-error suppression and call-mode stand-down are implemented. Call entry after the initial check can still precede Assistant delivery; this is a known limit, not an established parked-test BLOCKER.
   - **3 — SHOULD-FIX:** latch, separate dismiss thread and closed checks work as specified. Already-started dismissal can outlive closure; register/unregister remain synchronous. No new BLOCKER established.
6. **Primary evidence:**
   - **1:** H/InputEvents.java:35–50 implements per-key state/reset; H/AaSessionService.java:559–562 resets at startup. B/BundleTests.java:143–150 covers the previous trace/reset; actual release scheduling is H/AaSessionService.java:129–130 and H/AaOverlayService.java:404–408.
   - **2:** H/AppSettings.java:103–110 defaults talkVoice off; H/AaSessionService.java:200–218 checks call mode, requires successful Binder dismissal, then delays Assistant 400 ms without rechecking calls. Binder success at :190–192 does **not** prove native abort completion.
   - **2:** R/vrsvc/sources/com/honda/speechrecognizer/service/AbstractVrInputHandlerService.java:303–310,486 blocks focus during calls; R/vrlib/sources/com/honda/auto/voicerecognition/VrProvider.java:97–105 requires focus for active callbacks. R/vrsvc/sources/com/honda/tjba/speechrecognizer/SpeechRecognizerService.java:846–854 requests abort/hides UI.
   - **3:** H/InputEvents.java:57–64 latches for 30 seconds, shortened by NOT_ACTIVE to an 800-ms rearm. H/AaSessionService.java:170–178,203–210 shows closure, synchronous registration and worker dismissal; :206–208 suppresses subsequent Assistant work when closed.
7. **Assumptions:** supplied Honda decompilation represents the target; complete paired pulses model the intended routes.
8. **Unresolved uncertainties:** live binding, native abort completion, call-transition timing, next-press recovery and native key-delivery failures are **UNKNOWN**.
9. **Exact diff summary:** none; no files changed.
10. **Preservation checks:** only read/in-memory operations performed; no credential/private-material access or frozen-artifact writes. Hashes were not recomputed.