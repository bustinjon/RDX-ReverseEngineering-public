# T150 review reconciliation (Claude, 2026-11-08)

Codex verdict: NOT READY (CODEX-T150.md). Claude's checks:

- 1a false triggers on a still picture: NOT A BLOCKER. Every VIDEO_FPS line in analysis/test-prep/runs (89 runs, 1860 lines, ~930 ten-second windows) is 7.4 fps or higher, still maps included. A gap of 8 s or more would show as about 2 fps or lower. Calls and the reverse camera stay UNKNOWN; check them at the car.
- 1b focus return did not reset the clock: FIXED. lastFrameMs is now reset when native focus returns (video-focus request 1, and overlayRestored).
- 2b concurrent saves, partial files, no empty check: FIXED. One save at a time (AtomicBoolean), refuses to overwrite an existing name, deletes the file on failure, empty logcat counts as a failure.
- 2c no size cap: FIXED. 8 MB cap per file (LOG_MAX_BYTES), so 5 files stay under 40 MB.
- 3 Developer page fit: shortened the Save-logs status to "saved N KB" so it doesn't wrap. Host test asserts the 15-item fit. Real fit to be confirmed on screen.
- Saved snapshot was missing stuck protection: added stuckProtect= to the saved settings line.

Rebuilt: T150-bundle 2B36ACC4E5CA2D1B2DCDD1DAE363C080E71608E4F8C1F2BC2CA11DD0D3504F35, PASS 196 bundle checks plus feature suites.
