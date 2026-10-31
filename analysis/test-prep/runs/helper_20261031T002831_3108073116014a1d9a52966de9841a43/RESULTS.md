# Directional focus A retry — Up navigation still fails

Operator: **cannot go up**. The candidate is not a working navigation fix. Capture confirms 22 raw Up swipes and 22 matching native Up DOWN/UP pairs, all result=0. This establishes local mapping/submission, not the phone's selected target or acceptance.

Final evidence saved and cleanup verified; user cleared to disconnect. No new implementation or test started.

## 1. Files inspected

Run session/artifact metadata; complete captured log; watchdog, cleanup script, PID files; postchecks; current directional-focus preparation and earlier timeout result. Owned PID identities checked against current process state. No key material or unrelated phone data inspected.

## 2. Files changed

Run evidence, hashes, postchecks, manual-cleanup.txt, RESULTS.json and this report. No source/APK, guard, Git/public repository or historical report changes.

## 3. Commands run

Authorized targeted ADB run-directory pull and settings/process checks. Because user returned before the 180-second watchdog deadline and helper/capture/watchdog remained active, reviewed the generated cleanup.sh, ran that existing cleanup, and conditionally stopped watchdog PID 6915 only after matching its command line to this run's watchdog path. Rechecked settings/process absence, pulled final evidence and regenerated hashes. No new device session was armed.

## 4. Tests run and results

- Installed bytes match directional-focus A SHA-256 `F6D485977DEF00B0C6BADE0E0CD7ED50E8615923E522B3CC73F7BF0D66C57F92`.
- 22 raw Up key codes 152; 22 native code=19 DOWN/UP pairs, all result=0.
- Other pairs: Down=2, Left=11, Right=12, Select=2. No nonzero native key result, duplicate DOWN, orphan UP or held key at capture end in this sequence.
- Key-only policy active: 164 sampled ignored-hover diagnostics, no forwarded TOUCH log, no native Page/Move keys.
- No window-focus-loss or fatal/GAL-error marker in the bounded app-process logs. This cannot establish the phone's internal focus state.
- Media summary: 1,038 frames received, 8,503,296 bytes written, zero recorded drops. Operator audibility not explicitly reported for this attempt. Guidance summary zero frames/bytes.
- Initial pull had nine files while cleanup was pending. Final pull has ten files after cleanup/cancel creation, all hashed. Manual cleanup emitted CLEANUP_FINISHED; current services empty/enabled=0 match the recorded original baseline; helper and owned capture PID 6794/watchdog PID 6915 absent.

## 5. Findings

1. Explicit directional keys without forwarded hover are not sufficient to provide correct navigation in this observed state.
2. The failed Up action cannot be explained solely by an absent raw Up gesture, wrong normalized code, unpaired release, or nonzero native return in the logged helper path. Phone processing/selected-focus behavior remains UNKNOWN.
3. Neither the v5 mixed hover/fallback path, the page/move candidate nor this key-only candidate has established reliable panel navigation. Initial track selection in another run is not a general input PASS.
4. The next useful evidence is a synchronized observation of the visible UI/selection and panel state around an attempted move. Direction labels and coordinate ranges alone do not establish the phone's navigation state. No new capture feature or remapping is implemented here.

## 6. Primary evidence

- Capture SHA-256 `ADB69B3B92DDBFD3F5427F4823213BB94267165DDA4F0A1C6DC7A9B1E761A8C8`; unique RDX.PREP boundary line 49984; app PID6848. RESULTS.json preserves exact counts and pairing results filtered to that boundary/process.
- Capture 57357–57361, 57772–57788, 58546–58581 show raw 152, mapped Up and paired native results of zero. Later media summaries at 59078/59081.
- device-evidence-hashes.json preserves the final ten-file inventory. manual-cleanup.txt records CLEANUP_FINISHED; session.json holds original accessibility baseline and installed hash; postchecks.txt shows restored values and process absence.
- Watchdog log only records WATCHDOG_STARTED deadline=582; do not claim automatic watchdog completion. Explicit reviewed cleanup and owned-watchdog termination completed the cleanup instead.

## 7. Assumptions

Operator's inability to move up refers to the active Android Auto interface. Exact target, time, entry path, and whether other directions remained usable were not supplied. Initial/first-return/second-return outcomes remain UNKNOWN rather than silently passed.

## 8. Unresolved uncertainties

Phone-side focus graph/state, exact UI layout and selected target, perceived versus native key acceptance, and suitable complete input policy. Positive media byte accounting is not independent audibility evidence for this run. No UI-state screenshot/recording was collected. No new test authorization is inferred from this result.

## 9. Exact diff summary

Saved one failed input-policy run and final cleanup evidence. No key mapping, geometry, audio, native library, source or existing APK changed.

## 10. Preservation checks performed

Installed candidate identity matched; all final evidence files hashed. Cleanup compared with saved original settings and process identities, with no persistent timer left to stop a later helper instance. No private keys read, factory package change, guard bypass, Git/publication or milestone action.
