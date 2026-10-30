# Run the frozen qualifier later

No Android runtime was available during the freeze. **Do not download an image as part of this procedure. Do not connect any physical Android device.**

1. Supply an already local API22 Android5.1/5.1.1 image and compatible emulator binaries. Verify package metadata, ABI and files before creating a fresh dedicated AVD. Use fresh writable data; do not load untrusted snapshots. No network is needed; keep the emulator host isolated from external networking.
2. Boot only that AVD. Require an official emulator serial, ro.kernel.qemu=1, API22, release5.1/5.1.1 and goldfish/ranchu hardware. The runner additionally refuses any physical/unknown device reported in host ADB inventory. No physical-target override exists.
3. From project root, after checking `API22-TLS-QUALIFIER-FROZEN.md`:

[Code block omitted from public report; see authored source where available.]

Replace the serial with the positively identified emulator. Do not run this command when a car/phone/other physical ADB device is present. Every invocation specifies that emulator serial. Host-server device enumeration is read-only and stops the runner before device-target operations if a physical/unknown serial appears.

4. The runner verifies the frozen APK hash, checks identity, refuses an existing package, installs only the qualifier, explicitly launches it, polls bounded completion, retrieves private JSON/text/checkpoints and filtered logs, hashes evidence, uninstalls and verifies package/process absence. The APK is debuggable specifically for app-private `run-as` retrieval and requires zero permissions.
5. Default corpus is500 mechanics/200 combined AA/TLS cases plus20 semantic test groups and240 bounded opaque synthetic deliveries. Optional `-MechanicsCases 5000 -CombinedCases 5000` is available if runtime speed permits; the app retains its600-second bound. More volume does not replace close/completion evidence.
6. Inspect `comparison.json`, raw results and close checkpoints. No result automatically grants AndroidOpenSSL a production completion profile. A generic emulator build and the saved Acura provider have distinct provenance. An Android runtime native crash or timeout is INCONCLUSIVE until minimized; earlier `progress.json` is evidence, not a complete PASS.

Verdicts: A requires runtime TLS1.2/cipher/mutual trust/accounting/final flight, application/AA/media recovery, safely justified body completion and adequate close handling. B permits explicit non-core limitations after review. C requires a demonstrated, minimized core contract failure after ruling out adapter/fixture/clock issues. D means runtime unavailable; it remains this freeze's verdict. Runtime observations that do not yet justify completion are INCONCLUSIVE, never promoted to A by a script.

Choose a clean native backend only after actual provider behavior demonstrates an unadaptable core gap. A missing image, old API number, unobserved task or close-only limitation is insufficient. Do not use Honda JNI or vendor system libssl as the default fallback. No live milestone is authorized by running this test.
