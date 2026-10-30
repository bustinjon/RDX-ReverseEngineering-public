# Pad select candidate and v4 test evidence — 2026-10-30

New candidate built and locally verified, not installed. APK: `analysis/parallel-aa-receiver/usb-helper/build/20261030-185210-531/rdx-usb-helper-v6h-pad-select-v5.apk`.

SHA-256: `98E6A0015F249960B7730F210FAFB46BDFDAFE7A31686478FD619A930C3831A4`.

## 1. Files inspected

- `PROJECT-RULES.md`.
- V4 run: `analysis/test-prep/runs/helper_20261030T224655_187e9b00afbf45e292f9d23e87e97a58/` (capture, watchdog, postchecks, session and artifact plan).
- Factory source: `decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/ui/ProjectionActivity.java` and `com/google/android/projection/protocol/InputSource.java`.
- Helper InputEvents, AaOverlayService and effective InputSource; InputPcmTest; v4/v5 source-hash build metadata.

## 2. Files changed

- `analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/InputEvents.java`.
- `analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/AaOverlayService.java`.
- `tools/car-test/InputPcmTest.java`.
- New local build, preparation and evidence summaries in this directory. Audio code is unchanged from tested v4, established by source-hash comparison in `validation.json`.

## 3. Commands run

Local source/log inspection, JDK 17 javac/java tests, `scripts/Build-RdxUsbHelper.ps1 -Version v6h-pad-select-v5`, source/APK/DEX and frozen-artifact hash checks, packaged DEX marker checks, and Run-CarTest Mode Prepare (CurrentSource, PhonePreference, 120 seconds, nonexistent ADB executable path).

No device commands were run in this offline implementation turn. Earlier authorized evidence retrieval copied all ten remote run files and saved `device-evidence-hashes.json` plus postchecks in the v4 run folder.

## 4. Tests run and results

- **PASS: 25713 input/PCM checks**, `results.txt`. Includes 17 new select-state assertions: normal DOWN/UP, duplicate DOWN suppression, movement/multiple-pointer nontransitions, orphan UP, CANCEL release, and hover independence. Counts include repeated byte assertions in existing PCM cases.
- Full 25-source compile/DEX/package/sign succeeded. All source hashes still match build inputs.
- API-22 signature and alignment verification passed. Packaged DEX equals generated DEX and contains INPUT_PAD_PRESS/INPUT_PAD_SELECT diagnostics.
- Four frozen anchors match. Full static audit remains PENDING. This v5 candidate has no hardware result.

## 5. Findings

1. V4 successfully received Android Auto PCM and wrote it to public AudioTrack. This is direct evidence that audio progressed through this receiver. Which audible route the user heard is still UNKNOWN; Bluetooth could have contributed independently.
2. The click implementation conflated hover movement with ordinary pad touch. Factory code treats ordinary touch DOWN/UP as select key events while hover supplies touchpad movement. V4's Enter-key mapping could not fix this ordinary-motion path.
3. V5 implements that factory distinction. Its physical click behavior remains UNKNOWN until tested.

## 6. Primary evidence for each finding

- Finding 1: v4 `device-evidence/capture.log:34934–34950` records gain request 1, Android focus granted and protocol gain response 1; `:35023` playback start; `:35092` AudioTrack ready. `:39472` records media summary received=1251, playedBytes=10248192, dropped=0. Guidance summary at `:39475` is zero. Capture SHA-256 `38A85B7D4F03039EBA2A9F102D46456FF93028453755A66F05207DB52EA1E128`. Extracted strings and boundary are in `live-evidence.json`.
- Finding 2: factory `ProjectionActivity.java:161–162` defines select key DOWN/UP, `:559–572` ordinary pad touch dispatches those keys, and `:574` onward independently converts hover to native pad movement. Accessors at `:1051–1056` resolve to those select keys. V4 raw-key logs contain no 23/66 selection events; absence does not identify an alternative physical key code.
- Finding 3: new helper `AaOverlayService.java:229` onward routes ordinary touch through SelectPress and `:279` sends key 23 transitions. Hover dispatch still calls the existing movement handler. `InputEvents.java:8` holds the pure select-state logic, exercised by host assertions. `validation.json` establishes fresh candidate/source provenance.

## 7. Assumptions

The ordinary-touch versus hover distinction in Honda's matching factory projection code applies to this overlay's delivered events. The next test's INPUT_PAD_PRESS and INPUT_PAD_SELECT logs will check it directly.

## 8. Unresolved uncertainties

- Hardware click acceptance and paired native key delivery for v5.
- Whether the audible v4 sound came from AudioTrack, Bluetooth, or both. PCM reception and successful writes do not establish speaker routing. A later controlled comparison must isolate Bluetooth media audio while retaining whatever connection the Android Auto session requires; no phone/Bluetooth setting was changed here.
- Multitouch hover still uses the preexisting single-pointer movement approximation. This change handles one select press and does not implement multi-finger gestures.
- Next bounded test: move to a known item, press/release once, verify INPUT_PAD_PRESS 0/1, INPUT_PAD_SELECT true/false and native KEY code=23 results. Then confirm the selected UI action. Audio code should continue to emit PCM/write counters.

## 9. Exact diff summary

- Add InputEvents.SelectPress: DOWN starts one held selection; UP/CANCEL releases it; duplicate/orphan transitions and other motion actions produce no key.
- Ordinary VIDEO onTouch now logs action/pointer count/button state, emits select transitions and consumes the event. It no longer forwards these events as native pad movement.
- Hover mapping and raw native movement remain unchanged. Test-pattern mode retains its prior diagnostic touch handler.
- Overlay removal cancels/releases an outstanding select press through the existing listener when available.
- Add 17 select-state assertions. Source comparison against v4 shows exactly two changed production Java inputs: AaOverlayService and InputEvents. No audio, video geometry, USB policy, native library, watchdog or readiness-guard change.

## 10. Preservation checks performed

All four frozen hashes match canonical anchors (`validation.json`). No frozen rebuild, key contents printed, Git mutation, guard bypass, car/phone action or milestone advancement in this offline turn. V4 watchdog logged CLEANUP_FINISHED; postchecks show original accessibility services empty, enabled=0, and helper/capture PID 5314/watchdog PID 5427 absent. Saved remote evidence remains available in the v4 run folder; historical reports were not rewritten.

Offline plan: `analysis/test-prep/runs/helper_20261030T225250_6edd6b2a9ddd4da3b2db34b67cba2627/artifact-plan.json`.
