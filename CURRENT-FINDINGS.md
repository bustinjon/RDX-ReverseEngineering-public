# Current findings — October 30, 2026

Latest local helper candidate: **v6h-pad-select-v5**. Tested APK SHA-256: `98E6A0015F249960B7730F210FAFB46BDFDAFE7A31686478FD619A930C3831A4`. The APK is not distributed.

| Area | Result and evidence | Limits |
|---|---|---|
| Video | Operator reported good geometry after active-area transformation; implementation is in VideoGeometry and AaOverlayService | Specific negotiated active area/display; another car must be measured |
| Input focus | Focusable video overlay receives hover/navigation input; operator reported movement | No general guarantee for other input stacks |
| Physical click | Ordinary touch DOWN/UP produces select key 23 DOWN/UP; nine paired native sends returned zero in the final test, and operator reported activation | One tested configuration; multi-finger/rotary behavior remains incomplete |
| Protocol audio | Focus gain requested, Android focus granted, wire state GAIN returned; AudioTrack initialized | Public STREAM_MUSIC path, not Honda's complete OEM focus manager |
| Media PCM | Final periodic counter: 1,000 received frames; 8,135,680 written bytes; two drops | Partial writes adjacent to playback stops; final totals not captured |
| Bluetooth isolation | Operator reported audible music both with Bluetooth Media audio on and off | Switch state operator-observed; phase transition timestamps not recorded; internal output route unknown |
| Cleanup | Independent watchdog completed; original accessibility settings matched; owned helper/capture/watchdog processes absent | Bounded helper test, not persistent deployment |

The final raw capture is retained privately. SHA-256: `925553B76FFEEC2171FC91F627BFA3497892CFDD0386CFBB726414DEF0F7C2B8`. Sanitized result: [final test report](analysis/test-prep/runs/helper_20261030T230138_7ab757e6aae544d4b459621dc6365130/RESULTS.md). These are bounded observations, not a claim that all Android Auto functions work.

## Discoveries useful for another car

1. Separate three questions: whether the USB connection survives, whether the protocol responds correctly, and whether the OEM UI/input/audio policy admits the receiver. A read timeout does not by itself identify the failed layer.
2. USB permission UI can be rejected by Diagnostics lock-task. Being physically connected through a diagnostics menu is not proof a permission prompt can appear. Qualify foreground and lock-task state before any test; use the normal Home/return UI.
3. Force-stopping Honda's projection service is not a durable ownership strategy when other factory components bind and restart it. In the tested configuration, the user's per-phone Android Auto disabled preference permitted cooperative helper operation. Do not assume that preference has identical semantics on another car.
4. A visible overlay can still leave input with the underlying Home window. Capture focus diagnostics and raw events rather than inferring routing from the image.
5. Hover movement and physical pad depression are separate event paths. Forward hover as pad movement; the tested physical press needed key-23 select transitions. An Enter-to-select key mapping alone did not fix it.
6. Protocol focus values differ from Android focus values. The previous stub always replied LOSS=3. The corrected configured path requests Android focus and reports protocol gain only when granted, with asynchronous replies outside the native incoming callback.
7. PCM reception and AudioTrack writes do not alone establish audible speakers. Combine timestamped counters with an audible test that isolates Bluetooth media while keeping the needed session connectivity.
8. Preserve complete evidence before disconnecting, and make cleanup independent of laptop connectivity. Never infer cleanup solely because the display returned Home.

The research milestone archive has its own authorization/status rules; this helper result does not automatically advance those milestones. Long-session reliability, microphone/voice, rotary controls and complete multitouch support are unresolved.
