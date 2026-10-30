$ErrorActionPreference='Stop'
$adb=(Resolve-Path -LiteralPath './adb/adb.exe').Path
$serial='00000000'
$root=[IO.Path]::GetFullPath('./apks/current-update-stack')
$capture=Join-Path $root 'metadata'
[IO.Directory]::CreateDirectory($capture)|Out-Null
$packages=@('com.honda.auto.softwareupdate','com.honda.auto.transportservice','com.honda.ota','com.honda.auto.factoryflashing','com.honda.auto.diagnostics.service','com.honda.miscellaneous','com.redbend.client')
function Invoke-ReadOnlyAdb([string]$Name,[string[]]$Arguments,[int]$TimeoutMs=15000){
    # Call sites below are only devices, getprop, pm path, dumpsys package, ls and pull.
    $start=[Diagnostics.ProcessStartInfo]::new($adb)
    $start.UseShellExecute=$false;$start.CreateNoWindow=$true
    $start.RedirectStandardOutput=$true;$start.RedirectStandardError=$true
    foreach($arg in $Arguments){$start.ArgumentList.Add($arg)}
    $proc=[Diagnostics.Process]::new();$proc.StartInfo=$start
    $when=[DateTime]::UtcNow.ToString('o')
    $proc.Start()|Out-Null
    $outTask=$proc.StandardOutput.ReadToEndAsync();$errTask=$proc.StandardError.ReadToEndAsync()
    $timeout=-not$proc.WaitForExit($TimeoutMs)
    if($timeout){$proc.Kill();$proc.WaitForExit()}
    $stdout=$outTask.GetAwaiter().GetResult();$stderr=$errTask.GetAwaiter().GetResult()
    [IO.File]::WriteAllText((Join-Path $capture "$Name.stdout.txt"),$stdout)
    [IO.File]::WriteAllText((Join-Path $capture "$Name.stderr.txt"),$stderr)
    $record=[ordered]@{startedUtc=$when;arguments=$Arguments;exitCode=$proc.ExitCode;timedOut=$timeout;stdout="$Name.stdout.txt";stderr="$Name.stderr.txt"}
    $record|ConvertTo-Json -Compress|Add-Content -LiteralPath (Join-Path $capture 'commands.jsonl')
    $exitCode=$proc.ExitCode;$proc.Dispose()
    if($timeout-or$exitCode-ne0){throw "Read-only ADB failed: $Name; inspect metadata logs"}
    return $stdout
}
$devices=Invoke-ReadOnlyAdb 'devices' @('devices')
if($devices-notmatch"(?m)^$serial\s+device\s*$"){throw 'Expected serial not connected; no collection performed'}
$fw=Invoke-ReadOnlyAdb 'firmware' @('-s',$serial,'shell','getprop','ro.build.fwversion')
if($fw.Trim()-ne'D.1.6.4'){throw "Unexpected firmware $fw; review before collecting a different build"}
$packageRecords=[Collections.Generic.List[object]]::new()
foreach($package in $packages){
    $pathsText=Invoke-ReadOnlyAdb "$package.pm-path" @('-s',$serial,'shell','pm','path',$package)
    $dump=Invoke-ReadOnlyAdb "$package.package-dump" @('-s',$serial,'shell','dumpsys','package',$package)
    $paths=@([regex]::Matches($pathsText,'(?m)^package:([^\r\n]+)')|ForEach-Object {$_.Groups[1].Value.Trim()})
    if($paths.Count-eq0){throw "No active path for $package"}
    $dirs=@($paths|ForEach-Object {$_.Substring(0,$_.LastIndexOf('/'))}|Sort-Object -Unique)
    foreach($dir in $dirs){
        if($dir-notmatch'^/(system/(app|priv-app)/[^/]+|persistdata/app/[^/]+|data/app/[^/]+)$'){throw "Unexpected package directory $dir; no broad pull attempted"}
        if($dir-match'[^a-zA-Z0-9_./+-]'){throw "Unsafe device path spelling $dir"}
        $name="$package.directory-$([Array]::IndexOf($dirs,$dir))"
        Invoke-ReadOnlyAdb "$name.listing" @('-s',$serial,'shell','ls','-lnR',$dir)|Out-Null
        $relative=$dir.TrimStart('/')
        $localDir=Join-Path $root $relative
        [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($localDir))|Out-Null
        Invoke-ReadOnlyAdb "$name.pull" @('-s',$serial,'pull',$dir,[IO.Path]::GetDirectoryName($localDir)) 120000|Out-Null
    }
    $versionName=[regex]::Match($dump,'(?m)^\s*versionName=([^\r\n]*)').Groups[1].Value.Trim()
    $versionCode=[regex]::Match($dump,'\bversionCode=(\d+)').Groups[1].Value
    $uid=[regex]::Match($dump,'(?m)^\s*userId=(\d+)').Groups[1].Value
    $shared=[regex]::Match($dump,'(?m)^\s*sharedUser=([^\r\n]+)').Groups[1].Value.Trim()
    $packageRecords.Add([pscustomobject]@{package=$package;deviceApkPaths=$paths;deviceDirectories=$dirs;versionName=$versionName;versionCode=$versionCode;uid=$uid;sharedUserDump=$shared;dump="$package.package-dump.stdout.txt"})
    $packageRecords|ConvertTo-Json -Depth 5|Set-Content -LiteralPath (Join-Path $capture 'packages.json')
    Write-Output "Collected $package version $versionName ($versionCode), UID $uid"
}
$security=Join-Path $root 'security'
[IO.Directory]::CreateDirectory($security)|Out-Null
Invoke-ReadOnlyAdb 'sw-update-root.listing' @('-s',$serial,'shell','ls','-ln','/system/etc/security/sw_update_root.crt')|Out-Null
Invoke-ReadOnlyAdb 'sw-update-root.pull' @('-s',$serial,'pull','/system/etc/security/sw_update_root.crt',(Join-Path $security 'sw_update_root.crt'))|Out-Null
$inventory=foreach($packageRecord in $packageRecords){foreach($dir in $packageRecord.deviceDirectories){
    $localDir=Join-Path $root $dir.TrimStart('/')
    foreach($file in Get-ChildItem -LiteralPath $localDir -Recurse -File){
        $sub=[IO.Path]::GetRelativePath($localDir,$file.FullName).Replace('\','/')
        [pscustomobject]@{package=$packageRecord.package;devicePath="$dir/$sub";localPath=[IO.Path]::GetRelativePath($root,$file.FullName).Replace('\','/');bytes=$file.Length;sha256=(Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash}
    }
}}
$cert=Get-Item -LiteralPath (Join-Path $security 'sw_update_root.crt')
$inventory+= [pscustomobject]@{package=$null;devicePath='/system/etc/security/sw_update_root.crt';localPath='security/sw_update_root.crt';bytes=$cert.Length;sha256=(Get-FileHash -LiteralPath $cert.FullName -Algorithm SHA256).Hash}
$inventory|ConvertTo-Json -Depth 5|Set-Content -LiteralPath (Join-Path $capture 'files.json')
[ordered]@{capturedUtc=[DateTime]::UtcNow.ToString('o');serial=$serial;firmware=$fw.Trim();packages=$packageRecords.Count;files=$inventory.Count;vehicleOperations='devices; shell getprop; shell pm path; shell dumpsys package; shell ls; adb pull only';hashScope='SHA256 of pulled local bytes; no remote hash program invoked'}|ConvertTo-Json|Set-Content -LiteralPath (Join-Path $capture 'collection.json')
'Read-only update-stack collection complete.'
