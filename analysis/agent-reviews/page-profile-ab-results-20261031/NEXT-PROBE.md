# Proposed smallest next probe — Down motion without its extra key pulse

**Recommendation only. No code changed or APK built for this probe.** Current selected source remains reviewed profileB, E931…EF383.

## Question

Does the synthetic key generated at the end of a Down gesture interfere with, or add an unwanted action after, navigation already driven by the continuous pad stream?

This question follows the timing evidence; it is not a finding that the key actually reverses focus. Archived factory code also sends both streams, so coexistence by itself is not a defect. The user reports the row can be entered/traversed from some states, making path-dependent traversal a stronger symptom description than permanently disabled buttons.

## Exact proposed change

In InputEvents.dispatchKey, after existing consumer/key/action validation, **consume raw146 ACTION_DOWN and ACTION_UP without calling the native-key consumer**. Continue forwarding hover-derived pad DOWN/MOVE/UP exactly as profileB does. This suppresses only the physical Down gesture's native PageDown93 pulse.

Keep profileB's declared key list, mapping table, dimensions, absolute=false, pad forwarding/dedup, Up92, Left122, Right123, Back4, Select23 and video/audio unchanged. Keep B-zone OFF. Do not remove93 from the advertised list during this probe; changing delivery and capability declaration together would obscure the result. Other explicitly delivered93 inputs are not the subject of this source-specific suppression.

Both raw146 phases must be consumed so Android cannot synthesize a fallback navigation event underneath AA. Missing callbacks must still reject input according to the existing contract. Do not suppress all keys, disable hover, add a long-swipe heuristic or modify Up/Select/window focus in the same build.

## Minimal proof requirements if a build is later requested

- Host check: raw146 press/release consumed, zero native consumer calls; no framework fallback. Other actual swipe/Select/Back pairs remain identical to B. Existing hover replay unchanged.
- Exact source diff and APK-derived dispatch check; same manifest/resources/native/key declaration. Installed APK bound to the new hash.
- Runtime evidence: raw146 events and normal pad contacts present; no native93 or fallback20 from those gestures. Other mappings and ordinary controls remain functional. A new diagnostic marker is optional if the verified installed hash plus raw/native counts distinguish the candidate; do not silently infer suppression from missing logs alone.

## Smallest future car sequence

Using the large pad and same multi-track queue: enter bottom row with the known startup Right route if available, move Up, try one ordinary Down and one large Down separately; test Down in Spotify's playlist and Maps, plus Up/Left/Right/Select/Back. Report starting/ending focused controls, not merely "worked". Record an operator video with a stated action order if available. Reconnect for collection/cleanup normally. No live step is authorized by this document.

## Conditional interpretation

- Direct Down becomes reliable and ordinary controls remain working: the extra Down key delivery is implicated under this pad/profile; confirm repeatability and then compare the baseline under matching focus/state before calling it a final fix.
- Nothing changes: the extra Down key is not sufficient to explain the symptom; investigate the phone's traversal/state/layout with a matched independent receiver/controller comparison.
- Playlist/Maps Down stops working: the key contributes required navigation there; do not ship a blanket suppression. Preserve the failed comparison instead of stacking changes or making an unproved Spotify-specific branch.
- Startup Right remains the only route: preserve that useful path observation; focus-history/distance dependence remains unresolved.

The result will test a common delivery path, not whether Spotify or Google is uniquely responsible. No new car test, build, source selection or re-arm occurred during this analysis.
