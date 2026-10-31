# Next diagnostic — same APK, controlled starting focus

No new build or car action has been performed for this plan. Use the currently installed Down-only probe as a known reference; do not change flags, mappings, queue or apps during the comparison. This test identifies a focus path, not a code fix.

## Established observations

- User now identifies the successful start as the **bottom-left Android Auto app-grid button being selected**. Right from there reaches the compact Spotify playback row.
- Up leaves that row; Down cannot return.
- Latest private capture frame2 has an outline around Play/Pause. Frames3/4 have an outline around the title on the same compact card. The row is not permanently unfocusable.
- Maps controls in similar screen positions were navigable in earlier reported tests. They are different UI targets, so this does not prove a vertical navigation link exists inside the media card.

## Smallest future sequence, once the user requests another live session

1. With the same compact Spotify layout/queue, identify **focus on the bottom-left app-grid icon**, without pressing Select. Move Right and record which playback button becomes outlined.
2. Move Up and name the new outlined item. Attempt one ordinary Down; name the result.
3. Without restarting AA, return **focus** to that same bottom-left app-grid icon. Move Right again. Record whether the original row-entry path works a second time.
4. Distinguish merely focusing the app-grid button from activating/opening the launcher. If focusing it without opening it is not possible, record that limitation instead of treating the state as identical.
5. If filming, include both the focus outline and the gesture/action order. A screenshot per10seconds can miss a short successful path; the current Down-only probe also does not schedule screenshots from suppressed Down keys.
6. Reconnect for ordinary log/capture collection and cleanup. No automatic re-arm or settings change.

## Interpretation

| Result | Supported inference | Still unknown |
|---|---|---|
| Grid-focus -> Right works again after the failure | Reachability depends on focus origin/path; a restart is not required for that recovery | Why the title's vertical route fails |
| Same grid origin restored but Right now fails | Startup/history or an interaction-mode transition matters beyond visible origin | Which event changed mode; whether Up's extra key matters |
| Opening the launcher then Right recovers, but simple refocus does not | Recreating UI/navigation state can recover the path | Whether focus cache, app state or another transition is responsible |
| Row reachable but Select cannot operate it | Focus reachability and playback action availability are separate issues | Actual phone session/action state |

Do not globally remap Down to Right/MoveEnd as a substitute: that would also change working Maps/list behavior, and the receiver has no reliable knowledge of which phone control currently owns focus.

## Remaining configuration comparison, held for later

The verified matrix leaves one navigation-setting combination uncovered: page/move mappings, no declared arrows19–22, **uiAbsolute=true**, normal Down pulse. Archived Honda registration uses true; our recent no-arrow profiles used false. If a new build is later chosen, reference the original B APK/source E931…EF383 and change only its live absolute flag. Restoring the normal Down dispatch is restoration of that reference, not a second experimental variable versus B. Against the current Down-only source it would be two source edits, which must be reported honestly.

This would test an interaction left open by previous single-setting comparisons. It is not a promised fix or full factory parity, and should not replace the cheaper no-code focus-origin check above.
