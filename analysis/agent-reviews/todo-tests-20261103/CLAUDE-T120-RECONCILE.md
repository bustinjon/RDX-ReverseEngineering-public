# T120: Claude's reconciliation of CODEX-T120.md (NOT READY)

| Finding | Verified | Action |
|---|---|---|
| BLOCKER a denied re-grab cleared the ownership flag, so an earlier granted entry was never abandoned | Yes | Every request marks ownership; release always abandons |
| Early NOT_ACTIVE lost (checked on the Binder thread before startTakeover ran) | Yes | NOT_ACTIVE always queued on the handler behind the start |
| No call recheck during the takeover | Yes | Rechecked at start and before the Assistant key |
| Siri watcher fired on NOT_AVAILABLE | Yes | Only active states open Gemini; others are logged |
| onPlayFromMediaId bypassed BTN_PLAY | Yes | Gated |
| Settings lost the Disabled/Never note, probe logs, auto-accept result | Yes | Restored |
| VISIT: Collect needs COLLECT first; takeover wording | Yes | Fixed |
| Home off plus side hold off removes in-session Settings | Yes | Accepted: Back hold, the exit icon and unplugging still work; it is the operator's choice |
| Re-grabs may displace our music (stream 9 may share the music stack) | Possible | Accepted: Gemini pauses music anyway |

## Recheck (CODEX-T120-RECHECK.md, NOT READY)

| Finding | Verified | Action |
|---|---|---|
| BLOCKER a stale NOT_ACTIVE could end a new takeover | Yes | States numbered on arrival; a stop counts only if it came after the takeover's own start |
| Re-grabs did not recheck calls | Yes | A re-grab during a call ends the takeover with no Assistant |
| The Assistant key runnable has one more queue hop after the call check | Yes | Accepted: one handler hop, milliseconds |

## Final recheck (CODEX-T120-RECHECK2.md, NOT READY) and stop

Arrival order cannot tie a NOT_ACTIVE to its voice session (Binder threads). Added: a stop within 250 ms of the takeover start is ignored (the car's real abort took about 2 s). Accepted as known limits, and the review loop stops here (lead's call): a leftover stop arriving later than 250 ms could open Gemini early; overlapping callbacks can lose an early stop, so the 3 s timeout releases without Gemini; one handler hop between the call check and the key. Default-off test switch, no safety impact.
