# Spotify compact playback row also failing in stock Honda AA

## 1. Files inspected

PROJECT-RULES.md and AGENTS.md; canonical spotify-row-mechanism-20261031/REPORT.md, spotify-bottom-row-20261031/REPORT.md and codex-touchpad-investigation.md; current helper input/session/overlay/accessibility/boot-blocker Java, manifest and accessibility XML; current Maps candidate provenance; last completed run helper_20261101T003246_a7d55e76890f4a10be4ae662173bc343 collection/postchecks; historical PROJECT-STATE.json and audit package list; primary public Spotify/Google community reports and Android developer documentation. Exact inspected source excerpts, paths, lines and hashes are in source-excerpts.json.

## 2. Files changed

Only this investigation's scope, saved-evidence extraction procedure, source/provenance/state summaries, preservation check output, public-source assessment and report. No app/source/build/setting/device or historical report changed.

## 3. Commands run

Scoped Get-Content, rg, Get-ChildItem and saved JSON inspection; pwsh -File analysis/agent-reviews/spotify-stock-aa-20261101/Inspect-SavedEvidence.ps1. Public web search/open/find on primary sources; related reports were checked against the exact symptom. Some Google pages rendered incomplete content and legacy Spotify/Reddit URL opens failed; these limitations are identified in public-sources.json. One optional asynchronous clarification asks whether stock reproduction occurred after a fresh start before our helper; no answer was available when this report was written. No ADB/USB/car/phone command, software change, Git action or delegated agent.

## 4. Tests run and results

No new behavior tests or connected comparison. Saved-evidence verification completed: all 27 current Java inputs match the selected Maps candidate; current manifest hash matches its recorded manifest; 18 prior artifacts and six guard/runner hashes match preservation records. The saved completed-run snapshot confirms helper/process absence, owned diagnostics absence and accessibility restored to empty service list/enabled=0. These checks establish saved state at collection, not the state when the user later reproduced the issue in stock AA.

## 5. Findings

### A. Conclusion: shared AA/media focus behavior is the leading explanation; exact ownership remains UNKNOWN

The user reports: "The spotify issue also affects the honda android auto." Taking that to mean the same compact playback-row traversal failure materially weakens a defect unique to our receiver's mapping/window/geometry. The phone, Spotify/AA integration and OEM hardware/input services remain common to both receiver paths. Stock reproduction does not, by itself, exonerate every installed app or persistent shared setting.

The strongest existing localization remains **bottom-left app-grid focus -> Right can enter playback row; playback row -> Up reaches title; title -> Down cannot return**, while Maps and Spotify browsing controls remain navigable. This supports a context-dependent focus/traversal problem over a fixed dead screen region or globally missing Down. The canonical mechanism report preserves the original visual/run evidence; no new focus-tree/wire evidence was obtained here.

**Assessment:** moderate confidence in a shared Android Auto/media-card navigation or media-integration issue over a receiver-only regression. Exact assignment among phone AA renderer, Spotify integration/state, shared native receiver behavior and OEM controller compatibility remains UNKNOWN. No numerical probability is justified.

### B. Related non-touch AA/Spotify problems are publicly documented; our exact row bug is not verified as a named known issue

A Spotify community user reports navigation trapped near upper controls on non-touch AA after notifications/safety pauses; reconnecting reportedly restores it. This resembles state-dependent focus loss, but does not identify our right-third row or version. It is related evidence, not an exact diagnosis. [Spotify report](https://community.spotify.com/forum/en/discussion/5414823/android-auto-unable-to-navigate-spotify-app-on-non-touch-screens).

A July 2026 Google community report describes stock Mazda hardware Back navigation freezing Spotify; an Android Auto team specialist followed up in July and other owners reported the behavior. Spotify's related thread also includes an Acura TLX owner and an April moderator referral to Google. These corroborate production non-touch/hardware-navigation regressions, but are **Back/loading bugs**, distinct from our inaccessible transport row. [Google report](https://support.google.com/androidauto/thread/448740817/android-auto-spotify-freezes-on-loading-screen-when-pressing-back-button-on-mazda-rotary-control?hl=en), [Spotify related thread](https://community.spotify.com/forum/en/discussion/7399476/android-auto-back-button-not-working-bricking-the-app).

A separate May Google report about split-screen play/pause touch activation, including a reported beta improvement, is not treated as our fix: activating a touched button and reaching it through directional focus are different failures. Current local AA/Spotify/phone-OS versions are UNKNOWN. No matching fixed release was established.

Google's media architecture supports browser/session-driven interfaces and templated media apps. Spotify branding therefore does not prove Spotify alone owns the missing directional path, nor does stock head-unit reproduction identify the component rendering that exact card. [Official media architecture](https://developer.android.com/training/cars/media).

### C. What the installed helper can do, and what saved evidence rules out

| Component/state | Primary evidence | Implication and limitation |
|---|---|---|
| Our AA overlay | AaOverlayService.java:536–570 removes its window/surface on teardown; canonical prior reports document local TextureView/input forwarding | It can affect foreground/input while active. No local Spotify playback-button views or permanent Spotify-row routing were identified in this path. Native/shared OEM state is not fully proven by Java review. |
| Permission auto-clicker | PermissionClickService.java:33–67 and203–214; accessibility_config.xml:1–8 | Requests window-state events/window retrieval and targets a SystemUI USB dialog. No directional-key-filter/touch-exploration request or onKeyEvent remapping in reviewed service. This is a weak explanation for a permanent isolated media row, but active accessibility state should still be checked at reproduction. |
| Boot blocker | BootBlockerService.java:20–26,68–83,100–105; AndroidManifest.xml:27–32 | Declares boot activation and an eight-second black overlay after an eight-second delay; window is nonfocusable/nontouchable and removed on shutdown. Its reviewed behavior does not explain a steady, visibly selectable title above an unreachable Spotify row. Do not assume all installed apps are inert merely because our AA session is closed. |
| Last completed cleanup | collection.json:2–15 and longdrive-postchecks.json, summarized in saved-state-summary.json | Helper/owned diagnostics absent; accessibility services empty and enabled=0 at 2026-11-01T00:34:43Z. Strong evidence of that cleanup only; not a contemporaneous stock-failure snapshot. |
| Factory/system preservation | PROJECT-STATE.json dated2026-10-25; preserved current project artifacts/guards | Historical record says factory AA preserved. It is not a current full hash/inventory audit of the stock AA APK, every input policy/keymap, native service or other installed package. Current comprehensive installation-side effects remain UNKNOWN. |

AaSessionService.java:588–638 destroys protocol/input resources when workers stop; if workers do not stop it explicitly retains native objects. Force-stop/process absence in saved cleanup is stronger evidence of absence than a graceful shutdown message alone. No claim is made that Java lifecycle review proves every OEM/native state reset.

### D. Evidence-ranked alternatives

1. **Leading, moderate confidence:** shared AA/media-card focus or media-integration handling. Supported by the user's cross-receiver result, prior origin-dependent path, working Maps/browsing and independent public non-touch regression reports. Exact component/version not established.
2. **Remaining shared-path alternative:** factory input/native/phone compatibility, including current layout/profile interpretation. Both receiver paths use the same car/controller; stock reproduction does not eliminate that common hardware/software path.
3. **Conditional alternative:** an active installed service/window/accessibility component or residual common state. Saved cleanup argues against it at collection time, but the stock reproduction's state/time are not captured. A fresh-start clarification would adjust this assessment, not conclusively prove it.
4. **Unsupported by reviewed evidence, not fully excluded:** a persistent system modification or another installed app. Reviewed helper code and historical preservation do not identify such a cause; a complete current device inventory/hash audit was not available. No recommendation to remove random apps or reset the car follows from that gap.

## 6. Primary evidence for each finding

- User's current stock-AA reproduction report; canonical analysis/agent-reviews/spotify-row-mechanism-20261031/REPORT.md:1–10 and its underlying visual/test-matrix evidence for the direction-specific row problem.
- source-excerpts.json contains indexed original Java/XML/manifest text; reviewed-source-provenance.json links all 27 current Java hashes to the Maps APK record and saved-state-summary.json verifies manifest provenance.
- analysis/test-prep/runs/helper_20261101T003246_a7d55e76890f4a10be4ae662173bc343/collection.json and longdrive-postchecks.json: cleanup/installed hash/accessibility/process evidence, explicitly separated from later stock-AA time.
- analysis/parallel-aa-receiver/PROJECT-STATE.json: historical factory preservation only; codex-touchpad-investigation.md:40–51 records unavailable native touchbridge implementation/callers, limiting claims of global input-state exclusion.
- public-sources.json lists direct links, content scope, dates where established, overlap, nonmatching features and fetch limitations. It identifies related reports, not an officially confirmed exact compact-row diagnosis.
- preservation.json records 24 matching artifact/guard hashes.

## 7. Assumptions

"The Spotify issue" means the same unreachable compact-card Previous/Play-Pause/Next row after moving Up, rather than a different Back/loading, playback or audio problem. Stock Honda AA is the factory receiver path rather than our overlaid receiver. Whether that observation was after a real reboot before helper activation is still UNKNOWN pending user clarification. The report does not assume the current phone OS/AA/Spotify versions from other owners' reports.

## 8. Unresolved uncertainties and smallest useful discriminator

No device action is requested or executed now. A future authorized, parked comparison should first reproduce stock AA while recording that our helper/overlay/auto-clicker remain absent **during the failure**, with normal accessibility restored. A car-off cycle alone does not establish that condition. Record the exact phone OS, Android Auto and Spotify versions, layout, focus origin and input sequence before changing software.

Then change one variable:

| Comparison | What it would separate |
|---|---|
| Another already-available media provider in the same stock AA compact card, same phone/input sequence | Spotify-specific integration/state versus media-card-wide traversal. |
| A second phone on the same clean stock AA receiver, recording both sets of versions | Phone/version/account/layout state versus car-wide behavior. |
| Exact same focus-origin sequence on another untouched Acura, accounting for TLX/RDX controller/layout differences | Local installation effects versus a reproducible stock/OEM/software interaction. |

Persistence in clean stock AA with our services absent would substantially reduce the case for changing our receiver mapping. Disappearance with our services stopped and reproducible return when one component alone is re-enabled would support installed-service interference. Both are stronger than repeated broad input-profile edits. No factory reset, random uninstalls, cache/data clearing, app downgrade or geometry rewrite is justified before this baseline. No exact known-fix version was verified.

## 9. Exact diff summary

New investigation/report/evidence metadata only. No production code change, helper install/uninstall, app-data change, setting write, launcher change, APK/firmware rebuild or car test. Prior reports are linked rather than rewritten.

## 10. Preservation checks performed

All 27 inspected Java inputs match the recorded Maps candidate; current manifest matches its recorded hash. Eighteen prior APK/artifact anchors and six guard/runner hashes remain intact. Scope writes are limited to this new analysis directory; no credentials/private-test-material read, no device/Git command, no guard bypass, no frozen rebuild or milestone advancement. Saved cleanup evidence is not mislabeled as live current state. Public reports and technical architecture are attributed to their primary sources with exact-match limits stated.
