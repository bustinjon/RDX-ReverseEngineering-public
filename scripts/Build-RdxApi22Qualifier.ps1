param([string]$CredentialDirectory,[switch]$ReuseFrozenTestAssets)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent;$base=Join-Path $root 'analysis/parallel-aa-receiver';$project=Join-Path $base 'api22-tls-qualifier';$clean=Join-Path $base 'clean-receiver';$java='C:/Program Files/Eclipse Adoptium/jdk-17.0.20.101-hotspot/bin';$sdk='C:/Program Files (x86)/Android/android-sdk';$bt="$sdk/build-tools/32.0.0";$android="$sdk/platforms/android-33/android.jar"
$build=Join-Path $project ('build/'+(Get-Date -Format 'yyyyMMdd-HHmmss-fff'));foreach($p in @($build,"$build/classes","$build/host","$build/dex","$build/res")){New-Item -ItemType Directory -Path $p -Force|Out-Null}
function Check([string]$stage){if($LASTEXITCODE-ne0){throw "$stage failed: $build"}}
$names=@('AaFrame','AaFrameParser','AaFrameWriter','AaMessageAssembler','OuterFrameContext','RawAaFrame','DecryptedAaFragment','SecureBodyAdapter','SecureBodyPipeline','SyntheticTlsState','MemoryTlsEngine','RealTlsBodyAdapter','TlsPumpResults','TlsRecordLedger','ProtocolLimits','ProtoWire','DiscoveryCodec','AaServiceDiscovery','AaServiceRegistry','InputConfig','VideoConfig','ControlMessages','HondaMediaMessages','MediaConfigStatus','MediaPayload','H264')
$production=@($names|ForEach-Object {Join-Path $clean "source/com/rdx/fullscreen/clean/$_.java"});$qualifier=@(Get-ChildItem "$project/source" -Recurse -Filter *.java|ForEach-Object FullName)
& "$java/javac.exe" -encoding UTF-8 -source 7 -target 7 -bootclasspath $android -d "$build/classes" @production @qualifier *> "$build/javac.log";Check 'Java7 API-surface compile'
$hostSources=@(Get-ChildItem "$project/host" -Filter *.java|ForEach-Object FullName)
# Compile together from source: no dependency on host classes in the target APK.
$core="$project/source/com/rdx/fullscreen/api22tls/QualifierCore.java"
& "$java/javac.exe" -encoding UTF-8 -source 7 -target 7 -d "$build/host" @production $core "$clean/tests/com/rdx/fullscreen/clean/Mp4FixtureReader.java" @hostSources *> "$build/host-javac.log";Check 'Host fixture exporters'
if(-not$ReuseFrozenTestAssets){
 if(-not$CredentialDirectory-or-not(Test-Path "$CredentialDirectory/TEST-ONLY.txt")){throw 'Fresh generated TEST-only hierarchy required'}
 foreach($f in (Get-Content "$CredentialDirectory/credential-hashes.json" -Raw|ConvertFrom-Json)){if((Get-FileHash -LiteralPath $f.path).Hash-ne$f.sha256){throw 'Disposable fixture input changed'}}
 New-Item -ItemType Directory -Force "$project/assets/test-credentials","$project/assets/fixtures"|Out-Null
 & "$java/java.exe" -cp "$build/host" ExportTestCredentials $CredentialDirectory "$project/assets/test-credentials";Check 'PUBLIC TEST export'
 & "$java/java.exe" -cp "$build/host" ExportQualifierFixtures $clean "$base/decoder-test/assets/clips" "$project/assets/fixtures";Check 'Existing clip fixture export'
 Get-ChildItem "$project/assets" -Recurse -File|Get-FileHash|ConvertTo-Json|Set-Content "$project/test-asset-hashes.json"
}else{foreach($f in (Get-Content "$project/test-asset-hashes.json" -Raw|ConvertFrom-Json)){if((Get-FileHash -LiteralPath $f.Path).Hash-ne$f.Hash){throw 'Frozen PUBLIC TEST asset changed'}}}
& "$java/jar.exe" cf "$build/classes.jar" -C "$build/classes" .;Check 'JAR'
& "$java/java.exe" -cp "$bt/lib/d8.jar" com.android.tools.r8.D8 --min-api 22 --lib $android --output "$build/dex" "$build/classes.jar" *> "$build/d8.log";Check 'D8 min22'
& "$bt/aapt.exe" package -f -M "$project/AndroidManifest.xml" -I $android -S "$build/res" -A "$project/assets" -F "$build/base.apk" *> "$build/aapt.log";Check 'aapt'
Add-Type -AssemblyName System.IO.Compression.FileSystem
Copy-Item "$build/base.apk" "$build/unsigned.apk";$zip=[IO.Compression.ZipFile]::Open("$build/unsigned.apk",[IO.Compression.ZipArchiveMode]::Update);try{[void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip,"$build/dex/classes.dex",'classes.dex',[IO.Compression.CompressionLevel]::Optimal)}finally{$zip.Dispose()}
& "$bt/zipalign.exe" -f 4 "$build/unsigned.apk" "$build/aligned.apk";Check 'alignment'
$apk="$build/rdx-api22-tls-qualifier.apk"
& "$java/java.exe" -jar "$bt/lib/apksigner.jar" sign --ks "$base/signing/rdx-parallel-development.p12" --ks-key-alias rdx-parallel-development --ks-pass "env:RDX_SIGNING_PASSWORD" --min-sdk-version 22 --v1-signing-enabled true --v2-signing-enabled true --v3-signing-enabled false --out $apk "$build/aligned.apk" *> "$build/sign.log";Check 'Development signing'
& "$java/java.exe" -jar "$bt/lib/apksigner.jar" verify --min-sdk-version 22 --max-sdk-version 22 --verbose --print-certs $apk *> "$build/signature.txt";Check 'API22 signature'
& "$bt/zipalign.exe" -c 4 $apk;Check 'Alignment verification'
& "$bt/aapt.exe" dump badging $apk > "$build/badging.txt";Check 'badging'
& "$bt/aapt.exe" dump xmltree $apk AndroidManifest.xml > "$build/manifest-tree.txt";Check 'manifest'
& "$bt/dexdump.exe" -d "$build/dex/classes.dex" > "$build/dexdump.txt";Check 'DEX independent dump'
[ordered]@{apk=$apk;sha256=(Get-FileHash $apk).Hash;package='com.rdx.fullscreen.api22tls';version='0.3.0-final-offline-qualifier';code=3;minSdk=22;targetSdk=22;requestedPermissions=@();signing='Existing independent development signer; NOT Honda';productionSources=$production;sourceHashes=@(Get-FileHash -LiteralPath ($production+$qualifier));hostHashes=@(Get-FileHash -LiteralPath $hostSources);manifestHash=(Get-FileHash "$project/AndroidManifest.xml").Hash;DEX=(Get-FileHash "$build/dex/classes.dex").Hash;assets='PUBLIC TEST MATERIAL: disposable PKCS8 keys and public certificates retained intentionally for reproducible test APK';runtime='NOT EXECUTED on Android'}|ConvertTo-Json -Depth 6|Set-Content "$build/build-report.json"
Set-Content "$project/latest-build.txt" $build
Write-Output "Qualifier built: $apk"
