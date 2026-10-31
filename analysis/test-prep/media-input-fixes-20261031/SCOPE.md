# Media/input fix candidate

User task: try fixes for the inaccessible compact Spotify playback row, missing volume display and physical/steering-wheel track controls. Preserve the already built navigation-focus fix. Offline work only; no device action or new milestone.

Production scope: InputEvents.java (media input adapter/key declaration; restore ordinary PageDown); AaSessionService.java (factory-matching live absolute touchpad flag); AaOverlayService.java (media dispatch and passive volume HUD); new pure-Java VolumeFeedback.java (validate/deduplicate actual OEM amplifier feedback). No audio adjustment, native library, sensor, manifest, permission, Select/Back/hover conversion, screen geometry or guard changes. Candidate/report/test files belong in this directory.

Evidence: canonical Spotify matrix in analysis/agent-reviews/spotify-row-mechanism-20261031/REPORT.md identifies page/move + no arrows + absolute=true + ordinary Down as untested. Stock GalIntegration registers that pad mode; ProjectionActivity emits ordinary PageDown. SystemUI HondaStatusBar maps138/139 to seekDown/seekUp, and SeekKeyHandler maps these to Previous/Next. SystemUI VolumeManager receives the OEM amplifier volume byte broadcast. Policy places our SYSTEM_ERROR window above Honda's volume dialog.

Design: consume matching media press/release locally and send one balanced AA pair on release, ignoring repeats/cancelled/orphan releases. Display actual received amplifier volume inside the existing AA window; do not lower the whole AA window, manufacture volume values or modify OEM windows. Spotify profile change is an experiment, not a proven fix. Native and standard media key paths are covered; unseen steering-wheel delivery paths remain UNKNOWN.

Acceptance: host event-sequence/cancellation and volume-state tests; navigation-focus regression tests retained; only scoped production inputs differ; public non-DEX APK payload identical; all previous artifacts and shared guard/runner hashes preserved; compiled candidate matches source; untimed preparation retained. Actual volume display, wheel buttons and Spotify traversal require a future live comparison.
