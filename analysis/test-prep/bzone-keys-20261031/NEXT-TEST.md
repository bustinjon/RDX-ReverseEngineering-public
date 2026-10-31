# Future test — secondary pad release keys

**Offline preparation only. Do not run tonight.** Candidate `v6h-bzone-release-a`, SHA-256 `DB9B0598467DE2BD1C7D363E52F5A0E6C759641F6490A66ED18632F402371206`. Built artifact and validation: [REPORT.md](REPORT.md), [validation.json](validation.json).

Purpose: determine whether the narrow right pad's raw B-zone gestures can reach the Spotify right-third lower controls through ordinary AA Up/Down, while retaining working main-pad movement, Select and Back. The adapter is OFF by default and must be explicitly armed for one video session. Installing the APK alone does not enable the experiment.

## Operator sequence for a later authorized session

1. Start with phone USB disconnected, vehicle parked, Honda Home visible and ADB connected to the head unit. Keep the paired phone disabled for stock Honda projection as in the last successful setup. No external keyboard.
2. Agent verifies readiness, installs the pinned APK, verifies the installed hash, A11Y auto-clicker, capture/logger and watchdog, then explicitly arms B-zone and capture for the next session. The saved `Prepare-LiveTest.ps1` is a future live script, syntax checked but **not executed**. It is not new live authorization.
3. Only after the agent says **READY — plug in phone**, switch USB mode to phone connection using the existing menu, return to Honda Home, and plug in the phone. The full connection instructions and actual remaining watchdog time must be repeated in chat at that cue. Do not connect early; if remaining time is insufficient, stop rather than race the timer. The configured watchdog is 180 seconds from preparation, not a promised three-minute test after connection.
4. **TEST NOW:** in the app grid, briefly check main-pad Left, Right, Up, Down, Select and Back. If any newly fails, stop this experiment and report which control.
5. Recreate `photos/THISSETUP.jpg`: Spotify occupies the right third. First use the **large left pad** to attempt to reach the lower skip controls. Then use the **narrow right pad** with one deliberate Down swipe and release; try Up and release. State which pad was used and whether focus changed or a skip control became selectable. Do not change several settings or spam gestures.
6. If time permits, leave the widget and return once, then repeat the narrow-pad test. Confirm main-pad Select/Back still work. Report initial success separately from success after return.
7. Return to Honda Home, reconnect ADB and request log collection. The agent must pull logs/private captures first, verify cleanup, then say **SAFE TO DISCONNECT**. If projection exits/crashes or any system overlay intervenes, report it and preserve logs; do not keep cycling connections.

## Agent checks after collection

- Verify installed APK SHA-256 equals DB9B…371206 and `INPUT_BZONE_RELEASE_V1 enabled=true` belongs to the fresh run/PID. Arm acknowledgement alone does not prove the active overlay used it.
- Correlate `INPUT_BZONE_DEVICE`, both `INPUT_BZONE_RAW` action phases and mapped `INPUT_BZONE_KEY` pairs. Actual release delivery is not established by the old fixture. New raw logs explicitly include UP.
- Expected bottom: code38 / scan36 / source257, matched device DOWN then UP, exactly one mapped20 DOWN/UP. Top: code39 / scan37, one mapped19 pair. Confirm both native results through the existing AA key logs. Check for OEM action underneath and continued normal main-pad behavior.
- If there are no matching B-zone raw events, record which physical pad was tested; this is not proof that AA ignored a mapped Down.
- If DOWN arrives but UP does not, the release-only adapter cannot complete. Do not blame phone-side focus or quietly change the experiment to fire on DOWN.
- If complete mapped/native pairs succeed but widget controls remain unreachable, the missing local B-zone key path is insufficient to explain the widget problem. Keep the working baseline and return to the separate alternatives in the canonical review (media commands, controller comparison, mixed-input/capability analysis) for later scoped authorization.
- A pass requires reachable controls, repeatability after return and no regression of Left/Right/Up/Down/Select/Back. Partial success is not a completed fix.

Do not combine Gemini/mic, audio, coordinate geometry, rotary, capability changes or media key additions with this comparison. Capture files may contain private phone content; retain locally.
