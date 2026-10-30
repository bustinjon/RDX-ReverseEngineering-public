#Requires -Version 7.0
[CmdletBinding()]
param([Parameter(Mandatory)][string]$OutputDirectory)
$ErrorActionPreference='Stop'
$repoRoot=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
if(Test-Path -LiteralPath $OutputDirectory){throw 'Use a fresh output directory'}
$testClasses=Join-Path ([IO.Path]::GetFullPath($OutputDirectory)) 'classes'
$null=New-Item -ItemType Directory -Path $testClasses
$javaHome='C:/Program Files/Eclipse Adoptium/jdk-17.0.20.101-hotspot'
$source=Join-Path $repoRoot 'analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/VideoGeometry.java'
& "$javaHome/bin/javac.exe" -encoding UTF-8 -source 7 -target 7 -d $testClasses $source (Join-Path $PSScriptRoot 'VideoGeometryTest.java') *> (Join-Path $OutputDirectory 'javac.log')
if($LASTEXITCODE -ne 0){throw 'Geometry test compilation failed'}
$result=& "$javaHome/bin/java.exe" -cp $testClasses VideoGeometryTest 2>&1 | Out-String
$result | Set-Content -LiteralPath (Join-Path $OutputDirectory 'results.txt')
if($LASTEXITCODE -ne 0){throw $result}
$result
