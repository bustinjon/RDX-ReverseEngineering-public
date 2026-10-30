# Could we "trick" the head unit into full screen? (final overnight answer, 2026-10-26)

Evidence base: Honda's own decompiled app and framework (read by Claude and, independently, by Codex: `CODEX-PROXY-VIDEO-CONFIG-ANALYSIS.md`, `CODEX-WM-SIZE-TRICK-ANALYSIS.md`), plus public project pages. Nothing here was tried on the car.

## 1. Plain answer
**No ADB-level or proxy-level trick we could find makes Honda's Android Auto draw wider.** Each idea fails for a specific, code-level reason. What decides the picture's width is a hard-coded setting inside Honda's own app, so only changing that app (or replacing it) can change it. The one thing your contact may truly have done is the display trick you already use, which widens Honda's *UI* but not the Android Auto picture. Worth asking her which it was (questions at the end).

| Idea | Verdict | Why (evidence) |
|---|---|---|
| A. `wm overscan` (what you use now) | Widens Honda UI only | Confirmed by your earlier logs; AA video box unchanged. |
| B. `wm size` taller virtual screen, hoping the panel stretches it | **Predicted to fail** (SUPPORTED) | This firmware scales the whole logical screen **uniformly** onto the panel: `displayRectWidth = logicalWidth * physHeight / logicalHeight` (Codex, `LogicalDisplay.java:130-156`). A taller logical screen just shrinks everything; AA stays ~1340 px wide (1920x1031 → 1340x720, 1920x1000 → 1382x720). Remaining unknown: the native compositor. |
| C. Protocol proxy (aa-proxy-rs style board) rewriting what the car says | **Cannot widen the box on its own** (SUPPORTED) | Honda looks up the phone's chosen configuration in **its own Java list** (index 0 = 1280x720 + 32 margin, index 1 = 800x480 + 50 margin) and uses those dimensions for the decoder, box and crop (`VideoSink.java:161`, `ProjectionListenerWrapper.java:25-26`). A bigger stream would be drawn into the old box (mis-scaled/cropped, or a decoder error). |
| D. Hidden settings (`SettingsBroadcastReceiver`, `screen_width` prefs) | Dead end (your notes + code) | Those preferences feed a different object; the video offer comes from hard-coded `HMIPresenter.getVideoMode` (`:819-830`). |
| E. Honda's own 2022+ app | **The only route that fixes the actual setting** | See section 3. Needs files from a 2022+ owner and has install/native-library hurdles. |
| F. Our own receiver | Correct-shape full screen if it all works | Long chain; M5 tomorrow is its first gate. |

## 2. What the code shows about the root cause (CONFIRMED, read directly)
- `HMIPresenter.getVideoMode()` = **1280x688 @229dpi/60fps** (primary), **800x430 @143dpi** (fallback), hard-coded.
- The 1340x720 box is **calculated**, not a constant: `DimensionUtils.makeViewport` fits the video into the screen keeping its aspect ratio: `min(1920/1280, 720/688) = 1.0465` → 1340x720, centred (290 px each side). Your logs match to the pixel.
- Honda already supports **margins**: it subtracts them from the negotiated size (`width - widthMargin`), and its crop/scale code has size "buckets" for 800x480, 1280x720 and **1920x1080**.
- So if the negotiated visible video were **1920x720** (a 1920x1080 stream with a 360-px height margin), the very same code would draw a **full-width, correctly shaped 1920x720 box**, and touch would follow automatically. This is exactly why a one-line change to `getVideoMode` (the project's "Candidate A") is the textbook fix, and why Honda's 2022+ full-screen update is plausibly a small change of these literals. (Plausible, not proven: no 2022+ code has been seen.)
- Decoder: the car's TI H.264 decoder declares up to 1920x1088 and 489,600 macroblocks/s (1080p@60 is exactly at that ceiling; 30 fps is safer).
- Touch: Honda registers its touchpad as 1325x720 independent of video geometry (Codex).

## 3. What would actually work, ranked (rough odds, SPECULATIVE)
| Path | Odds | Notes |
|---|---|---|
| E. Install Honda's 2022+ AA (APK) as an update | ~3-5% | Needs a 2022+ owner's files. Signer matches (CONFIRMED earlier), PMS can accept it (SUPPORTED). Hurdles: the stock APK has **no native library inside** (Honda keeps `libautoreceiver_jni.so` beside it), so an APK-only update may not find it; rollback of a higher version wipes AA data; newer Java may need newer Honda pieces. `scripts/Test-CandidateAaApk.ps1` triages this offline. |
| F. Our own receiver | ~10-15% end to end | Needs USB permission (M5 tomorrow), then taking over the phone from Honda's stock AA. |
| Patch Honda's app in place | ~0-2% | Blocked by signing/root. |
| A/B/C/D alone | ~0-3% each | Fail for the reasons above. |

## 4. One more combination worth knowing about (idea only)
C and B together are still not enough, but a proxy **could help once the box is correct**: if Honda's setting were ever changed (path E or F), a proxy board could then tune DPI/margins without touching the car. It is a tuning tool, not a way past the hard-coded setting.

## 5. Questions to put to your contact (decide what she really did)
1. Which car, year and software version? Is hers a 2019-2021 D-series or a 2022+ F-series?
2. What exactly did she run or install, and from where (a command, an app, a dongle)?
3. Is the Android Auto picture itself wider, or only the Honda screen around it? Can she share a photo and the log lines `onSourceVideoConfigChanged` / `Surface Rect(...) becomes Rect(...)`? (Those two lines tell the answer at once: a 1920-wide `Rect` means the box really widened.)
4. Does she have root, or is this a dealer/engineering unit?

## 6. What I did NOT do
Bought, installed, posted, contacted, or changed anything. All findings are from reading code and public pages.

## 7. Ground-truth confirmation from direct disassembly (2026-10-26, Rizin, not decompiled Java)

Ghidra and Rizin were set up (hash-verified downloads from their official GitHub releases: `tools/re/`) and used to check the native library directly, independent of the Java decompilation above.

- `VideoSink::codecResolutionToPixels` (native address `0xc9edc`) was disassembled by hand. It compares the resolution field to exactly three literal values and returns a hard error (`-8`) for anything else:
  | Enum value | Resulting pixels |
  |---|---|
  | 1 | 800 x 480 |
  | 2 | 1280 x 720 |
  | 3 | 1920 x 1080 |
  | anything else | rejected, `-8` |
  There is no fourth value and no `1920x720` option anywhere in the native code. This matches Codex's independent reading exactly (same function addresses), now confirmed from raw instructions rather than a decompiler.
- `HMIPresenter.getInstance()` is a plain singleton (`new HMIPresenter(context)`); there is no reflection, no OEM-variant class selection, and no property gate. `getVideoMode()` has exactly one call site. There is no second, unused presenter implementation with different numbers sitting in the APK.
- Net effect: this closes off the last plausible "maybe there's an already-built-in alternate path we haven't found yet" question. There isn't one in this binary. The two routes in section 3 (Honda's 2022+ app, or our own receiver) remain the only ones.
