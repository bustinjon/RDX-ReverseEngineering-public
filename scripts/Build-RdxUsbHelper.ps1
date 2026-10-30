## Build USB Helper APK — combines usb-helper/source/ + src/ (helper takes precedence on dupes)
## Package: com.rdx.fullscreen.usbhelper
## Usage: .\scripts\Build-RdxUsbHelper.ps1 [-Version "v6h"]
param([string]$Version)

$ErrorActionPreference = 'Stop'
$project = (Resolve-Path './analysis/parallel-aa-receiver').Path
$javaHome = 'C:/Program Files/Eclipse Adoptium/jdk-17.0.20.101-hotspot'
$sdk = 'C:/Program Files (x86)/Android/android-sdk'
$tools = "$sdk/build-tools/32.0.0"
$android = "$sdk/platforms/android-33/android.jar"

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
$buildDir = "$project/usb-helper/build/$timestamp"
foreach ($part in "$buildDir/classes", "$buildDir/dex", "$project/libs/armeabi-v7a",
         "$project/assets/private-test-material", "$project/signing") {
    [IO.Directory]::CreateDirectory($part) | Out-Null
}

function Check-Exit([string]$operation) {
    if ($LASTEXITCODE -ne 0) { throw "$operation failed (exit $LASTEXITCODE)" }
}

Write-Host "=== USB Helper Build ===" -ForegroundColor Cyan

# --- Credentials (same as receiver build) ---
$source = './decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/common/PlatformCertKeysImpl.java'
$text = Get-Content -LiteralPath $source -Raw
$creds = @(foreach ($field in 'ROOT_CERTIFICATE', 'CLIENT_CERTIFICATE', 'PRIVATE_KEY') {
    $match = [regex]::Match($text, '\b' + $field + '\s*=\s*new String\(Base64.decode\("([^"\r\n]+)"\s*,\s*0\)\)')
    if (-not $match.Success) { throw "Credential field $field not found" }
    $encoded = $match.Groups[1].Value.Replace('\n', "`n").Replace('\r', "`r")
    , [Convert]::FromBase64String($encoded)
})
$asset = [IO.File]::Create("$project/assets/private-test-material/platform.creds")
try {
    foreach ($cred in $creds) {
        $length = [BitConverter]::GetBytes([int]$cred.Length)
        [Array]::Reverse($length)
        $asset.Write($length, 0, 4)
        $asset.Write($cred, 0, $cred.Length)
    }
} finally { $asset.Dispose() }
Write-Host "  Credentials packed" -ForegroundColor Green

# --- Native library ---
$native = "$project/evidence/device/libautoreceiver_jni.so"
$nativeHash = (Get-FileHash -LiteralPath $native).Hash
if ($nativeHash -ne '031797DD4B0AECCA007A3AD7AF31C365BA3D47BEBDA8C94BFF13C5289F464C50') {
    throw "Unexpected native library hash: $nativeHash"
}
Copy-Item -LiteralPath $native -Destination "$project/libs/armeabi-v7a/libautoreceiver_jni.so"
Write-Host "  Native lib copied" -ForegroundColor Green

# --- Gather sources: usb-helper/source/ takes precedence over src/ ---
$helperSources = @(Get-ChildItem "$project/usb-helper/source" -Recurse -Filter '*.java' |
    ForEach-Object { $_.FullName })
$helperNames = @(Get-ChildItem "$project/usb-helper/source" -Recurse -Filter '*.java' |
    ForEach-Object { $_.Name })
$sharedSources = @(Get-ChildItem "$project/src" -Recurse -Filter '*.java' |
    Where-Object { $helperNames -notcontains $_.Name } |
    ForEach-Object { $_.FullName })
$allSources = $helperSources + $sharedSources
$sourceHashes = @($allSources | ForEach-Object { Get-FileHash -LiteralPath $_ -Algorithm SHA256 })
Write-Host "  Sources: $($helperSources.Count) helper + $($sharedSources.Count) shared = $($allSources.Count) total" -ForegroundColor Green

# --- Compile ---
& "$javaHome/bin/javac.exe" -encoding UTF-8 -source 7 -target 7 `
    -bootclasspath $android -d "$buildDir/classes" @allSources *> "$buildDir/javac.log"
Check-Exit 'javac'
Write-Host "  Compiled" -ForegroundColor Green

# --- DEX ---
& "$javaHome/bin/jar.exe" cf "$buildDir/classes.jar" -C "$buildDir/classes" .
Check-Exit 'jar'
& "$javaHome/bin/java.exe" -cp "$tools/lib/d8.jar" com.android.tools.r8.D8 `
    --min-api 21 --lib $android --output "$buildDir/dex" "$buildDir/classes.jar" *> "$buildDir/d8.log"
Check-Exit 'D8'
Write-Host "  DEXed" -ForegroundColor Green

# --- Package (uses usb-helper manifest + resources) ---
& "$tools/aapt.exe" package -f `
    -M "$project/usb-helper/AndroidManifest.xml" `
    -I $android `
    -S "$project/usb-helper/res" `
    -A "$project/assets" `
    -F "$buildDir/base.apk" *> "$buildDir/aapt.log"
Check-Exit 'aapt'

# --- Assemble APK ---
Add-Type -AssemblyName System.IO.Compression.FileSystem
$unsigned = "$buildDir/unsigned.apk"
Copy-Item -LiteralPath "$buildDir/base.apk" -Destination $unsigned
$zip = [IO.Compression.ZipFile]::Open($unsigned, [IO.Compression.ZipArchiveMode]::Update)
try {
    [IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
        $zip, "$buildDir/dex/classes.dex", 'classes.dex',
        [IO.Compression.CompressionLevel]::Optimal) | Out-Null
    [IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
        $zip, "$project/libs/armeabi-v7a/libautoreceiver_jni.so",
        'lib/armeabi-v7a/libautoreceiver_jni.so',
        [IO.Compression.CompressionLevel]::Optimal) | Out-Null
} finally { $zip.Dispose() }

# --- Align ---
$aligned = "$buildDir/aligned.apk"
& "$tools/zipalign.exe" -f 4 $unsigned $aligned *> "$buildDir/zipalign.log"
Check-Exit 'zipalign'

# --- Sign ---
$keystore = "$project/signing/rdx-parallel-development.p12"
$password = $env:RDX_SIGNING_PASSWORD
if (-not $password) { throw "Set RDX_SIGNING_PASSWORD to a new local signing password before building." }
if (-not (Test-Path -LiteralPath $keystore)) {
    & "$javaHome/bin/keytool.exe" -genkeypair -alias rdx-parallel-development `
        -keyalg RSA -keysize 2048 -validity 3650 -storetype PKCS12 `
        -keystore $keystore -storepass $password -keypass $password `
        -dname 'CN=RDX Parallel Receiver DEVELOPMENT ONLY, OU=Local research, O=RDX Test' `
        *> "$buildDir/keytool.log"
    Check-Exit 'keytool'
}

$apkName = if ($Version) { "rdx-usb-helper-$Version.apk" } else {
    "rdx-usb-helper-0.1.0-usb-helper-development.apk"
}
$signed = "$buildDir/$apkName"
& "$javaHome/bin/java.exe" -jar "$tools/lib/apksigner.jar" sign `
    --ks $keystore --ks-key-alias rdx-parallel-development `
    --ks-pass "env:RDX_SIGNING_PASSWORD" --min-sdk-version 21 `
    --v1-signing-enabled true --v2-signing-enabled true --v3-signing-enabled false `
    --out $signed $aligned *> "$buildDir/sign.log"
Check-Exit 'apksigner sign'

# --- Verify ---
& "$javaHome/bin/java.exe" -jar "$tools/lib/apksigner.jar" verify `
    --min-sdk-version 22 --max-sdk-version 22 --verbose --print-certs $signed `
    *> "$buildDir/signature-verification.txt"
Check-Exit 'API22 signature verify'
& "$tools/zipalign.exe" -c 4 $signed *> "$buildDir/alignment-verification.txt"
Check-Exit 'signed APK alignment verify'

# --- Report ---
$apkInfo = Get-Item -LiteralPath $signed
$apkHash = (Get-FileHash -LiteralPath $signed).Hash
foreach ($inputHash in $sourceHashes) {
    if ((Get-FileHash -LiteralPath $inputHash.Path -Algorithm SHA256).Hash -ne $inputHash.Hash) {
        throw 'Java input changed during build; candidate provenance rejected'
    }
}
[ordered]@{
    harness = 'usb-helper'
    version = '0.1.0-usb-helper'
    versionCode = '1'
    candidateLabel = $Version
    utc = [DateTime]::UtcNow.ToString('o')
    apk = $signed
    sha256 = $apkHash
    build = $buildDir
    minSdk = 21
    targetSdk = 22
    signatureVerifiedAPI22 = $true
    alignmentVerified = $true
    staticAudit = 'PENDING'
    sourceHashes = $sourceHashes
    manifestSHA256 = (Get-FileHash -LiteralPath "$project/usb-helper/AndroidManifest.xml").Hash
    nativeSHA256 = $nativeHash
    provenanceScope = 'Recorded Java inputs, manifest and native library; not a complete reproducible-build audit'
} | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath "$buildDir/build-report.json" -Encoding utf8
"$buildDir" | Set-Content "$project/usb-helper/latest-build.txt"

Write-Host "`n=== BUILD COMPLETE ===" -ForegroundColor Green
Write-Host "  APK: $signed"
Write-Host "  Size: $($apkInfo.Length) bytes"
Write-Host "  SHA256: $apkHash"
Write-Host "  Sources: $($allSources.Count) Java files"
Write-Host "  latest-build.txt updated"
