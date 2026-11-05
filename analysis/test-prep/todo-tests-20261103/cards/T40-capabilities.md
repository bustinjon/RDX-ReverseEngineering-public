# T40 — Sensors / Wi-Fi access point / Bluetooth / network check

**Type:** ADB check  
**Run with:** Check-Capabilities.cmd  
**Do first:** —

**Why:** Decides car sensors to the phone (accelerometer, gyro, compass), wireless AA (native library already contains WifiProjectionService, Wi-Fi credentials and Bluetooth pairing messages), and the parked data question. Read-only.

## Steps
- Run Check-Capabilities.cmd, type CHECK, wait for SAFE TO DISCONNECT, tell Claude the summary.

**Pass:** Summary recorded.

**Emergency stop:** stay parked and unplug the phone — that always ends our session.

**Evidence Claude reads:** capabilities-*/summary.json.

## Result (fill in)
- Date:
- Result: PASS / FAIL / PARTIAL / NOT RUN
- What you saw:
- Photos:
