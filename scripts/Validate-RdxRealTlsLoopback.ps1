param([Parameter(Mandatory=$true)][string]$Build,[Parameter(Mandatory=$true)][string]$Session,[string]$TranscriptDirectory='second-transcripts')
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$project=Join-Path $root 'analysis/parallel-aa-receiver/clean-receiver'
$r=Get-Content "$Build/build-validation.json" -Raw|ConvertFrom-Json
foreach($f in @($r.sourceHashes)+@($r.testHashes)){if((Get-FileHash -LiteralPath $f.Path).Hash-ne$f.Hash){throw "Build input differs: $($f.Path)"}}
$baseline=Get-Content "$Session/baseline.json" -Raw|ConvertFrom-Json
foreach($field in @('fixtureHashes','sessionFixtureHashes','hondaMediaFixtureHashes','videoDataFixtureHashes','secureBodyFixtureHashes')){foreach($f in $baseline.$field){if((Get-FileHash -LiteralPath $f.Path).Hash-ne$f.Hash){throw 'Historical fixture changed'}}}
$golden=Get-Content "$project/test-fixtures/real-tls-v1/manifest.json" -Raw|ConvertFrom-Json
foreach($f in $golden){$path="$project/test-fixtures/real-tls-v1/$($f.id).bin";if((Get-FileHash $path).Hash-ne$f.sha256-or[Convert]::ToHexString([IO.File]::ReadAllBytes($path)).ToLowerInvariant()-ne$f.hex){throw 'Independent TLS envelope fixture differs'}}
$clips=Get-Content "$root/analysis/parallel-aa-receiver/decoder-test/clips/clip-manifest.json" -Raw|ConvertFrom-Json
foreach($clip in $clips){if((Get-FileHash $clip.path).Hash-ne$clip.sha256){throw 'Existing clip differs'}}
foreach($snapshot in @('source-tests-before.json','apks-before.json','live-reports-before.json')){
 foreach($f in (Get-Content "$Session/$snapshot" -Raw|ConvertFrom-Json)){if((Get-FileHash -LiteralPath $f.Path).Hash-ne$f.Hash){throw "Historical artifact changed: $($f.Path)"}}
}
$frozen=Join-Path $root 'analysis/parallel-aa-receiver/m5-permission/build/20261023-180320-335/rdx-m5-permission-0.2.0-m5-single-port-300s-development.apk'
if((Get-FileHash $frozen).Hash-ne'A22E96490B9557AFF022893A8B8B7A08BB13CEC236E52704CDDAFA90A8EE8F40'){throw 'Frozen M5 changed'}
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -Path @("$root/scripts/RdxDex.cs","$root/scripts/RdxDexApi.cs")
$definitions=[Collections.Generic.HashSet[string]]::new();$parents=@{}
foreach($name in @('core-libart.jar','framework.jar')){
 $zip=[IO.Compression.ZipFile]::OpenRead((Join-Path $root "adb/RDX-Audit/framework/$name")) # LOCAL saved artifacts only.
 try{foreach($entry in $zip.Entries|Where-Object FullName -match '^classes\d*\.dex$'){$stream=$entry.Open();$memory=[IO.MemoryStream]::new();try{$stream.CopyTo($memory);$api=[RdxOffline.DexApi]::new([RdxOffline.Dex]::new($memory.ToArray()));foreach($d in $api.Definitions){[void]$definitions.Add($d)};foreach($pair in $api.Parents.GetEnumerator()){$parents[$pair.Key]=@($pair.Value)}}finally{$stream.Dispose();$memory.Dispose()}}}finally{$zip.Dispose()}
}
function Resolve-Method([string]$Type,[string]$Suffix,[Collections.Generic.HashSet[string]]$Seen){if(-not$Seen.Add($Type)){return $false};if($definitions.Contains($Type+'->'+$Suffix)){return $true};if($Suffix.StartsWith('<init>')){return $false};foreach($parent in $parents[$Type]){if(Resolve-Method $parent $Suffix $Seen){return $true}};return $false}
$apiResults=@(foreach($method in $r.methodRefs){if($method.StartsWith('Lcom/rdx/fullscreen/clean/')){continue};$parts=$method-split'->',2;$intrinsic=$parts[0].StartsWith('[')-and$parts[1]-eq'clone()Ljava/lang/Object;';[pscustomobject]@{method=$method;API22=($intrinsic-or(Resolve-Method $parts[0] $parts[1] ([Collections.Generic.HashSet[string]]::new())))}})
$apiResults|ConvertTo-Json|Set-Content "$Build/api22-real-tls-methods.json"
if(@($apiResults|Where-Object {-not$_.API22}).Count){$apiResults|Where-Object {-not$_.API22}|Format-Table;throw 'API22 method missing'}
$dex=[RdxOffline.Dex]::new([IO.File]::ReadAllBytes("$Build/dex/classes.dex"))
if(@($dex.DefinedClasses()|Where-Object {$_-match'TlsLoopbackTests|FakeTlsPump|FakeSecure|Mp4Fixture|FakeVideoDecoder'}).Count){throw 'Host test leaked into library'}
if(@($dex.Strings|Where-Object {$_-match'BEGIN (RSA |EC )?PRIVATE KEY|BEGIN CERTIFICATE|nativeSetCreds|libautoreceiver_jni|/data/misc/gal/socket|disposable-test-only|\.p12$'}).Count){throw 'Credential/test material leaked into library'}
$test=(Get-Content "$Session/$TranscriptDirectory/test-results.txt" -Tail 1)
function Metric([string]$Name){return [long]([regex]::Match($test,"\b$Name=(\d+)").Groups[1].Value)}
if(-not$test.StartsWith('RESULT PASS')-or(Metric 'tlsCases')-lt10000-or(Metric 'combinedCases')-lt10000){throw 'Loopback corpus incomplete'}
$result=[ordered]@{PASS=$true;scope='HOST-LOCAL REAL TLS, disposable TEST credentials, MEMORY queues only';modules=$r.sourceClasses;baselineModules=53;deterministic=72211+(Metric 'deterministic');newDeterministic=(Metric 'deterministic');propertyAssertions=7077158+(Metric 'propertyChecks');newPropertyAssertions=(Metric 'propertyChecks');TLSCases=(Metric 'tlsCases');combinedCases=(Metric 'combinedCases');seed=(Metric 'seed');aaSeed=(Metric 'aaSeed');api22ExternalMethods=$apiResults.Count;API22methodSurface='PASS; runtime UNTESTED';Java7='PASS';D8min22='PASS';DEX_SHA256=$r.DEX_SHA256;historicalSourceTests='UNCHANGED';historicalAPKs='UNCHANGED';M4M5liveReports='UNCHANGED';frozenM5=(Get-FileHash $frozen).Hash;provider='SunJSSE desktop only qualified for body-completion profile';nativePrototype='NOT NECESSARY for desktop contract; API22 backend choice deferred';furthest='REAL_TLS_ABSTRACT_INPUT_ACCEPTED';nextLIVE='M5 RETRY ONLY';M6='DISABLED';noDeviceOrHondaCredentials=$true;testResults=$test}
$result|ConvertTo-Json -Depth 5|Set-Content "$Session/final-validation.json"
$result|ConvertTo-Json -Depth 5

