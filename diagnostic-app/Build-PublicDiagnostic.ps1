#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$SdkPath=$env:ANDROID_SDK_ROOT,
    [string]$JavaHome=$env:JAVA_HOME,
    [string]$BuildToolsVersion='32.0.0',
    [string]$Platform='android-33'
)
$ErrorActionPreference='Stop'
if(-not $SdkPath){throw 'Set ANDROID_SDK_ROOT or pass -SdkPath.'}
if(-not $JavaHome){throw 'Set JAVA_HOME or pass -JavaHome (JDK 17).'}
if(-not $env:RDX_DIAGNOSTIC_SIGNING_PASSWORD){throw 'Set RDX_DIAGNOSTIC_SIGNING_PASSWORD to your own local signing password.'}
$tools=Join-Path $SdkPath "build-tools/$BuildToolsVersion"
$androidJar=Join-Path $SdkPath "platforms/$Platform/android.jar"
$bin=Join-Path $JavaHome 'bin'
$stamp=[DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss-fff')
$build=Join-Path $PSScriptRoot "build/$stamp"
$classes=Join-Path $build 'classes'
$dex=Join-Path $build 'dex'
$signing=Join-Path $PSScriptRoot 'build/local-signing'
foreach($dir in @($classes,$dex,$signing)){$null=New-Item -ItemType Directory -Force -Path $dir}
function Check-Exit([string]$step){if($LASTEXITCODE -ne 0){throw "$step failed; inspect local build logs."}}
$source=Join-Path $PSScriptRoot 'source/org/rdxresearch/diagnostics/DiagnosticActivity.java'
$manifest=Join-Path $PSScriptRoot 'AndroidManifest.xml'
$sourceHashes=@($source,$manifest | ForEach-Object {[pscustomobject]@{path=[IO.Path]::GetRelativePath($PSScriptRoot,$_).Replace('\','/');sha256=(Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash}})
& "$bin/javac.exe" -encoding UTF-8 -source 7 -target 7 -bootclasspath $androidJar -d $classes $source *> "$build/javac.log"
Check-Exit 'javac'
& "$bin/jar.exe" cf "$build/classes.jar" -C $classes .
Check-Exit 'jar classes'
& "$bin/java.exe" -cp "$tools/lib/d8.jar" com.android.tools.r8.D8 --min-api 21 --lib $androidJar --output $dex "$build/classes.jar" *> "$build/d8.log"
Check-Exit 'D8'
& "$tools/aapt.exe" package -f -M $manifest -I $androidJar -F "$build/unsigned.apk" *> "$build/aapt.log"
Check-Exit 'aapt'
& "$bin/jar.exe" uf "$build/unsigned.apk" -C $dex classes.dex
Check-Exit 'package DEX'
& "$tools/zipalign.exe" -f 4 "$build/unsigned.apk" "$build/aligned.apk" *> "$build/zipalign.log"
Check-Exit 'zipalign'
$keystore=Join-Path $signing 'public-diagnostic.p12'
if(-not (Test-Path -LiteralPath $keystore)){
    & "$bin/keytool.exe" -genkeypair -alias public-diagnostic -keyalg RSA -keysize 2048 -validity 3650 -storetype PKCS12 -keystore $keystore -storepass:env RDX_DIAGNOSTIC_SIGNING_PASSWORD -keypass:env RDX_DIAGNOSTIC_SIGNING_PASSWORD -dname 'CN=Public Head Unit Diagnostic Test, O=Independent Research' *> "$build/keytool.log"
    Check-Exit 'create new diagnostic signing identity'
}
$apk=Join-Path $build 'headunit-diagnostics-0.1.0.apk'
& "$bin/java.exe" -jar "$tools/lib/apksigner.jar" sign --ks $keystore --ks-key-alias public-diagnostic --ks-pass env:RDX_DIAGNOSTIC_SIGNING_PASSWORD --min-sdk-version 21 --v1-signing-enabled true --v2-signing-enabled true --v3-signing-enabled false --out $apk "$build/aligned.apk" *> "$build/sign.log"
Check-Exit 'sign'
& "$bin/java.exe" -jar "$tools/lib/apksigner.jar" verify --min-sdk-version 21 --verbose --print-certs $apk *> "$build/signature.txt"
Check-Exit 'verify signature'
& "$tools/zipalign.exe" -c 4 $apk *> "$build/alignment.txt"
Check-Exit 'verify alignment'
$permissions=& "$tools/aapt.exe" dump permissions $apk
Check-Exit 'inspect permissions'
if(($permissions -join "`n") -match 'uses-permission'){throw 'Unexpected permission request in diagnostic APK.'}
$entries=@(& "$bin/jar.exe" tf $apk)
Check-Exit 'inspect APK entries'
$unexpected=@($entries | Where-Object {$_ -notmatch '^(AndroidManifest\.xml|classes\.dex|resources\.arsc|META-INF/[^/]*|META-INF/)$'})
if($unexpected.Count){throw 'Unexpected APK contents: only manifest, DEX, optional resource table and signing metadata are permitted.'}
$dexText=[Text.Encoding]::UTF8.GetString([IO.File]::ReadAllBytes((Join-Path $dex 'classes.dex')))
if($dexText -match 'PRIVATE KEY|private-test-material|libautoreceiver'){throw 'Unexpected sensitive/project-specific DEX marker.'}
foreach($entry in $sourceHashes){if((Get-FileHash -LiteralPath (Join-Path $PSScriptRoot $entry.path) -Algorithm SHA256).Hash -ne $entry.sha256){throw 'Source changed during build'}}
$report=[ordered]@{
    artifact='headunit-diagnostics-0.1.0.apk';package='org.rdxresearch.diagnostics';version='0.1.0';minSdk=21;targetSdk=22
    sha256=(Get-FileHash -LiteralPath $apk -Algorithm SHA256).Hash;bytes=(Get-Item -LiteralPath $apk).Length
    sourceHashes=$sourceHashes;apkEntries=$entries;permissions=@($permissions);signatureVerified=$true;alignmentVerified=$true
    nativeLibrariesIncluded=$false;assetsIncluded=$false;protocolCredentialsIncluded=$false;hardwareTested=$false
}
$report | ConvertTo-Json -Depth 6 | Set-Content "$build/build-report.json"
Write-Host "BUILT: $apk"
Write-Host "SHA256: $($report.sha256)"
Write-Host 'Signature/alignment/permission/entry checks passed. No device commands run; hardware behavior untested.'
