# T350 Wi-Fi disconnect protection — CODEX ATTACKS

CLAUDE PROPOSES (the claim you must try to break):

"When the phone leaves the wireless Android Auto link (walks out of range / Wi-Fi drops), Hackura
now reliably ends the frozen session within ~8-10s so Honda's screen returns and a reconnect can
happen — WITHOUT ever falsely tearing down a healthy-but-idle Wi-Fi session, and without breaking
USB sessions or the existing stuck-screen behavior."

Find counterexamples. This is read-only. Do not build, do not touch any device.

## The change (new bundle T350-bundle, copied from T340-bundle)
The canonical source tree is `analysis/parallel-aa-receiver/usb-helper/source/...`. The T350 edits
live in the bundle copy at:
`analysis/test-prep/todo-tests-20261103/builds/T350-bundle/source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/`

Changed files (diff T340-bundle vs T350-bundle):
- `InputEvents.java` — new `public static final long LINK_DEAD_MS=8000;` and
  `public static boolean isLinkDead(long nowMs,long lastDataMs,boolean tcpMode)`.
- `AaSessionService.java` — `stuckWatch` Runnable: added a `tcpMode` branch that, when
  `InputEvents.isLinkDead(now, lastGalMs, true)` is true, logs `LINK_DEAD` and calls `abortIo()`.
  The USB (`!tcpMode`) branch is the unchanged T150 stuck-screen behavior.
- `AndroidManifest.xml` versionName 0.9-T350; `BundleTests.java` adds 8 isLinkDead checks.

## Key facts to verify against primary evidence (cite file:line)
1. `lastGalMs` semantics: is it updated on EVERY inbound GAL frame header (all channels: ping reply,
   audio, media, video), or only some? If only some, the "all traffic" claim is wrong. See `readLoop()`.
2. Ping cadence: does `pingLoop()` actually generate ~1Hz inbound traffic on a healthy idle link, so
   `lastGalMs` stays fresh when the picture is static? Confirm the phone's reply path updates lastGalMs.
3. `stuckWatch` lifecycle over Wi-Fi: is it scheduled for tcpMode sessions, does it self-repost every
   STUCK_CHECK_MS even after frames stop, and is it cancelled on shutdown so it can't fire twice or
   leak? Does calling `abortIo()` from the handler thread (where stuckWatch runs) deadlock or re-enter?
4. False-positive windows: at session start, during the handshake before the first frame, when AA is
   minimized/hidden, during Gemini/voice (nativeFocus), during a legitimate Wi-Fi scan stall — can
   `lastGalMs` legitimately be stale >=8s on a STILL-connected phone? Enumerate every path.
5. Double-teardown / races: can abortIo() run concurrently with byeBye(), a real read IOException, an
   operator STOP, or shutdown() already in progress? Is `running`/`stopping` enough to make it idempotent?
6. Reconnect after teardown: does ending this way leave ReconnectPolicy in REARM (not DISABLE), and is
   there a mechanism that actually re-establishes the Wi-Fi session when the phone returns, or does the
   user end up stuck on Honda's screen with no AA until a manual action?
7. Restart-budget thrashing: MAX_RESTARTS=3 per 10min. Could a flaky-but-present link trip repeated
   8s teardowns and exhaust the budget (DISABLE), making things WORSE than the frozen screen?
8. Is 8000ms defensible given the recorded stall evidence (T250_READ_GAP, T280 freeze recorder,
   stall auto-save at 3000ms)? Is there any observed legit gap >= 8s?

Report: files inspected, findings ranked by severity (P1..P3) with file:line evidence, any way the
proposition is false, assumptions, uncertainties (say UNKNOWN when unproven), preservation checks.
