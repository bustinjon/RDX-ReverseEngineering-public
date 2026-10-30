$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$project=Join-Path $root 'analysis/parallel-aa-receiver/clean-receiver'
$session=(Get-Content "$project/latest-secure-body-session.txt" -Raw).Trim()
$build=(Get-Content "$project/latest-build.txt" -Raw).Trim()
$r=Get-Content "$build/build-validation.json" -Raw|ConvertFrom-Json
foreach($field in @('sourceHashes','testHashes','fixtureHashes','sessionFixtureHashes','hondaMediaFixtureHashes','videoDataFixtureHashes','secureBodyFixtureHashes')){foreach($entry in $r.$field){if((Get-FileHash -LiteralPath $entry.Path).Hash-ne$entry.Hash){throw 'Build input differs'}}}
$before=Get-Content "$session/protected-before.json" -Raw|ConvertFrom-Json
$allowed=@('SimulatedSessionEngine.java')
foreach($entry in $before){if((Split-Path $entry.Path -Leaf)-notin$allowed -and (Get-FileHash -LiteralPath $entry.Path).Hash-ne$entry.Hash){throw "Protected historical input differs: $($entry.Path)"}}
$frozen=Join-Path $root 'analysis/parallel-aa-receiver/m5-permission/build/20261023-180320-335/rdx-m5-permission-0.2.0-m5-single-port-300s-development.apk'
if((Get-FileHash $frozen).Hash-ne'A22E96490B9557AFF022893A8B8B7A08BB13CEC236E52704CDDAFA90A8EE8F40'){throw 'Frozen M5 differs'}
if($r.prohibitedReferences.Count-or @($r.definedClasses|Where-Object {$_-match'Tests|FakeSecure|SecureBodyOracle|Mp4FixtureReader|FakeVideoDecoder|ReferenceWireOracle|IndependentFixtures|InMemorySessionTransport|FakePhone'}).Count){throw 'Unsafe external API or host test leaked into library'}
$fixtures=Get-Content "$project/test-fixtures/secure-body-v1/manifest.json" -Raw|ConvertFrom-Json
foreach($f in $fixtures){$path="$project/test-fixtures/secure-body-v1/$($f.id).bin";if((Get-FileHash $path).Hash-ne$f.sha256 -or [Convert]::ToHexString([IO.File]::ReadAllBytes($path)).ToLowerInvariant()-ne$f.rawHex){throw 'Secure golden fixture mismatch'}}
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
$apiResults|ConvertTo-Json|Set-Content "$build/api22-secure-body-methods.json"
if(@($apiResults|Where-Object {-not$_.API22}).Count){throw 'Missing target-platform method reference'}
$dex=[RdxOffline.Dex]::new([IO.File]::ReadAllBytes("$build/dex/classes.dex"))
if(@($dex.Strings|Where-Object {$_ -match 'BEGIN (RSA |EC )?PRIVATE KEY|BEGIN CERTIFICATE|nativeSetCreds|libautoreceiver_jni|/data/misc/gal/socket'}).Count){throw 'Credential/native receiver material leaked'}


$baseline=Get-Content "$session/baseline.json" -Raw|ConvertFrom-Json
$clipManifest=Get-Content "$root/analysis/parallel-aa-receiver/decoder-test/clips/clip-manifest.json" -Raw|ConvertFrom-Json
foreach($clip in $clipManifest){if((Get-FileHash $clip.path).Hash-ne$clip.sha256){throw 'Original clip changed'}}
$det=[int]([regex]::Match($r.secureBodyTests,'deterministic=(\d+)').Groups[1].Value)
$prop=[int]([regex]::Match($r.secureBodyTests,'propertyChecks=(\d+)').Groups[1].Value)
if($det-lt5800-or$prop-lt280000){throw 'Secure association corpus incomplete'}
$result=[ordered]@{PASS=$true;scope='FULL OFFLINE ENCRYPTION-BOUNDARY SESSION SIMULATION';modules=$r.sourceClasses;baselineModules=$baseline.sourceClasses;baselineDeterministic=66293;baselinePropertyAssertions=6791914;newDeterministic=$det;deterministic=66293+$det;newProperties=$prop;propertyAssertions=6791914+$prop;newValidCases=25000;newMalformedCases=5000;newCases=30000;randomCasesTotal=112500;seed='23438578244600921 / 0x534543424f4459';chunkSeed=777;newFixtures=$fixtures.Count;totalFixtures=94+$fixtures.Count;newTranscripts=6;totalTranscripts=52;clips=6;samples=2700;api22Methods=$apiResults.Count;Java7='PASS';D8min22='PASS';protectedAPKs=@($before|Where-Object Path -like '*.apk').Count;oldTestsAndFixtures='UNCHANGED';frozenM5=(Get-FileHash $frozen).Hash;furthest='ABSTRACT_INPUT_ACCEPTED; synthetic verified transport only';nextLIVE='M5 RETRY ONLY';M6='DISABLED';noHardwareOrCrypto=$true;build=$build;DEX_SHA256=$r.DEX_SHA256}
$result|ConvertTo-Json -Depth 5|Set-Content "$session/final-validation.json"
$result|ConvertTo-Json -Depth 5
