# Notes for the Hackura user guide (operator, 2026-11-07/08)

## Opening Gemini
Three ways, each switchable in Settings > Buttons:
- **Talk button, short press** (on by default): opens Gemini instead of Acura voice while Android Auto is running.
- **Talk button, hold** (off by default): opens Gemini.
- **Side-panel press while AA is showing** (off by default): opens Gemini. Press the side panel again to close Gemini (it also closes by itself after you speak to it).

## Known limitations
- **The short press replaces Acura voice** while Android Auto is running. If you use Acura voice (for example for the car's own functions), turn the short press off and use the hold or the side panel for Gemini instead.
- **Not tested with AcuraLink** (remote start, remote lock, vehicle finder, concierge, automatic collision notification and SOS calls through the car's built-in cellular unit). Hackura may affect remote start or other AcuraLink features. In particular, the talk-button takeover briefly takes the car's voice audio and only knows about phone calls, not AcuraLink's own calls.
- The Hackura tile and Honda's Now Playing card cannot open Android Auto while the car is moving (Honda blocks every non-Honda screen). Use the side panel.
- Changing Day / Night / Auto with the skip-forward hold may resume paused music (Honda sends "play" when a long press ends).

- Honda shows "Non authorized by Honda application(s) detected" after every power-off once any app has been installed, and keeps doing so even after the app is removed (Honda's detector never forgets). Hackura dismisses it automatically (Developer > Auto-dismiss Honda warning). **Never tap "Remove all"**: it uninstalls Hackura.
