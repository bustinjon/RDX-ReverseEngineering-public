$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$prior = './adb/RDX-Audit/full-system/priv-app/RedBendApp/RedBendApp.apk'
$current = './apks/current-update-stack/system/priv-app/RedBendApp/RedBendApp.apk'
function Get-ArchiveEntries([string]$path) {
    $zip = [IO.Compression.ZipFile]::OpenRead((Resolve-Path -LiteralPath $path).Path)
    try {
        foreach ($entry in $zip.Entries) {
            $stream = $entry.Open()
            $sha = [Security.Cryptography.SHA256]::Create()
            try { $hash = [Convert]::ToHexString($sha.ComputeHash($stream)) }
            finally { $sha.Dispose(); $stream.Dispose() }
            [pscustomobject]@{ name=$entry.FullName; bytes=$entry.Length; sha256=$hash }
        }
    } finally { $zip.Dispose() }
}
$priorEntries = @(Get-ArchiveEntries $prior)
$currentEntries = @(Get-ArchiveEntries $current)
$priorMap = @{}
$currentMap = @{}
foreach ($entry in $priorEntries) { $priorMap[$entry.name] = $entry }
foreach ($entry in $currentEntries) { $currentMap[$entry.name] = $entry }
$differences = @(foreach ($name in @(@($priorMap.Keys) + @($currentMap.Keys) | Sort-Object -Unique)) {
    $a = $priorMap[$name]; $b = $currentMap[$name]
    if ($null -eq $a -or $null -eq $b -or $a.sha256 -ne $b.sha256) {
        [pscustomobject]@{ name=$name; prior=$a; current=$b }
    }
})
$report = [ordered]@{
    priorPath=$prior; currentPath=$current
    priorRedBendSHA256=(Get-FileHash -LiteralPath $prior -Algorithm SHA256).Hash
    currentRedBendSHA256=(Get-FileHash -LiteralPath $current -Algorithm SHA256).Hash
    byteIdentical=((Get-FileHash -LiteralPath $prior).Hash -eq (Get-FileHash -LiteralPath $current).Hash)
    priorEntryCount=$priorEntries.Count; currentEntryCount=$currentEntries.Count
    allUncompressedEntriesIdentical=($differences.Count -eq 0)
    dexIdentical=($priorMap['classes.dex'].sha256 -eq $currentMap['classes.dex'].sha256)
    dexSHA256=$currentMap['classes.dex'].sha256
    decodedManifestDifferences=@(Compare-Object (Get-Content './decompiled/RedBendApp/resources/AndroidManifest.xml') (Get-Content './decompiled/current-update-stack/com.redbend.client/resources/AndroidManifest.xml') | Select-Object InputObject,SideIndicator)
    differences=$differences
    priorEntries=$priorEntries; currentEntries=$currentEntries
    globalNativeLibraries='No new global SMM/libdevelupdate/transport libs were pulled; previous native collection remains separately identified evidence.'
}
$report | ConvertTo-Json -Depth 7 | Set-Content -LiteralPath './analysis/current-update-stack/redbend-provenance.json'
[pscustomobject]$report | Select-Object priorRedBendSHA256,currentRedBendSHA256,byteIdentical,priorEntryCount,currentEntryCount,allUncompressedEntriesIdentical,dexIdentical,dexSHA256,decodedManifestDifferences | ConvertTo-Json -Depth 6
