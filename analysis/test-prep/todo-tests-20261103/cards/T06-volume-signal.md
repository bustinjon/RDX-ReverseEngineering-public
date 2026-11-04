# T06 — Can our app read Honda's volume signal?

**Type:** ADB check  
**Run with:** Check-Signals.cmd (laptop on ADB, phone unplugged)  
**Do first:** —

**Why:** Decides whether T09 (volume display) is possible.

## Steps
- Run Check-Signals.cmd, type CHECK.
- Turn the volume knob up 3, down 3. Release and re-apply the parking brake (foot on brake). Press Enter.

**Pass:** Result line for get_main_volume reads NO PERMISSION RECORDED. PROTECTED means T09 cannot work; NOT SEEN means repeat.

**Emergency stop:** stay parked and unplug the phone — that always ends our session.

**Evidence Claude reads:** signals-*/signals.json and the raw dumpsys file.

## Result (fill in)
- Date:
- Result: PASS / FAIL / PARTIAL / NOT RUN
- What you saw:
- Photos:
