# Discriminating checks for the unreachable whole playback row

No checks in this document have been executed. No new APK is built or phone/car action authorized by the document.

## First distinction: enabled controls versus unreachable focus

The operator clarified that **Play/Pause as well as both skip controls are unreachable**. The useful question is now whether the compact row has any controller focus route, not just whether a queue permits skipping. A future check should use a known multi-track playlist, keep the same item/queue between compact and main-player views, and record which controls are focusable. A different song/view in an old capture is not a perfect same-state comparison.

Google documents that playback actions/state govern media controls. Its developer guidance identifies `dumpsys media_session` as an inspection method. Any future phone-side read must target the actual phone/session, be separately authorized, and retain sensitive metadata locally. Head-unit HondaStatusBar/RAAM states in this archive are not a substitute. Do not clear app data, update/downgrade apps, or change Spotify settings based on an unproved disabled-state theory.

## Recommended independent comparison before another receiver repair

Use Google's Desktop Head Unit with the same phone/app versions, the same compact media layout and a known queue. Compare directional input against sequential rotation and, in a separate matching layout/profile, touch activation. These are distinct documented DHU inputs. No DHU binary was found at the standard SDK path in this workspace; none was installed or run. Bench setup requires a later authorized install/phone connection.

Match the receiver's current video request as closely as documented settings permit: nominal1920x1080, total vertical margin360, dpi229,60fps, left driver. The DHU's public configuration does not establish exact1325x720/60x40mm pad parity or native implementation equivalence. Match layout visually and record its requested/negotiated values. A mismatched layout makes the result weaker.

| Result | What it supports | What it does not establish |
|---|---|---|
| DHU arrows fail but rotation reaches the row | Sequential control path can reach children that this directional path does not | That the RDX should become rotary globally, or that AAOS FocusAreas apply to projected AA |
| DHU controller reaches row in the same layout | Investigate our registration/event contract more closely | Exact receiver parity or a specific Java bug |
| Touch activation works but controller cannot enter row | Buttons can execute in that tested state; focus traversal is the problem there | That RDX pointer injection is a safe production replacement |
| Another available media provider has the same compact-row issue | Shared AA media-card/controller path becomes stronger than a Spotify-only explanation | A Google defect is proved; receiver contract may affect all providers |
| Only Spotify reproduces under matched conditions | Spotify session/layout compatibility becomes stronger | That raw Down is broken or updating Spotify is the fix |

Use an already available provider if possible; no new media app purchase/install is selected by this review.

## Newly identified capability comparison

The old page/move APK is **not** a full factory-profile control: it maps raw146/152 to93/92 but advertises `{4,19,20,21,22,23,92,93,122,123}`. The archived Honda presenter/integration does not advertise arrows19–22. The APK's native registration call was independently inspected, so this is an artifact-backed distinction, not merely current-source reasoning. Phone use of that distinction remains UNKNOWN.

A clean future A/B for this hypothesis would keep the same stable Select/Back, hover dedup, dimensions, absolute flag and page/move mappings in both references, then compare advertised navigation lists **with and without19–22**. Main-pad gestures in both must emit the registered page/move codes; sending DPAD20 while deliberately omitting20 is an invalid comparison. Do not transplant the old APK wholesale and reintroduce old hover/other differences. This requires an explicitly scoped future build, not a runtime toggle performed here.

A simpler factory-style navigation-subset candidate would combine coherent mappings/registration, but its result would test that combined profile rather than isolate key declaration from mapping. Do not call either candidate “full factory parity”: omitted media/voice/navigation keys and current versus archived behavior would still differ. Do not add unrelated media actions merely to match the archived list.

## Keep prior negative results

The simple absolute true->false flag comparison did not fix the bottom row. The B-zone adapter was enabled but received no matching raw events in the two recent sessions. Key-only/hover-off previously lost working Up. Page/move mappings previously failed after returning, but their advertised arrows remained present. Each result limits a different claim; none justifies another unrecorded global remap.

Sources: [Google DHU input/configuration](https://developer.android.com/training/cars/testing/dhu), [media playback controls/state](https://developer.android.com/training/cars/media/enable-playback). Source-specific claims and local lines are indexed in REPORT.md.
