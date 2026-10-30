# Dot-source only. Local evidence writer; explicit calls execute commands and preserve all outputs.
$script:M4Root=Split-Path $PSScriptRoot -Parent
$script:M4Directory=(Get-Content "$script:M4Root/analysis/parallel-aa-receiver/m4-current-session.txt" -Raw).Trim()
$script:M4SerialPath=Join-Path $script:M4Directory 'selected-serial.txt'
function Invoke-M4Evidence {
 param([Parameter(Mandatory)][string]$Name,[Parameter(Mandatory)][string]$Executable,[string[]]$Arguments,[int]$TimeoutMs=15000)
 $safeName=$Name -replace '[^A-Za-z0-9._-]','_'
 $stem=Join-Path $script:M4Directory ((Get-Date -Format 'yyyyMMdd-HHmmss-fff')+'-'+$safeName)
 $si=[Diagnostics.ProcessStartInfo]::new();$si.FileName=$Executable;$si.UseShellExecute=$false;$si.CreateNoWindow=$true;$si.RedirectStandardOutput=$true;$si.RedirectStandardError=$true
 foreach($a in $Arguments){$si.ArgumentList.Add($a)}
 $p=[Diagnostics.Process]::new();$p.StartInfo=$si;$start=[DateTime]::UtcNow.ToString('o')
 [void]$p.Start();$out=$p.StandardOutput.ReadToEndAsync();$err=$p.StandardError.ReadToEndAsync();$timeout=-not$p.WaitForExit($TimeoutMs)
 if($timeout){$p.Kill();$p.WaitForExit()}
 $stdout=$out.GetAwaiter().GetResult();$stderr=$err.GetAwaiter().GetResult();$exit=$p.ExitCode
 [IO.File]::WriteAllText($stem+'.stdout.txt',$stdout);[IO.File]::WriteAllText($stem+'.stderr.txt',$stderr)
 $record=[ordered]@{name=$Name;startUtc=$start;endUtc=[DateTime]::UtcNow.ToString('o');executable=$Executable;arguments=$Arguments;exitCode=$exit;timedOut=$timeout;timeoutMs=$TimeoutMs;stdoutFile=$stem+'.stdout.txt';stderrFile=$stem+'.stderr.txt'}
 $record|ConvertTo-Json -Depth 6|Set-Content ($stem+'.command.json');$p.Dispose()
 return [pscustomobject]@{stdout=$stdout;stderr=$stderr;exitCode=$exit;timedOut=$timeout;record=$record}
}
function Invoke-M4Adb {
 param([Parameter(Mandatory)][string]$Name,[Parameter(Mandatory)][string[]]$Arguments,[int]$TimeoutMs=15000)
 if(-not(Test-Path -LiteralPath $script:M4SerialPath)){throw 'No explicitly selected serial'}
 $serial=(Get-Content -LiteralPath $script:M4SerialPath -Raw).Trim()
 if($serial-notmatch'^[A-Za-z0-9._:-]+$'){throw 'Invalid serial'}
 Invoke-M4Evidence -Name $Name -Executable "$script:M4Root/adb/adb.exe" -Arguments (@('-s',$serial)+$Arguments) -TimeoutMs $TimeoutMs
}
