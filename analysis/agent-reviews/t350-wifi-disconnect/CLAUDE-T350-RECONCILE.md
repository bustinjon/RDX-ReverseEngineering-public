# T350 Wi-Fi disconnect — CLAUDE RECONCILES (after CODEX ATTACKS)

Codex review: `CODEX-T350.md` (model gpt-6.1-sol, read-only). It broke the first design with
**primary evidence**, so the mechanism was redesigned. Summary of what each finding changed.

## Design change driven by the review
**Before (rejected):** a frame-counting watchdog on the 2 s `stuckWatch`: if `lastGalMs` (last completed
GAL frame) was stale for 8 s over Wi-Fi, call `abortIo()`.

**After (shipped):** a **byte-level socket read timeout** on the AA TCP socket
(`AaSessionService.tcpPipe`: `s.setSoTimeout((int) InputEvents.LINK_DEAD_MS)`, 20 s). A real stall makes
`readFully` throw `SocketTimeoutException`, which the existing `readLoop` catch already turns into the
proven `abortIo()` teardown. The frame-based `stuckWatch` tcpMode branch was reverted.

## Finding-by-finding

- **P1 — 8 s misclassifies recorded recoverable stalls (8549 ms header + 10896 ms body, same session
  resumed).** FIXED by the redesign. The timeout is now **byte-level**: it resets on *any* byte received,
  so a slow-but-alive link (bytes/pings still trickling) never trips. And the threshold was raised to
  **20 s**, comfortably above the worst recorded ~11 s recoverable silence. Host test asserts
  `LINK_DEAD_MS > 11000` with that evidence in the message (`BundleTests.java`).
- **P1 — `lastGalMs` measures completed headers, not bytes received.** OBSOLETE: the new signal is the
  socket's own byte timer, not `lastGalMs`. A long body read that is actually receiving bytes keeps the
  timer alive.
- **P1 — watchdog never arms before the first rendered frame; handshake/pre-render silence hangs
  forever.** FIXED: the timeout is set inside `tcpPipe`, before the first read, so it covers the
  handshake and the pre-first-frame window too — exactly the gap the old watchdog missed.
- **P2 — duplicate teardown (reader/writer/byeBye/watchdog racing into `abortIo`).** FIXED: `abortIo`
  now has an `aborting` AtomicBoolean so only the first caller schedules `shutdown()`; it still closes
  the transport on every call (idempotent) so a blocked reader always unblocks. Removing the separate
  watchdog thread also removed one concurrent caller.
- **P2 — 8–10 s is detection, not guaranteed return to Honda's screen; shutdown joins workers before
  overlay removal, adding seconds.** ACKNOWLEDGED, not changed. This is pre-existing `shutdown()`
  ordering, not introduced here. Total time = detection (≤20 s) + existing shutdown (a few s). Still a
  strict improvement over an indefinite freeze. Moving overlay-STOP to the front of shutdown is a
  possible follow-up but reorders teardown, so it is out of scope for this minimal change.
- **P2 — automatic reconnect is conditional; TCP sessions bypass ReconnectPolicy; BT bootstrap release
  is gated on `WIRELESS_TEST` (default off).** ACKNOWLEDGED, scoped out. This change's job is to STOP
  THE FREEZE and return a usable Honda screen (AA is re-enterable via the Hackura tile / side panel).
  The Wi-Fi listener stays up (`WirelessProbeService` keeps accepting), so a phone that re-initiates
  reconnects; guaranteed *automatic* re-establishment timing remains **UNKNOWN** and is a separate
  enhancement, not a regression from today's behavior.
- **"phone disconnected" overclaim.** FIXED: the log now reads `T350_LINK_DEAD ... (phone likely
  disconnected)` — states the observation (no bytes for the window), not a certainty.
- **USB / T150 regression.** None: the USB `stuckWatch` predicate and action are byte-for-byte the
  T340 behavior (the tcpMode branch was reverted). Runtime parity remains untested (host-only).

## Residual risks (honest, still open)
1. A phone that dribbles a byte occasionally but sends no real frames would keep the socket timer alive
   and not be torn down (pathological; not the reported bug). No frame-level backstop was added, to keep
   the change minimal.
2. A genuinely healthy session that goes fully silent (no video, no ping replies) for >20 s would be
   torn down; the phone reconnects when brought forward. Considered acceptable given the 1 Hz ping
   keepalive makes 20 s of true silence a dead link in practice.
3. Not yet car-tested. `test.json` has the repro (walk away ~30 s; confirm a brief scan stall does NOT
   end the session).

## Verification
Rebuilt offline, baseline restored. Host tests PASS: **280 bundle checks** + all feature suites.
APK sha256 `EE77507A478F091B4C1E2BA7611FD82C32CA5A445333869C77CE1EC87514CDFD`.
Source diff vs T340: `AaSessionService.java`, `InputEvents.java`, `AndroidManifest.xml` only.

---

## Round 2 (CODEX-T350-round2.md) — socket-timeout design

Verdict: **no P1**. The timeout passes the recorded ~11 s stall (max single phase 10,896 ms < 20,000 ms),
both TCP session paths (inbound hand-off and outbound 5277) get the timeout before any read, and the
Bluetooth bootstrap/RFCOMM reads correctly do NOT get it (AA-session-only scope, as intended).

- **P2 — "teardown at most once" is false globally; direct shutdown() callers bypass the gate.** Claim
  softened (code unchanged): the `aborting` gate only dedupes the abortIo callers (reader/writer/ping/
  byeBye). Direct shutdown() callers (surface-loss, device-policy) are unchanged from T340 and can still
  re-enter after shutdown resets `stopping=false`. This re-entrancy PRE-DATES T350 and its second pass is
  largely idempotent (guarded native destroys, idempotent overlay STOP). Not changed to avoid
  rearchitecting shutdown across USB too.
- **P2 — the gate could strand the session if native receiver.prepare() hangs/throws after the CAS,
  before posting shutdown.** FIXED in code: abortIo now posts shutdown FIRST (right after claiming the
  gate), then does receiver.prepare() best-effort in try/catch. A native hiccup can no longer skip the
  teardown post. shutdown() calls prepare() again (no-op), so the early signal is not required.
- **P3 — "per-byte timer" / "~11 s of silence" overstated.** FIXED wording in both comments: the timeout
  bounds each underlying read(); the recorded 8549/10896 ms figures are whole header/body read durations.
  The safety argument (max single phase < 20 s) is unchanged.
- **"USB unaffected" needs qualification.** Noted: SO_TIMEOUT is TCP-only, but abortIo is shared, so the
  new gate + close-first ordering also apply to USB aborts — benignly (one shutdown instead of N; USB
  pipe close is idempotent). USB stuck-screen predicate/action unchanged.

Residual UNKNOWNs (honest): guaranteed sub-20 s AA byte cadence for every state (long-background, voice,
nav-only, screen-off, audio-only) is UNKNOWN — a truly silent-but-alive session >20 s would be torn down
(phone reconnects when foregrounded); a pathological 1-byte-per-19.999 s dribble would NOT be torn down.
End-to-end time to Honda's screen = detection (<=20 s) + existing shutdown joins.

Rebuilt: host tests PASS 280 bundle checks + feature suites; APK sha256
10AFF79DDDA025625CDC89438E492D60347307C629580B319818B2B45C040579.
