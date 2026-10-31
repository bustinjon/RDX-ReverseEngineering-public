# B-zone candidate — collection and initial observations

## 1. Files inspected
PROJECT-RULES.md; previous Collect-CurrentTest.ps1 template; this run's session.json/final-ready.json; current collection.json, postchecks.json and capture.log. Source onAaKey location inspected without modification. Exact capture/run paths and line references: input-observation.json.

## 2. Files changed
Only new collection/report scripts under analysis/test-prep/bzone-keys-20261031 and this run's generated collection evidence/report. Temporary helper/logging/watchdog state cleaned up through the existing procedure. No production source/APK changed.

## 3. Commands run
Targeted Get-Content/rg reads; Collect-ThisTest.ps1 creates the existing Collect-CurrentTest.ps1 procedure with this run ID and updated operator result, parses it, then executes it. Save-CollectionReport.ps1 reads local evidence and saves this report/input-observation.json. Collection uses explicit-target ADB, with timeouts, through CarTest.Core.ps1. Detailed device commands/output remain in the run evidence.

## 4. Tests run and results
PASS: logs pulled before manual cleanup; 12 private capture files retrieved; installed APK matches DB9B0598467DE2BD1C7D363E52F5A0E6C759641F6490A66ED18632F402371206; fresh capture boundary; original A11Y settings restored; helper services/process, owned logger and watchdog absent. Capture hash rechecked locally. No new input behavior test performed by the agent after collection.

## 5. Findings
The operator reports the same Spotify right-third problem: cannot move down to skip previous/next, but can move up from the song title to the top-right button. Maps in the right third allows Up/Down/Left/Right across all options. The physical pad used is UNKNOWN. These are operator observations, not a timestamp-correlated proof of the phone-side focus cause.

The fresh run's overlay logs the B-zone experiment enabled at capture.log line 37189 (PID 5551), but no INPUT_BZONE_RAW or INPUT_BZONE_KEY events were found for that PID after the run boundary. Thus the saved session does not demonstrate execution of the new B-zone adapter or hardware release delivery. Do not classify it as a successful mapped-pair experiment whose AA result failed. The reported Maps/Spotify difference helps narrow investigation, but the root cause remains UNKNOWN.

## 6. Primary evidence for each finding
collection.json records operator results, hashes, 12 captures and cleanup checks; postchecks.json and manual-cleanup.txt record the returned state; device-evidence-hashes.json/private-image-hashes.json preserve copied evidence. input-observation.json records the fresh boundary, PID, experiment marker line, raw/mapped B-zone counts and ordinary raw key histogram. Capture SHA-256: 1155CD10064732026B62202DA1D08B6C558E6A3F71347C50987F048D9135FB93.

## 7. Assumptions
The operator's report applies to this explicitly identified session. No assumption that large/narrow pad use or exact widget timestamps were reported. No inference of phone-side delivery from native return codes.

## 8. Unresolved uncertainties
Spotify widget focus semantics, exact operator action/capture timing, physical pad used, why no secondary B-zone events were captured, hardware UP delivery, and this APK's full regression result remain UNKNOWN. StaticAudit PENDING. This report does not establish a repair.

## 9. Exact diff summary
New Collect-ThisTest.ps1, generated Collect-CurrentTest.ps1 (previous template changes only run ID/operator text), Save-CollectionReport.ps1; new run evidence and this report. No Java, native, manifest, readiness guard, frozen artifact, Git state or production policy edits.

## 10. Preservation checks performed
Retrieved installed APK matches the pinned test hash; capture and copied evidence hashes saved; local capture hash reverified; baseline A11Y restored and owned temporary processes absent. No key material/private APK assets inspected, no rebuild/Git mutation/guard bypass/milestone action. Frozen artifacts were not rehashed in this collection step and were not modified. Private phone captures retained locally. Device no longer needed for this log collection.
