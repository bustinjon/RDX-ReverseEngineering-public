$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$project=Join-Path $root 'analysis/parallel-aa-receiver/clean-receiver'
$java='C:/Program Files/Eclipse Adoptium/jdk-17.0.20.101-hotspot/bin'
$bt='C:/Program Files (x86)/Android/android-sdk/build-tools/32.0.0'
$android='C:/Program Files (x86)/Android/android-sdk/platforms/android-33/android.jar'
$build=Join-Path $project ('build/'+(Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
foreach($p in @($build,"$build/classes","$build/tests","$build/dex")){New-Item -ItemType Directory -Path $p -Force|Out-Null}
$sources=@(Get-ChildItem "$project/source" -Recurse -Filter *.java|ForEach-Object FullName)
$tests=@(Get-ChildItem "$project/tests" -Recurse -Filter *.java|ForEach-Object FullName)
& "$java/javac.exe" -source 7 -target 7 -bootclasspath $android -d "$build/classes" @sources *> "$build/javac.log"
if($LASTEXITCODE-ne0){throw 'Foundation compile failed'}
& "$java/javac.exe" -source 7 -target 7 -bootclasspath $android -d "$build/tests" @sources @tests *> "$build/test-javac.log"
if($LASTEXITCODE-ne0){throw 'Host tests compile failed'}
& "$java/java.exe" -cp "$build/tests" com.rdx.fullscreen.clean.FoundationTests *> "$build/test-results.txt"
if($LASTEXITCODE-ne0){throw 'Synthetic foundation tests failed'}
& "$java/java.exe" -Xmx128m -cp "$build/tests" com.rdx.fullscreen.clean.ProtocolCoreTests *> "$build/protocol-test-results.txt"
if($LASTEXITCODE-ne0){throw 'Pure protocol tests failed'}
if(Test-Path "$project/tests/com/rdx/fullscreen/clean/IndependentValidationTests.java"){
 & "$java/java.exe" -Xmx128m -cp "$build/tests" com.rdx.fullscreen.clean.IndependentValidationTests "$project/test-fixtures/v1" *> "$build/independent-test-results.txt"
 if($LASTEXITCODE-ne0){throw 'Independent protocol oracle/golden tests failed'}
}
if(Test-Path "$project/tests/com/rdx/fullscreen/clean/SessionEngineTests.java"){
 & "$java/java.exe" -Xmx128m -cp "$build/tests" com.rdx.fullscreen.clean.SessionEngineTests "$project/test-fixtures/session" "$build/session-transcripts" *> "$build/session-test-results.txt"
 if($LASTEXITCODE-ne0){Get-Content "$build/session-test-results.txt";throw 'Session state-machine tests failed'}
}
if(Test-Path "$project/tests/com/rdx/fullscreen/clean/HondaMediaTests.java"){
 & "$java/java.exe" -Xmx128m -cp "$build/tests" com.rdx.fullscreen.clean.HondaMediaTests "$project/test-fixtures/honda-media-v1" "$build/honda-media-transcripts" *> "$build/honda-media-test-results.txt"
 if($LASTEXITCODE-ne0){Get-Content "$build/honda-media-test-results.txt";throw 'Honda media tests failed'}
}
if(Test-Path "$project/tests/com/rdx/fullscreen/clean/VideoDataTests.java"){
 & "$java/java.exe" -Xmx256m -cp "$build/tests" com.rdx.fullscreen.clean.VideoDataTests "$project" "$root/analysis/parallel-aa-receiver/decoder-test/assets/clips" "$build/video-data-transcripts" *> "$build/video-data-test-results.txt"
 if($LASTEXITCODE-ne0){Get-Content "$build/video-data-test-results.txt";throw 'Video data tests failed'}
}
if(Test-Path "$project/tests/com/rdx/fullscreen/clean/SecureBodyTests.java"){
 & "$java/java.exe" -Xmx256m -cp "$build/tests" com.rdx.fullscreen.clean.SecureBodyTests "$project" "$root/analysis/parallel-aa-receiver/decoder-test/assets/clips" "$build/secure-body-transcripts" *> "$build/secure-body-test-results.txt"
 if($LASTEXITCODE-ne0){Get-Content "$build/secure-body-test-results.txt";throw 'Secure body association tests failed'}
}
if(Test-Path "$project/tests/com/rdx/fullscreen/clean/Api22ProviderModelTests.java"){
 & "$java/java.exe" -Xmx128m -cp "$build/tests" com.rdx.fullscreen.clean.Api22ProviderModelTests *> "$build/api22-provider-model-test-results.txt"
 if($LASTEXITCODE-ne0){Get-Content "$build/api22-provider-model-test-results.txt";throw 'Static-evidence API22 provider MODEL tests failed (not an Android runtime test)'}
}
if(Test-Path "$project/tests/com/rdx/fullscreen/clean/Api22ShadowStateTests.java"){
 & "$java/java.exe" -Xmx128m -cp "$build/tests" com.rdx.fullscreen.clean.Api22ShadowStateTests *> "$build/api22-shadow-test-results.txt"
 if($LASTEXITCODE-ne0){Get-Content "$build/api22-shadow-test-results.txt";throw 'Static provider shadow-state model failed'}
}
& "$java/jar.exe" cf "$build/clean-foundation.jar" -C "$build/classes" .
if($LASTEXITCODE-ne0){throw 'Library JAR failed'}
& "$java/java.exe" -cp "$bt/lib/d8.jar" com.android.tools.r8.D8 --min-api 22 --lib $android --output "$build/dex" "$build/clean-foundation.jar" *> "$build/d8.log"
if($LASTEXITCODE-ne0){throw 'API22 DEX failed'}
& "$bt/dexdump.exe" -d "$build/dex/classes.dex" > "$build/dexdump.txt"
if($LASTEXITCODE-ne0){throw 'Foundation disassembly failed'}
Add-Type -Path "$root/scripts/RdxDex.cs"
$dex=[RdxOffline.Dex]::new([IO.File]::ReadAllBytes("$build/dex/classes.dex"))
$refs=@($dex.Methods|ForEach-Object {$_.Class+'->'+$_.Name+$_.Prototype});$refs|Set-Content "$build/dex-methods.txt"
$bad=@($refs|Where-Object {$_-match'->(openDevice|requestPermission|claimInterface|controlTransfer|bulkTransfer|releaseInterface|loadLibrary|createSocket|getSocketFactory|getServerSocketFactory)\(|Ljava/net/|Ljavax/net/ssl/(SSLSocket|SSLServerSocket)|Ljava/lang/Runtime;->exec|Ljava/lang/ProcessBuilder;|Landroid/media/MediaCodec;'})
if($bad.Count){$bad|Set-Content "$build/prohibited-references.txt";throw 'Foundation has an enabled external API'}
$result=[ordered]@{utc=[DateTime]::UtcNow.ToString('o');status='PASS: compileable library protocol core; NO APK';api=22;bytecode='Java7 / D8 min22';compilePlatform='android-33.jar public API subset; minimum runtime API requires reference review';sourceClasses=$sources.Count;tests=(Get-Content "$build/test-results.txt" -Tail 1);protocolTests=(Get-Content "$build/protocol-test-results.txt" -Tail 1);DEX_SHA256=(Get-FileHash "$build/dex/classes.dex").Hash;librarySHA256=(Get-FileHash "$build/clean-foundation.jar").Hash;definedClasses=@($dex.DefinedClasses());methodRefs=$refs;prohibitedReferences=$bad;sourceHashes=@(Get-FileHash -LiteralPath $sources);testHashes=@(Get-FileHash -LiteralPath $tests);constructors='Local state only; MemoryTlsEngine provider creation requires explicit initialize';externalExecution='SSLEngine memory backend allowed only by explicit host harness initialization with disposable credentials; no socket/USB/decoder/manifest';noVehicleOperations=$true}
$result|ConvertTo-Json -Depth 7|Set-Content "$build/build-validation.json"
if(Test-Path "$build/independent-test-results.txt"){
 $result.independentTests=(Get-Content "$build/independent-test-results.txt" -Tail 1)
 $result.fixtureHashes=@(Get-ChildItem "$project/test-fixtures/v1" -File|Get-FileHash)
 $result|ConvertTo-Json -Depth 7|Set-Content "$build/build-validation.json"
}
if(Test-Path "$build/session-test-results.txt"){
 $result.sessionTests=(Get-Content "$build/session-test-results.txt" -Tail 1)
 $result.sessionFixtureHashes=@(Get-ChildItem "$project/test-fixtures/session" -File|Get-FileHash)
 $result|ConvertTo-Json -Depth 7|Set-Content "$build/build-validation.json"
}
if(Test-Path "$build/honda-media-test-results.txt"){
 $result.hondaMediaTests=(Get-Content "$build/honda-media-test-results.txt" -Tail 1)
 $result.hondaMediaFixtureHashes=@(Get-ChildItem "$project/test-fixtures/honda-media-v1" -File|Get-FileHash)
 $result|ConvertTo-Json -Depth 7|Set-Content "$build/build-validation.json"
 Get-Content "$build/honda-media-test-results.txt" -Tail 1
}
if(Test-Path "$build/video-data-test-results.txt"){
 $result.videoDataTests=(Get-Content "$build/video-data-test-results.txt" -Tail 1)
 $result.videoDataFixtureHashes=@(Get-ChildItem "$project/test-fixtures/video-data-v1" -File|Get-FileHash)
 $result|ConvertTo-Json -Depth 7|Set-Content "$build/build-validation.json"
 Get-Content "$build/video-data-test-results.txt" -Tail 1
}
if(Test-Path "$build/secure-body-test-results.txt"){
 $result.secureBodyTests=(Get-Content "$build/secure-body-test-results.txt" -Tail 1)
 $result.secureBodyFixtureHashes=@(Get-ChildItem "$project/test-fixtures/secure-body-v1" -File|Get-FileHash)
 $result|ConvertTo-Json -Depth 7|Set-Content "$build/build-validation.json"
 Get-Content "$build/secure-body-test-results.txt" -Tail 1
}
Set-Content "$project/latest-build.txt" $build
if(Test-Path "$build/api22-shadow-test-results.txt"){
 $result.api22ShadowTests=(Get-Content "$build/api22-shadow-test-results.txt" -Tail 1)
 $result|ConvertTo-Json -Depth 7|Set-Content "$build/build-validation.json"
 Get-Content "$build/api22-shadow-test-results.txt" -Tail 1
}
if(Test-Path "$build/api22-provider-model-test-results.txt"){
 $result.api22ProviderModelTests=(Get-Content "$build/api22-provider-model-test-results.txt" -Tail 1)
 $result.api22Runtime='NOT EXECUTED: static-evidence models are not provider qualification'
 $result|ConvertTo-Json -Depth 7|Set-Content "$build/build-validation.json"
 Get-Content "$build/api22-provider-model-test-results.txt" -Tail 1
}
Get-Content "$build/test-results.txt" -Tail 1
Get-Content "$build/protocol-test-results.txt" -Tail 1
if(Test-Path "$build/independent-test-results.txt"){Get-Content "$build/independent-test-results.txt" -Tail 1}
if(Test-Path "$build/session-test-results.txt"){Get-Content "$build/session-test-results.txt" -Tail 1}
Write-Output "Foundation build: $build"



