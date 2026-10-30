$ErrorActionPreference='Stop'
Add-Type -Path './scripts/RdxDex.cs'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$inventory=Get-Content -LiteralPath './analysis/local-software-search/inventory.json' -Raw | ConvertFrom-Json
$records=@($inventory | Where-Object {$_.Kind-eq'dex'} | Group-Object SHA256 | ForEach-Object {$_.Group[0]})
function Read-ArchivedLeaf([string]$Location){
    $parts=$Location.Split('!')
    $bytes=[IO.File]::ReadAllBytes($parts[0])
    for($part=1;$part-lt$parts.Length;$part++){
        $stream=[IO.MemoryStream]::new($bytes,$false)
        $archive=[IO.Compression.ZipArchive]::new($stream,[IO.Compression.ZipArchiveMode]::Read)
        try{
            $entry=$archive.GetEntry($parts[$part]);if($null-eq$entry){throw "Missing archive entry $Location"}
            $leaf=$entry.Open();$memory=[IO.MemoryStream]::new()
            try{$leaf.CopyTo($memory);$bytes=$memory.ToArray()}finally{$leaf.Dispose();$memory.Dispose()}
        }finally{$archive.Dispose();$stream.Dispose()}
    }
    return ,$bytes
}
$report=foreach($record in $records){
    $bytes=Read-ArchivedLeaf $record.Location
    if([RdxOffline.Dex]::HexHash($bytes)-ne$record.SHA256){throw "Input hash mismatch $($record.Location)"}
    $dex=[RdxOffline.Dex]::new($bytes)
    $references=@($dex.Methods | Where-Object {
        $_.Class-match'Ldalvik/system/(DexClassLoader|PathClassLoader|DexFile|BaseDexClassLoader);|Ljava/net/URLClassLoader;' -or
        ($_.Class-match'ClassLoader;' -and $_.Name-match'loadClass|findClass') -or
        ($_.Class-eq'Ljava/lang/System;' -and $_.Name-match'^load(Library)?$') -or
        ($_.Class-eq'Ljava/lang/Runtime;' -and $_.Name-match'^exec$|^load') -or
        ($_.Name-match'startInstrumentation|createPackageContext')
    } | Select-Object Class,Name,Prototype,CodeOffset)
    $paths=@($dex.Strings | Where-Object {$_-match'^/(data|persistdata|sdcard|mnt|storage)/' -and $_-match'\.(dex|jar|apk|so)(/|$)|class|plugin|script|test|debug'})
    $harnesses=@($dex.DefinedClasses() | Where-Object {$_-match'(?i)instrumentation|plugin|loader|engineering|validation|testharness|debugloader'})
    [pscustomobject]@{location=$record.Location;sha256=$record.SHA256;methodReferences=$references;codePathStrings=$paths;harnessClasses=$harnesses}
}
$report | ConvertTo-Json -Depth 7 | Set-Content -LiteralPath './analysis/deployment-evidence/dex-loader-audit.json'
[pscustomobject]@{uniqueDexExamined=$records.Count;dexWithLoaderOrRuntimeReferences=@($report|Where-Object {$_.methodReferences.Count-gt0}).Count;dexWithWritableCodePathStrings=@($report|Where-Object {$_.codePathStrings.Count-gt0}).Count;internetUsed=$false;adbUsed=$false} | ConvertTo-Json | Set-Content -LiteralPath './analysis/deployment-evidence/dex-loader-summary.json'
Get-Content -LiteralPath './analysis/deployment-evidence/dex-loader-summary.json'
