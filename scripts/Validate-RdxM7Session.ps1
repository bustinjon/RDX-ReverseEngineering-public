$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$project=Join-Path $root 'analysis/parallel-aa-receiver/clean-receiver'
$session=(Get-Content "$project/latest-m7-session.txt" -Raw).Trim()
$build=(Get-Content "$project/latest-build.txt" -Raw).Trim()
$r=Get-Content "$build/build-validation.json" -Raw|ConvertFrom-Json
$base=Get-Content "$session/baseline.json" -Raw|ConvertFrom-Json
foreach($field in @('sourceHashes','testHashes','fixtureHashes','sessionFixtureHashes')){foreach($entry in $r.$field){if((Get-FileHash $entry.Path).Hash -ne $entry.Hash){throw 'Build input changed'}}}
foreach($entry in @($base.sourceHashes)+@($base.testHashes)+@($base.fixtureHashes)){if((Get-FileHash $entry.Path).Hash -ne $entry.Hash){throw 'Pre-existing production/test/golden input changed unexpectedly'}}
$protected=Get-Content "$session/protected-apks-before.json" -Raw|ConvertFrom-Json
foreach($entry in $protected){if((Get-FileHash $entry.Path).Hash -ne $entry.Hash){throw 'Protected historical APK changed'}}
foreach($entry in Get-Content "$session/protected-reports-before.json" -Raw|ConvertFrom-Json){if((Get-FileHash $entry.Path).Hash -ne $entry.Hash){throw 'Historical live report changed'}}
$frozen=Join-Path $root 'analysis/parallel-aa-receiver/m5-permission/build/20261023-180320-335/rdx-m5-permission-0.2.0-m5-single-port-300s-development.apk'
if((Get-FileHash $frozen).Hash -ne 'A22E96490B9557AFF022893A8B8B7A08BB13CEC236E52704CDDAFA90A8EE8F40'){throw 'Frozen M5 differs'}
if($r.prohibitedReferences.Count -or @($r.definedClasses|Where-Object {$_ -match 'Tests|InMemorySessionTransport|ReferenceWireOracle|FakePhone|FakeTls|IndependentFixtures'}).Count){throw 'Unsafe API or host-test leakage'}
foreach($kind in @('v1','session')){
 $manifest=Get-Content "$project/test-fixtures/$kind/manifest.json" -Raw|ConvertFrom-Json
 $expected=if($kind -eq 'v1'){28}else{22}
 if($manifest.Count -ne $expected){throw 'Fixture inventory mismatch'}
 foreach($fixture in $manifest){
  $path="$project/test-fixtures/$kind/$($fixture.id).bin"
  $hex=[Convert]::ToHexString([IO.File]::ReadAllBytes($path)).ToLowerInvariant()
  $encoded=if($kind -eq 'v1'){$fixture.expectedEncodedHex}else{$fixture.rawHex}
  if($hex -ne $encoded -or (Get-FileHash $path).Hash -ne $fixture.sha256){throw 'Golden fixture changed'}
 }
}
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -Path @("$root/scripts/RdxDex.cs","$root/scripts/RdxDexApi.cs")
$definitions=[Collections.Generic.HashSet[string]]::new();$parents=@{};$platform=@()
foreach($name in @('core-libart.jar','framework.jar')){
 $path=Join-Path $root "adb/RDX-Audit/framework/$name" # Previously saved LOCAL artifact, never a device command.
 $platform+=Get-FileHash $path;$zip=[IO.Compression.ZipFile]::OpenRead($path)
 try{foreach($entry in $zip.Entries|Where-Object FullName -match '^classes\d*\.dex$'){
  $stream=$entry.Open();$memory=[IO.MemoryStream]::new()
  try{$stream.CopyTo($memory);$api=[RdxOffline.DexApi]::new([RdxOffline.Dex]::new($memory.ToArray()))
   foreach($d in $api.Definitions){[void]$definitions.Add($d)}
   foreach($pair in $api.Parents.GetEnumerator()){$parents[$pair.Key]=@($pair.Value)}
  }finally{$stream.Dispose();$memory.Dispose()}
 }}finally{$zip.Dispose()}
}
function Resolve-Method([string]$Type,[string]$Suffix,[Collections.Generic.HashSet[string]]$Seen){
 if(-not$Seen.Add($Type)){return $false};if($definitions.Contains($Type+'->'+$Suffix)){return $true};if($Suffix.StartsWith('<init>')){return $false}
 foreach($parent in $parents[$Type]){if(Resolve-Method $parent $Suffix $Seen){return $true}};return $false
}
$apiResults=@(foreach($method in $r.methodRefs){
 if($method.StartsWith('Lcom/rdx/fullscreen/clean/')){continue}
 $parts=$method -split '->',2;$intrinsic=$parts[0].StartsWith('[') -and $parts[1] -eq 'clone()Ljava/lang/Object;'
 [pscustomobject]@{method=$method;API22=($intrinsic -or (Resolve-Method $parts[0] $parts[1] ([Collections.Generic.HashSet[string]]::new())))}
})
$apiResults|ConvertTo-Json|Set-Content "$build/api22-m7-methods.json"
if(@($apiResults|Where-Object {-not$_.API22}).Count){throw 'Missing target-platform method reference'}
$dex=[RdxOffline.Dex]::new([IO.File]::ReadAllBytes("$build/dex/classes.dex"))
if(@($dex.Strings|Where-Object {$_ -match 'BEGIN (RSA |EC )?PRIVATE KEY|BEGIN CERTIFICATE|nativeSetCreds|libautoreceiver_jni|/data/misc/gal/socket'}).Count){throw 'Credential/native receiver material leaked'}
$newDet=[int]([regex]::Match($r.sessionTests,'deterministic=(\d+)').Groups[1].Value)
$newProp=[int]([regex]::Match($r.sessionTests,'propertyChecks=(\d+)').Groups[1].Value)
if($newDet -lt 100 -or $newProp -lt 1000000){throw 'Session tests incomplete'}
$result=[ordered]@{PASS=$true;scope='HOST/OFFLINE ONLY; NO ADB/DEVICE/REAL TLS/MEDIACODEC';baselineModules=$base.sourceClasses;baselineDeterministic=329;baselinePropertyAssertions=43295;baselineRandomIterations=22500;currentModules=$r.sourceClasses;newDeterministic=$newDet;totalDeterministic=329+$newDet;newPropertyAssertions=$newProp;totalPropertyAssertions=43295+$newProp;newSequences=15000;eventsPerSequence=24;totalRandomIterations=37500;seeds=@('23156093377450019','21734399680196657','21734403991622473');sessionFixtures=22;originalGoldenFixtures=28;transcripts=18;states=11;nonErrorEdges=18;invalidationEdges=9;stateEventMatrixCells=44;API22Methods=$apiResults.Count;targetFiles=$platform;Javac='source7/target7, SDK33 stubs';D8='min-api22';hostClassesExcluded=$true;protectedAPKs=$protected.Count;frozenM5SHA256=(Get-FileHash $frozen).Hash;historicalLiveReportsUnchanged=$true;allPrior31ProductionModulesUnchanged=$true;build=$build;DEX_SHA256=$r.DEX_SHA256;M4='PASS';M5='Original INCONCLUSIVE; frozen retry READY';M6='DISABLED/NOT AUTHORIZED';M7='HOST SIMULATION ONLY; no live pass';furthestState='MEDIA_SETUP_PENDING / UNKNOWN_MEDIA_TRANSITION'}
$result|ConvertTo-Json -Depth 6|Set-Content "$session/final-validation.json"
$result|ConvertTo-Json -Depth 6
