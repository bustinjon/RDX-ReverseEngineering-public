# Backburner: extra apps / video through our overlay (2026-11-05)

Status: parked by user decision. Revisit only when asked.

## Findings so far
- Phone-side route works in principle: apps inside Android Auto on the phone (CarStream, Fermata Auto, installed via AAAD; needs AA developer settings and unknown sources) render through our receiver like any AA screen. No receiver code needed. Untested.
- Head-unit browser engine: CONFIRMED com.android.webview, Chromium 39.0.2171.95 (2014), plus com.android.browser (audit copy of libwebviewchromium.so). LIKELY too old for YouTube and some secure sites. A newer engine (older GeckoView builds supported Android 5) could be bundled (about 80 MB); UNKNOWN whether it still works.
- Data for a head-unit app: AA gives the head unit no internet. Options: phone hotspot; Bluetooth tethering (car support UNKNOWN); the car's own LTE (pppd seen in the audit process list, AcuraLink plan likely needed, app access UNKNOWN); our own USB data link (big project, conflicts with AA on the cable).
- Safety rule for any head-unit video: parked-only, gated on car GPS speed (T25), because gear/brake signals are protected.

## Cheap first steps when revived
1. Watch-only: CarStream/Fermata through our receiver.
2. Read-only ADB network check: interfaces/routes, connectivity, Bluetooth PAN.
3. Parked: YouTube in the car's Browser app or a test page in our app.
