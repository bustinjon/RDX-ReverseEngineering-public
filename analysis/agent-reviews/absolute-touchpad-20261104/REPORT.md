# Absolute touchpad inside AA (T33) — design note, 2026-11-04 (Claude)

User idea: on Honda screens the touchpad is absolute (finger position = screen position); inside AA it behaves like arrow keys. Offer absolute positioning inside AA as an option.

## Findings

| Finding | Label | Evidence |
|---|---|---|
| The receiver currently registers a **touchpad** (1325×720 pad domain, 60×40 mm) with UI navigation on. The phone treats it like focus/arrow movement | CONFIRMED | `usb-helper/source/.../protocol/InputSource.java:60-66`, `AaSessionService` registerTouchPad call |
| The same native library exposes `nativeRegisterTouchScreen(width,height,type)` and `nativeSendTouchEvent(timestamp, ids[], xs[], ys[], action, actionIndex)`, matching stock AA's facade | CONFIRMED | `InputSource.java:31,40`; stock `decompiled/AndroidAuto-current/.../protocol/InputSource.java:46,56` |
| The Honda pad delivers absolute pad coordinates to the overlay (hover/touch events in the 1325×720 domain); the video picture is 1920×720 active inside a 1920×1080 codec frame with transform (1, 1.5, 0, −180) | CONFIRMED | earlier geometry/input reports (video-geometry-20261030, input-pcm-20261030) |

## Design (option, off by default)

1. A build-time or settings switch `touchMode = navigation | absolute`.
2. Absolute mode registers a touchscreen sized to the **codec frame** (1920×1080), as stock touchscreen cars do. It keeps key codes registered (Back, select, track keys).
3. Each pad DOWN/MOVE/UP maps its pad (x, y) onto the visible active picture:
   - x_screen = x_pad × 1920/1325
   - y_screen = y_pad × 720/720 + 180, the inverse of the existing video transform.
   - It is sent as one-pointer touch events. Hover without contact moves nothing; only press-and-slide drags, as on Honda screens.
4. Physical pad **click** stays select (key 23) in navigation mode. In absolute mode, the click becomes a tap at the finger position.

## Risks / unknowns

- AA may restrict touch input while "driving". We report parked (user decision), so it is likely allowed. UNKNOWN.
- Whether the phone accepts both a touchpad and a touchscreen in one session; the safer first test registers only the touchscreen.
- Honda's pad may not report pressure/contact the same way as a touchscreen; the hover-vs-press split from the select work applies.

## Test (when built)

One change on the current baseline, with `touchMode=absolute`. Pass means:
- tapping a Maps button, a Spotify control and the app-launcher icons hits what is under the finger;
- dragging the map pans it;
- Back still works.
