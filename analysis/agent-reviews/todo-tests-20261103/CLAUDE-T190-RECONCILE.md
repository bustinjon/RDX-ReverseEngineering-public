# T190 reconciliation (Claude, 2026-11-08)

Final build: T190-bundle A9AC31E7B858B06CD1010361A8E710247B5FB80D5E8EF44508AD617E46B2CF6D, PASS 232 bundle checks plus feature suites.

Contents:
- re-pair diagnostics (P6_*)
- settings kept across updates
- T200: AA over Wi-Fi to the phone's head-unit server, port 5277
- T210: the "Honda reconnect" wireless variant
- T220 (QR / WPP-over-TCP): deferred. It needs a QR encoder, a Java TLS client with the car certificate (uncertain), the WPP-over-TLS exchange and a projection accept. Do it after T200 proves AA over Wi-Fi.

Reviews:
- CODEX-T190.md (diagnostics): OK; state label fixed.
- CODEX-T190B.md: NOT READY.
  - T200 fixes (USB START refusal with notifyEnded, connect cancellation via token/destroyed, socket cleanup): FIXED per CODEX-T190B-RECHECK.md.
  - T210 restore after the recheck:
    - reconnect fires as soon as Honda confirms the disconnect (4-s fallback)
    - the obligation is cleared only on HFP connected for the peer, or after 6 tries
    - stopping the test keeps the restore running (service and diagnostics stay alive)
    - a finished operation can't disconnect again
    - destroy sends a last request
- Accepted (loop stopped):
  - The phone address is a gateway / first p2p ARP client (test with a single phone).
  - No call monitoring during the ~4-s interruption (parked test, no calls; the checklist asks for a test call after).
  - Developer page fit (16 items) to be confirmed on screen.
  - Honda reconnects known phones by itself as a backstop (observed in T180 logs after Bluetooth toggles).
