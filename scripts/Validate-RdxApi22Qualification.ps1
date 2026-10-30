param([Parameter(Mandatory=$true)][string]$Session,[Parameter(Mandatory=$true)][string]$First,[Parameter(Mandatory=$true)][string]$Second,[switch]$RemoveTestCredentials)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$project=Join-Path $root 'analysis/parallel-aa-receiver/clean-receiver'
$Session=(Resolve-Path -LiteralPath $Session).Path
if(-not$Session.StartsWith($project+[IO.Path]::DirectorySeparatorChar)){throw 'Project-local session required'}
& "$PSScriptRoot/Compare-RdxProtocolBuilds.ps1" -First $First -Second $Second -Output "$Session/reproducibility.json"
& "$PSScriptRoot/Validate-RdxRealTlsLoopback.ps1" -Build $Second -Session $Session -TranscriptDirectory desktop-repeat | Out-Null
$baseline=Get-Content "$Session/final-validation.json" -Raw|ConvertFrom-Json
$b=Get-Content "$Second/build-validation.json" -Raw|ConvertFrom-Json
$a=Get-Content "$First/build-validation.json" -Raw|ConvertFrom-Json
foreach($f in @($b.sourceHashes)+@($b.testHashes)){if((Get-FileHash -LiteralPath $f.Path).Hash-ne$f.Hash){throw 'Final build input changed'}}
foreach($field in @('fixtureHashes','sessionFixtureHashes','hondaMediaFixtureHashes','videoDataFixtureHashes','secureBodyFixtureHashes')){
 $left=@($a.$field|ForEach-Object {$_.Path+'='+$_.Hash}|Sort-Object);$right=@($b.$field|ForEach-Object {$_.Path+'='+$_.Hash}|Sort-Object)
 if(@(Compare-Object $left $right).Count){throw 'Fixture hashes differ'}
}
function Tree-Hashes([string]$Directory){$base=(Resolve-Path -LiteralPath $Directory).Path;return @(Get-ChildItem -LiteralPath $base -Recurse -File|ForEach-Object {$_.FullName.Substring($base.Length)+'='+(Get-FileHash -LiteralPath $_.FullName).Hash}|Sort-Object)}
foreach($sub in @('session-transcripts','honda-media-transcripts','video-data-transcripts','secure-body-transcripts')){if(@(Compare-Object (Tree-Hashes "$First/$sub") (Tree-Hashes "$Second/$sub")).Count){throw "Transcript differs: $sub"}}
if(@(Compare-Object (Tree-Hashes "$Session/desktop-baseline") (Tree-Hashes "$Session/desktop-repeat")).Count){throw 'Repeated desktop semantic output differs (random TLS records are not persisted)'}
$model=Get-Content "$Second/api22-provider-model-test-results.txt" -Tail 1
if($model-ne(Get-Content "$First/api22-provider-model-test-results.txt" -Tail 1)){throw 'Model corpus differs'}
function Metric([string]$name){return [long]([regex]::Match($model,"\b$name=(\d+)").Groups[1].Value)}
if(-not$model.StartsWith('RESULT PASS')-or(Metric 'api22RuntimeCases')-ne0-or(Metric 'modelSequences')-ne10000){throw 'Model/result scope differs'}
$static=Get-Content "$Session/static-review-result.json" -Raw|ConvertFrom-Json
if($static.qualified-or$static.runtimeCases-ne0){throw 'Invalid target qualification claim'}
$cleanupPath="$Session/test-credential-cleanup.json"
if($RemoveTestCredentials){
 $cred=(Resolve-Path -LiteralPath "$Session/test-credentials").Path
 if(-not$cred.StartsWith($Session+[IO.Path]::DirectorySeparatorChar)-or-not(Test-Path -LiteralPath "$cred/TEST-ONLY.txt")){throw 'Only this run disposable test directory may be cleaned'}
 $allowed=@('root.p12','other-root.p12','root-trust.p12','other-root-trust.p12','client.p12','server.p12','expired.p12','future.p12','other-client.p12')
 $containers=@(Get-ChildItem -LiteralPath $cred -File -Filter *.p12)
 $hashes=@(foreach($f in $containers){if($f.Name-notin$allowed-or-not$f.FullName.StartsWith($cred+[IO.Path]::DirectorySeparatorChar)){throw 'Unexpected private container path'};Get-FileHash -LiteralPath $f.FullName})
 foreach($f in $containers){Remove-Item -LiteralPath $f.FullName}
 if(@(Get-ChildItem -LiteralPath $cred -Recurse -File|Where-Object {$_.Extension-in@('.p12','.pfx','.key','.pem')}).Count){throw 'Test private container remains'}
 if($containers.Count-or-not(Test-Path $cleanupPath)){[ordered]@{deleted=$hashes;count=$containers.Count;remainingPrivateContainers=0;scope='Only current-session disposable test containers; public certificates and hashes retained';secureErasureClaim=$false}|ConvertTo-Json -Depth 5|Set-Content $cleanupPath}
}
$cleanup=if(Test-Path $cleanupPath){Get-Content $cleanupPath -Raw|ConvertFrom-Json}else{$null}
$frozen=Join-Path $root 'analysis/parallel-aa-receiver/m5-permission/build/20261023-180320-335/rdx-m5-permission-0.2.0-m5-single-port-300s-development.apk'
$result=[ordered]@{verdict='D: API22 RUNTIME TEST UNAVAILABLE; STATIC EVIDENCE ONLY';targetQualified=$false;foundationFinalized=$false;runtimeCases=0;api22MechanicsCases=0;api22CombinedCases=0;modules=$b.sourceClasses;baselineDeterministic=$baseline.deterministic;baselinePropertyAssertions=$baseline.propertyAssertions;newModelDeterministic=(Metric 'deterministic');newModelAssertions=(Metric 'propertyChecks');newModelSequences=(Metric 'modelSequences');modelSeed=(Metric 'seed');finalDeterministic=$baseline.deterministic+(Metric 'deterministic');finalPropertyAssertions=$baseline.propertyAssertions+(Metric 'propertyChecks');independentBinaryFixtures=@(Get-ChildItem "$project/test-fixtures" -Recurse -File -Filter *.bin).Count;desktopMechanicsCases=$baseline.TLSCases;desktopCombinedCases=$baseline.combinedCases;desktopSeed=$baseline.seed;desktopAASeed=$baseline.aaSeed;api22ExternalReferences=$baseline.api22ExternalMethods;Java7='PASS';D8min22='PASS';DEX=$b.DEX_SHA256;production='UNCHANGED';priorTests='UNCHANGED';historicalAPKs=@(Get-Content "$Session/apks-before.json" -Raw|ConvertFrom-Json).Count;historicalAPKsUnchanged=$true;liveReportsUnchanged=$true;frozenM5=(Get-FileHash $frozen).Hash;sourceAnchors=$static.anchors;DEXmethods=$static.dexMethods;reproducibility='PASS DEX/class/JAR payloads/fixtures/semantic transcripts; ordinary ZIP timestamps differ';credentials=$cleanup;APK='NOT BUILT/INSTALLED: no emulator';ADBexecuted=$false;noHardwareHondaCredentialsJNIOrDecoder=$true;realCryptoScope='Desktop in-memory loopback with disposable test credentials ONLY';nextLIVE='M5 RETRY ONLY';M6='DISABLED'}
$result|ConvertTo-Json -Depth 8|Set-Content "$Session/qualification-final.json"
$result|ConvertTo-Json -Depth 8
