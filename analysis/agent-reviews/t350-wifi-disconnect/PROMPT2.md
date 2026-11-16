# T350 Wi-Fi disconnect protection v2 (socket read timeout) — CODEX ATTACKS, round 2

This is a RE-REVIEW. The first design (a frame-counting watchdog) was rejected after your round-1
counterexample (an ~11 s recoverable stall at
`analysis/test-prep/todo-tests-20261103/builds/T300-bundle/headunit-logs-20261110-153805/hackura-20261110-094547-auto-stall-8549ms.txt`).
It has been REPLACED. Attack the NEW design only. Read-only. Do not build or touch any device.

CLAUDE PROPOSES (break this):
"A byte-level read timeout of LINK_DEAD_MS=20000 on the AA Wi-Fi socket makes a truly dropped phone's
blocked read throw, so the existing abortIo()->shutdown() teardown runs and Honda's screen returns —
while a slow-but-alive link (bytes/pings still arriving, incl. the ~11 s recoverable stall you found)
never trips, USB is unaffected, and teardown now happens at most once."

## The new change (bundle T350-bundle vs T340-bundle), files to diff:
`analysis/test-prep/todo-tests-20261103/builds/T350-bundle/source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/`
- `AaSessionService.java`:
  - `tcpPipe(Socket s)` now calls `s.setSoTimeout((int) InputEvents.LINK_DEAD_MS)` before any read.
  - `readLoop` catch logs `T350_LINK_DEAD` for a `java.net.SocketTimeoutException` in tcpMode, else as before.
  - `abortIo()` now: sets running=false, closes transport every call, then an `aborting`
    AtomicBoolean.compareAndSet gate so only the first caller posts shutdown().
  - The round-1 frame-based `stuckWatch` tcpMode branch was REVERTED to T340 (`&& !tcpMode`).
- `InputEvents.java`: `LINK_DEAD_MS=20000` constant (the old `isLinkDead` predicate was removed).
- `AndroidManifest.xml`: versionName 0.9-T350.

## Attack these specifically (cite file:line vs primary evidence; say UNKNOWN when unproven):
1. SO_TIMEOUT semantics vs this code's partial-read loop: in `tcpPipe.readFully`, a SocketTimeoutException
   thrown MID-FRAME (after some bytes of a multi-byte read) — does the partial read reset the 20 s timer,
   or can a frame that dribbles in just under 20 s per in.read() stretch unboundedly? Is 20 s per-read or
   per-byte? Confirm against Java SO_TIMEOUT semantics. Does mid-frame timeout corrupt anything beyond the
   (correct) full teardown?
2. Does setSoTimeout actually apply to EVERY session read path? Is `tcpPipe` the only place TCP session
   bytes are read, for BOTH the inbound phone hand-off socket and the outbound head-unit-server (5277)
   socket? Any read before tcpPipe (bootstrap/RFCOMM in WirelessProbeService) that would NOT get the
   timeout — and is that correct (we only want the AA session socket timed out, not the BT bootstrap)?
3. False teardown: with the car pinging ~1/s and the phone replying, can a HEALTHY session still see 20 s
   with zero bytes at the socket? Consider: AA minimized/backgrounded long-term, voice/Gemini session,
   nav-only, phone screen off, audio-only playback. Does the phone keep sending at least one byte / <20 s
   in those states? If UNKNOWN, say so and name the state.
4. Re-run your round-1 counterexample against the NEW code: the 8549 ms header wait + 10896 ms body wait.
   Was that gap truly zero bytes at the socket for that whole span (would trip a 20 s... it is <20 s, so no),
   or could any single in.read gap exceed 20 s? Does the new design pass this case? Show the arithmetic.
5. abortIo idempotence: walk the races (reader catch, writer catch, pingLoop, byeBye, surface-lost,
   device-policy stop). Can shutdown() still run twice, or can the `aborting` gate wedge so shutdown()
   NEVER runs (e.g., set true then an early return path skips posting)? Can closing transport on a second
   caller while the first shutdown is mid-join cause harm? Is there a path where running=false + transport
   closed but shutdown never posted (session half-dead)?
6. Does `setSoTimeout` throw on this socket type/state (already-connected handoff socket), and is that
   throw handled (tcpPipe throws IOException — is the caller's path safe)? Could it leave the session in a
   bad state if it throws?
7. Regression: the write path, the freeze recorder, T250/T270 gap logging, and USB sessions — unaffected?

Report: files inspected, findings ranked P1..P3 with file:line evidence, whether the proposition holds,
assumptions, uncertainties, preservation checks.
