$ErrorActionPreference='Stop'
$project=(Resolve-Path './analysis/parallel-aa-receiver').Path
$javaHome='C:/Program Files/Eclipse Adoptium/jdk-17.0.20.101-hotspot'
$sdk='C:/Program Files (x86)/Android/android-sdk'
$tools="$sdk/build-tools/32.0.0"
$android="$sdk/platforms/android-33/android.jar"
foreach($part in 'build/classes','build/dex','build/empty-res','libs/armeabi-v7a','assets/private-test-material','signing'){
    [IO.Directory]::CreateDirectory((Join-Path $project $part))|Out-Null
}
function Check-Exit([string]$operation){if($LASTEXITCODE-ne0){throw "$operation failed (exit $LASTEXITCODE)"}}
# Credentials stay in a local binary APK asset; no key values appear in build logs/reports.
$source='./decompiled/AndroidAuto-current/sources/com/honda/androidauto/projection/sink/common/PlatformCertKeysImpl.java'
$text=Get-Content -LiteralPath $source -Raw
$creds=@(foreach($field in 'ROOT_CERTIFICATE','CLIENT_CERTIFICATE','PRIVATE_KEY'){
    $match=[regex]::Match($text,'\b'+$field+'\s*=\s*new String\(Base64.decode\("([^"\r\n]+)"\s*,\s*0\)\)')
    if(-not$match.Success){throw "Expected static credential initializer missing for $field; no build"}
    $encoded=$match.Groups[1].Value.Replace('\n',"`n").Replace('\r',"`r")
    ,[Convert]::FromBase64String($encoded)
})
$asset=[IO.File]::Create("$project/assets/private-test-material/platform.creds")
try{foreach($cred in $creds){$length=[BitConverter]::GetBytes([int]$cred.Length);[Array]::Reverse($length);$asset.Write($length,0,4);$asset.Write($cred,0,$cred.Length)}}finally{$asset.Dispose()}
$certRows=@(for($i=0;$i-lt2;$i++){
    $pem=[Text.Encoding]::UTF8.GetString($creds[$i])
    $der=[Convert]::FromBase64String(([regex]::Match($pem,'(?s)-----BEGIN CERTIFICATE-----(.*?)-----END CERTIFICATE-----').Groups[1].Value-replace'\s',''))
    $cert=[Security.Cryptography.X509Certificates.X509Certificate2]::new($der)
    try{[pscustomobject]@{role=if($i-eq0){'protocolRoot'}else{'protocolClient'};derSHA256=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($der));subject=$cert.Subject;notBeforeUtc=$cert.NotBefore.ToUniversalTime().ToString('o');notAfterUtc=$cert.NotAfter.ToUniversalTime().ToString('o')}}finally{$cert.Dispose()}
})
$key=[Security.Cryptography.RSA]::Create()
try{
    $keyPem=[Text.Encoding]::UTF8.GetString($creds[2]);$key.ImportFromPem($keyPem)
    $clientPem=[Text.Encoding]::UTF8.GetString($creds[1])
    $clientDer=[Convert]::FromBase64String(([regex]::Match($clientPem,'(?s)-----BEGIN CERTIFICATE-----(.*?)-----END CERTIFICATE-----').Groups[1].Value-replace'\s',''))
    $client=[Security.Cryptography.X509Certificates.X509Certificate2]::new($clientDer)
    $clientKey=[Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPublicKey($client)
    try{$keyMatches=[Convert]::ToHexString($key.ExportSubjectPublicKeyInfo())-eq[Convert]::ToHexString($clientKey.ExportSubjectPublicKeyInfo())}finally{$clientKey.Dispose();$client.Dispose()}
    if(-not$keyMatches){throw 'Platform protocol key does not match client certificate'}
}finally{$key.Dispose()}
[ordered]@{origin=$source;sourceSHA256=(Get-FileHash -LiteralPath $source).Hash;storage='Local binary asset used only for explicit GAL initialization; contains sensitive original protocol credential material. Do not publish APK/asset.';certificates=$certRows;clientKeyMatchesCertificate=$keyMatches;privateKeyContents='Not recorded';APKSigning='Separate newly generated development key';vehicleHardwareLookup='None in this static provider; phone acceptance not tested'}|ConvertTo-Json -Depth 5|Set-Content "$project/evidence/protocol-credential-metadata.json"
$native="$project/evidence/device/libautoreceiver_jni.so"
if((Get-FileHash -LiteralPath $native).Hash-ne'031797DD4B0AECCA007A3AD7AF31C365BA3D47BEBDA8C94BFF13C5289F464C50'){throw 'Unexpected current native library hash'}
Copy-Item -LiteralPath $native -Destination "$project/libs/armeabi-v7a/libautoreceiver_jni.so"
$sources=@(Get-ChildItem "$project/src" -Recurse -Filter '*.java'|ForEach-Object {$_.FullName})
& "$javaHome/bin/javac.exe" -encoding UTF-8 -source 7 -target 7 -bootclasspath $android -d "$project/build/classes" @sources *> "$project/build/javac.log"
Check-Exit 'javac'
& "$javaHome/bin/jar.exe" cf "$project/build/classes.jar" -C "$project/build/classes" .
Check-Exit 'jar'
& "$javaHome/bin/java.exe" -cp "$tools/lib/d8.jar" com.android.tools.r8.D8 --min-api 21 --lib $android --output "$project/build/dex" "$project/build/classes.jar" *> "$project/build/d8.log"
Check-Exit 'D8'
& "$tools/aapt.exe" package -f -M "$project/AndroidManifest.xml" -I $android -S "$project/build/empty-res" -A "$project/assets" -F "$project/build/base.apk" *> "$project/build/aapt.log"
Check-Exit 'aapt'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$unsigned="$project/build/parallel-aa-unsigned.apk"
Copy-Item -LiteralPath "$project/build/base.apk" -Destination $unsigned
$zip=[IO.Compression.ZipFile]::Open($unsigned,[IO.Compression.ZipArchiveMode]::Update)
try{
    [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip,"$project/build/dex/classes.dex",'classes.dex',[IO.Compression.CompressionLevel]::Optimal)|Out-Null
    [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip,"$project/libs/armeabi-v7a/libautoreceiver_jni.so",'lib/armeabi-v7a/libautoreceiver_jni.so',[IO.Compression.CompressionLevel]::Optimal)|Out-Null
}finally{$zip.Dispose()}
$aligned="$project/build/parallel-aa-aligned.apk"
& "$tools/zipalign.exe" -f 4 $unsigned $aligned *> "$project/build/zipalign.log"
Check-Exit 'zipalign'
$keystore="$project/signing/rdx-parallel-development.p12"
$password=$env:RDX_SIGNING_PASSWORD
if(-not(Test-Path -LiteralPath $keystore)){
    & "$javaHome/bin/keytool.exe" -genkeypair -alias rdx-parallel-development -keyalg RSA -keysize 2048 -validity 3650 -storetype PKCS12 -keystore $keystore -storepass $password -keypass $password -dname 'CN=RDX Parallel Receiver DEVELOPMENT ONLY, OU=Local research, O=RDX Test' *> "$project/build/keytool.log"
    Check-Exit 'keytool'
}
$signed="$project/build/rdx-parallel-aa-0.1.0-development.apk"
& "$javaHome/bin/java.exe" -jar "$tools/lib/apksigner.jar" sign --ks $keystore --ks-key-alias rdx-parallel-development --ks-pass "env:RDX_SIGNING_PASSWORD" --min-sdk-version 21 --v1-signing-enabled true --v2-signing-enabled true --v3-signing-enabled false --out $signed $aligned *> "$project/build/sign.log"
Check-Exit 'apksigner sign'
& "$javaHome/bin/java.exe" -jar "$tools/lib/apksigner.jar" verify --min-sdk-version 22 --max-sdk-version 22 --verbose --print-certs $signed *> "$project/build/signature-verification.txt"
Check-Exit 'API22 signature verify'
& "$tools/aapt.exe" dump badging $signed > "$project/build/badging.txt"
Check-Exit 'aapt badging'
$signerText=Get-Content "$project/build/signature-verification.txt" -Raw
$signer=[regex]::Match($signerText,'Signer #1 certificate SHA-256 digest: ([a-fA-F0-9]+)').Groups[1].Value
if($signer-eq'2156c50e3c08347f28adccb49ae839394053a45767f153bd8f036ae33d5f8568'){throw 'Unexpected OEM signer'}
[ordered]@{status='OFFLINE BUILD ONLY; NOT INSTALLED OR LAUNCHED; no runtime milestones demonstrated';package='com.rdx.fullscreen.projection';version='0.1.0-experimental-offline';minSdk=21;targetSdk=22;compileSdk=33;nativeABI='armeabi-v7a';sharedUserId=$null;requestedPermissions=@();developmentSignerSHA256=$signer;developmentKeyAlias='rdx-parallel-development';developmentKeystore='signing/rdx-parallel-development.p12';keystorePassword='Local TEST key only; see build script. Not an OEM key.';output='build/rdx-parallel-aa-0.1.0-development.apk';outputBytes=(Get-Item -LiteralPath $signed).Length;outputSHA256=(Get-FileHash -LiteralPath $signed).Hash;dexSHA256=(Get-FileHash "$project/build/dex/classes.dex").Hash;nativeSHA256=(Get-FileHash "$project/libs/armeabi-v7a/libautoreceiver_jni.so").Hash;candidate=@{activeWidth=1920;activeHeight=720;dpi=229;fps=60;codecResolutionEnum=3;widthMargin=0;heightMargin=360;configIndex=0;fallback='800x430 / 143dpi / 60fps, index1'};credentials='Sensitive original protocol material bundled for same-unit local research; not printed in reports; distinct from APK signer';noAutoStart=$true;noUsbModeSwitch=$true;noForcedClaim=$true;noResetSocket=$true;noHondaBinderCalls=$true;noSettingsOrPropertyWrites=$true;vehicleOperations='None performed by this build script'}|ConvertTo-Json -Depth 6|Set-Content "$project/build/build-report.json"
Get-Content "$project/build/build-report.json"
