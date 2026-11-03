# Roll back for the Diagnostics shortcut comparison

User requested reverting the recent change and retesting. Select the last actually car-tested long-drive APK D1A29B34812B2C3188C57C840DB1DE4F44E1362FF8BD8E3D9A52B1317EDABCE4, not the intervening untested Maps-only candidate.

Restore its exact27 recorded Java inputs by reverting only GalReceiver, InputEvents, AaOverlayService and AaSessionService from verified pre-change snapshots, and moving the newly added VolumeFeedback outside the production tree. Preserve all five current source files, the A2F478… and21037… APKs, prior/frozen artifacts and guard files. Do not rebuild an old APK or alter Git history.

First later car step: install the exact old APK with helper/overlay stopped and accessibility unchanged; test manual Diagnostics entry before starting the receiver. No phone handoff, helper rearm, settings reset, reboot, guard bypass or live action is authorized by this file. A future explicit ADB connection authorizes only the requested comparison steps in context.

The old build intentionally restores the earlier Spotify/volume/media limitations and old navigation-focus reply. Restoring the Maps fix is deferred until the shortcut change boundary is understood. A successful rollback would be evidence of a difference, not proof that a particular feature caused it; reinstalling may itself reset transient state.
