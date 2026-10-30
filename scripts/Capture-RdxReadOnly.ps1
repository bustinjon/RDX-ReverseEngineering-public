param([string]$OutputDirectory = 'logs/2026-10-22-investigation')
$ErrorActionPreference = 'Stop'
$adbPath = (Resolve-Path -LiteralPath './adb/adb.exe').Path
$outputPath = [IO.Path]::GetFullPath((Join-Path (Get-Location) $OutputDirectory))
[IO.Directory]::CreateDirectory($outputPath) | Out-Null
function Invoke-AdbReadOnly {
    param([string]$Name, [string[]]$AdbArguments, [int]$TimeoutMs = 12000)
    $startInfo = [Diagnostics.ProcessStartInfo]::new($adbPath)
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    foreach ($argument in $AdbArguments) { $startInfo.ArgumentList.Add($argument) }
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    $startedAt = [DateTime]::UtcNow.ToString('o')
    $process.Start() | Out-Null
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    $timedOut = -not $process.WaitForExit($TimeoutMs)
    if ($timedOut) { $process.Kill(); $process.WaitForExit() }
    $stdout = $stdoutTask.GetAwaiter().GetResult()
    $stderr = $stderrTask.GetAwaiter().GetResult()
    [IO.File]::WriteAllText((Join-Path $outputPath "$Name.txt"), $stdout + $stderr)
    $result = [ordered]@{ name=$Name; startedUtc=$startedAt; arguments=$AdbArguments; exitCode=$process.ExitCode; timedOut=$timedOut; stdoutCharacters=$stdout.Length; stderrCharacters=$stderr.Length }
    $result | ConvertTo-Json -Compress | Add-Content -LiteralPath (Join-Path $outputPath 'commands.jsonl')
    $process.Dispose()
    [pscustomobject]$result
}
Invoke-AdbReadOnly 'devices' @('devices')
Invoke-AdbReadOnly 'ps-before-jdwp' @('shell','ps')
Invoke-AdbReadOnly 'jdwp' @('jdwp') 8000
Invoke-AdbReadOnly 'ps-after-jdwp' @('shell','ps')
Invoke-AdbReadOnly 'activity-settings' @('shell','dumpsys','activity','settings')
Invoke-AdbReadOnly 'services' @('shell','service','list')
foreach ($serviceName in @('factorysettings','DiagnosticsService','EngineeringAccessService','software_update','lcd_service','swupdate','state_machine_service')) {
    Invoke-AdbReadOnly "dumpsys-$serviceName" @('shell','dumpsys',$serviceName) 6000
}
Invoke-AdbReadOnly 'content-providers' @('shell','dumpsys','activity','providers')
Invoke-AdbReadOnly 'all-packages' @('shell','dumpsys','package') 20000
Invoke-AdbReadOnly 'unix-sockets' @('shell','cat','/proc/net/unix')
Invoke-AdbReadOnly 'aa-process-status' @('shell','cat','/proc/2442/status')
Invoke-AdbReadOnly 'aa-process-maps' @('shell','cat','/proc/2442/maps')
Invoke-AdbReadOnly 'logcat' @('logcat','-d','-v','time') 20000
