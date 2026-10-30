#Requires -Version 7.0
# All device responses are an in-process simulation. No shell/device commands are evaluated.
[CmdletBinding()]
param([string]$OutputDirectory)
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
. (Join-Path $PSScriptRoot 'CarTest.Core.ps1')
if (-not $OutputDirectory) { $OutputDirectory = Join-Path $repoRoot ('analysis/test-prep/runner-tests-' + [guid]::NewGuid().ToString('N')) }
if (Test-Path -LiteralPath $OutputDirectory) { throw 'Use a new test-output directory.' }
$null = New-Item -ItemType Directory -Path $OutputDirectory
$OutputDirectory = (Resolve-Path -LiteralPath $OutputDirectory).Path
$fixtureApk = Join-Path $OutputDirectory 'fixture.apk'
$fixtureJava = Join-Path $OutputDirectory 'Fixture.java'
[IO.File]::WriteAllText($fixtureApk, 'SIMULATED APK: NOT INSTALLABLE')
[IO.File]::WriteAllText($fixtureJava, 'class Fixture {}')
$fixtureHash = (Get-FileHash -LiteralPath $fixtureApk -Algorithm SHA256).Hash
$reportFile = Join-Path $OutputDirectory 'build-report.json'
$policySource=Join-Path $repoRoot 'analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/HondaPhonePolicy.java'
@{harness='usb-helper';sha256=$fixtureHash;staticAudit='SIMULATED';sourceHashes=@(@{Path=$fixtureJava;Hash=(Get-FileHash -LiteralPath $fixtureJava -Algorithm SHA256).Hash},@{Path=$policySource;Hash=(Get-FileHash -LiteralPath $policySource -Algorithm SHA256).Hash})} | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $reportFile
$plan = Get-CarTestArtifactPlan -RepoRoot $repoRoot -ApkPath $fixtureApk -ExpectedHash $fixtureHash -BuildReportPath $reportFile -CandidateRole CurrentSource
$results = [Collections.Generic.List[object]]::new()
function Assert-Test([bool]$Condition, [string]$Message) { if (-not $Condition) { throw $Message } }
function Test-Case([string]$Name, [scriptblock]$Test) {
    try { & $Test; $results.Add([pscustomobject]@{name=$Name;pass=$true;error=$null}) }
    catch { $results.Add([pscustomobject]@{name=$Name;pass=$false;error=$_.Exception.Message}) }
}

function Run-Simulation([string]$Scenario, [string]$Newline = "`n", [bool]$Cooperative = $false) {
    $directory = Join-Path $OutputDirectory $Scenario
    $null = New-Item -ItemType Directory -Path $directory
    $sim = @{
        Services='org.example.reader/.Speak:com.rdx.fullscreen.usbhelper/.PermissionClickService'
        Enabled='1'; Bound=$true; HelperStarted=$false; Marker=''; Phase=0
        Original='org.example.reader/.Speak:com.rdx.fullscreen.usbhelper/.PermissionClickService'
        Calls=[Collections.Generic.List[object]]::new(); Scenario=$Scenario; Apk=$fixtureApk; Newline=$Newline; Cooperative=$Cooperative
    }
    $transport = {
        param([string[]]$Arguments)
        $sim.Calls.Add(@($Arguments))
        if ($Arguments[0] -ne '-s' -or $Arguments[1] -ne '00000000') { throw 'Unscoped simulated command.' }
        $output=''; $code=0
        switch ($Arguments[2]) {
            'get-state' { if($sim.Scenario -eq 'transport-timeout'){throw 'SIMULATED timeout'}; $output=if($sim.Scenario -eq 'offline-target'){'offline'}else{'device'} }
            'install' {
                if($sim.Scenario -eq 'install-exit-failure'){$code=1;$output='Success'}
                elseif($sim.Scenario -eq 'install-text-failure'){$output='Failure [INSTALL_FAILED]'}
                else{$output='Success'}
            }
            'pull' {
                if($sim.Scenario -eq 'installed-hash-mismatch'){[IO.File]::WriteAllText($Arguments[4],'wrong apk')}
                else {Copy-Item -LiteralPath $sim.Apk -Destination $Arguments[4]}
            }
            'push' { if($sim.Scenario -eq 'push-failure'){$code=1} }
            'shell' {
                $wrapped=$Arguments[3]
                if($wrapped -notmatch '(?s)^\( (.*) \); rdx_rc=\$\?; echo; echo "(RDX_RC_[a-f0-9]+):\$rdx_rc"$') { throw 'Unknown shell envelope.' }
                $command=$Matches[1];$rcMarker=$Matches[2];$remoteCode=0
                switch -Regex ($command) {
                    '^getprop ro.serialno$' { $output=if($sim.Scenario -eq 'wrong-device'){'OTHER'}else{'00000000'}; break }
                    '^settings get secure enabled_accessibility_services$' {$output=if($sim.Scenario -eq 'malformed-settings'){'Error invalid; touch nope'}else{$sim.Services};break}
                    '^settings get secure accessibility_enabled$' {$output=$sim.Enabled;break}
                    "^settings put secure enabled_accessibility_services '(.*)'$" {
                        $sim.Services=$Matches[1]
                        $sim.Bound=$sim.Services -match 'PermissionClickService'
                        if($sim.Scenario -eq 'unbind-failure'){$sim.Bound=$true}
                        break
                    }
                    "^settings put secure accessibility_enabled '?([01])'?$" {$sim.Enabled=$Matches[1];break}
                    '^pm path ' {$output='package:/data/app/com.rdx.fullscreen.usbhelper-1/base.apk';break}
                    '^am stopservice -n ' {$output='Service stopped';break}
                    '^dumpsys activity services .*\.(\w+)$' {
                        $service=$Matches[1]
                        $active=($service -eq 'PermissionClickService' -and $sim.Bound) -or ($service -eq 'UsbHelperService' -and ($sim.HelperStarted -or $sim.Scenario -eq 'stale-helper'))
                        $output='ACTIVITY MANAGER SERVICES (dumpsys activity services)'
                        if($active) {
                            $output+="`n  User 0 active services:`n  * ServiceRecord{abc u0 com.rdx.fullscreen.usbhelper/.$service}`n    app=ProcessRecord{def 5278:com.rdx.fullscreen.usbhelper/u0a49}"
                            if($sim.Scenario -eq 'missing-process'){$output=$output -replace 'app=ProcessRecord[^\r\n]+','app=null'}
                        }
                        break
                    }
                    '^dumpsys accessibility$' {
                        $current=if($sim.Scenario -eq 'wrong-user'){'false'}else{'true'}
                        $bound=if($sim.Bound -and $sim.Scenario -notin @('not-bound','cleanup-disconnect','external-settings-change')){'Service[label=Other service, feedbackType[FEEDBACK_GENERIC]], Service[label=RDX USB, feedbackType[FEEDBACK_GENERIC], capabilities=1]'}else{''}
                        if($sim.Scenario -eq 'external-settings-change' -and $sim.Marker){$sim.Services='org.new.accessibility/.KeepMe';$sim.Enabled='0'}
                        $output="ACCESSIBILITY MANAGER (dumpsys accessibility)`nUser state[attributes:{id=0, currentUser=$current, accessibilityEnabled=true, touchExplorationEnabled=false}`n           services:{$bound}]"
                        break
                    }
                    "^log -p i -t RDX.PREP '([^']+)'$" {$sim.Marker=$Matches[1];break}
                    '^logcat -d ' {
                        $output="10-29 10:00:00.000 5278 5278 I RDX.A11Y: PermissionClickService connected OLD`n"
                        if($sim.Scenario -ne 'missing-boundary'){$output+="10-29 10:01:00.000 2000 2000 I RDX.PREP: $($sim.Marker)`n"}
                        if($sim.Bound -and $sim.Scenario -ne 'stale-callback'){
                            $callbackPid=if($sim.Scenario -eq 'wrong-callback-pid'){9999}else{5278}
                            $output+="10-29 10:01:01.000 $callbackPid $callbackPid I RDX.A11Y: PermissionClickService connected`n"
                        }
                        if($sim.HelperStarted){
                            $phase=if($sim.Scenario -eq 'wrong-phase'){3}else{0}
                            $output+="10-29 10:01:02.000 5278 5278 I RDX.USB : === Service started v5 uid=10049 pid=5278 ===`n10-29 10:01:02.000 5278 5278 I RDX.USB : onStartCommand phase=$phase action=null`n"
                            if($sim.Cooperative -and $sim.Scenario -ne 'missing-policy-marker'){$output+="10-29 10:01:02.000 5278 5278 I RDX.USB : HONDA_PHONE_NEVER_V1: phone-scoped policy loaded`n"}
                            if($sim.Scenario -eq 'legacy-side-effect'){$output+="10-29 10:01:02.000 5278 5278 I RDX.USB : Attempting VBUS reset`n"}
                            if($sim.Scenario -eq 'early-phone'){$output+="10-29 10:01:02.000 5278 5278 I RDX.USB : AOAP device detected: vid=18d1`n"}
                        }
                        break
                    }
                    '^dumpsys package ' {$output=if($sim.Scenario -eq 'honda-not-stopped'){'User 0: stopped=false'}else{'User 0: installed=true stopped=true'};break}
                    '^am startservice ' {$sim.HelperStarted=$true;$output='Starting service: Intent';if($sim.Scenario -eq 'helper-start-error'){$output='Error: not found'};break}
                    "^cat '.*/deadline'; cat /proc/uptime$" {$output="1060`n1001.00 4000.00";break}
                    "^cat '.*/deadline' '.*/honda-deadline'; cat /proc/uptime$" {
                        $output=switch($sim.Scenario){
                            'short-safety-window' {"1010`n1030`n1001.00 4000.00"}
                            'short-honda-window' {"1060`n1010`n1001.00 4000.00"}
                            'malformed-timing' {'UNKNOWN'}
                            default {"1060`n1030`n1001.00 4000.00"}
                        };break
                    }
                    default {
                        if($sim.Scenario -eq 'cleanup-disconnect' -and $command -eq 'am force-stop com.rdx.fullscreen.usbhelper'){throw 'SIMULATED disconnect during cleanup'}
                        if($sim.Scenario -eq 'capture-failure' -and $command -like 'test -s *capture.pid*'){$remoteCode=1}
                        if($sim.Scenario -eq 'watchdog-failure' -and $command -like 'kill -0 *watchdog.pid*'){$remoteCode=1}
                        if($sim.Scenario -eq 'loop-failure' -and $command -like 'kill -0 *honda.pid*'){$remoteCode=1}
                        if($sim.Scenario -eq 'remote-shell-failure' -and $command -like 'mkdir *'){$remoteCode=1}
                        if($command -like "sh '*/cleanup.sh'"){$sim.Services=$sim.Original}
                    }
                }
                if($sim.Scenario -ne 'missing-shell-status'){$output+="`n${rcMarker}:$remoteCode`n"}
            }
            default {throw "Unexpected transport verb $($Arguments[2])"}
        }
        [pscustomobject]@{ExitCode=$code;Output=$output.Replace("`n",$sim.Newline)}
    }.GetNewClosure()
    $errorText=$null;$result=$null
    $strategy=if($Cooperative){'PhonePreference'}else{'ForceStop'}
    try {$result=Invoke-CarTestPreparation -Plan $plan -Serial 00000000 -SafetySeconds 60 -RunDirectory $directory -RepoRoot $repoRoot -Transport $transport -HondaStrategy $strategy -PhoneSerial 'fixture-phone' -HondaPhoneDisabled $Cooperative -Delay {param($Milliseconds)}}
    catch {$errorText=$_.Exception.Message}
    $session=Get-Content -LiteralPath (Join-Path $directory 'session.json') -Raw | ConvertFrom-Json
    [pscustomobject]@{Result=$result;Error=$errorText;Session=$session;Simulation=$sim}
}

Test-Case 'success preserves unrelated services, targets every command, and starts watchdog before helper' {
    $r=Run-Simulation 'success'
    Assert-Test ($null -eq $r.Error) "Unexpected failure: $($r.Error)"
    Assert-Test ($r.Session.Status -eq 'READY') 'Missing READY result.'
    Assert-Test ($r.Session.ToolHashes.Count -eq 4) 'Runner/script provenance missing.'
    Assert-Test ($r.Simulation.Services -like 'org.example.reader/.Speak:*') 'Unrelated service lost.'
    $commands=@($r.Simulation.Calls | ForEach-Object {$_ -join ' '})
    Assert-Test (@($commands | Where-Object {$_ -notlike '-s 00000000 *'}).Count -eq 0) 'Missing target binding.'
    $joined=$commands -join "`n"
    Assert-Test ($joined.IndexOf('/system/bin/sh') -lt $joined.IndexOf('am startservice ')) 'Watchdog starts too late.'
    Assert-Test ($joined -match 'usb.CONFIGURE_LEGACY') 'New helper legacy startup must clear persisted cooperative mode explicitly.'
    Assert-Test (@($commands | Where-Object {$_ -like "*trap '' HUP; /system/bin/*"}).Count -eq 3) 'Background launches must ignore HUP before external exec.'
    Assert-Test ($joined -notmatch 'logcat -c|pkill') 'Global log destruction.'
    Assert-Test ($r.Session.SafetyRemainingSeconds -eq (57 - $r.Session.TimingRoundTripReserveSeconds) -and $r.Session.HondaRemainingSeconds -eq (27 - $r.Session.TimingRoundTripReserveSeconds)) 'Deadline accounting wrong.'
}
$expectedErrors=@{
    'offline-target'='Head unit is not online';'wrong-device'='Target identity mismatch';'wrong-user'='confirmed current user 0'
    'install-exit-failure'='Command failed: install';'install-text-failure'='Installation did not succeed';'installed-hash-mismatch'='Installed APK differs'
    'missing-shell-status'='Remote command failed or omitted exit status: getprop';'remote-shell-failure'='Remote command failed or omitted exit status: mkdir'
    'stale-helper'='Old service remains active';'missing-process'='one confirmed application process';'capture-failure'='Capture start failed'
    'unbind-failure'='did not unbind';'not-bound'='bound-services dump';'stale-callback'='No fresh accessibility connection';'wrong-callback-pid'='No fresh accessibility connection'
    'missing-boundary'='Fresh capture boundary missing';'honda-not-stopped'='Honda stopped state not confirmed';'push-failure'='Command failed: push'
    'watchdog-failure'='Watchdog start failed';'helper-start-error'='Remote error: Error: not found';'wrong-phase'='Fresh WAITING helper';'early-phone'='Phone activity occurred'
    'loop-failure'='Honda loop start failed';'short-safety-window'='Insufficient remaining';'short-honda-window'='Insufficient remaining';'malformed-timing'='Unrecognized device timing'
    'transport-timeout'='Command failed: get-state';'malformed-settings'='Unrecognized accessibility settings';'cleanup-disconnect'='bound-services dump';'external-settings-change'='settings did not persist'
}
foreach($scenario in $expectedErrors.Keys | Sort-Object) {
    Test-Case "reject $scenario" {
        $r=Run-Simulation $scenario
        Assert-Test ($null -ne $r.Error -and $r.Session.Status -eq 'FAILED' -and $null -eq $r.Result) 'Failure reached READY.'
        Assert-Test ($r.Error -like "*$($expectedErrors[$scenario])*") "Failed for an unexpected reason: $($r.Error)"
        if($scenario -in @('not-bound','stale-callback','honda-not-stopped','watchdog-failure','early-phone','short-safety-window')) {
            Assert-Test ($r.Session.CleanupAttempted -and $null -eq $r.Session.CleanupError) "Cleanup missing/failed: $($r.Session.CleanupError)"
            Assert-Test ($r.Simulation.Services -eq $r.Simulation.Original) 'Original service list not restored.'
        }
        if($scenario -eq 'cleanup-disconnect'){Assert-Test ($r.Session.CleanupAttempted -and $r.Session.CleanupError) 'Cleanup failure was not retained.'}
        if($scenario -eq 'external-settings-change'){Assert-Test ($r.Simulation.Services -eq 'org.new.accessibility/.KeepMe' -and $r.Simulation.Enabled -eq '0') 'Concurrent accessibility change was overwritten.'}
    }
}
Test-Case 'historical or malformed service records never prove active binding' {
    foreach($dump in @('ACTIVITY MANAGER SERVICES (dumpsys activity services)' + "`n  Last ANR service:`n  * ServiceRecord{abc u0 com.rdx.fullscreen.usbhelper/.PermissionClickService}`n    app=ProcessRecord{def 5278:com.rdx.fullscreen.usbhelper/u0a49}", 'Permission denied')) {
        $rejected=$false
        try {$null=Get-CTServicePid $dump 'PermissionClickService'} catch {$rejected=$true}
        Assert-Test $rejected 'Historical/unrecognized service dump accepted.'
    }
}
Test-Case 'full preparation accepts CRLF output' {
    $r=Run-Simulation 'success-crlf' "`r`n"
    Assert-Test ($null -eq $r.Error -and $r.Session.Status -eq 'READY') "CRLF rejected: $($r.Error)"
}
Test-Case 'full preparation accepts doubled-CR PTY output' {
    $r=Run-Simulation 'success-crcrlf' "`r`r`n"
    Assert-Test ($null -eq $r.Error -and $r.Session.Status -eq 'READY') "CRCRLF rejected: $($r.Error)"
}
Test-Case 'captured head-unit service dump yields the actual active PID' {
    $fixture=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'fixtures/api22-service-response.json') -Raw | ConvertFrom-Json
    $replay=@{Output=$fixture.Output}
    $transport={param([string[]]$Arguments)
        $null=$Arguments[-1] -match 'RDX_RC_[a-f0-9]+'
        [pscustomobject]@{ExitCode=0;Output=($replay.Output -replace 'RDX_RC_[a-f0-9]+',$Matches[0])}
    }.GetNewClosure()
    $context=[pscustomobject]@{Serial='00000000';Transport=$transport;Directory=$OutputDirectory}
    $text=Invoke-CTShell $context 'dumpsys activity services com.rdx.fullscreen.usbhelper/.PermissionClickService'
    Assert-Test ((Get-CTServicePid $text 'PermissionClickService') -eq 9135) 'Captured active service not recognized.'
    Assert-Test ($text -notmatch '\r') 'PTY carriage returns remain in parser input.'
}
Test-Case 'capture cleanup is scoped to the owned file and numeric PID' {
    $text=New-CTStopCaptureText '/data/local/tmp/rdx_fixture'
    Assert-Test ($text.Contains('/proc/$capture_pid/cmdline') -and $text.Contains("*'/data/local/tmp/rdx_fixture/capture.log'*)") -and $text.Contains('exit 9')) 'Capture identity check missing.'
    $r=Get-Content -LiteralPath (Join-Path $OutputDirectory 'not-bound/session.json') -Raw | ConvertFrom-Json
    Assert-Test $r.CaptureCleanupAttempted 'Failed preparation leaves owned capture unhandled.'
}
Test-Case 'cooperative setup leaves Honda running and starts no kill loop' {
    $r=Run-Simulation 'cooperative-success' "`r`r`n" $true
    Assert-Test ($null -eq $r.Error -and $r.Session.Status -eq 'READY') "Cooperative setup failed: $($r.Error)"
    $commands=($r.Simulation.Calls | ForEach-Object {$_ -join ' '}) -join "`n"
    Assert-Test ($commands -notmatch 'force-stop com.honda|nohup|/system/bin/sh.*kill-honda.sh') 'Honda suppression still executed.'
    Assert-Test ($commands -match 'usb.CONFIGURE_HONDA_NEVER' -and $commands -match 'fixture-phone') 'Device-scoped configuration not sent.'
    Assert-Test ($null -eq $r.Session.HondaRemainingSeconds -and $r.Session.SafetyRemainingSeconds -ge 30) 'Cleanup deadline lost or fake kill deadline reported.'
}
foreach($case in @('missing-policy-marker','legacy-side-effect')) {
    Test-Case "cooperative startup rejects $case" {
        $r=Run-Simulation $case "`n" $true
        Assert-Test ($r.Session.Status -eq 'FAILED' -and $r.Error -like '*Cooperative startup not confirmed*') 'Invalid cooperative startup reached READY.'
    }
}
Test-Case 'cooperative preflight rejects missing confirmation, identity and old APK' {
    foreach($argsCase in @(@($plan,'fixture-phone',$false),@($plan,'',$true),@([pscustomobject]@{CandidateRole='HistoricalBaseline';SourceDifferences=@();PhonePolicySupported=$false},'fixture-phone',$true))) {
        $rejected=$false
        try {Assert-CTPhonePreferencePlan $argsCase[0] $argsCase[1] $argsCase[2]} catch {$rejected=$true}
        Assert-Test $rejected 'Cooperative preflight accepted missing prerequisites.'
    }
}
Test-Case 'mismatched source cannot be called CurrentSource' {
    [IO.File]::WriteAllText($fixtureJava,'class Fixture { int changed; }')
    $rejected=$false
    try {$null=Get-CarTestArtifactPlan -RepoRoot $repoRoot -ApkPath $fixtureApk -ExpectedHash $fixtureHash -BuildReportPath $reportFile -CandidateRole CurrentSource} catch {$rejected=$true}
    Assert-Test $rejected 'Source mismatch accepted.'
    $baseline=Get-CarTestArtifactPlan -RepoRoot $repoRoot -ApkPath $fixtureApk -ExpectedHash $fixtureHash -BuildReportPath $reportFile -CandidateRole HistoricalBaseline
    Assert-Test (@($baseline.SourceDifferences).Count -eq 1) 'Historical difference not disclosed.'
}
Test-Case 'wrong pinned hash is rejected' {
    $rejected=$false
    try {$null=Get-CarTestArtifactPlan -RepoRoot $repoRoot -ApkPath $fixtureApk -ExpectedHash ('0'*64) -BuildReportPath $reportFile -CandidateRole HistoricalBaseline} catch {$rejected=$true}
    Assert-Test $rejected 'Wrong hash accepted.'
}
$summary=[ordered]@{scope='OFFLINE SIMULATIONS ONLY; zero device processes or commands executed';passed=@($results | Where-Object pass).Count;failed=@($results | Where-Object {-not $_.pass}).Count;tests=@($results)}
$summary | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $OutputDirectory 'results.json') -Encoding utf8
$summary | ConvertTo-Json -Depth 6
if($summary.failed -gt 0){throw "$($summary.failed) offline tests failed; see $OutputDirectory"}
