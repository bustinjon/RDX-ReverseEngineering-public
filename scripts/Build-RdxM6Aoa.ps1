param()
$ErrorActionPreference='Stop';$root=Split-Path $PSScriptRoot -Parent;$base="$root/analysis/parallel-aa-receiver";$p="$base/m6-aoa";$java='C:/Program Files/Eclipse Adoptium/jdk-17.0.20.101-hotspot/bin';$bt='C:/Program Files (x86)/Android/android-sdk/build-tools/32.0.0';$android='C:/Program Files (x86)/Android/android-sdk/platforms/android-33/android.jar'
if((Get-Content "$p/source/com/rdx/fullscreen/m6aoa/LiveExecutionPolicy.java" -Raw)-notmatch'EXECUTION_ENABLED=false;'){throw 'Only live-disabled M6 builds are authorized by this build script'}
$b=Join-Path $p ('build/'+(Get-Date -Format yyyyMMdd-HHmmss-fff));foreach($d in @($b,"$b/classes","$b/host","$b/dex","$b/res")){New-Item -ItemType Directory -Path $d|Out-Null}
function Check([string]$name){if($LASTEXITCODE-ne0){throw "$name failed; inspect $b"}}
$src=@(Get-ChildItem "$p/source" -Recurse -Filter *.java|ForEach-Object FullName);$pure=@($src|Where-Object {[IO.Path]::GetFileName($_)-notin@('AndroidAoaAdapter.java','M6AoaService.java')});$tests=@(Get-ChildItem "$p/tests" -Recurse -Filter *.java|ForEach-Object FullName);$hostSources=@(Get-ChildItem "$p/host" -File -Filter *.java|ForEach-Object FullName)
& "$java/javac.exe" -encoding UTF-8 -source 7 -target 7 -bootclasspath $android -d "$b/classes" @src *> "$b/javac.log";Check Java7
& "$java/javac.exe" -encoding UTF-8 -source 7 -target 7 -d "$b/host" @pure @tests @hostSources *> "$b/host-javac.log";Check 'Host core tests'
& "$java/java.exe" -Xmx192m -cp "$b/host" com.rdx.fullscreen.m6aoa.M6Tests "$p/fixtures" "$b/transcripts" *> "$b/test-results.txt";Check 'M6 host simulation'
& "$java/java.exe" -cp "$b/host" M6EvidenceTool "$b/transcripts/evidence.journal" "$b/transcripts/evidence.summary" "$b/evidence-oracle.json" *> "$b/evidence-oracle.txt";Check 'Independent evidence accounting'
if((Get-Content "$b/evidence-oracle.json" -Raw|ConvertFrom-Json).verdict-ne'SYNTHETIC_PASS_NOT_LIVE_M6'){throw 'Independent evidence oracle did not preserve synthetic scope'}
& "$java/jar.exe" cf "$b/classes.jar" -C "$b/classes" .;Check JAR
& "$java/java.exe" -cp "$bt/lib/d8.jar" com.android.tools.r8.D8 --min-api 22 --lib $android --output "$b/dex" "$b/classes.jar" *> "$b/d8.log";Check D8min22
& "$bt/aapt.exe" package -f -M "$p/AndroidManifest.xml" -I $android -S "$b/res" -A "$p/assets" -F "$b/base.apk" *> "$b/aapt.log";Check aapt
Add-Type -AssemblyName System.IO.Compression.FileSystem
Copy-Item "$b/base.apk" "$b/unsigned.apk";$z=[IO.Compression.ZipFile]::Open("$b/unsigned.apk",[IO.Compression.ZipArchiveMode]::Update);try{[void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($z,"$b/dex/classes.dex",'classes.dex',[IO.Compression.CompressionLevel]::Optimal)}finally{$z.Dispose()}
& "$bt/zipalign.exe" -f 4 "$b/unsigned.apk" "$b/aligned.apk";Check Alignment
$apk="$b/rdx-m6-aoa-only-disabled.apk"
& "$java/java.exe" -jar "$bt/lib/apksigner.jar" sign --ks "$base/signing/rdx-parallel-development.p12" --ks-key-alias rdx-parallel-development --ks-pass env:RDX_SIGNING_PASSWORD --min-sdk-version 22 --v1-signing-enabled true --v2-signing-enabled true --v3-signing-enabled false --out $apk "$b/aligned.apk" *> "$b/sign.log";Check Signing
& "$java/java.exe" -jar "$bt/lib/apksigner.jar" verify --min-sdk-version 22 --max-sdk-version 22 --verbose --print-certs $apk *> "$b/signature.txt";Check Signature
& "$bt/zipalign.exe" -c 4 $apk;Check AlignmentVerify
& "$bt/aapt.exe" dump badging $apk > "$b/badging.txt";Check Badging
& "$bt/aapt.exe" dump xmltree $apk AndroidManifest.xml > "$b/manifest-tree.txt";Check Manifest
& "$bt/dexdump.exe" -d "$b/dex/classes.dex" > "$b/dexdump.txt";Check Dexdump
[ordered]@{apk=$apk;sha256=(Get-FileHash $apk).Hash;DEX=(Get-FileHash "$b/dex/classes.dex").Hash;package='com.rdx.fullscreen.m6aoa';version='0.1.0-m6-aoa-only-frozen';minSdk=22;targetSdk=22;liveExecutionEnabled=$false;modules=$src.Count;sourceHashes=@(Get-FileHash -LiteralPath $src);testHashes=@(Get-FileHash -LiteralPath ($tests+$hostSources));fixtureHashes=@(Get-ChildItem "$p/fixtures" -File|Get-FileHash);assetHashes=@(Get-ChildItem "$p/assets" -File|Get-FileHash);testResult=(Get-Content "$b/test-results.txt" -Tail 1);noHardware=$true}|ConvertTo-Json -Depth 6|Set-Content "$b/build-report.json"
& "$root/tools/m6/Test-M6StaticPolicy.ps1" -Build $b > "$b/static-audit-log.txt"
Set-Content "$p/latest-build.txt" $b;Get-Content "$b/test-results.txt" -Tail 1;Write-Output "M6 disabled build: $b"
