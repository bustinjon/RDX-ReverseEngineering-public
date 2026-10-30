$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$outputDirectory='./logs/2026-10-22-investigation'
$pairs=[ordered]@{
    AndroidAuto=@('./apks/AndroidAuto-current-2026-10-22.apk','./adb/AndroidAuto-system/AndroidAuto.apk')
    HondaDiagnostics=@('./apks/HondaDiagnostics-current.apk','./adb/HondaDiagnostics.apk')
    HondaSettings=@('./apks/HondaSettings-current.apk','./adb/HondaSettings.apk')
    HondaManager=@('./apks/honda-manager-current.jar','./adb/RDX-Dump/honda-manager.jar')
    Services=@('./apks/services-current.jar','./adb/RDX-Audit/framework/services.jar')
    Framework=@('./apks/framework-current.jar','./adb/RDX-Audit/framework/framework.jar')
}
$hashes=foreach ($pair in $pairs.GetEnumerator()) {
    foreach ($path in $pair.Value) {
        $archive=[IO.Compression.ZipFile]::OpenRead((Resolve-Path -LiteralPath $path))
        try {
            foreach ($entry in $archive.Entries) {
                if ($entry.FullName -match '^classes[0-9]*\.dex$|^AndroidManifest\.xml$') {
                    $stream=$entry.Open()
                    try { $hash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($stream)) } finally { $stream.Dispose() }
                    [pscustomobject]@{component=$pair.Key; file=$path; entry=$entry.FullName; bytes=$entry.Length; sha256=$hash}
                }
            }
        } finally { $archive.Dispose() }
    }
}
$hashes | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $outputDirectory 'archive-entry-hashes.json')
$needles=@('screen_width','screen_height','screen_dpi','scale_checkbox','WIRELESS_PROJECTED_ENABLED','com.honda.androidauto.projection.sink')
$paths=@(Get-ChildItem -LiteralPath './adb/RDX-Audit/full-system/framework','./adb/RDX-Audit/full-system/priv-app','./apks' -Recurse -File | Where-Object { $_.Extension -in '.apk','.jar' })
$scanErrors=[Collections.Generic.List[object]]::new()
$matches=foreach ($path in $paths) {
    try { $archive=[IO.Compression.ZipFile]::OpenRead($path.FullName) }
    catch { $scanErrors.Add([pscustomobject]@{file=$path.FullName; error=$_.Exception.Message}); continue }
    try {
        foreach ($entry in $archive.Entries) {
            if ($entry.FullName -notmatch '^classes[0-9]*\.dex$') { continue }
            $stream=$entry.Open(); $memory=[IO.MemoryStream]::new()
            try { $stream.CopyTo($memory); $dexText=[Text.Encoding]::Latin1.GetString($memory.ToArray()) } finally { $memory.Dispose(); $stream.Dispose() }
            $found=@($needles | Where-Object { $dexText.Contains($_,[StringComparison]::Ordinal) })
            if ($found.Count -gt 0) { [pscustomobject]@{file=$path.FullName; entry=$entry.FullName; strings=$found} }
        }
    } finally { $archive.Dispose() }
}
$matches | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $outputDirectory 'cross-archive-string-hits.json')
$scanErrors | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $outputDirectory 'archive-scan-errors.json')
Write-Output "Scanned $($paths.Count) local APK/JAR archives ($($scanErrors.Count) unreadable); hashes and cross-archive string hits saved."
$matches | ForEach-Object { Write-Output "$($_.file): $($_.strings -join ', ')" }
