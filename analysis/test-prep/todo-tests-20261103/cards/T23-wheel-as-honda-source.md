# T23 — Steering wheel: Next/Previous and talk button (BLOCKED: buttons_pressed needs AUTOMOTIVE_VCS_SERVICE, signal check 2026-11-04 22:27)

**Type:** ADB check then research  
**Run with:** Check-Signals.cmd  
**Do first:** —

**Why:** Item 2. The wheel sends com.honda.auto.autovcs.buttons_pressed (RIGHT_FWD/LEFT_REW; the talk button is in the same SteeringWheelCommands set). If our app may receive it, both track buttons and talk-to-Gemini become possible; if not, the remaining route is our app appearing as a Honda audio source.

## Steps
- Run Check-Signals.cmd, type CHECK, and when asked press the wheel Next/Previous, volume and talk buttons a few times.
- Tell Claude the buttons_pressed line.

**Pass:** Decision recorded: readable (build wheel + talk) or protected (media-source route only, wheel unlikely).

**Emergency stop:** stay parked and unplug the phone — that always ends our session.

**Evidence Claude reads:** signals-*/signals.json; research in analysis/agent-reviews/wheel-media-source-20261104/REPORT.md.

## Result (fill in)
- Date:
- Result: PASS / FAIL / PARTIAL / NOT RUN
- What you saw:
- Photos:
