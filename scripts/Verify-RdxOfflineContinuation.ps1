$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent;$base=Join-Path $root 'analysis/parallel-aa-receiver'
& "$root/scripts/Verify-RdxOfflineImplementation.ps1"
if(-not$?){throw 'Base preservation validation failed'}
$core=(Get-Content "$base/clean-receiver/latest-build.txt" -Raw).Trim()
$foundation=Get-Content "$core/build-validation.json" -Raw|ConvertFrom-Json
if($foundation.tests-notmatch'RESULT PASS tests=67' -or $foundation.prohibitedReferences.Count-ne0){throw 'Foundation validation failed'}
foreach($s in $foundation.sourceHashes){if((Get-FileHash $s.Path).Hash-ne$s.Hash){throw 'Foundation source changed after tests'}}
if(@(Get-ChildItem "$base/clean-receiver" -Recurse -Filter *.apk).Count){throw 'Unexpected clean receiver APK'}
$m4="$base/usb-probe/build/20261023-081948-336/rdx-usb-probe-0.1.0-development.apk"
if((Get-FileHash $m4).Hash-ne'BAD93C688F7019E4205DC86EF34E6078B695623DB85770C789F29B0A3CFF4148'){throw 'Cleared M4 changed'}
if((Get-FileHash "$base/decoder-test/build/20261023-104441-074/rdx-decoder-test-0.1.0-development.apk").Hash-ne'A9509D00E312725F0062292950F513FF44BD9D5AB3C38C4B9A6B864397504B05'){throw 'Historical decoder APK changed'}
$old=Get-Content "$base/decoder-test/build/20261023-104441-074/build-report.json" -Raw|ConvertFrom-Json
foreach($s in $old.sourceHashes){$snapshot=$s.Path.Replace('decoder-test\source\','decoder-test\revisions\0.1.0-audited-source\source\');if((Get-FileHash $snapshot).Hash-ne$s.Hash){throw 'Historical source snapshot mismatch'}}
$decoderAudit=(Get-Content "$base/decoder-test/latest-audit.txt" -Raw).Trim()
$assets=Get-Content "$decoderAudit/packaged-assets-validation.json" -Raw|ConvertFrom-Json
if(-not$assets.PASS-or$assets.clips.Count-ne6){throw 'Decoder assets validation missing'}
$clips=Get-Content "$base/decoder-test/clips/clip-manifest.json" -Raw|ConvertFrom-Json
foreach($c in $clips){if((Get-FileHash $c.path).Hash-ne$c.sha256){throw 'Clip source changed'};if((Get-Item "$base/decoder-test/clips/$($c.file).host-decode.txt").Length-ne0){throw 'Host decode error log nonempty'}}
$tool=Get-Content "$root/tools/ffmpeg/provenance.json" -Raw|ConvertFrom-Json
foreach($f in $tool.files){if((Get-FileHash $f.path).Hash-ne$f.sha256){throw 'Portable tool hash changed'}}
if((Get-FileHash "$root/tools/ffmpeg/ffmpeg-9.0.2-essentials_build.zip").Hash-ne$tool.publisherSHA256){throw 'Archive hash changed'}
$reports=@('decoder-test/DECODER-APK-AUDIT.md','m5-permission/M5-INDEPENDENT-AUDIT.md','decoder-test/clips/CLIP-MANIFEST.md','clean-receiver/README.md','MALICIOUS-DETECTOR-READONLY-ACQUISITION.md')
foreach($r in $reports){if(-not(Test-Path "$base/$r")){throw "Missing report $r"}}
$result=[ordered]@{utc=[DateTime]::UtcNow.ToString('o');PASS=$true;scope='OFFLINE ONLY; no ADB/Android installation or vehicle operation';M4Unchanged=$true;historicalDecoderAPKAndSourcePreserved=$true;decoderPackagedClips=6;independentSPS=$true;hostSoftwareDecodes=6;TIExecution=$false;portableFFmpeg='9.0.2 pinned publisher archive/binary hashes verified';M5='Built/audited, M4 PASS prerequisite not yet satisfied';cleanFoundationClasses=$foundation.sourceClasses;syntheticTests=67;foundationAPI=22;enabledAOAorTransportorTLSorVideo=$false;nextLive='M4 ONLY';model='GPT-6.1 Sol High';knownUnknowns='Vehicle USB visibility/permission/ownership, TI performance, phone SPS/crop/touch, exact MaliciousDetector behavior'}
$result|ConvertTo-Json -Depth 7|Set-Content "$base/offline-continuation-validation.json"
$result|ConvertTo-Json -Depth 7
