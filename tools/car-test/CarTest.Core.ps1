# Local functions only. Importing this file never invokes a device command.
Set-StrictMode -Version Latest
$script:CTPackage = 'com.rdx.fullscreen.usbhelper'
$script:CTComponent = 'com.rdx.fullscreen.usbhelper/com.rdx.fullscreen.usbhelper.PermissionClickService'

function Get-CarTestArtifactPlan {
    param([string]$RepoRoot, [string]$ApkPath, [string]$ExpectedHash, [string]$BuildReportPath,
        [ValidateSet('HistoricalBaseline','CurrentSource')][string]$CandidateRole)
    $root = (Resolve-Path -LiteralPath $RepoRoot).Path
    $apk = (Resolve-Path -LiteralPath $ApkPath).Path
    $reportPath = (Resolve-Path -LiteralPath $BuildReportPath).Path
    if ([IO.Path]::GetExtension($apk) -ne '.apk' -or [IO.Path]::GetExtension($reportPath) -ne '.json') { throw 'Expected APK and build-report JSON.' }
    $actual = (Get-FileHash -LiteralPath $apk -Algorithm SHA256).Hash
    $report = Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json
    if ($report.harness -ne 'usb-helper' -or $actual -ne $ExpectedHash -or $actual -ne $report.sha256) { throw 'Candidate APK/hash/build-report mismatch.' }
    if (@($report.sourceHashes).Count -eq 0) { throw 'Build report has no source provenance.' }
    $differences = @(foreach ($source in $report.sourceHashes) {
        $path = [IO.Path]::GetFullPath($source.Path)
        if (-not $path.StartsWith($root + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase) -or [IO.Path]::GetExtension($path) -ne '.java') { throw 'Source hash entry outside local Java scope.' }
        $hash = if (Test-Path -LiteralPath $path) { (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash } else { 'MISSING' }
        if ($hash -ne $source.Hash) { [pscustomobject]@{ Path=$path; Recorded=$source.Hash; Current=$hash } }
    })
    if ($CandidateRole -eq 'CurrentSource' -and $differences.Count -gt 0) { throw 'CurrentSource candidate does not match current Java inputs. Rebuild/review separately or explicitly select a historical baseline.' }
    [pscustomobject]@{ ApkPath=$apk; Sha256=$actual; BuildReport=$reportPath;
        BuildReportSha256=(Get-FileHash -LiteralPath $reportPath -Algorithm SHA256).Hash;
        CandidateRole=$CandidateRole; StaticAudit=$report.staticAudit; SourceCount=@($report.sourceHashes).Count;
        SourceDifferences=$differences; PhonePolicySupported=(@($report.sourceHashes | Where-Object { [IO.Path]::GetFileName($_.Path) -eq 'HondaPhonePolicy.java' }).Count -eq 1);
        SourceCoverage='Recorded Java inputs only; not a complete APK-input audit'; LiveReadiness='NOT_ESTABLISHED' }
}

function Assert-CTPhonePreferencePlan($Plan, [string]$PhoneSerial, [bool]$Confirmed) {
    if (-not $Confirmed) { throw 'Phone-scoped Honda Disable/Never must be confirmed by the operator.' }
    if ($PhoneSerial -notmatch '^[A-Za-z0-9._-]{1,64}$') { throw 'Explicit valid phone serial required.' }
    if ($Plan.CandidateRole -ne 'CurrentSource' -or @($Plan.SourceDifferences).Count -ne 0 -or -not $Plan.PhonePolicySupported) {
        throw 'PhonePreference requires a matching CurrentSource APK containing HondaPhonePolicy; the historical APK is incompatible.'
    }
}

function ConvertTo-CarTestServiceList([string]$Value) {
    if ($Value -eq 'null' -or $Value -eq '') { return @() }
    $items = @($Value.Split(':'))
    foreach ($item in $items) {
        if ($item -notmatch '^[A-Za-z0-9_.]+/[A-Za-z0-9_.$]+$') { throw 'Unrecognized accessibility settings; refusing to overwrite.' }
    }
    return $items
}

function Test-CarTestOwnComponent([string]$Value) {
    $Value -in @($script:CTComponent, "$script:CTPackage/.PermissionClickService")
}

function Invoke-CTCommand($Context, [string[]]$Arguments) {
    $argsWithTarget = @('-s', $Context.Serial) + $Arguments
    try { $result = & $Context.Transport -Arguments $argsWithTarget }
    catch { $result = [pscustomobject]@{ ExitCode=-1; Output=$_.Exception.Message } }
    [ordered]@{ utc=[DateTime]::UtcNow.ToString('o'); arguments=$argsWithTarget; result=$result } |
        ConvertTo-Json -Depth 6 -Compress | Add-Content -LiteralPath (Join-Path $Context.Directory 'commands.jsonl') -Encoding utf8
    if ($null -eq $result -or $result.ExitCode -ne 0) { throw "Command failed: $($Arguments[0])" }
    return [string]$result.Output
}

function Invoke-CTShell($Context, [string]$Command) {
    # API22 adb shell may return host exit 0 even when the remote command fails.
    $marker = 'RDX_RC_' + [guid]::NewGuid().ToString('N')
    $wrapped = "( $Command ); rdx_rc=`$?; echo; echo `"${marker}:`$rdx_rc`""
    $output = Invoke-CTCommand $Context @('shell', $wrapped)
    # API22's legacy PTY can translate CRLF twice. Preserve raw journal output,
    # normalize only the text passed to the readiness parsers.
    $output = $output -replace '\r+\n', "`n"
    $match = [regex]::Match($output, '(?s)^(.*)\r?\n' + $marker + ':(\d+)\s*$')
    if (-not $match.Success -or $match.Groups[2].Value -ne '0') { throw "Remote command failed or omitted exit status: $Command" }
    $text = $match.Groups[1].Value.Trim()
    if ($text -match '(?im)^\s*(Error:|Failure\b|SecurityException|java\.lang\.SecurityException|Permission denied|.*: not found\s*$)') { throw "Remote error: $text" }
    return $text
}

function Get-CTServicePid([string]$Text, [string]$Service) {
    if ($Text -notmatch '^ACTIVITY MANAGER SERVICES') { throw 'Unrecognized service dump.' }
    $record = [regex]::Escape("$script:CTPackage/.$Service")
    $active = [regex]::Match($Text, '(?ms)^  User 0 active services:\r?\n(.*?)(?=^  [A-Za-z]|\z)').Groups[1].Value
    if ([regex]::Matches($active, "(?m)^\s*\* ServiceRecord\{[^\r\n}]*\s$record\}").Count -ne 1) {
        if ($Text -match 'ServiceRecord|ProcessRecord') { throw 'Service record is ambiguous, historical, or outside the active user-0 section.' }
        return 0
    }
    $pids = [regex]::Matches($active, 'app=ProcessRecord\{[^\r\n}]*\s(\d+):' + [regex]::Escape($script:CTPackage) + '/u0a\d+\}')
    if ($pids.Count -ne 1) { throw 'Service exists without one confirmed application process.' }
    return [int]$pids[0].Groups[1].Value
}

function Assert-CTAccessibility([string]$Dump, [string]$Events, [int]$ProcessId) {
    # Firmware dumps bound services by label, not component (AMS:1304-1327,2046-2054).
    # Pair this with an exact component/process dump and fresh onServiceConnected callback.
    $user = [regex]::Match($Dump, '(?s)User state\[attributes:\{id=0, currentUser=true, accessibilityEnabled=true[^\r\n]*\}\s*services:\{(.*?)\}\]')
    if (-not $user.Success -or $user.Groups[1].Value -notmatch 'Service\[label=RDX USB,') { throw 'Helper not confirmed in current user accessibility bound-services dump.' }
    if ($Events -notmatch ('(?m)^\d\d-\d\d\s+\S+\s+' + $ProcessId + '\s+\d+\s+I\s+RDX\.A11Y\s*:.*PermissionClickService connected')) { throw 'No fresh accessibility connection callback for the active helper process.' }
}

function Get-CTEvents($Context) {
    $text = Invoke-CTShell $Context "logcat -d -v threadtime -s RDX.PREP:I RDX.A11Y:I RDX.USB:I '*:S'"
    $marker = "RDX.PREP: $($Context.RunId)"
    $start = $text.LastIndexOf($marker, [StringComparison]::Ordinal)
    if ($start -lt 0) { throw 'Fresh capture boundary missing.' }
    return $text.Substring($start + $marker.Length)
}

function Wait-CTCondition($Context, [scriptblock]$Condition, [string]$Description) {
    $last = ''
    for ($attempt=0; $attempt -lt 10; $attempt++) {
        try { return (& $Condition) } catch { $last = $_.Exception.Message }
        & $Context.Delay 300
    }
    throw "$Description failed: $last"
}

function New-CTStopCaptureText([string]$RemoteDirectory) {
    @'
if [ -s '__DIR__/capture.pid' ]; then
  capture_pid=$(cat '__DIR__/capture.pid')
  case "$capture_pid" in ''|*[!0-9]*) exit 7 ;; esac
  if kill -0 "$capture_pid" 2>/dev/null; then
    capture_command=$(cat "/proc/$capture_pid/cmdline")
    case "$capture_command" in
      *'__DIR__/capture.log'*) kill "$capture_pid" || exit 8 ;;
      *) echo CAPTURE_PID_IDENTITY_MISMATCH; exit 9 ;;
    esac
  fi
fi
'@.Replace('__DIR__',$RemoteDirectory)
}

function New-CTCleanupText([string]$RemoteDirectory, [string]$OriginalServices, [string]$OriginalEnabled, [string]$WrittenServices) {
    $restoreServices = if ($OriginalServices -eq 'null') { 'settings delete secure enabled_accessibility_services' } else { "settings put secure enabled_accessibility_services '$OriginalServices'" }
    $restoreEnabled = if ($OriginalEnabled -eq 'null') { 'settings delete secure accessibility_enabled' } else { "settings put secure accessibility_enabled '$OriginalEnabled'" }
    @'
#!/system/bin/sh
dir='__DIR__'
: > "$dir/cancel"
am force-stop com.rdx.fullscreen.usbhelper || exit 4
# Restore only our exact write; preserve settings changed subsequently by someone else.
current=$(settings get secure enabled_accessibility_services)
if [ "$current" = '__WRITTEN__' ]; then
  __RESTORE_SERVICES__ || exit 5
  if [ "$(settings get secure accessibility_enabled)" = '1' ]; then
    __RESTORE_ENABLED__ || exit 6
  fi
  echo ACCESSIBILITY_RESTORED
else
  echo ACCESSIBILITY_NOT_RESTORED_SETTINGS_CHANGED
fi
echo CLEANUP_FINISHED
__STOP_CAPTURE__
'@.Replace('__DIR__',$RemoteDirectory).Replace('__WRITTEN__',$WrittenServices).Replace('__RESTORE_SERVICES__',$restoreServices).Replace('__RESTORE_ENABLED__',$restoreEnabled).Replace('__STOP_CAPTURE__',(New-CTStopCaptureText $RemoteDirectory))
}

function Invoke-CarTestPreparation {
    param($Plan, [ValidateSet('00000000')][string]$Serial, [ValidateRange(60,300)][int]$SafetySeconds,
        [string]$RunDirectory, [string]$RepoRoot, [Parameter(Mandatory)][scriptblock]$Transport,
        [ValidateSet('ForceStop','PhonePreference')][string]$HondaStrategy='ForceStop',
        [string]$PhoneSerial='', [bool]$HondaPhoneDisabled=$false,
        [scriptblock]$Delay = { param($Milliseconds) Start-Sleep -Milliseconds $Milliseconds })
    $context = [pscustomobject]@{ Serial=$Serial; Transport=$Transport; Delay=$Delay; Directory=$RunDirectory; RunId=('rdx_' + [guid]::NewGuid().ToString('N')) }
    $remote = '/data/local/tmp/' + $context.RunId
    $state = [ordered]@{ Status='PREPARING'; RunId=$context.RunId; Serial=$Serial; RemoteDirectory=$remote; Candidate=$Plan; OriginalServices=$null; OriginalEnabled=$null; CleanupAttempted=$false; CleanupError=$null }
    $cleanupUploaded = $false
    $captureLaunched = $false
    $settingsChanged = $false
    $originalServices = $null
    $originalEnabled = $null
    $writtenServices = $null
    try {
        if ($HondaStrategy -eq 'PhonePreference') { Assert-CTPhonePreferencePlan $Plan $PhoneSerial $HondaPhoneDisabled }
        $state.HondaStrategy=$HondaStrategy
        $state.PhonePreferenceOperatorConfirmed=$HondaPhoneDisabled
        $state.ToolHashes = @(foreach ($relative in @('scripts/Run-CarTest.ps1','tools/car-test/CarTest.Core.ps1','scripts/device-kill-honda.sh','scripts/device-car-test-watchdog.sh')) {
            [pscustomobject]@{ Path=$relative; Sha256=(Get-FileHash -LiteralPath (Join-Path $RepoRoot $relative) -Algorithm SHA256).Hash }
        })
        if ((Get-FileHash -LiteralPath $Plan.ApkPath -Algorithm SHA256).Hash -ne $Plan.Sha256 -or
            (Get-FileHash -LiteralPath $Plan.BuildReport -Algorithm SHA256).Hash -ne $Plan.BuildReportSha256) { throw 'Artifact changed after preparation.' }
        $null = Get-CarTestArtifactPlan -RepoRoot $RepoRoot -ApkPath $Plan.ApkPath -ExpectedHash $Plan.Sha256 -BuildReportPath $Plan.BuildReport -CandidateRole $Plan.CandidateRole
        if ((Invoke-CTCommand $context @('get-state')).Trim() -ne 'device') { throw 'Head unit is not online.' }
        if ((Invoke-CTShell $context 'getprop ro.serialno') -ne $Serial) { throw 'Target identity mismatch.' }
        if ((Invoke-CTShell $context 'dumpsys accessibility') -notmatch 'User state\[attributes:\{id=0, currentUser=true,') { throw 'Only a confirmed current user 0 is supported.' }
        $originalServices = Invoke-CTShell $context 'settings get secure enabled_accessibility_services'
        $originalEnabled = Invoke-CTShell $context 'settings get secure accessibility_enabled'
        $services = @(ConvertTo-CarTestServiceList $originalServices)
        if ($originalEnabled -notin @('null','0','1')) { throw 'Unknown accessibility_enabled state.' }
        $state.OriginalServices = $originalServices
        $state.OriginalEnabled = $originalEnabled
        $others = @($services | Where-Object { -not (Test-CarTestOwnComponent $_) })
        $writtenServices = ($others + $script:CTComponent) -join ':'
        $installed = Invoke-CTCommand $context @('install','-r',$Plan.ApkPath)
        if ($installed -notmatch '(?m)^Success\s*$' -or $installed -match '(?i)Failure|Error:') { throw 'Installation did not succeed.' }
        $packagePath = Invoke-CTShell $context "pm path $script:CTPackage"
        if ($packagePath -notmatch '^package:(/data/app/[A-Za-z0-9_./-]+\.apk)$') { throw 'Expected one installed helper APK under /data/app.' }
        $remoteApk = $Matches[1]
        $installedCopy = Join-Path $RunDirectory 'installed.apk'
        $null = Invoke-CTCommand $context @('pull',$remoteApk,$installedCopy)
        $state.InstalledSha256 = (Get-FileHash -LiteralPath $installedCopy -Algorithm SHA256).Hash
        if ($state.InstalledSha256 -ne $Plan.Sha256) { throw 'Installed APK differs from the selected candidate.' }
        foreach ($service in @('UsbHelperService','AaSessionService','AaOverlayService')) {
            $null = Invoke-CTShell $context "am stopservice -n $script:CTPackage/.$service"
            $null = Wait-CTCondition $context { if ((Get-CTServicePid (Invoke-CTShell $context "dumpsys activity services $script:CTPackage/.$service") $service) -ne 0) { throw 'Old service remains active.' } } "Stop $service"
        }
        $null = Invoke-CTShell $context "mkdir '$remote'"
        # Set HUP disposition before fork; an external executable closes mksh's saved FDs.
        $null = Invoke-CTShell $context "trap '' HUP; /system/bin/logcat -v threadtime -f '$remote/capture.log' > '$remote/capture-launch.log' 2>&1 < /dev/null & echo `$! > '$remote/capture.pid'"
        $captureLaunched = $true
        $null = Wait-CTCondition $context { $null = Invoke-CTShell $context "test -s '$remote/capture.pid' && kill -0 `$(cat '$remote/capture.pid') && test -s '$remote/capture.log'" } 'Capture start'
        $settingsChanged = $true
        $null = Invoke-CTShell $context "settings put secure enabled_accessibility_services '$($others -join ':')'"
        $null = Wait-CTCondition $context { if ((Get-CTServicePid (Invoke-CTShell $context "dumpsys activity services $script:CTPackage/.PermissionClickService") 'PermissionClickService') -ne 0) { throw 'Accessibility service did not unbind.' } } 'Fresh accessibility unbind'
        $null = Invoke-CTShell $context "log -p i -t RDX.PREP '$($context.RunId)'"
        $null = Invoke-CTShell $context "settings put secure enabled_accessibility_services '$writtenServices'"
        $null = Invoke-CTShell $context 'settings put secure accessibility_enabled 1'
        $checkAccessibility = {
            if ((Invoke-CTShell $context 'settings get secure enabled_accessibility_services') -ne $writtenServices -or
                (Invoke-CTShell $context 'settings get secure accessibility_enabled') -ne '1') { throw 'Accessibility settings did not persist.' }
            $processId = Get-CTServicePid (Invoke-CTShell $context "dumpsys activity services $script:CTPackage/.PermissionClickService") 'PermissionClickService'
            if ($processId -le 0) { throw 'Accessibility component is not running.' }
            Assert-CTAccessibility (Invoke-CTShell $context 'dumpsys accessibility') (Get-CTEvents $context) $processId
        }
        $null = Wait-CTCondition $context $checkAccessibility 'Accessibility binding'
        if ($HondaStrategy -eq 'ForceStop') {
            $null = Invoke-CTShell $context 'am force-stop com.honda.androidauto.projection.sink'
            $honda = Invoke-CTShell $context 'dumpsys package com.honda.androidauto.projection.sink'
            if ($honda -notmatch '(?m)^\s*User 0:[^\r\n]*\bstopped=true\b') { throw 'Honda stopped state not confirmed.' }
        }
        $cleanupFile = Join-Path $RunDirectory 'cleanup.sh'
        [IO.File]::WriteAllText($cleanupFile, (New-CTCleanupText $remote $originalServices $originalEnabled $writtenServices).Replace("`r`n","`n") + "`n", [Text.UTF8Encoding]::new($false))
        foreach ($pair in @(@($cleanupFile,'cleanup.sh'),@((Join-Path $RepoRoot 'scripts/device-car-test-watchdog.sh'),'watchdog.sh'),@((Join-Path $RepoRoot 'scripts/device-kill-honda.sh'),'kill-honda.sh'))) {
            $null = Invoke-CTCommand $context @('push',$pair[0],"$remote/$($pair[1])")
            if ($pair[1] -eq 'cleanup.sh') { $cleanupUploaded = $true }
        }
        # Start cleanup clock after slow preparation, before starting the helper.
        $null = Invoke-CTShell $context "trap '' HUP; /system/bin/sh '$remote/watchdog.sh' '$remote' $SafetySeconds > '$remote/watchdog.log' 2>&1 < /dev/null & echo `$! > '$remote/watchdog.pid'"
        $null = Wait-CTCondition $context { $null = Invoke-CTShell $context "kill -0 `$(cat '$remote/watchdog.pid') && test -s '$remote/deadline'" } 'Watchdog start'
        $action = if ($HondaStrategy -eq 'PhonePreference') { "-a usb.CONFIGURE_HONDA_NEVER --es phoneSerial '$PhoneSerial' " } elseif ($Plan.PhonePolicySupported) { '-a usb.CONFIGURE_LEGACY ' } else { '' }
        $start = Invoke-CTShell $context "am startservice ${action}-n $script:CTPackage/.UsbHelperService"
        if ($start -notmatch 'Starting service:') { throw 'Helper start was not acknowledged.' }
        $null = Wait-CTCondition $context {
            $processId = Get-CTServicePid (Invoke-CTShell $context "dumpsys activity services $script:CTPackage/.UsbHelperService") 'UsbHelperService'
            $events = Get-CTEvents $context
            if ($HondaStrategy -eq 'PhonePreference' -and ($events -notmatch 'HONDA_PHONE_NEVER_V1' -or $events -match 'POLICY_REJECTED|Attempting am force-stop|Attempting VBUS reset')) {
                throw 'Cooperative startup not confirmed or legacy side effects detected.'
            }
            if ($processId -le 0 -or $events -notmatch ('(?m)^\d\d-\d\d\s+\S+\s+' + $processId + '\s+\d+\s+I\s+RDX\.USB\s*:.*=== Service started') -or $events -notmatch 'RDX\.USB\s*:.*onStartCommand phase=0 action=') { throw 'Fresh WAITING helper instance not confirmed.' }
            if ($events -match 'RDX\.USB\s*:.*(device detected:|AUTO_GRANTED|Requesting permission|Handing off to)') { throw 'Phone activity occurred before readiness; unplug and start a separate attempt.' }
        } 'Fresh helper start'
        $null = & $checkAccessibility
        if ($HondaStrategy -eq 'ForceStop') {
            $null = Invoke-CTShell $context "trap '' HUP; /system/bin/sh '$remote/kill-honda.sh' '$remote' 30 > '$remote/honda-loop.log' 2>&1 < /dev/null & echo `$! > '$remote/honda.pid'"
            $null = Wait-CTCondition $context { $null = Invoke-CTShell $context "kill -0 `$(cat '$remote/honda.pid') && test -s '$remote/honda-deadline'" } 'Honda loop start'
        }
        $null = Invoke-CTShell $context "kill -0 `$(cat '$remote/capture.pid') && test -s '$remote/capture.log' && kill -0 `$(cat '$remote/watchdog.pid') && test ! -e '$remote/cancel'"
        $timingWatch = [Diagnostics.Stopwatch]::StartNew()
        $timingCommand = if ($HondaStrategy -eq 'ForceStop') { "cat '$remote/deadline' '$remote/honda-deadline'; cat /proc/uptime" } else { "cat '$remote/deadline'; cat /proc/uptime" }
        $timing = Invoke-CTShell $context $timingCommand
        $timingWatch.Stop()
        $format = if ($HondaStrategy -eq 'ForceStop') { '^(\d+)\s+(\d+)\s+(\d+(?:\.\d+)?)\s+\d+(?:\.\d+)?$' } else { '^(\d+)\s+(\d+(?:\.\d+)?)\s+\d+(?:\.\d+)?$' }
        if ($timing -notmatch $format) { throw 'Unrecognized device timing evidence.' }
        $deadline = [double]$Matches[1]
        $hondaDeadline = if ($HondaStrategy -eq 'ForceStop') { [double]$Matches[2] } else { $null }
        $now = [double]::Parse($Matches[$(if ($HondaStrategy -eq 'ForceStop') {3} else {2})], [Globalization.CultureInfo]::InvariantCulture)
        $roundTripReserve = [math]::Ceiling($timingWatch.Elapsed.TotalSeconds)
        $remaining = [math]::Floor($deadline - $now) - $roundTripReserve - 2
        $hondaRemaining = if ($HondaStrategy -eq 'ForceStop') { [math]::Floor($hondaDeadline - $now) - $roundTripReserve - 2 } else { $null }
        if ($remaining -lt 30 -or ($HondaStrategy -eq 'ForceStop' -and $hondaRemaining -lt 15)) { throw 'Insufficient remaining test window; readiness refused.' }
        $state.Status = 'READY'
        $state.SafetyRemainingSeconds = $remaining
        $state.HondaRemainingSeconds = $hondaRemaining
        $state.DeviceUptimeAtReadiness = $now
        $state.TimingRoundTripReserveSeconds = $roundTripReserve
        $state.ReadinessSampleUtc = [DateTime]::UtcNow.ToString('o')
        return [pscustomobject]$state
    } catch {
        $state.Status = 'FAILED'
        $state.Error = $_.Exception.Message
        if ($settingsChanged) {
            $state.CleanupAttempted = $true
            try {
                if ($cleanupUploaded) { $null = Invoke-CTShell $context "sh '$remote/cleanup.sh'" }
                else {
                    $null = Invoke-CTShell $context 'am force-stop com.rdx.fullscreen.usbhelper'
                    $current = Invoke-CTShell $context 'settings get secure enabled_accessibility_services'
                    if ($current -in @($writtenServices, ($others -join ':'))) {
                        $restore = if ($originalServices -eq 'null') { 'settings delete secure enabled_accessibility_services' } else { "settings put secure enabled_accessibility_services '$originalServices'" }
                        $null = Invoke-CTShell $context $restore
                        if ((Invoke-CTShell $context 'settings get secure accessibility_enabled') -eq '1') {
                            $restore = if ($originalEnabled -eq 'null') { 'settings delete secure accessibility_enabled' } else { "settings put secure accessibility_enabled '$originalEnabled'" }
                            $null = Invoke-CTShell $context $restore
                        }
                    }
                }
            } catch { $state.CleanupError = $_.Exception.Message }
        }
        if ($captureLaunched) {
            $state.CaptureCleanupAttempted = $true
            try { $null = Invoke-CTShell $context (New-CTStopCaptureText $remote) }
            catch { $state.CaptureCleanupError = $_.Exception.Message }
        }
        throw
    } finally {
        $state | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $RunDirectory 'session.json') -Encoding utf8
    }
}
