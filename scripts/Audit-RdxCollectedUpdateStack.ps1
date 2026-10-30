$ErrorActionPreference='Stop'
$root=(Resolve-Path './apks/current-update-stack').Path
$out='./analysis/current-update-stack'
Add-Type -Path './scripts/RdxDex.cs'
Add-Type -Path './scripts/RdxElf.cs'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$files=Get-Content -LiteralPath "$root/metadata/files.json" -Raw|ConvertFrom-Json
$rows=foreach($record in $files){
    $copy=Join-Path $root $record.localPath
    if((Get-Item -LiteralPath $copy).Length-ne$record.bytes -or (Get-FileHash -LiteralPath $copy -Algorithm SHA256).Hash-ne$record.sha256){throw 'Captured file integrity mismatch'}
    if($record.localPath.EndsWith('.apk')){
        $archive=[IO.Compression.ZipFile]::OpenRead($copy)
        try{foreach($entry in $archive.Entries|Where-Object {$_.FullName-match'^classes\d*\.dex$'}){
            $stream=$entry.Open();$memory=[IO.MemoryStream]::new()
            try{$stream.CopyTo($memory);$bytes=$memory.ToArray()}finally{$stream.Dispose();$memory.Dispose()}
            $dex=[RdxOffline.Dex]::new($bytes)
            [pscustomobject]@{package=$record.package;entry=$entry.FullName;sha256=[RdxOffline.Dex]::HexHash($bytes);classes=$dex.DefinedClasses().Count;loaderReferences=@($dex.Methods|Where-Object {$_.Class-match'DexClassLoader|PathClassLoader|DexFile|BaseDexClassLoader|URLClassLoader' -or $_.Name-match'startInstrumentation|loadDex'}|Select-Object Class,Name,Prototype);trustStrings=@($dex.Strings|Where-Object {$_-match'(?i)sw_update_root|certificate|\.crt$|\.pem$|\.bks$|wrap\.|LD_PRELOAD|CLASSPATH|AndroidAuto|androidauto|instrumentation|test.?runner|rollback'})}
        }}finally{$archive.Dispose()}
    }elseif($record.localPath.EndsWith('.so')){
        $elf=[RdxOffline.Elf32]::new([IO.File]::ReadAllBytes($copy))
        $name=[IO.Path]::GetFileName($copy)
        $elf.Symbols|ConvertTo-Json -Depth 4|Set-Content -LiteralPath "$out/$name.symbols.json"
        $elf.Strings(5)|ConvertTo-Json -Depth 4|Set-Content -LiteralPath "$out/$name.strings.json"
    }
}
$rows|ConvertTo-Json -Depth 7|Set-Content -LiteralPath "$out/dex-audit.json"
$queries=[ordered]@{
    'install-and-rollback'='installApk|installPackage|deletePackage|pm install|pm uninstall|persistdata/app|ROLLBACK|rollback|partitionSwitch|setStatusUpdated|sw_update_root'
    'loaders-and-harnesses'='DexClassLoader|PathClassLoader|loadDex|Class\.forName|\.loadClass|startInstrumentation|instrumentation|wrap\.|LD_PRELOAD|CLASSPATH|[Tt]estRunner|[Pp]lugin|System\.load|runtime\.exec|Runtime\.getRuntime'
    'caller-and-permissions'='enforceCalling|enforcePermission|checkCalling|permission=|ServiceManager.addService|com.honda.ota.event|SwmcClient.SwmcDilEvent'
}
foreach($query in $queries.GetEnumerator()){
    & rg -n --glob '*.java' --glob 'AndroidManifest.xml' --glob '!R.java' -- $query.Value './decompiled/current-update-stack' > "$out/$($query.Key).txt"
    if($LASTEXITCODE-gt1){throw 'Static query failed'}
}
# Preserve remote symlink topology explicitly; adb pull materializes link target bytes.
$symlinks=foreach($listing in Get-ChildItem -LiteralPath "$root/metadata" -Filter '*.listing.stdout.txt'){
    $directory=$null
    foreach($line in Get-Content -LiteralPath $listing.FullName){
        if($line-match'^(/[^:]+):\s*$'){$directory=$Matches[1]}
        elseif($line-match'^l\S+\s+.*?\s+(\S+)\s+->\s+(\S+)\s*$'){
            [pscustomobject]@{deviceLinkPath="$directory/$($Matches[1])";deviceLinkTarget=$Matches[2];localRepresentation='Materialized target contents, original link topology retained in this record and raw ls listing.'}
        }
    }
}
$symlinks|ConvertTo-Json -Depth 4|Set-Content -LiteralPath "$root/metadata/symlinks.json"
$commands=@(Get-Content -LiteralPath "$root/metadata/commands.jsonl"|ForEach-Object {$_|ConvertFrom-Json})
foreach($command in $commands){
    $argv=@($command.arguments)
    $allowed=($argv.Count-eq1 -and $argv[0]-eq'devices') -or ($argv.Count-ge4 -and $argv[0]-eq'-s' -and $argv[2]-eq'pull') -or ($argv.Count-ge5 -and $argv[0]-eq'-s' -and $argv[2]-eq'shell' -and $argv[3]-in'getprop','ls') -or ($argv.Count-ge6 -and $argv[2]-eq'shell' -and (($argv[3]-eq'pm' -and $argv[4]-eq'path') -or ($argv[3]-eq'dumpsys' -and $argv[4]-eq'package')))
    if(-not$allowed -or $command.exitCode-ne0 -or $command.timedOut){throw 'Unexpected or failed collection command; review JSONL'}
}
[ordered]@{capturedFiles=$files.Count;apkFiles=@($files|Where-Object {$_.localPath.EndsWith('.apk')}).Count;dexFiles=$rows.Count;nativeSymlinks=@($symlinks).Count;loggedAdbCommands=$commands.Count;allLoggedCommandsAllowedAndSuccessful=$true;allCapturedSizesAndHashesValid=$true;pullSkipCounts='All seven package pull reports and certificate pull report: 0 skipped';notes='Initial interactive adb devices check also succeeded before the logged collection. No vehicle operations performed by this local audit.'}|ConvertTo-Json|Set-Content -LiteralPath "$out/collection-validation.json"
Get-Content -LiteralPath "$out/collection-validation.json"
