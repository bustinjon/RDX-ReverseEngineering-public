#Requires -Version 7.0
[CmdletBinding()]
param([string]$OutputDirectory=(Join-Path ([IO.Path]::GetTempPath()) ('rdx-public-changes-'+[guid]::NewGuid().ToString('N'))))
$ErrorActionPreference='Stop'
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$javac=(Get-Command javac -ErrorAction Stop).Source
$java=(Get-Command java -ErrorAction Stop).Source
if(Test-Path $OutputDirectory){throw 'Use a fresh output directory'}
$mediaClasses=Join-Path $OutputDirectory 'media-classes'
$navSource=Join-Path $OutputDirectory 'navigation-source/com/google/android/projection/protocol'
$navClasses=Join-Path $OutputDirectory 'navigation-classes'
New-Item -ItemType Directory -Path $mediaClasses,$navSource,$navClasses | Out-Null
$helper=Join-Path $root 'analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper'
& $javac -source 7 -target 7 -d $mediaClasses (Join-Path $helper 'InputEvents.java') (Join-Path $helper 'VolumeFeedback.java') (Join-Path $root 'analysis/test-prep/media-input-fixes-20261031/MediaInputTest.java')
if($LASTEXITCODE){throw 'Media/input host compile failed'}
& $java -cp $mediaClasses com.rdx.fullscreen.usbhelper.MediaInputTest
if($LASTEXITCODE){throw 'Media/input host checks failed'}
# Real navigation callback source; replace only its native endpoint in a fixture copy.
$gal=Get-Content (Join-Path $root 'analysis/parallel-aa-receiver/src/com/google/android/projection/protocol/GalReceiver.java') -Raw
$seam='private native void nativeSetNavFocus(int state);'
if(([regex]::Matches($gal,[regex]::Escape($seam))).Count -ne 1){throw 'Expected one native fixture endpoint'}
$gal.Replace($seam,'private void nativeSetNavFocus(int state) { NavigationFocusTest.recordNative(state); }') |
    Set-Content (Join-Path $navSource 'GalReceiver.java') -Encoding utf8
Copy-Item (Join-Path $root 'analysis/test-prep/maps-nav-focus-20261031/NavigationFocusTest.java') $navSource
foreach($type in @('VideoSink','InputSource','AudioSink','AudioSource','SensorSource')){
    "package com.google.android.projection.protocol; final class $type { public long handle(){return 0;} }" |
        Set-Content (Join-Path $navSource ($type+'.java')) -Encoding utf8
}
$inputs=@(Get-ChildItem $navSource -Filter '*.java' | ForEach-Object FullName)
& $javac -source 7 -target 7 -d $navClasses @inputs
if($LASTEXITCODE){throw 'Navigation-focus host compile failed'}
& $java -cp $navClasses com.google.android.projection.protocol.NavigationFocusTest
if($LASTEXITCODE){throw 'Navigation-focus host checks failed'}
Write-Output 'Host-only checks complete; no native library, credentials, device commands or hardware proof.'
