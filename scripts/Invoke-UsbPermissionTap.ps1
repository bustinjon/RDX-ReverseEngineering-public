<#
.SYNOPSIS
    Auto-press OK on the UsbPermissionActivity dialog via ADB keyevent.

    This bypasses the car touchscreen entirely. When the dialog appears,
    it sends DPAD_CENTER (hardware enter) to press the focused button.

.DESCRIPTION
    The UsbPermissionActivity dialog on the RDX head unit seems to have
    touch handling issues — the user can see and tap the dialog but the
    permission callback always returns denied. This script watches logcat
    for the dialog to appear and sends keyevent input to press OK.

    The dialog is an AlertActivity with positive (OK) and negative (Cancel)
    buttons. On API 22, the positive button typically has initial focus.

.PARAMETER Serial
    ADB device serial number.

.PARAMETER Adb
    Path to adb.exe
#>
param(
    [string]$Serial = '00000000',
    [string]$Adb = "$PSScriptRoot\..\adb\adb.exe"
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $Adb)) {
    Write-Error "adb.exe not found at $Adb"
    return
}

function Invoke-Adb {
    param([string[]]$Args)
    $result = & $Adb -s $Serial @Args 2>&1
    return $result
}

Write-Host "=== USB Permission Auto-Tap ===" -ForegroundColor Cyan
Write-Host "Monitoring logcat for UsbPermissionActivity..." -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop." -ForegroundColor DarkGray
Write-Host ""

# Clear logcat buffer to only see new events
Invoke-Adb 'logcat', '-c' | Out-Null

$tapCount = 0
$maxTaps = 10

# Monitor logcat for the permission dialog being displayed
$process = Start-Process -FilePath $Adb -ArgumentList @(
    '-s', $Serial, 'logcat', '-v', 'time',
    'ActivityManager:I', 'RDX.USB:I', '*:S'
) -NoNewWindow -PassThru -RedirectStandardOutput "$env:TEMP\rdx-usb-logcat.txt"

try {
    $lastSize = 0
    while ($tapCount -lt $maxTaps -and -not $process.HasExited) {
        Start-Sleep -Milliseconds 300

        if (-not (Test-Path "$env:TEMP\rdx-usb-logcat.txt")) { continue }

        $content = Get-Content "$env:TEMP\rdx-usb-logcat.txt" -Raw -ErrorAction SilentlyContinue
        if (-not $content -or $content.Length -eq $lastSize) { continue }

        $newContent = $content.Substring($lastSize)
        $lastSize = $content.Length

        # Check for dialog appearing
        if ($newContent -match 'Displayed com\.android\.systemui/\.usb\.UsbPermissionActivity') {
            $tapCount++
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Dialog appeared! Sending OK keyevent (#$tapCount)..." -ForegroundColor Green

            # Small delay to let the dialog fully render
            Start-Sleep -Milliseconds 500

            # Strategy 1: Try DPAD_CENTER (select focused item)
            Write-Host "  Sending KEYCODE_DPAD_CENTER (23)..." -ForegroundColor DarkCyan
            Invoke-Adb 'shell', 'input', 'keyevent', '23'
            Start-Sleep -Milliseconds 200

            # Strategy 2: If that didn't work, try TAB then ENTER
            # (TAB moves focus between buttons, ENTER activates)
            Write-Host "  Sending KEYCODE_TAB (61) + KEYCODE_ENTER (66)..." -ForegroundColor DarkCyan
            Invoke-Adb 'shell', 'input', 'keyevent', '61'
            Start-Sleep -Milliseconds 100
            Invoke-Adb 'shell', 'input', 'keyevent', '66'

            Write-Host "  Keyevents sent. Checking result..." -ForegroundColor Yellow
        }

        # Check for permission result
        if ($newContent -match 'Permission callback: granted=(\w+) verified=(\w+)') {
            $granted = $Matches[1]
            $verified = $Matches[2]
            if ($granted -eq 'true' -and $verified -eq 'true') {
                Write-Host "`n*** SUCCESS: Permission GRANTED! ***" -ForegroundColor Green
                break
            } else {
                Write-Host "  Result: granted=$granted verified=$verified" -ForegroundColor Red
            }
        }

        if ($newContent -match 'DIRECT GRANT SUCCEEDED') {
            Write-Host "`n*** SUCCESS via direct grant! ***" -ForegroundColor Green
            break
        }

        if ($newContent -match 'FAILED after \d+ attempts') {
            Write-Host "`nAll attempts failed." -ForegroundColor Red
            break
        }

        # Print RDX.USB lines
        foreach ($line in ($newContent -split "`n")) {
            if ($line -match 'RDX\.USB') {
                Write-Host "  $($line.Trim())" -ForegroundColor DarkGray
            }
        }
    }
} finally {
    if (-not $process.HasExited) {
        $process.Kill()
    }
    Remove-Item "$env:TEMP\rdx-usb-logcat.txt" -ErrorAction SilentlyContinue
}

Write-Host "`nDone. Tapped $tapCount time(s)." -ForegroundColor Cyan
