# Idea: full-screen Maps or Spotify instead of the split screen (user, 2026-11-05)

The user wants Maps or the music app to fill the whole screen instead of the split layout.

**Working theory (medium confidence, not verified):** the phone picks the split layout, not our receiver. It decides from the screen size we report: 1920x720 at 229 dpi is about 1341 dp wide, a very wide screen, so the phone splits it. Reporting a higher density makes the screen look narrower to the phone, which may switch it to the single-app layout.

**Cheap first probe:** during the T50 density check, note whether **Larger (280 dpi, about 1097 dp wide)** changes the layout.

**If it does not:** add one or two higher-density test choices in Settings (for example 320 and 360 dpi). Find the width where the phone drops the split. The trade-off is bigger icons and text.

**Other levers:** the reported pixel size and the margins in the video config. Keeping the 1920x720 fullscreen output is a hard requirement.

Status: not built. Decide after the T50 density results.
