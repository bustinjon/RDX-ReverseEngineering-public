# Current findings — October 31, 2026

Latest source candidate: **v6h-media-input-a**, original local APK SHA-256 `A2F4785466AD41E2459051A096B917881349EC2B64E06303D19F66DA38D4FB0F`. It has passed offline checks but is **not installed or car-tested**. Its authenticated APK is not distributed; sanitized source is available for independent review/adaptation. Sanitized public builds need not reproduce the original container hash.

| Area | Latest observation / candidate change | Confidence and limits |
|---|---|---|
| Baseline video/input/audio | Earlier operator tests established useful video, movement, Select, Back and audible media | Target-specific observations, not production qualification |
| Spotify compact playback row | The row is reachable from startup app-grid focus via Right, but Down from its title/upper target fails; playlists/Maps navigation works | Root cause UNKNOWN. Candidate restores ordinary PageDown and factory-matching absolute pad mode without declaring arrow keys; this combination remains untested on hardware |
| Volume display | Adjustment worked while the OEM display was hidden; current overlay lies above the OEM volume dialog in inspected window policy | Candidate adds a noninteractive three-second display from actual OEM amplifier feedback, without altering volume or whole-window priority; delivery/rendering unverified |
| Physical Next/Previous | Observed vendor keys were not forwarded; stock code identifies seek-down/up semantics | Candidate handles known vendor signatures and standard media keys, with balanced release pairs and repeat/cancel suppression. Actual steering-wheel path and duplicate behavior require testing |
| Maps route cancellation | User reports the route ends after roughly30 seconds while AA/music continue | Installed old callback always replied native navigation focus1. Candidate preserves valid requested native1/projected2 and logs it; actual route retention still unverified |
| Untimed operation | A prepared untimed session survived beyond the previous short-test cutoff; manual log collection/cleanup completed | Not a multi-hour stability pass. Normal USB/lifecycle termination still applies |
| Offline validation |77 media/input/volume checks and10 navigation-focus requests pass; a negative control detects the original navigation-focus defect | Java tests do not simulate OEM broadcast/UI, actual JNI/native delivery, phone focus decisions or car behavior |

See [latest test plan](LATEST-TEST-PLAN.md), [navigation-focus investigation](analysis/agent-reviews/maps-route-20261031/REPORT.md), [Spotify evidence](analysis/agent-reviews/spotify-row-mechanism-20261031/REPORT.md), and [candidate report](analysis/test-prep/media-input-fixes-20261031/REPORT.md). The receiver native library, protocol material, original device logs and private captures remain withheld.

## Historical bounded v5 test — October 30

Earlier tested helper: **v6h-pad-select-v5**, APK SHA-256 `98E6A0015F249960B7730F210FAFB46BDFDAFE7A31686478FD619A930C3831A4`. The following records that historical test; it does not establish a result for the current candidate.

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
