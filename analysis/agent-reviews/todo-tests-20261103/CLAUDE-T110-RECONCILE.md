# T110: Claude's reconciliation of CODEX-T110.md (NOT READY)

| Finding | Verified | Action |
|---|---|---|
| BLOCKER talk grab not released if shutdown cancels the delayed release | Yes | TalkBridge.stop releases it first |
| Grab on STREAM_MUSIC may not reach Honda's voice (stream 9, per-stream focus stacks) and pauses our sinks | Yes | Grab stream 9 |
| Decoder waits up to 6 s for config; recovery ignores minimize/native focus and config drops | Yes | Config tries 100 ms (1.2 s max); recovery guarded; "Dropping frame" also triggers |
| Night reports race across threads; orphan or canceled releases could cycle; Honda long-seek sends Play on release | Yes | reportNight synchronized; own press only, not canceled; Play ignored 1.5 s after a hold |
| USB "every device" overstated; lastRemembered set before commit | Yes | Wording fixed; set after a successful write |
| Reset left night override; VISIT talk-off needs a replug | Yes | Fixed |
| Home: OK | - | - |

## Recheck (CODEX-T110-RECHECK.md, NOT READY)

| Finding | Verified | Action |
|---|---|---|
| BLOCKER Play suppression swallowed any Play for 1.5 s, including a real knob/wheel resume | Yes | Ignore one Play within 600 ms, consumed once |
| Night ownership: key/device not checked; minimize reset kept nightKeyDown | Yes | Key and device checked; cleared on both media resets |
| Reset did not report Auto to the session | Yes | nightOverrideChanged after reset |
| Stream 9 may share the music stack on this firmware, so our music may still pause | Yes, possible | Accepted: Gemini pauses music anyway when it opens |

## Final recheck (CODEX-T110-RECHECK2.md, NOT READY on item 1)

Honda's release Play cannot be told apart from a knob/wheel resume, so any suppression window can swallow a real resume. Suppression removed. Known limit: the map-colours hold may resume paused music. Items 2 and 3 OK.
