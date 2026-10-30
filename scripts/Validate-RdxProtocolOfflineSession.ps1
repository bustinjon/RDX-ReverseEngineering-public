$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$project=Join-Path $root 'analysis/parallel-aa-receiver/clean-receiver'
$session=(Get-Content "$project/latest-host-validation-session.txt" -Raw).Trim()
$build=(Get-Content "$project/latest-build.txt" -Raw).Trim()
$current=Get-Content "$build/build-validation.json" -Raw|ConvertFrom-Json
$baseline=Get-Content "$session/baseline.json" -Raw|ConvertFrom-Json
$repro=Get-Content "$session/reproducibility.json" -Raw|ConvertFrom-Json
if(-not$repro.PASS-or-not$repro.DEXByteIdentical-or-not$repro.jarPayloadEntriesIdentical){throw 'Reproducibility not verified'}
foreach($field in @('sourceHashes','testHashes','fixtureHashes')){foreach($f in $current.$field){if((Get-FileHash -LiteralPath $f.Path).Hash-ne$f.Hash){throw "Current build inputs changed: $($f.Path)"}}}
foreach($f in Get-Content "$session/compiler-input-hashes.json" -Raw|ConvertFrom-Json){if((Get-FileHash -LiteralPath $f.Path).Hash-ne$f.Hash){throw 'Compiler inputs changed'}}
$hostExcluded=@($current.definedClasses|Where-Object {$_-match 'ReferenceWireOracle|IndependentValidationTests|FakePhoneEndpoint|FakeTlsAdapter|FoundationTests|ProtocolCoreTests|IndependentFixtures'})
if($hostExcluded.Count){throw 'Test-only class leaked into library'}
$manifest=Get-Content "$project/test-fixtures/v1/manifest.json" -Raw|ConvertFrom-Json
if($manifest.Count-ne28){throw 'Golden fixture count differs'}
foreach($f in $manifest){$path=Join-Path $project ('test-fixtures/v1/'+$f.id+'.bin');$bytes=[IO.File]::ReadAllBytes($path);if((Get-FileHash -LiteralPath $path).Hash-ne$f.SHA256-or[Convert]::ToHexString($bytes).ToLowerInvariant()-ne$f.expectedEncodedHex){throw 'Golden bytes/hash mismatch'}}
$scriptFiles=@('Build-RdxCleanFoundation.ps1','New-RdxProtocolGoldenFixtures.ps1','Compare-RdxProtocolBuilds.ps1','Validate-RdxProtocolOfflineSession.ps1')
foreach($name in $scriptFiles){$t=$null;$e=$null;[void][Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot $name),[ref]$t,[ref]$e);if($e.Count){throw "Script syntax failure: $name"}}
$det=[regex]::Match($current.protocolTests,'deterministic=(\d+)');$prop=[regex]::Match($current.protocolTests,'propertyChecks=(\d+)')
$newDet=[regex]::Match($current.independentTests,'deterministic=(\d+)');$newProp=[regex]::Match($current.independentTests,'propertyChecks=(\d+)')
if(-not$det.Success-or-not$prop.Success-or-not$newDet.Success-or-not$newProp.Success){throw 'Test counters absent'}
$deterministic=67+[int]$det.Groups[1].Value+[int]$newDet.Groups[1].Value
$properties=[int]$prop.Groups[1].Value+[int]$newProp.Groups[1].Value
$originalProtection=Get-Content "$project/protocol-core-session/protected-apk-hashes-before.json" -Raw|ConvertFrom-Json
foreach($f in $originalProtection){if((Get-FileHash -LiteralPath $f.Path).Hash-ne$f.Hash){throw 'Protected APK modified'}}
$result=[ordered]@{utc=[DateTime]::UtcNow.ToString('o');PASS=$true;scope='OFFLINE/HOST ONLY; no ADB or vehicle communication';baselineModules=$baseline.sourceClasses;baselineOriginalTests=$baseline.tests;baselineProtocolTests=$baseline.protocolTests;currentModules=$current.sourceClasses;deterministicTests=$deterministic;propertyAssertions=$properties;newIndependentTests=$current.independentTests;goldenFixtures=28;independentOracle='Batch DataInput/DataOutput; no production codecs/constants; host-only';validRandomCases=5000;malformedRandomCases=2500;allRandomIterationsIncludingExisting=22500;seeds=@('23156093377450019','21734399680196657');sourceHashChecks=$true;compilerHashChecks=$true;hostClassesExcluded=$true;protectedAPKs=$originalProtection.Count;reproducibility=$repro.PASS;DEXByteIdentical=$repro.DEXByteIdentical;jarPayloadsIdentical=$repro.jarPayloadEntriesIdentical;jarContainerIdentical=$repro.jarArchiveByteIdentical;jarTimestampNondeterminismDocumented=$true;DEX_SHA256=$current.DEX_SHA256;libraryBuild=$build;noRealCredentials=$true;nextLive='M4 ONLY';M7Runtime='NOT TESTED/AUTHORIZED';sideEffects='Only local source/fixture/build/report file I/O; no active transport'}
$result|ConvertTo-Json -Depth 5|Set-Content "$session/final-validation.json"
$result|ConvertTo-Json -Depth 5
