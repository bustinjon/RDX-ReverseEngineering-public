# In-car checklist: read-only latency measurement (NOT an M5 attempt)

## What this session is
It times the car's responses to the same read-only questions the M5 safety check asks, so we can pick a fix based on real
numbers. **Nothing gets installed, nothing gets armed, no settings change, no phone needed.** It takes about one minute.

## What it is not
- Not an M5 attempt. No app install, no USB permission dialog, no phone swap.
- It does not authorize anything else. After it finishes, Claude stops and analyses offline.

## Authorization
At the car, say exactly: **"Latency measurement authorized."** Claude will not run anything on the car before that.

## Before
1. Park, handbrake on, ignition on (accessory/engine as in previous sessions).
2. Head unit on the normal **Honda Home** screen. If Diagnostics is showing, leave it through the normal on-screen RETURN.
3. Phone **unplugged** from the car.
4. Laptop connected to the car exactly as in previous sessions.
5. Do not touch the head unit while it runs.

## During (Claude does this)
1. Confirms the car is connected (read-only device list).
2. Runs `scripts/Measure-M5ReadinessLatency.ps1` **once** with defaults: 12 samples with the 400 ms pause and 12 without,
   in alternating blocks of 4. The script first checks the car's identity and framework files, and only then asks the
   lock-task question.
3. No retries. One run only.

## It stops by itself if
The lock-task check isn't "inactive", the screen isn't Honda Home, any reply contains an error, a command times out, or the
car's identity or framework files don't match. Partial results are kept.

## Stop it yourself (tell Claude) if
The screen lags or freezes, Diagnostics or anything else unexpected appears, or the unit reboots or disconnects.

## After
Claude saves the results, confirms no `adb` process is still running, and stops. The analysis, and any proposed change to
the safety check, comes later, offline, for your approval.
