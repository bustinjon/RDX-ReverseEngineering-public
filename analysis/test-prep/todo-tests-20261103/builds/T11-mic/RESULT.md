# T11 mic — 2026-11-04

- Run 1: did not start. ADB timeout while starting the background monitor (host/cable side); cleanup ran; read-only check confirmed helper absent and accessibility original.
- Run 2 (build 8A61A004…, on T21 baseline): operator reports Gemini via the AA mic icon works, "Hey Google" works, and high fan is no issue. Music resumes.
- Logs (helper_20261104T212331_010851ecddfd4a1cb58497543d9caf75): 6 MIC_REQUEST (3 open/close pairs), 3 MIC_RECORDING, 3 MIC_STOPPED, no MIC_ACK_TIMEOUT, no MIC_THREAD_STUCK. 3 MIC_ACK_SESSION_MISMATCH, all late acks after close (open=-1), which supports releasing acks as stock does. Guidance AUDIO_SUMMARY id=5 dropped=0.
- **PASS. Promoted to the baseline.**
