# Smallest useful next check — no new APK

The operator has already held the three buttons long enough and repeated the attempt. Do not repeat an unrecorded hold or assume user timing is the problem.

At a later explicitly authorized ADB connection, keep the receiver helper stopped and record one complete physical attempt with passive input capture:

1. Verify own helper/overlay remain absent and record current Home/window policy, input devices and accessibility state. No install or rearm first.
2. Discover the current Acura_TouchBridge input node from dumpsys input; this snapshot used /dev/input/event2, but rediscover it rather than hardcoding it. Capture all relevant input devices as well, because WindowManager's pressed-key bitset is global. If shell read access is unavailable, record that failure without changing input-node permissions.
3. Start a bounded, read-only timestamped getevent trace and concurrent explicit main/system/events logging. The owner releases all buttons, performs the same physical three-button gesture once, and releases them. Capture actual start/end timestamps; no synthetic key injection.
4. Save the complete sequence and post-attempt input/window/activity state. Correlate logical Home3, Back4 and Guide172 with scans172,158 and362 in the observed Generic.kl mapping. Check for missing/bouncing events and additional keyboard keys. Raw touch/button EV_KEY events are not automatically extra Android keyboard bits; interpret device/mapping context.
5. If all three logical keys remain down together beyond the archived3-second threshold, with no other relevant key, yet no dealer action is issued, prioritize OEM combo bookkeeping/timer/dispatch state. The saved dumps do not expose WindowManager's private mPressedKeys directly. If the correct dealer action is issued, follow the launch result instead; that is a different failure point.

An ordinary full head-unit restart, followed by the same captured attempt before enabling the helper, could distinguish transient state from a persistent change. It should be a separate controlled comparison with a verified new boot and helper state, not an assumed fix. No restart is performed or required by this offline report.

For continuing AA testing, the normal exported dealer entry already opened successfully through ADB. That is a supported operational fallback, not a repair of the three-button shortcut. Preserve Home/lock-task readiness before receiver preparation, use the normal menu path for USB mode, and return normally to Home before phone connection. Do not install/arm while Diagnostics is pinning the UI or bypass the guard.

Current media/volume/Spotify/Maps candidate remains installed but stopped and has not received its actual AA feature test. No receiver rebuild is needed to investigate this shortcut first. Git work remains paused.
