# T23 — Steering-wheel track buttons (via Honda media source)

**Type:** Research  
**Run with:** Not built  
**Do first:** Signal check confirms buttons_pressed permission

**Why:** The wheel sends com.honda.auto.autovcs.buttons_pressed (RIGHT_FWD/LEFT_REW), which Honda routes to the selected Honda audio source; with FM selected the dash says function unavailable. The only plausible route is for our app to appear as a Honda audio source (a standard media-browser service) that the user selects.

## Steps
- Claude: check how Honda discovers and selects media sources, and what selection requires.

**Pass:** Wheel Next/Previous skip tracks in AA.

**Emergency stop:** stay parked and unplug the phone — that always ends our session.

**Evidence Claude reads:** VolumeManager/SeekKeyHandler, our media session.

## Result (fill in)
- Date:
- Result: PASS / FAIL / PARTIAL / NOT RUN
- What you saw:
- Photos:
