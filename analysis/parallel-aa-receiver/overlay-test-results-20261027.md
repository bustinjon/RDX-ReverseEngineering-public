# Overlay Fullscreen Test Results — 2026-10-27

## Summary

**CONFIRMED: System overlay windows draw over the entire 1920x720 physical display,
bypassing all Honda zone restrictions (status bar, B-zone, sidebar).**

## Test Results

| # | Window Type               | View Size  | Position | Covers Status Bar | Covers Sidebar |
|---|---------------------------|------------|----------|-------------------|----------------|
| 1 | TYPE_SYSTEM_OVERLAY (2006)| 1920x720   | (0,0)    | YES               | YES            |
| 2 | TYPE_SYSTEM_ERROR (2010)  | 1920x720   | (0,0)    | YES               | YES            |
| 3 | TYPE_SYSTEM_ALERT (2003)  | 1920x720   | (0,0)    | YES               | YES            |

## Key Findings

1. **Physical framebuffer is 1920x720** — not 1280x720 as previously assumed.
   Honda splits this into: main content area (~1280px) + sidebar/Cards panel (~640px).

2. **All three system overlay types bypass Honda's zone restrictions:**
   - 32px status bar at top: BYPASSED
   - B-zone 1280x688 activity area: BYPASSED
   - Sidebar/A-zone boundary: BYPASSED

3. **SYSTEM_ALERT_WINDOW permission works on API 22** — it's a "normal" permission
   (auto-granted at install), no runtime grant needed. No Honda policy blocks it.

4. **FLAG_LAYOUT_IN_SCREEN + FLAG_LAYOUT_NO_LIMITS + FLAG_FULLSCREEN** together
   achieve the full coverage. MATCH_PARENT gives 1920x720.

5. **Overlay draws on top of Honda's own UI** — home screen icons, sidebar cards,
   and status bar clock are all visible underneath the semi-transparent overlay.

## Implications for Fullscreen Android Auto

The fullscreen path is now clear:
- Create a TYPE_SYSTEM_OVERLAY (or TYPE_SYSTEM_ERROR) window from our service
- Render Android Auto video frames into a SurfaceView or TextureView inside that overlay
- The AA content will cover the entire 1920x720 display
- Negotiate AA protocol video at 1920x720 (or 1280x720 centered if the protocol caps out)
- Touch events: TYPE_SYSTEM_OVERLAY is FLAG_NOT_TOUCHABLE by default;
  TYPE_SYSTEM_ALERT or TYPE_SYSTEM_ERROR can receive touch

## Touch Consideration

For Android Auto we need touch input. TYPE_SYSTEM_OVERLAY (2006) uses
FLAG_NOT_TOUCHABLE — touches pass through to the underlying activity.
TYPE_SYSTEM_ERROR (2010) and TYPE_SYSTEM_ALERT (2003) CAN receive touch events.
**TYPE_SYSTEM_ERROR is the best candidate** — highest z-order of the touchable types.

## Flags Used

[Code block omitted from public report; see authored source where available.]

## Raw Logs

[Code block omitted from public report; see authored source where available.]

## Touch Test Results

Touch test used TYPE_SYSTEM_ERROR with FLAG_NOT_TOUCHABLE removed.

**Touchpad coordinate range (from 6 DOWN events):**
- X: 20 — 1324  (~1300px usable width, maps to main content area only)
- Y: 3 — 719   (full 720px height, including status bar region)

The touchpad does NOT reach the sidebar area (x > ~1324).
The touchpad DOES reach the status bar area (y < 32).

**Implication:** Render AA video at 1280x720 positioned at x=0 — it fits exactly
within the touchable zone. The remaining ~640px sidebar width can be black.

[Code block omitted from public report; see authored source where available.]

## Photo Evidence

- `photos/Test 1- Test 2.jpg` — TYPE_SYSTEM_ERROR overlay covering full screen + sidebar
- `photos/Test 3.jpg` — TYPE_SYSTEM_ALERT overlay, sidebar visible underneath
