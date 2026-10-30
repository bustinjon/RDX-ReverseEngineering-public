package com.rdx.fullscreen.clean;
/**
 * Host-only regression tests for the future SurfaceRenderer viewport math, written after the 2026-10-26
 * finding that Honda's stock receiver draws a 1340x720 box (not full 1920x720) because it aspect-fits its
 * hard-coded 1280x688 video into the panel. These tests pin down, with the project's own VideoConfig
 * values, that: (1) our viewport math reproduces Honda's real captured numbers exactly, so it is a faithful
 * model; (2) VideoConfig.fullscreenExperiment() with active (margin-subtracted) dimensions genuinely fills
 * the 1920x720 panel with zero letterboxing; (3) feeding NOMINAL dimensions instead of ACTIVE dimensions
 * into the same math reproduces the narrow-box symptom in our own code. No device, no decoder, no APK.
 */
public final class SurfaceViewportTests {
 private static int passed;
 private static void check(String name,boolean yes){if(!yes)throw new AssertionError(name);passed++;System.out.println("PASS "+name);}
 public static void main(String[] args){
  // (1) Faithfulness check: same inputs as the real captured log line
  //     "Surface Rect(0, 0 - 1920, 720) becomes Rect(290, 0 - 1630, 720) for video Rect(0, 0 - 1280, 688)".
  SurfaceViewport.Rect stockBox=SurfaceViewport.fit(1920,720,1280,688);
  check("reproduces Honda's real captured narrow-box numbers exactly",stockBox.equals(new SurfaceViewport.Rect(290,0,1340,720)));

  // (2) Our own fullscreen configuration, used correctly (active, margin-subtracted dimensions):
  //     nominal 1920x1080, margin 0,360 -> active 1920x720, which equals the panel exactly.
  VideoConfig full=VideoConfig.fullscreenExperiment();
  check("fullscreenExperiment active dims are exactly 1920x720",full.activeWidth()==1920&&full.activeHeight()==720);
  SurfaceViewport.Rect correct=SurfaceViewport.fitActive(1920,720,full);
  check("used correctly: zero letterbox, fills the whole 1920x720 panel",correct.equals(new SurfaceViewport.Rect(0,0,1920,720)));

  // (3) Cautionary regression: the SAME fullscreenExperiment() nominal dimensions, misused (margin NOT
  //     subtracted), reproduce the narrow-box symptom in our own code -- this is the mistake to never make
  //     when the real Android SurfaceRenderer is eventually implemented.
  SurfaceViewport.Rect misused=SurfaceViewport.fit(1920,720,full.nominalWidth,full.nominalHeight);
  check("misusing nominal instead of active dims reproduces letterboxing (not full width)",misused.width<1920&&misused.left>0);
  check("exact misuse numbers: 1280x720 letterboxed, 320px bars each side",misused.equals(new SurfaceViewport.Rect(320,0,1280,720)));

  // (4) Honda's own conservative config, used correctly, also fills the box it actually fits (sanity check
  //     that fitActive() == fit() when margin is zero on width and the panel matches the active width ratio).
  VideoConfig conservative=VideoConfig.conservative();
  check("conservative active dims are 1280x688 (Honda's own negotiated size)",conservative.activeWidth()==1280&&conservative.activeHeight()==688);
  check("conservative via fitActive matches the direct fit() call",SurfaceViewport.fitActive(1920,720,conservative).equals(stockBox));

  System.out.println("SURFACE_VIEWPORT_TESTS_PASSED "+passed);
 }
}
