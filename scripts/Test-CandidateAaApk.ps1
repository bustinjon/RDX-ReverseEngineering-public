<#
.SYNOPSIS
Offline compatibility triage of a candidate Honda Android Auto APK (e.g. a 2022+ F-series receiver)
against this project's stock D.1.6.4 receiver and the saved framework/Honda jars.

.DESCRIPTION
READ-ONLY and HOST-ONLY: never runs adb, never touches the car or phone, never installs anything,
never modifies the candidate. It can only say "no blocker found yet" or list blockers; passing it
does NOT authorize any installation (that needs its own review and explicit user approval).

Checks: sha256; API22-aware signer vs stock signer; package/versionCode/SDK levels/sharedUserId;
new permissions; Honda (com.honda.*) and android.* classes the candidate references that neither it
nor this unit's framework/Honda jars define; native library ELF type and hash vs stock.

.PARAMETER CandidateApk   The candidate APK (do not run it; this only reads it).
.PARAMETER CandidateLibDir Optional folder holding the candidate's native libs (libautoreceiver_jni.so ...).
.PARAMETER OutputJson     Optional path for a machine-readable report.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$CandidateApk,
    [string]$CandidateLibDir,
    [string]$StockApk = 'apks\AndroidAuto-current-2026-10-22.apk',
    [string]$StockLib = 'adb\AndroidAuto-system\lib\arm\libautoreceiver_jni.so',
    [string]$FrameworkDir = 'adb\RDX-Audit\full-system\framework',
    [string]$OutputJson
)
$ErrorActionPreference = 'Stop'
$root = 'C:/Users/REDACTED\Desktop\RDX-ReverseEngineering'
Set-Location $root
$bt = 'C:\Program Files (x86)\Android\android-sdk\build-tools\32.0.0'
$java = 'C:/Program Files/Eclipse Adoptium/jdk-17.0.20.101-hotspot/bin/java.exe'
foreach ($p in $bt, $java) { if (-not (Test-Path $p)) { throw "Missing tool path: $p" } }
$CandidateApk = (Resolve-Path -LiteralPath $CandidateApk).Path
$StockApk = (Resolve-Path -LiteralPath $StockApk).Path
Add-Type -AssemblyName System.IO.Compression.FileSystem

$results = New-Object System.Collections.Generic.List[object]
function Add-Check([string]$Name, [ValidateSet('PASS', 'WARN', 'FAIL', 'INFO')][string]$Status, [string]$Detail) {
    $results.Add([pscustomobject]@{ Check = $Name; Status = $Status; Detail = $Detail })
}

function Get-ApkSigner([string]$apk) {
    $out = & $java -jar "$bt/lib/apksigner.jar" verify --verbose --print-certs --min-sdk-version 22 --max-sdk-version 22 $apk 2>&1 | Out-String
    [pscustomobject]@{
        Verifies = ($out -match '(?m)^Verifies')
        V1       = ($out -match 'v1 scheme \(JAR signing\): true')
        Signers  = @([regex]::Matches($out, 'Signer #\d+ certificate SHA-256 digest: ([0-9a-f]{64})') | ForEach-Object { $_.Groups[1].Value.ToUpper() })
        Raw      = $out.Trim().Substring(0, [Math]::Min(400, $out.Trim().Length))
    }
}
function Get-ApkInfo([string]$apk) {
    $b = & "$bt\aapt.exe" dump badging $apk 2>&1 | Out-String
    $x = & "$bt\aapt.exe" dump xmltree $apk AndroidManifest.xml 2>&1 | Out-String
    $pkg = [regex]::Match($b, "package: name='([^']+)' versionCode='(\d+)' versionName='([^']*)'")
    [pscustomobject]@{
        Package = $pkg.Groups[1].Value; VersionCode = [int]$pkg.Groups[2].Value; VersionName = $pkg.Groups[3].Value
        MinSdk = [regex]::Match($b, "sdkVersion:'(\d+)'").Groups[1].Value
        TargetSdk = [regex]::Match($b, "targetSdkVersion:'(\d+)'").Groups[1].Value
        SharedUid = [regex]::Match($x, 'sharedUserId\(0x[0-9a-f]+\)="([^"]+)"').Groups[1].Value
        Permissions = @([regex]::Matches($b, "uses-permission: name='([^']+)'") | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
        NativeCode = [regex]::Match($b, "native-code: (.*)").Groups[1].Value.Trim()
    }
}
function Get-DefinedClasses([string]$file) {
    $set = New-Object 'System.Collections.Generic.HashSet[string]'
    & "$bt\dexdump.exe" $file 2>$null | ForEach-Object { if ($_ -match "Class descriptor\s+:\s+'([^']+)'") { [void]$set.Add($Matches[1]) } }
    , $set
}
function Get-ReferencedDescriptors([string]$apk) {
    $set = New-Object 'System.Collections.Generic.HashSet[string]'
    $z = [IO.Compression.ZipFile]::OpenRead($apk)
    try {
        foreach ($e in ($z.Entries | Where-Object { $_.FullName -match '^classes\d*\.dex$' })) {
            $ms = New-Object IO.MemoryStream; $s = $e.Open(); $s.CopyTo($ms); $s.Dispose()
            $text = [Text.Encoding]::Latin1.GetString($ms.ToArray())
            foreach ($m in [regex]::Matches($text, 'L(?:com/honda|android)/[A-Za-z0-9_/$]*;')) { [void]$set.Add($m.Value) }
        }
    } finally { $z.Dispose() }
    , $set
}

# ---- 1. identity ----
$cHash = (Get-FileHash -LiteralPath $CandidateApk -Algorithm SHA256).Hash
Add-Check 'Candidate file' INFO ("{0}  {1:N0} bytes  sha256 {2}" -f (Split-Path $CandidateApk -Leaf), (Get-Item $CandidateApk).Length, $cHash)

# ---- 2. signing ----
$ss = Get-ApkSigner $StockApk; $cs = Get-ApkSigner $CandidateApk
if (-not $cs.Verifies) { Add-Check 'Candidate signature verifies (API22 rules)' FAIL $cs.Raw }
else { Add-Check 'Candidate signature verifies (API22 rules)' PASS ("v1 JAR signing: {0}" -f $cs.V1) }
if ($cs.Signers.Count -eq 0 -or $ss.Signers.Count -eq 0) { Add-Check 'Signer matches stock' FAIL 'Could not read a signer certificate digest' }
elseif (@($cs.Signers | Where-Object { $ss.Signers -contains $_ }).Count -eq $cs.Signers.Count -and $cs.Signers.Count -eq $ss.Signers.Count) { Add-Check 'Signer matches stock' PASS ("stock/candidate signer sha256 {0}" -f $ss.Signers[0]) }
else { Add-Check 'Signer matches stock' FAIL ("stock {0} vs candidate {1}: a shared-UID system app update will be rejected by Android" -f ($ss.Signers -join ','), ($cs.Signers -join ',')) }

# ---- 3. manifest ----
$si = Get-ApkInfo $StockApk; $ci = Get-ApkInfo $CandidateApk
Add-Check 'Package name' $(if ($ci.Package -eq $si.Package) { 'PASS' } else { 'FAIL' }) ("stock {0} / candidate {1}" -f $si.Package, $ci.Package)
$vc = if ($ci.VersionCode -gt $si.VersionCode) { 'PASS' } elseif ($ci.VersionCode -eq $si.VersionCode) { 'WARN' } else { 'FAIL' }
Add-Check 'versionCode vs stock' $vc ("stock {0} ({1}) / candidate {2} ({3}); lower is rejected as a downgrade on a production build" -f $si.VersionCode, $si.VersionName, $ci.VersionCode, $ci.VersionName)
Add-Check 'sharedUserId' $(if ($ci.SharedUid -eq $si.SharedUid -and $ci.SharedUid) { 'PASS' } else { 'FAIL' }) ("stock '{0}' / candidate '{1}'" -f $si.SharedUid, $ci.SharedUid)
Add-Check 'SDK levels' $(if ([int]$ci.TargetSdk -le 22 -and [int]$ci.MinSdk -le 22) { 'PASS' } else { 'WARN' }) ("stock min {0}/target {1}; candidate min {2}/target {3}; unit is API 22" -f $si.MinSdk, $si.TargetSdk, $ci.MinSdk, $ci.TargetSdk)
$newPerms = @($ci.Permissions | Where-Object { $si.Permissions -notcontains $_ })
Add-Check 'New permissions' $(if ($newPerms.Count -eq 0) { 'PASS' } else { 'WARN' }) $(if ($newPerms.Count -eq 0) { 'none' } else { $newPerms -join ', ' })

# ---- 4. class dependencies ----
$cacheDir = Join-Path $env:LOCALAPPDATA 'RdxClaude'; New-Item -ItemType Directory -Force $cacheDir | Out-Null
$idx = Join-Path $cacheDir 'unit-class-index.txt'
if (-not (Test-Path $idx)) {
    $all = New-Object 'System.Collections.Generic.HashSet[string]'
    $emptyJars = 0
    foreach ($j in Get-ChildItem -LiteralPath $FrameworkDir -File -Filter *.jar) {
        $d = Get-DefinedClasses $j.FullName; if ($d.Count -eq 0) { $emptyJars++ }; foreach ($c in $d) { [void]$all.Add($c) }
    }
    foreach ($c in (Get-DefinedClasses $StockApk)) { [void]$all.Add($c) }
    $all | Sort-Object | Set-Content $idx
    Add-Check 'Unit class index built' INFO ("{0} classes from {1}; {2} jars had no readable dex (odex-only)" -f $all.Count, $FrameworkDir, $emptyJars)
}
$unit = New-Object 'System.Collections.Generic.HashSet[string]'; Get-Content $idx | ForEach-Object { [void]$unit.Add($_) }
$candDefined = Get-DefinedClasses $CandidateApk
$refs = Get-ReferencedDescriptors $CandidateApk
$missing = @($refs | Where-Object { -not $candDefined.Contains($_) -and -not $unit.Contains($_) } | Sort-Object)
$missHonda = @($missing | Where-Object { $_ -like 'Lcom/honda/*' }); $missAndroid = @($missing | Where-Object { $_ -like 'Landroid/*' })
Add-Check 'Honda classes referenced but absent on this unit' $(if ($missHonda.Count -eq 0) { 'PASS' } else { 'FAIL' }) $(if ($missHonda.Count -eq 0) { 'none' } else { ("{0}: {1}" -f $missHonda.Count, (($missHonda | Select-Object -First 25) -join ' ')) })
Add-Check 'android.* classes referenced but absent on this unit' $(if ($missAndroid.Count -eq 0) { 'PASS' } else { 'WARN' }) $(if ($missAndroid.Count -eq 0) { 'none' } else { ("{0} (newer SDK APIs?): {1}" -f $missAndroid.Count, (($missAndroid | Select-Object -First 25) -join ' ')) })
Add-Check 'Candidate defined classes' INFO ("{0} (stock defines {1})" -f $candDefined.Count, (Get-DefinedClasses $StockApk).Count)

# ---- 5. native library ----
function Test-ElfArm32([string]$path) { $b = [IO.File]::ReadAllBytes($path); ($b.Length -gt 20) -and $b[0] -eq 0x7f -and $b[1] -eq 0x45 -and $b[4] -eq 1 -and $b[18] -eq 0x28 }
$stockLibHash = if (Test-Path $StockLib) { (Get-FileHash $StockLib -Algorithm SHA256).Hash } else { $null }
$libs = @()
if ($CandidateLibDir) { $libs = @(Get-ChildItem -LiteralPath $CandidateLibDir -Recurse -File -Filter *.so -ErrorAction SilentlyContinue) }
else {
    $z = [IO.Compression.ZipFile]::OpenRead($CandidateApk); $inApk = @($z.Entries | Where-Object { $_.FullName -like 'lib/*.so' } | ForEach-Object { $_.FullName }); $z.Dispose()
    if ($inApk.Count) { Add-Check 'Native libs inside APK' INFO ($inApk -join ', ') }
}
if ($libs.Count -eq 0 -and -not $inApk.Count) {
    Add-Check 'Native library delivery' WARN ('The candidate APK contains no lib/*.so and no -CandidateLibDir was given. The stock APK also has none (Honda keeps libautoreceiver_jni.so beside it under /system), but `pm install` only delivers what is INSIDE the APK: an APK-only update moves the package to /data/app with an empty lib folder, so System.loadLibrary("autoreceiver_jni") may fail (UnsatisfiedLinkError) even for identical stock bytes. See CODEX-AA-UPDATE-PATH-ANALYSIS.md Q5/Q6.')
}
elseif ($libs.Count -eq 0) { Add-Check 'Native library supplied' WARN 'Libraries are inside the APK but were not compared (no -CandidateLibDir given).' }
foreach ($l in $libs) {
    $arm = Test-ElfArm32 $l.FullName; $h = (Get-FileHash $l.FullName -Algorithm SHA256).Hash
    Add-Check ("Native lib {0}" -f $l.Name) $(if (-not $arm) { 'FAIL' } elseif ($l.Name -eq 'libautoreceiver_jni.so' -and $h -ne $stockLibHash) { 'WARN' } else { 'PASS' }) ("{0:N0} bytes sha256 {1}; ELF32-ARM: {2}{3}" -f $l.Length, $h, $arm, $(if ($l.Name -eq 'libautoreceiver_jni.so') { if ($h -eq $stockLibHash) { '; IDENTICAL to stock' } else { '; DIFFERS from stock (expected for a newer build; needs JNI-signature review)' } } else { '' }))
}

# ---- report ----
$fails = @($results | Where-Object Status -eq 'FAIL').Count; $warns = @($results | Where-Object Status -eq 'WARN').Count
$results | ForEach-Object { '{0,-5} {1,-52} {2}' -f $_.Status, $_.Check, $_.Detail }
''
if ($fails) { "RESULT: $fails blocker(s), $warns warning(s). Do NOT consider installing this candidate." }
else { "RESULT: no static blocker found ($warns warning(s)). This is triage only: it does NOT authorize installation; run a separate review with Claude/Codex and get explicit user approval." }
if ($OutputJson) { [ordered]@{ candidate = $CandidateApk; sha256 = $cHash; blockers = $fails; warnings = $warns; checks = $results } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $OutputJson -Encoding utf8 }
