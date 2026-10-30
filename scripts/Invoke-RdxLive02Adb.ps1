param([Parameter(Mandatory)][ValidatePattern('^[a-z0-9-]+$')][string]$Name,[Parameter(Mandatory)][string[]]$AdbArguments,[switch]$Binary)
$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath('./analysis/parallel-aa-receiver/live-test-02')
[IO.Directory]::CreateDirectory($root)|Out-Null
$recordPath=Join-Path $root "$Name.command.json"
if(Test-Path -LiteralPath $recordPath){throw 'Evidence name already exists; do not overwrite raw evidence'}
$start=[Diagnostics.ProcessStartInfo]::new()
$start.FileName=(Resolve-Path './adb/adb.exe').Path
$start.UseShellExecute=$false;$start.CreateNoWindow=$true
$start.RedirectStandardOutput=$true;$start.RedirectStandardError=$true
foreach($argument in $AdbArguments){$start.ArgumentList.Add($argument)}
$process=[Diagnostics.Process]::new();$process.StartInfo=$start
$utc=[DateTime]::UtcNow.ToString('o')
[void]$process.Start()
$errorTask=$process.StandardError.ReadToEndAsync()
if($Binary){
    $stream=[IO.File]::Create((Join-Path $root "$Name.png"))
    try{$process.StandardOutput.BaseStream.CopyTo($stream)}finally{$stream.Dispose()}
}else{
    $stdout=$process.StandardOutput.ReadToEnd()
    [IO.File]::WriteAllText((Join-Path $root "$Name.stdout.txt"),$stdout)
}
$process.WaitForExit();$stderr=$errorTask.GetAwaiter().GetResult()
[IO.File]::WriteAllText((Join-Path $root "$Name.stderr.txt"),$stderr)
$record=[ordered]@{utc=$utc;endUtc=[DateTime]::UtcNow.ToString('o');arguments=$AdbArguments;exitCode=$process.ExitCode;name=$Name;stdout=if($Binary){"$Name.png"}else{"$Name.stdout.txt"};stderr="$Name.stderr.txt"}
$record|ConvertTo-Json -Depth 5|Set-Content -LiteralPath $recordPath
[pscustomobject]@{name=$Name;exitCode=$process.ExitCode;stdoutBytes=if($Binary){(Get-Item (Join-Path $root "$Name.png")).Length}else{[Text.Encoding]::UTF8.GetByteCount($stdout)}}|ConvertTo-Json -Compress
$process.Dispose()

