#Requires -Version 7.0
[CmdletBinding()]
param([string]$OutputDirectory = (Join-Path ([IO.Path]::GetTempPath()) ('rdx-public-host-' + [guid]::NewGuid().ToString('N'))))
$ErrorActionPreference='Stop'
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$javac=(Get-Command javac -ErrorAction Stop).Source
$java=(Get-Command java -ErrorAction Stop).Source
if(Test-Path -LiteralPath $OutputDirectory){throw 'Use a fresh host test output directory'}
$classes=Join-Path $OutputDirectory 'classes'
$null=New-Item -ItemType Directory -Path $classes
$sources=@(
    'analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/InputEvents.java',
    'analysis/parallel-aa-receiver/src/com/google/android/projection/protocol/PcmFrames.java',
    'analysis/parallel-aa-receiver/src/com/google/android/projection/protocol/AudioFocusPolicy.java',
    'tools/car-test/InputPcmTest.java'
) | ForEach-Object {Join-Path $root $_}
& $javac -d $classes @sources
if($LASTEXITCODE -ne 0){throw 'Host compilation failed'}
& $java -cp $classes InputPcmTest
if($LASTEXITCODE -ne 0){throw 'Host tests failed'}
