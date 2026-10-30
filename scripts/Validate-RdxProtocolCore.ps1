$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$project=Join-Path $root 'analysis/parallel-aa-receiver/clean-receiver'
$session=Join-Path $project 'protocol-core-session'
$build=(Get-Content "$project/latest-build.txt" -Raw).Trim()
$report=Get-Content "$build/build-validation.json" -Raw|ConvertFrom-Json
if($report.protocolTests -notmatch 'RESULT PASS deterministic=\d+ propertyChecks=\d+' -or $report.prohibitedReferences.Count){throw 'Protocol build failed/incomplete'}
if(@($report.definedClasses|Where-Object {$_-match 'FakePhone|FakeTls|FoundationTests|ProtocolCoreTests|IndependentFixtures'}).Count){throw 'Host-only classes leaked into library'}
foreach($f in @($report.sourceHashes)+@($report.testHashes)){if((Get-FileHash -LiteralPath $f.Path).Hash -ne $f.Hash){throw "Untested source/test revision: $($f.Path)"}}
$before=Get-Content "$session/protected-apk-hashes-before.json" -Raw|ConvertFrom-Json
foreach($f in $before){if((Get-FileHash -LiteralPath $f.Path).Hash -ne $f.Hash){throw "Protected APK changed: $($f.Path)"}}
$before|ConvertTo-Json -Depth 4|Set-Content "$session/protected-apk-hashes-after.json"
if(@(Get-ChildItem $project -Recurse -Filter *.apk).Count){throw 'Unexpected receiver APK'}
Add-Type -Path @("$root/scripts/RdxDex.cs","$root/scripts/RdxDexApi.cs")
$definitions=[Collections.Generic.HashSet[string]]::new()
$parents=@{};$platformHashes=@()
foreach($name in @('core-libart.jar','framework.jar')){
 $path=Join-Path $root "adb/RDX-Audit/framework/$name"
 $platformHashes+=Get-FileHash -LiteralPath $path
 $zip=[IO.Compression.ZipFile]::OpenRead($path)
 try{foreach($entry in $zip.Entries|Where-Object FullName -match '^classes\d*\.dex$'){
  $stream=$entry.Open();$memory=[IO.MemoryStream]::new()
  try{$stream.CopyTo($memory);$dex=[RdxOffline.Dex]::new($memory.ToArray());$api=[RdxOffline.DexApi]::new($dex)
   foreach($d in $api.Definitions){[void]$definitions.Add($d)}
   foreach($kv in $api.Parents.GetEnumerator()){$parents[$kv.Key]=@($kv.Value)}
  }finally{$stream.Dispose();$memory.Dispose()}
 }}finally{$zip.Dispose()}
}
function Resolve-PlatformMethod([string]$Type,[string]$Suffix,[Collections.Generic.HashSet[string]]$Seen){
 if(-not$Seen.Add($Type)){return $false}
 if($definitions.Contains($Type+'->'+$Suffix)){return $true}
 if($Suffix.StartsWith('<init>')){return $false}
 foreach($parent in $parents[$Type]){if(Resolve-PlatformMethod $parent $Suffix $Seen){return $true}}
 return $false
}
$apiResults=@()
foreach($method in $report.methodRefs){
 if($method.StartsWith('Lcom/rdx/fullscreen/clean/')){continue}
 $parts=$method -split '->',2
 $intrinsic=$parts[0].StartsWith('[') -and $parts[1] -eq 'clone()Ljava/lang/Object;'
 $found=$intrinsic -or (Resolve-PlatformMethod $parts[0] $parts[1] ([Collections.Generic.HashSet[string]]::new()))
 $apiResults += [pscustomobject]@{method=$method;foundInPulledPlatformOrArrayIntrinsic=$found}
}
$apiResults|ConvertTo-Json -Depth 5|Set-Content "$build/api22-local-platform-method-check.json"
$missing=@($apiResults|Where-Object {-not$_.foundInPulledPlatformOrArrayIntrinsic})
if($missing.Count){$missing|ConvertTo-Json|Write-Output;throw 'Missing target-platform API references'}
$capture=Join-Path $root 'analysis/parallel-aa-receiver/offline-followup/public/open-android-auto/mrmees-open-android-auto-61eab61/captures/oem-vw-mib3oi-2026-04-06/messages.jsonl'
$expected=@{4='000708001001';58='000b08e7c9dccace6a1000';59='000c08e7c9dccace6a'}
$captured=@()
foreach($line in Get-Content -LiteralPath $capture -TotalCount 59){$m=$line|ConvertFrom-Json;if($expected.ContainsKey([int]$m.seq)){$b=[Convert]::FromBase64String($m.payload_b64);$hex=[Convert]::ToHexString($b,0,[int]$m.payload_len).ToLowerInvariant();if($hex-ne$expected[[int]$m.seq]){throw 'Independent capture fixture mismatch'};$captured += [pscustomobject]@{sequence=$m.seq;type=$m.msg_type;plaintextHex=$hex;outerHeaderAvailable=$false}}}
if($captured.Count-ne3){throw 'Capture fixture missing'}
$captured|ConvertTo-Json|Set-Content "$session/capture-fixture-validation.json"
foreach($f in Get-Content "$session/reference-hashes.json" -Raw|ConvertFrom-Json){if((Get-FileHash -LiteralPath $f.Path).Hash-ne$f.Hash){throw 'Pinned reference changed'}}
$coreDex=[RdxOffline.Dex]::new([IO.File]::ReadAllBytes("$build/dex/classes.dex"))
if(@($coreDex.Strings|Where-Object {$_-match 'BEGIN (RSA |EC )?PRIVATE KEY|BEGIN CERTIFICATE|nativeSetCreds|libautoreceiver_jni|/data/misc/gal/socket'}).Count){throw 'Unexpected credential/proprietary receiver material'}
$buildScriptTokens=$null;$buildScriptErrors=$null
[void][Management.Automation.Language.Parser]::ParseFile("$root/scripts/Build-RdxCleanFoundation.ps1",[ref]$buildScriptTokens,[ref]$buildScriptErrors)
if($buildScriptErrors.Count){throw 'Build script syntax error'}
$result=[ordered]@{utc=[DateTime]::UtcNow.ToString('o');PASS=$true;scope='PURE OFFLINE CORE; no ADB/device/USB/TLS/decoder execution';sourceModules=$report.sourceClasses;originalTests=$report.tests;protocolTests=$report.protocolTests;api22References=$apiResults.Count;targetPlatformFiles=$platformHashes;APIReferenceReview='Declared/native/abstract method definitions plus inherited lookup; not just DEX string presence. Installed compile SDK33; Java7, D8min22, referenced methods present in pulled target platform. Not an Android runtime execution.';protectedAPKs=$before.Count;capturePayloadFixtures=3;hostOnlyClassesExcluded=$true;library=$build;DEX_SHA256=$report.DEX_SHA256;realCredentials=$false;nextLive='M4 ONLY';M3='DEFERRED'}
$result|ConvertTo-Json -Depth 7|Set-Content "$session/validation.json"
$result|ConvertTo-Json -Depth 7
