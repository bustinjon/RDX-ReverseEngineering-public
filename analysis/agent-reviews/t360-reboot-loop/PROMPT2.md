# T360 round 2 — CODEX ATTACKS the F1/F2 hardening

Round 1 (`CODEX-T360.md`) confirmed the ACK ownership and the unchanged teardown callers, and raised
F1 (permanent decoder wedge could freeze Wi-Fi forever) and F2 (unbounded handler posts). Both are now
addressed. Reconciliation: `CLAUDE-T360-RECONCILE.md`.

CLAUDE PROPOSES (the claim you must try to break):

"T360 now (a) recovers from a transient full video-decoder queue without tearing down (stopping the
start-up restart loop), AND (b) still ends the session within ~12 s if the decoder is PERMANENTLY wedged
(queue stays full, nothing renders) so Honda's screen returns, AND (c) cannot pile up the main handler
under a frame-rate flood — all WITHOUT a new freeze, spin, double-teardown, or flow-control stall, and
WITHOUT false-tripping the 12 s backstop on a healthy session."

Find counterexamples. READ-ONLY. Do not build, do not touch any device, do not edit files.

## The change under review (T360-bundle, updated since round 1)
Files (bundle copy, switched into canonical `analysis/parallel-aa-receiver/usb-helper/source/...` at build):
`.../builds/T360-bundle/source/analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/`
- `AaSessionService.java` `frame(int,long,ByteBuffer)`: now
  `if (d != null && d.frame(copy, ack)) { queueFullSince = 0; } else { vs.ack(s); ... }`. In the else branch:
  set `queueFullSince = now` if 0; if `now - queueFullSince >= InputEvents.DECODER_WEDGE_MS` -> log + `abortIo()`;
  else if `now - lastQueueFullAsk >= 1000` -> `lastQueueFullAsk = now`, throttled log, `pictureLost()`;
  else just `videoQueueFullDrops++`. New volatile fields `queueFullSince`, `lastQueueFullAsk`.
  `rendered()` now also sets `queueFullSince = 0`.
- `InputEvents.java`: new `public static final long DECODER_WEDGE_MS=12000;`.
- `AndroidManifest.xml` versionName 0.9-T360. `BundleTests.java` adds 3 DECODER_WEDGE_MS sanity checks.

## Attack these specifically (cite file:line)
1. **False backstop trip on a HEALTHY session.** Can `queueFullSince` ever stay non-zero for 12 s while the
   session is actually fine? Enumerate: does EVERY rendered frame reach `rendered()` to clear it? If frames are
   being enqueued and decoded normally, is `queueFullSince` reliably reset on the accept path AND on render?
   Consider a decoder that accepts frames but renders nothing yet (startup/first-frame), AA minimized/hidden
   (nativeFocus / overlay minimized → phone stops sending → `frame()` not called → timer frozen at its last
   value, not advancing? or stale non-zero that fires on return?). Is there a path where a brief full-queue
   burst sets `queueFullSince`, frames then flow fine but via a route that never calls `rendered()`, and 12 s
   later a single late full-queue drop reads a stale `queueFullSince` and tears down a healthy session?
2. **Thread-safety of the two volatiles.** `queueFullSince` is written on the native frame thread (set) and
   the decoder worker thread (cleared in `rendered()`); `lastQueueFullAsk` on the frame thread. Are the
   read-modify-write sequences (`if (queueFullSince == 0) queueFullSince = now`) racy in a way that could
   defeat the reset (e.g. worker clears to 0, frame thread immediately re-sets, so a healthy render is lost)?
   Is any race here capable of causing a FALSE teardown, or only a slightly early/late true one?
3. **Backstop vs the real bug.** In the recorded stall (`...181617.txt` ~:261-278) the queue filled ~3-4 s
   after the first decoder drop. Confirm 12 s clears that transient with margin, i.e. the backstop would NOT
   have fired on the observed recoverable case. Would it fire on any normal start-up sequence in the clean log
   `...165532.txt`?
4. **abortIo() from the native frame thread.** The backstop calls `abortIo()` directly on the native GAL
   frame callback thread (not via handler). Is that safe given `abortIo()` closes the transport, posts
   shutdown to the handler, and best-effort calls `receiver.prepare()`? Any re-entrancy/deadlock if the native
   callback is holding a lock that `prepare()`/`transport.close()` needs?
5. **Flow-control still balanced** after the restructure: exactly one `vs.ack(s)` per frame on both the
   accept path (via the Runnable) and the reject path (explicit), never both, never neither.
6. **Did F2's 1 s gate drop the ACK or the recovery?** The ACK must still happen on EVERY rejected frame
   (it is outside the 1 s gate); only the `pictureLost()` post is gated. Confirm the ACK is not accidentally
   inside the throttle.

## Report back
Files inspected, findings ranked P1/P2/P3 with file:line primary evidence, assumptions, unresolved
uncertainties, and whether the core claim holds. "Looks fine" without cited evidence is rejected.
