$ErrorActionPreference='Stop'
$p='./analysis/parallel-aa-receiver/live-test-02/prototype'
$java='C:/Program Files/Eclipse Adoptium/jdk-17.0.20.101-hotspot/bin'
$sdk='C:/Program Files (x86)/Android/android-sdk'
$bt="$sdk/build-tools/32.0.0";$android="$sdk/platforms/android-33/android.jar"
foreach($part in 'src/com/rdx/fullscreen/projection','build/classes','build/dex','build/empty-res'){
    [IO.Directory]::CreateDirectory([IO.Path]::GetFullPath("$p/$part"))|Out-Null
}
function Check([string]$step){if($LASTEXITCODE-ne0){throw "$step failed"}}
& "$java/javac.exe" -encoding UTF-8 -source 7 -target 7 -bootclasspath $android -d "$p/build/classes" "$p/src/com/rdx/fullscreen/projection/ReceiverActivity.java" *> "$p/build/javac.log"
Check 'javac'
& "$java/jar.exe" cf "$p/build/classes.jar" -C "$p/build/classes" .
Check 'jar'
& "$java/java.exe" -cp "$bt/lib/d8.jar" com.android.tools.r8.D8 --min-api 21 --lib $android --output "$p/build/dex" "$p/build/classes.jar" *> "$p/build/d8.log"
Check 'D8'
& "$bt/aapt.exe" package -f -M "$p/AndroidManifest.xml" -I $android -S "$p/build/empty-res" -F "$p/build/base.apk" *> "$p/build/aapt.log"
Check 'aapt'
$unsigned="$p/build/unsigned.apk";Copy-Item "$p/build/base.apk" $unsigned
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip=[IO.Compression.ZipFile]::Open([IO.Path]::GetFullPath($unsigned),[IO.Compression.ZipArchiveMode]::Update)
try{
    [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip,[IO.Path]::GetFullPath("$p/build/dex/classes.dex"),'classes.dex',[IO.Compression.CompressionLevel]::Optimal)
    # Native bytes packaged for extraction/provenance only: no loadLibrary/native/session code exists in this synthetic-only Activity.
    [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip,(Resolve-Path './analysis/parallel-aa-receiver/libs/armeabi-v7a/libautoreceiver_jni.so'),'lib/armeabi-v7a/libautoreceiver_jni.so',[IO.Compression.CompressionLevel]::Optimal)
}finally{$zip.Dispose()}
& "$bt/zipalign.exe" -f 4 $unsigned "$p/build/aligned.apk" *> "$p/build/zipalign.log"
Check 'align'
$apk="$p/build/rdx-parallel-aa-0.1.1-live02-synthetic.apk"
& "$java/java.exe" -jar "$bt/lib/apksigner.jar" sign --ks './analysis/parallel-aa-receiver/signing/rdx-parallel-development.p12' --ks-key-alias rdx-parallel-development --ks-pass "env:RDX_SIGNING_PASSWORD" --min-sdk-version 21 --v1-signing-enabled true --v2-signing-enabled true --v3-signing-enabled false --out $apk "$p/build/aligned.apk" *> "$p/build/sign.log"
Check 'sign'
& "$java/java.exe" -jar "$bt/lib/apksigner.jar" verify --min-sdk-version 22 --max-sdk-version 22 --verbose --print-certs $apk *> "$p/build/signature-verification.txt"
Check 'API22 signer'
& "$bt/aapt.exe" dump badging $apk > "$p/build/badging.txt"
Check 'badging'
[ordered]@{package='com.rdx.fullscreen.projection';versionCode=2;versionName='0.1.1-live02-synthetic';minSDK=21;targetSDK=22;ABI='armeabi-v7a';sharedUserId=$null;permissions=@();output=$apk;sha256=(Get-FileHash $apk).Hash;originalPrototypePreserved=$true;nativePackagedButNeverLoaded=$true;M3='Deferred: load-time constructor safety not proved';credentialsIncluded=$false;activities='Only ReceiverActivity';services=@();receivers=@();providers=@();nativeCalls=$false;USBCalls=$false;GALClassesIncluded=$false;codecCalls=$false;displaySettingWrites=$false;purpose='M1/M2 synthetic Surface and own-process metrics only';signing='Same independently generated development key, not OEM';sourceHash=(Get-FileHash "$p/src/com/rdx/fullscreen/projection/ReceiverActivity.java").Hash}|ConvertTo-Json -Depth 6|Set-Content "$p/build/build-report.json"
Get-Content "$p/build/build-report.json" -Raw
