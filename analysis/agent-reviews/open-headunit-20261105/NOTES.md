# open-headunit: what we could reuse (first pass, 2026-11-05)

Local copy: `analysis/parallel-aa-receiver/offline-followup/public/open-headunit/andreknieriem-open-headunit-e9377ff` (version 4.0.0-alpha). It is an Android app that turns a tablet or head unit into an Android Auto receiver; it descends from Michael Reid's original "headunit".

## License (decides how we can use it)
- **GNU AGPL-3.0**, with the original author's copyright notice.
- **Ideas and protocol facts** can be reused freely. Examples: "touch rows are measured from the top of the UI area", or which messages a wireless start needs. We write our own code.
- **Copying code** makes our app a derivative work. Anyone who gets the app must then be able to get its full source under AGPL. Our public repo already shares source, but the receiver holds protocol credentials we keep local. So copying code needs a deliberate user decision first. Default: reimplement from understanding, cite the file.

## Most promising for us
1. **Wireless Android Auto ("Native Mode": Wi-Fi Direct or head-unit hotspot)** under `connection/wifi`, `connection/projection`, `connection/self`.
   - Our survey shows the car has Wi-Fi Direct and hotspot support.
   - Their minSdk is 16, so this code path was written to run on old Android like our 5.1 unit.
   - The README warns that recent AA versions restrict wireless start-up triggers, and lists five ways in.
   - This is the biggest possible feature: no cable.
2. **Touch mapping** (`input/TouchCoordinateMapper.kt`). Already used as evidence for the T60 touchpad v2 alignment.
3. **Connection robustness policies** (`connection/*Policy.kt`):
   - unresponsive peer
   - video starvation
   - teardown guard
   - same-endpoint reconnect

   Compare them with our T43 self-recovery and with the transport timeouts.
4. **Key routing** (`input/MediaKeyRoutingPolicy.kt`, `ProjectionKeyPolicy.kt`) and **GPS** (`location/`), to compare with our T10 and T25.
5. **Known issue they document:** Google Maps touch problems are fixed by lowering DPI. That's relevant to our density options.

## Next step (when the user wants it)
A focused read of the wireless path. Find what the head unit must advertise and which side starts Wi-Fi Direct. Then check the 5.1 APIs it needs, and whether the car's Wi-Fi stack allows it without system permissions. Output: a feasibility report, no code.
