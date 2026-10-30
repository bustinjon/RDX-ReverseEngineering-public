$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$base=Join-Path $root 'analysis/parallel-aa-receiver'
$matrix=@(Get-Content "$base/BUILD-VALIDATION-MATRIX.json" -Raw|ConvertFrom-Json)
foreach($row in $matrix){
 if((Get-FileHash $row.apk).Hash-ne$row.sha256){throw 'Built artifact hash changed'}
 $audit=Get-Content "$($row.audit)/audit.json" -Raw|ConvertFrom-Json
 $manual=Get-Content "$($row.audit)/manual-review.json" -Raw|ConvertFrom-Json
 if(-not$audit.PASS-or$manual.sha256-ne$row.sha256){throw 'Audit/manual review mismatch'}
 $b=Split-Path $row.apk;$build=Get-Content "$b/build-report.json" -Raw|ConvertFrom-Json
 foreach($file in $build.sourceHashes){if((Get-FileHash $file.Path).Hash-ne$file.Hash){throw 'Source changed since audited build'}}
 if((Get-FileHash (Join-Path (Split-Path (Split-Path $b)) 'AndroidManifest.xml')).Hash-ne$build.manifestHash){throw 'Source manifest changed'}
}
$scripts=@('Build-RdxBoundedHarness','Audit-RdxBoundedHarness','Capture-RdxBoundedBaseline','Generate-RdxDecoderClips','Scan-RdxWarningArtifacts','Write-RdxHarnessBuildMatrix','Verify-RdxOfflineImplementation','Get-RdxPortableFfmpeg','Build-RdxCleanFoundation','Verify-RdxDecoderAssets','Verify-RdxOfflineContinuation')
foreach($s in $scripts){$tokens=$null;$errors=$null;[void][Management.Automation.Language.Parser]::ParseFile("$root/scripts/$s.ps1",[ref]$tokens,[ref]$errors);if($errors.Count){throw "PowerShell parse error: $s"}}
$plans=@(Get-ChildItem "$root/analysis/live-logs" -Recurse -Filter plan.json | Where-Object {(Get-Content $_.FullName -Raw)-match'OFFLINE-PLAN-ONLY'})
if(-not$plans.Count){throw 'Offline plan-only capture evidence absent'}
$plan=Get-Content $plans[-1].FullName -Raw|ConvertFrom-Json
foreach($item in $plan){
 $a=@($item.arguments);$joined=$a-join' '
 if($joined-match'(^|\s)(root|reboot|remount|setprop|force-stop|chmod|chown)(\s|$)|settings put|pm clear|logcat -c|shell wm'){throw 'Mutation in capture plan'}
 if($a[0]-eq'devices'){continue}
 if($a[0]-ne'-s'-or$a[1]-ne'OFFLINE-PLAN-ONLY'){throw 'Implicit serial in capture plan'}
 if($a[2]-eq'get-state'){continue}
 if($a[2]-eq'logcat'-and$a[3]-eq'-d'){continue}
 if($a[2]-ne'shell'-or$a[3]-notin@('getprop','cat','pm','ps','dumpsys')){throw 'Non-allowlisted read-only command'}
 if($a[3]-eq'pm'-and$a[4]-ne'path'){throw 'Unexpected pm command'}
}
$capture=Get-Content "$root/scripts/Capture-RdxBoundedBaseline.ps1" -Raw
if($capture-notmatch'if\(\$PlanOnly\)' -or $capture-match'(shell.{0,10}(setprop|reboot|force-stop)|logcat.{0,10}''-c'')'){throw 'Capture source static review failed'}
$old=Get-Content "$root/analysis/current-update-stack/final-validation.json" -Raw|ConvertFrom-Json
$preserved=0
foreach($f in @($old.preservedNotes)+@($old.preservedAAArtifacts)){if((Get-FileHash $f.path).Hash-ne$f.sha256){throw "Historical notes/factory/candidate changed: $($f.path)"};$preserved++}
$original=Get-Content "$base/hashes.json" -Raw|ConvertFrom-Json
foreach($f in $original.files){if((Get-FileHash $f.path).Hash-ne$f.sha256){throw 'Original receiver prototype changed'};$preserved++}
foreach($test in @('live-test-01','live-test-02')){foreach($f in (Get-Content "$base/$test/evidence-hashes.json" -Raw|ConvertFrom-Json)){if((Get-FileHash (Join-Path "$base/$test" $f.name)).Hash-ne$f.sha256){throw 'Raw live evidence changed'};$preserved++}}
if((Get-FileHash "$base/OFFLINE-DEEP-INVESTIGATION-RESULTS.md").Hash-ne'C2DC5360556CDC8B8CEB591ADD0F1D84E3272A3E5F99F65E7B2CA05702670204'){throw 'Preserved research report changed'}
$reports=@('usb-probe/M4-INDEPENDENT-AUDIT.md','M4-USB-VISIBILITY-TEST.md','M5-USB-PERMISSION-TEST.md','M6-AOA-ONLY-TEST.md','HONDA-UNAUTHORIZED-APP-WARNING.md','STOCK-AA-USB-COMPETITION.md','CLEAN-RECEIVER-ARCHITECTURE-V2.md','DECODER-TEST-PLAN.md','FULLSCREEN-SURFACE-TEST.md','TEST-HARNESS-SAFETY.md','HONDA-LIFECYCLE-SIDE-EFFECT.md','NEXT-LIVE-TEST.md','BUILD-VALIDATION-MATRIX.md')
$links=0
foreach($relative in $reports){$file=Join-Path $base $relative;$body=Get-Content $file -Raw;if($body-match'-----BEGIN (?:RSA |EC )?PRIVATE KEY-----'){throw 'Private key in report'}
 foreach($m in [regex]::Matches($body,'\[[^\]]+\]\(([^)]+)\)')){$target=($m.Groups[1].Value-split'#',2)[0];if($target-match'^(https?:|#)' -or -not$target){continue};if(-not(Test-Path -LiteralPath (Join-Path (Split-Path $file) $target))){throw "Broken report link: $file -> $target"};$links++}
}
$result=[ordered]@{utc=[DateTime]::UtcNow.ToString('o');status='PASS: host-only validation';APKs=$matrix.Count;PowerShellScriptsParsed=$scripts.Count;capturePlanCommands=$plan.Count;capturePlanOnlyNoADB=$true;captureDynamicReads='only selected app numeric PID status/context';preservedHistoricalHashes=$preserved;researchReportUnchanged=$true;reports=$reports.Count;links=$links;M4='READY unchanged; NEXT LIVE SESSION M4 ONLY';grid='Static ready for separate geometry session';decoder='0.2 built/static/assets PASS; separate session only';M5='Built/audited; gated behind live M4 PASS';M6='Compileable disabled data-only scaffold; no APK';vehicleOperations=0;limitations='No new live milestone, Android codec execution, USB visibility/permission/ownership or exact MaliciousDetector dialog logic demonstrated'}
$result|ConvertTo-Json -Depth 6|Set-Content "$base/offline-implementation-validation.json"
$result|ConvertTo-Json -Depth 6
