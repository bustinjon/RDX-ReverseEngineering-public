param([Parameter(Mandatory)][ValidateSet('usb-probe','grid-test','decoder-test','m5-permission','usb-helper')][string]$Harness)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$project=Join-Path $root "analysis/parallel-aa-receiver/$Harness"
$java='C:/Program Files/Eclipse Adoptium/jdk-17.0.20.101-hotspot/bin'
$sdk='C:/Program Files (x86)/Android/android-sdk'
$bt=Join-Path $sdk 'build-tools/32.0.0'
$android=Join-Path $sdk 'platforms/android-33/android.jar'
[xml]$manifestSource=Get-Content "$project/AndroidManifest.xml" -Raw
$versionName=$manifestSource.manifest.GetAttribute('versionName','http://schemas.android.com/apk/res/android')
$versionCode=$manifestSource.manifest.GetAttribute('versionCode','http://schemas.android.com/apk/res/android')
if($versionName-notmatch'^[A-Za-z0-9._-]+$'){throw 'Unsafe/missing versionName'}
$build=Join-Path $project ('build/'+(Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
foreach($dir in @($build,"$build/classes","$build/dex","$build/res")){New-Item -ItemType Directory -Path $dir -Force|Out-Null}
function Check([string]$Step){if($LASTEXITCODE-ne0){throw "$Step failed; see $build"}}
$sources=@(Get-ChildItem "$project/source" -Recurse -Filter *.java | ForEach-Object FullName)
$receiverRoot=Join-Path $root 'analysis/parallel-aa-receiver'
if($Harness -eq 'usb-helper'){
 $extraSrc=Join-Path $receiverRoot 'src'
 if(Test-Path $extraSrc){$sources+=@(Get-ChildItem $extraSrc -Recurse -Filter *.java | ForEach-Object FullName)}
}
& "$java/javac.exe" -encoding UTF-8 -source 7 -target 7 -bootclasspath $android -d "$build/classes" @sources *> "$build/javac.log"
Check 'javac'
& "$java/jar.exe" cf "$build/classes.jar" -C "$build/classes" .
Check 'jar'
& "$java/java.exe" -cp "$bt/lib/d8.jar" com.android.tools.r8.D8 --min-api 21 --lib $android --output "$build/dex" "$build/classes.jar" *> "$build/d8.log"
Check 'D8'
$aaptArgs=@('package','-f','-M',"$project/AndroidManifest.xml",'-I',$android,'-S',"$build/res",'-F',"$build/base.apk")
$projectRes="$project/res"
if(Test-Path $projectRes){$aaptArgs+=@('-S',$projectRes)}
$assetsDir="$project/assets"
if(-not(Test-Path $assetsDir) -and $Harness -eq 'usb-helper'){$assetsDir=Join-Path $receiverRoot 'assets'}
if(Test-Path $assetsDir){$aaptArgs+=@('-A',$assetsDir,'-0','mp4')}
& "$bt/aapt.exe" @aaptArgs *> "$build/aapt.log"
Check 'aapt'
Copy-Item "$build/base.apk" "$build/unsigned.apk"
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip=[IO.Compression.ZipFile]::Open("$build/unsigned.apk",[IO.Compression.ZipArchiveMode]::Update)
try{
 [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip,"$build/dex/classes.dex",'classes.dex',[IO.Compression.CompressionLevel]::Optimal)
 if($Harness -eq 'usb-helper'){
  $nativeLib=Join-Path $receiverRoot 'libs/armeabi-v7a/libautoreceiver_jni.so'
  if(Test-Path $nativeLib){[void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip,$nativeLib,'lib/armeabi-v7a/libautoreceiver_jni.so',[IO.Compression.CompressionLevel]::NoCompression)}
 }
}finally{$zip.Dispose()}
& "$bt/zipalign.exe" -f 4 "$build/unsigned.apk" "$build/aligned.apk" *> "$build/zipalign.log"
Check 'zipalign'
$apk=Join-Path $build "rdx-$Harness-$versionName-development.apk"
& "$java/java.exe" -jar "$bt/lib/apksigner.jar" sign --ks "$root/analysis/parallel-aa-receiver/signing/rdx-parallel-development.p12" --ks-key-alias rdx-parallel-development --ks-pass "env:RDX_SIGNING_PASSWORD" --min-sdk-version 21 --v1-signing-enabled true --v2-signing-enabled true --v3-signing-enabled false --out $apk "$build/aligned.apk" *> "$build/sign.log"
Check 'sign'
& "$java/java.exe" -jar "$bt/lib/apksigner.jar" verify --min-sdk-version 22 --max-sdk-version 22 --verbose --print-certs $apk *> "$build/signature-verification.txt"
Check 'API22 signature'
& "$bt/zipalign.exe" -c -v 4 $apk *> "$build/zipalign-verification.txt"
Check 'alignment verification'
& "$bt/aapt.exe" dump badging $apk > "$build/badging.txt"
Check 'badging'
& "$bt/aapt.exe" dump xmltree $apk AndroidManifest.xml > "$build/manifest-tree.txt"
Check 'manifest tree'
[ordered]@{harness=$Harness;version=$versionName;versionCode=$versionCode;utc=[DateTime]::UtcNow.ToString('o');apk=$apk;sha256=(Get-FileHash $apk).Hash;build=$build;minSdk=21;targetSdk=22;signatureVerifiedAPI22=$true;alignmentVerified=$true;staticAudit='PENDING';sourceHashes=@(Get-FileHash -LiteralPath $sources);manifestHash=(Get-FileHash "$project/AndroidManifest.xml").Hash}|ConvertTo-Json -Depth 6|Set-Content "$build/build-report.json"
Set-Content "$project/latest-build.txt" $build
Get-Content "$build/build-report.json"
