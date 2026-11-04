# Session A result — 2026-11-04 (operator report + logs)

Run: analysis/test-prep/runs/helper_20261104T204814_5cb03b9b93184dc28e497b713886c86f (cleanup verified)

| Card | Result | Evidence |
|---|---|---|
| T03 reverse camera | PASS - normal camera, AA returned | operator |
| T01 Maps route | PASS - route did not end | NAVIGATION_PROTOCOL_REQUEST request=2 / REPLY state=2 (twice) |
| T04 calls | PASS - ringtone/answer/wheel controls/both directions via Bluetooth | operator |
| T05 talk button | Honda VR answers; long hold does not reach the phone | operator |
| T02 voice prompts | FAIL - music ducks, no speech | guidance id=5 received=205 dropped=181 playedBytes=49152; playbackStop clears queue + flushes track. Fix: T21 |
| Gemini (AA mic icon) | cannot hear / not heard | "Mic request open=true — denied (stub)" -> T11; replies also need T21 |
| Reconnect | Two mid-session USB detaches (15:50:16, 15:55:00) re-established automatically via UsbAttachActivity -> AUTO_GRANTED non-AOAP -> AOAP switch (phase reset to WAITING) | RDX.USB lines; operator to confirm whether unplugged |
| Plug-in rule | Plugging in while the Diagnostics menu is open left the permission overlay stuck until a car restart | operator; cards updated |
