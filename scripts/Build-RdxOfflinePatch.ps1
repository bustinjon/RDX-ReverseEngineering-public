param([ValidateSet(229,240)][int]$PrimaryDpi=229,[string]$OutputDirectory='./analysis/fullscreen-candidate')
$ErrorActionPreference='Stop'
Add-Type -Path './scripts/RdxDex.cs'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$inputApk=(Resolve-Path -LiteralPath './apks/AndroidAuto-current-2026-10-22.apk').Path
$outputDirectory=[IO.Path]::GetFullPath($OutputDirectory)
[IO.Directory]::CreateDirectory($outputDirectory) | Out-Null
$inputArchive=[IO.Compression.ZipFile]::OpenRead($inputApk)
try {
    $dexStream=$inputArchive.GetEntry('classes.dex').Open();$memory=[IO.MemoryStream]::new()
    try {$dexStream.CopyTo($memory);$originalBytes=$memory.ToArray()} finally {$memory.Dispose();$dexStream.Dispose()}
    $originalHash=[RdxOffline.Dex]::HexHash($originalBytes)
    if($originalHash -ne '2F7FE2CF2C494509326804F3D79F9FBF75D3C7F3AF87659C7D6B971D54605DD4'){throw 'Current APK DEX hash does not match audited input.'}
    $originalDex=[RdxOffline.Dex]::new($originalBytes)
    if(-not $originalDex.CheckHeaderHashes()){throw 'Original DEX checksum/signature invalid.'}
    $method=$originalDex.PresenterMethod()
    $patchedBytes=[byte[]]$originalBytes.Clone()
    $patchedDex=[RdxOffline.Dex]::new($patchedBytes)
    $patches=$patchedDex.PatchPrimary(1920,720,$PrimaryDpi)
    $reparsed=[RdxOffline.Dex]::new($patchedBytes)
    if(-not $reparsed.CheckHeaderHashes()){throw 'Patched DEX header hashes invalid.'}
    $methodAfter=$reparsed.PresenterMethod()
    if($methodAfter.CodeOffset -ne $method.CodeOffset -or $methodAfter.InstructionUnits -ne $method.InstructionUnits){throw 'Unexpected relocation.'}
    $allowed=[Collections.Generic.HashSet[int]]::new()
    foreach($patch in $patches){$allowed.Add($patch.LiteralByteOffset)|Out-Null;$allowed.Add($patch.LiteralByteOffset+1)|Out-Null}
    $changedOffsets=[Collections.Generic.List[int]]::new()
    for($index=0;$index -lt $originalBytes.Length;$index++){
        if($originalBytes[$index] -ne $patchedBytes[$index]){
            if($index -notin 8..31 -and -not $allowed.Contains($index)){throw "Unexpected byte change at $index"}
            $changedOffsets.Add($index)
        }
    }
    [IO.File]::WriteAllBytes((Join-Path $outputDirectory 'classes.original.dex'),$originalBytes)
    [IO.File]::WriteAllBytes((Join-Path $outputDirectory 'classes.fullscreen-candidate.dex'),$patchedBytes)
    # Repack a local analysis APK. Strip original v1 signature material explicitly;
    # the result is UNSIGNED, unaligned and unsuitable for installation/deployment.
    $outputApk=Join-Path $outputDirectory 'AndroidAuto-fullscreen-UNSIGNED-OFFLINE-ONLY.apk'
    $apkStream=[IO.File]::Open($outputApk,[IO.FileMode]::Create,[IO.FileAccess]::ReadWrite)
    $outputArchive=[IO.Compression.ZipArchive]::new($apkStream,[IO.Compression.ZipArchiveMode]::Create,$false)
    $removed=[Collections.Generic.List[string]]::new()
    try {
        foreach($entry in $inputArchive.Entries){
            if($entry.FullName -match '(?i)^META-INF/(MANIFEST\.MF|[^/]+\.(SF|RSA|DSA|EC))$'){$removed.Add($entry.FullName);continue}
            $newEntry=$outputArchive.CreateEntry($entry.FullName,[IO.Compression.CompressionLevel]::Optimal)
            $newEntry.LastWriteTime=$entry.LastWriteTime
            $destination=$newEntry.Open()
            try {if($entry.FullName -eq 'classes.dex'){$destination.Write($patchedBytes)}else{$source=$entry.Open();try{$source.CopyTo($destination)}finally{$source.Dispose()}}}finally{$destination.Dispose()}
        }
    }finally{$outputArchive.Dispose();$apkStream.Dispose()}
    $checkArchive=[IO.Compression.ZipFile]::OpenRead($outputApk)
    $entryChecks=[Collections.Generic.List[object]]::new()
    try {
        foreach($entry in $inputArchive.Entries){
            if($entry.FullName.EndsWith('/') -or $removed.Contains($entry.FullName)){continue}
            $counterpart=$checkArchive.GetEntry($entry.FullName)
            if($null -eq $counterpart){throw "Missing output entry $($entry.FullName)"}
            $beforeStream=$entry.Open();$afterStream=$counterpart.Open()
            try{$beforeHash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($beforeStream));$afterHash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($afterStream))}finally{$beforeStream.Dispose();$afterStream.Dispose()}
            $changed=$beforeHash -ne $afterHash
            if($changed -and $entry.FullName -ne 'classes.dex'){throw "Unexpected changed APK payload $($entry.FullName)"}
            $entryChecks.Add([pscustomobject]@{entry=$entry.FullName;before=$beforeHash;after=$afterHash;changed=$changed})
        }
    }finally{$checkArchive.Dispose()}
    $entryChecks|ConvertTo-Json|Set-Content -LiteralPath (Join-Path $outputDirectory 'apk-entry-validation.json')
    [ordered]@{
        status='OFFLINE ANALYSIS BUILD ONLY; UNSIGNED; NO INSTALLATION AUTHORIZED'
        inputApk=$inputApk;inputApkSHA256=(Get-FileHash -LiteralPath $inputApk -Algorithm SHA256).Hash
        originalDexSHA256=$originalHash;patchedDexSHA256=[RdxOffline.Dex]::HexHash($patchedBytes)
        method=$method;patches=$patches;changedByteOffsets=$changedOffsets
        dexHeaderChanges='SHA-1 bytes 12..31 and Adler-32 bytes 8..11 recalculated'
        originalDexHeaderValid=$originalDex.CheckHeaderHashes();patchedDexHeaderValid=$reparsed.CheckHeaderHashes()
        outputApk=$outputApk;outputApkSHA256=(Get-FileHash -LiteralPath $outputApk -Algorithm SHA256).Hash
        removedSignatureEntries=$removed;unchangedPayloadEntries=@($entryChecks|Where-Object {-not $_.changed}).Count
        primary=@{width=1920;height=720;dpi=$PrimaryDpi;fps=60;configIndex=0;resolutionEnum=3;frameRateEnum=1;widthMargin=0;heightMargin=360;codecTypeEnum=3}
        secondary='Unchanged 800x430 / 143dpi / 60fps, configuration index 1'
    }|ConvertTo-Json -Depth 8|Set-Content -LiteralPath (Join-Path $outputDirectory 'dex-patch-report.json')
    Write-Output "Offline APK built; DEX checksums verified; $($entryChecks.Count) APK payload entries compared."
    $method|ConvertTo-Json -Compress
    $patches|ConvertTo-Json -Compress
}finally{$inputArchive.Dispose()}
