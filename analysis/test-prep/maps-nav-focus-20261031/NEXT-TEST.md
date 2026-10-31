# Navigation-focus route comparison

Candidate: **v6h-nav-focus-a**, SHA-256 **21037DC393FCD162499589254D745DD0904A326BD7E5A33D69CF3FC69BFA4084**.

Change: valid projected request2 -> reply2; valid native request1 -> reply1. Invalid requests are logged/rejected. Numeric request/reply logs are included in the existing session log. No input, sensor, audio, overlay or transport changes.

Use this directory's `Prepare-RouteTest.ps1` and `Collect-RouteTest.ps1` after explicit live authorization. It reuses the successful untimed preparation. **Do not run Prepare-TimedStage.ps1 alone:** it is the ordinary readiness stage and still starts the short watchdog. The wrapper confirms removal of that run's owned timer before it issues the final untimed READY cue. Older candidate preparation scripts are not the matching CurrentSource build anymore and must not be used for this comparison.

## Instructions to repeat at the actual phone handoff

1. Park, leave the phone unplugged, and connect the laptop by ADB while Honda is on Home. Accept the user's Home confirmation without extra polling beyond required readiness checks. Keep this phone's stock Honda AA preference disabled and keep the preceding audio/Bluetooth settings unchanged.
2. Operator runs `pwsh -File analysis/test-prep/maps-nav-focus-20261031/Prepare-RouteTest.ps1`. Wait for **READY — untimed long-drive session; no scheduled cutoff**. A failed readiness result means no phone handoff.
3. Disconnect the laptop. Switch USB from ADB to Android Auto/phone mode using the established Honda menu procedure, return to Honda Home, then plug in the phone. Let the existing permission auto-clicker handle prompts.
4. **TEST NOW:** start Maps navigation to a destination clearly away from the current location. Note the start time. Make no input for at least90 seconds and check that turn-by-turn navigation remains active while AA/music continue. Avoid testing media buttons or Spotify focus during this interval so those actions do not confound cancellation timing.
5. End the route normally, start another route, and leave it active for another90 seconds. Note whether either route ends by itself and its approximate elapsed time. If it ends, distinguish actual turn-by-turn cancellation from a screen/layout change. No laptop connection is needed during either interval.
6. Unplug the phone normally and reconnect ADB. Operator runs this directory's `Collect-RouteTest.ps1`, retrieves evidence first and verifies cleanup. Wait for **SAFE TO DISCONNECT**.

No scheduled session cutoff applies after the untimed READY cue. Ordinary USB/lifecycle failures can still end AA. This candidate is not proven to fix Maps until the route comparison succeeds.

## Evidence needed

- Installed APK matches the pinned candidate hash.
- `NAVIGATION_PROTOCOL_REQUEST request=2` followed by `NAVIGATION_PROTOCOL_REPLY state=2` during route start if the phone requests focus. Any native request1 must receive reply1. Logs describe attempted native replies; they do not alone prove the phone accepted the state.
- Two routes remain active beyond90 seconds, with AA/music continuing and no other change in the test condition.
- Missing navigation-focus callbacks make the proposed causal test inconclusive. If the route still ends despite correct replies, preserve exact timing and inspect phone Maps/AA state before another change; sensor advertisement remains a separate hypothesis.

Rolling logs can replay older buffered messages. Use the current run boundary, helper PID and route timestamps when analysing the new capture, rather than attributing every matching historical line to this attempt.
