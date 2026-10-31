# Focus capture correction — 2026-10-31

Earlier Down-motion planning/report text described screenshots as triggered by Down callbacks and suggested suppressing Down would reduce their scheduling. That interpretation was incorrect.

Primary source: `analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/FocusCapture.java:37–46`. `key(...)` updates annotations only; `firstTextureUpdate(...)` starts a periodic capture tick. `FocusCaptureBudget.java:4–15` limits capture to 12 images, spaced at least 10 seconds apart, within a 120-second window. This budget ends image sampling, not the AA session.

This corrects the interpretation in `analysis/test-prep/down-motion-only-20261031/REPORT.md`, its `NEXT-TEST.md`, and related focus-origin planning under `analysis/test-prep/page-profile-ab-results-20261031/`. Historical test evidence and reports remain preserved. No app source changed for this correction.
