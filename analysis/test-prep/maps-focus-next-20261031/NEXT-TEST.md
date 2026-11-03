# Maps-only runtime test

APK: rdx-v6h-maps-focus-next.apk, SHA-256 **21037DC393FCD162499589254D745DD0904A326BD7E5A33D69CF3FC69BFA4084**. This is a verified copy of the existing navigation-focus candidate, not a new rebuild. The only production method changed versus D1A29 is navigationFocusCallback; no volume/media/input/sensor changes are included.

This test's Windows shortcuts require this project and the existing RDX-Working-Launcher runtime folder. They do not change the ordinary launcher's default APK. Close the ordinary launcher before running them so the session lock can be acquired.

1. Park, phone unplugged, Honda Home, laptop connected by ADB. Keep this phone's Honda Android Auto preference Disabled/Never. Run Start-Next-Test.cmd. The test first recovers the prior working-launcher session, then installs/verifies the Maps-only APK using unchanged required readiness checks and prepares untimed diagnostics.
2. **First checkpoint, before phone connection:** with helper, auto-clicker and capture arming active, try the normal three-button Diagnostics shortcut, then return to Home. In the console enter PASS only if that works. A non-PASS response collects logs/cleans up and provides no phone handoff.
3. Only after PASS: disconnect the laptop, use the established Honda Diagnostics USB menu to select Android Auto/phone mode, return Home, then plug in the configured phone. The permission auto-clicker should handle prompts. Keep prior working audio settings; for optional audio isolation disable only the car's Bluetooth Media audio on the phone, keeping pairing/call audio unchanged.
4. Start a Maps route to somewhere clearly away from the current location. Leave it active at least 90 seconds without media-button/Spotify experiments. End it normally, start a second route, and wait another 90 seconds. Note any actual route cancellation and elapsed time. A layout change is not by itself route cancellation.
5. Unplug phone, restore ADB mode with the same Honda menu procedure, reconnect laptop and run Collect-Next-Test.cmd. Wait for SAFE TO DISCONNECT. It uses the repaired short-path pull helper and saves original settings/cleanup verification.

No scheduled session cutoff applies after untimed readiness. Ordinary USB/lifecycle failures can still end AA. The route fix is not proven until runtime results and current-run focus request/reply logs support it. Missing callbacks make causal attribution inconclusive. Preserve the test's latest/run records for collection; do not start another test before collecting the previous one.

Operator automation for the active Codex session is Prepare-ConnectedTest.ps1: it uses the explicit current ADB/Home authorization and stops at the manual Diagnostics checkpoint. It does not connect a phone or automatically proceed into AA.

Canonical callback/compiled evidence and earlier ten host cases remain in analysis/test-prep/maps-nav-focus-20261031/REPORT.md. The earlier Diagnostics PASS with helper+auto-clicker but no capture arm is recorded in analysis/test-prep/one-change-nav-focus-20261031/retry-20261031-223038/collection.json.
