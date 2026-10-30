$ErrorActionPreference='Stop'
$r='./analysis/parallel-aa-receiver/live-test-02'
$s=Get-Content "$r/summary.json" -Raw|ConvertFrom-Json
if($s.milestones.M1-notlike'PASS*' -or $s.milestones.M2-notlike'PASS*' -or $s.milestones.M3-notlike'DEFERRED*'){throw 'Incorrect milestone claims'}
if(-not$s.cleanup.uninstallSuccess -or $s.stock.privateDataUnchanged-ne'NOT CLAIMED'){throw 'Cleanup/private-data qualification incorrect'}
$reports=@('./analysis/parallel-aa-receiver/LIVE-TEST-02-RESULTS.md','./analysis/parallel-aa-receiver/NEXT-LIVE-TEST.md','./analysis/parallel-aa-receiver/live-test-02/prototype/README.md','./analysis/PARALLEL-AA-RECEIVER-FEASIBILITY.md','./analysis/PARALLEL-AA-FIRST-LIVE-TEST.md','./analysis/parallel-aa-receiver/README.md','./NOTES.md')
$links=0
foreach($p in $reports){
    $body=Get-Content -LiteralPath $p -Raw
    if($body-match'-----BEGIN (?:RSA |EC )?PRIVATE KEY-----'){throw 'Private key in report'}
    foreach($m in [regex]::Matches($body,'\[[^\]]+\]\(([^)]+)\)')){
        $target=$m.Groups[1].Value.Trim('<','>');if($target-match'^(https?:|#)'){continue}
        $target=($target-split'#',2)[0]
        if(-not(Test-Path -LiteralPath (Join-Path (Split-Path $p) $target))){throw "Broken link $p -> $target"}
        $links++
    }
}
$evidence=@(Get-Content "$r/evidence-hashes.json" -Raw|ConvertFrom-Json)
foreach($file in $evidence){$path=Join-Path $r $file.name;if((Get-Item $path).Length-ne$file.bytes -or (Get-FileHash $path).Hash-ne$file.sha256){throw "Evidence changed $path"}}
$prior=Get-Content './analysis/current-update-stack/final-validation.json' -Raw|ConvertFrom-Json
foreach($file in @($prior.preservedNotes)+@($prior.preservedAAArtifacts)){if((Get-FileHash $file.path).Hash-ne$file.sha256){throw 'Original notes/factory/AB changed'}}
$original=Get-Content './analysis/parallel-aa-receiver/hashes.json' -Raw|ConvertFrom-Json
foreach($file in $original.files){if((Get-FileHash $file.path).Hash-ne$file.sha256){throw 'Original prototype changed'}}
$oldEvidence=Get-Content './analysis/parallel-aa-receiver/live-test-01/evidence-hashes.json' -Raw|ConvertFrom-Json
foreach($file in $oldEvidence){if((Get-FileHash (Join-Path './analysis/parallel-aa-receiver/live-test-01' $file.name)).Hash-ne$file.sha256){throw 'Test01 raw evidence changed'}}
foreach($name in 'stock-before','stock-after','installed-base'){
    if((Get-Content "$r/$name-signature.txt" -Raw)-notmatch'Verified using v1 scheme \(JAR signing\): true'){throw 'Missing API22 signer validation'}
}
Add-Type -Path './scripts/RdxDex.cs'
$dex=[RdxOffline.Dex]::new([IO.File]::ReadAllBytes((Resolve-Path "$r/prototype/build/dex/classes.dex")))
if(@($dex.DefinedClasses()).Count-ne2){throw 'Unexpected synthetic class set'}
$forbidden=@($dex.Methods|Where-Object {$_.Class-match'Lcom/(google|honda)/|Landroid/hardware/usb/|Landroid/media/|Landroid/os/SystemProperties;' -or $_.Name-in'load','loadLibrary','exec','setOverscan','setprop'})
if($forbidden.Count){throw 'Unexpected dangerous compiled dependency'}
Add-Type -AssemblyName System.IO.Compression.FileSystem
$build=Get-Content "$r/prototype/build/build-report.json" -Raw|ConvertFrom-Json
$zip=[IO.Compression.ZipFile]::OpenRead((Resolve-Path $build.output))
try{
    if(@($zip.Entries|Where-Object FullName -like 'assets/*').Count){throw 'Synthetic APK unexpectedly has credential/assets'}
    $native=$zip.GetEntry('lib/armeabi-v7a/libautoreceiver_jni.so');$stream=$native.Open();$sha=[Security.Cryptography.SHA256]::Create()
    try{$nativeHash=[Convert]::ToHexString($sha.ComputeHash($stream))}finally{$stream.Dispose();$sha.Dispose()}
    if($nativeHash-ne'031797DD4B0AECCA007A3AD7AF31C365BA3D47BEBDA8C94BFF13C5289F464C50'){throw 'Native bytes modified'}
}finally{$zip.Dispose()}
[xml]$manifest=Get-Content "$r/prototype/AndroidManifest.xml" -Raw
if($manifest.manifest.package-ne'com.rdx.fullscreen.projection' -or @($manifest.SelectNodes('/manifest/uses-permission|/manifest/application/service|/manifest/application/receiver|/manifest/application/provider')).Count -or $manifest.manifest.HasAttribute('sharedUserId','http://schemas.android.com/apk/res/android')){throw 'Unsafe synthetic manifest'}
& 'C:/Program Files (x86)/Android/android-sdk/build-tools/32.0.0/zipalign.exe' -c 4 $build.output
if($LASTEXITCODE-ne0){throw 'Alignment failed'}
$scripts=@('Invoke-RdxLive02Adb','Build-RdxLive02Synthetic','Analyze-RdxLive02','Verify-RdxLive02Final')
foreach($name in $scripts){$tokens=$null;$errors=$null;[void][Management.Automation.Language.Parser]::ParseFile((Resolve-Path "./scripts/$name.ps1"),[ref]$tokens,[ref]$errors);if($errors.Count){throw "Parse error $name"}}
$result=[ordered]@{utc=[DateTime]::UtcNow.ToString('o');scope='Host-only final validation; no vehicle actions';reports=$reports.Count;links=$links;test02EvidenceHashes=$evidence.Count;test01EvidenceHashesPreserved=@($oldEvidence).Count;deviceCommands=$s.commands;authorizedStateChangingCommands=@($s.stateChangingCommands).Count;runtime='M0/M1/M2 PASS, M3 deferred, no higher stage';cleanup='Clean own Activity finish and uninstall, package/process/paths absent';stock='APK/signer/full package preserved; observed OEM lifecycle setter explicitly recorded, no private-data equality claim';geometry='Own1339x720, baseline/after geometry consistent, no overscan';originalNotesFactoryABAndPrototypePreserved=$true;syntheticDexClasses=2;forbiddenCompiledReferences=0;sharedUIDOrPermissions=$false;nativeUnchangedNeverLoaded=$true;credentialsIncluded=$false;API22SignaturesVerified=$true;APK_SHA256=$build.sha256;scriptsParsed=$scripts.Count;limitations='No GAL/native load/USB/decoder test; no full private-data/system-files/settings forensic equality; model recommendation is judgment'}
$result|ConvertTo-Json -Depth 6|Set-Content './analysis/parallel-aa-receiver/live-test-02-validation.json'
$result|ConvertTo-Json -Depth 6
