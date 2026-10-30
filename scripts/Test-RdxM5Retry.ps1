$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$project=Join-Path $root 'analysis/parallel-aa-receiver/m5-permission'
$session=(Get-Content "$project/latest-retry-session.txt" -Raw).Trim()
$run=Join-Path $session ('host-'+(Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
New-Item -ItemType Directory -Path $run,"$run/classes","$run/data" | Out-Null
$java='C:/Program Files/Eclipse Adoptium/jdk-17.0.20.101-hotspot/bin'
$source=Join-Path $project 'source/com/rdx/fullscreen/m5permission'
$inputs=@("$source/PermissionMachine.java","$source/PrivateJournal.java","$project/tests/com/rdx/fullscreen/m5permission/PermissionTests.java")
& "$java/javac.exe" -encoding UTF-8 -source 7 -target 7 -d "$run/classes" @inputs *> "$run/javac.log"
if($LASTEXITCODE -ne 0){Get-Content "$run/javac.log";throw 'Host compilation failed'}
& "$java/java.exe" -cp "$run/classes" com.rdx.fullscreen.m5permission.PermissionTests "$run/data" *> "$run/tests.log"
if($LASTEXITCODE -ne 0){Get-Content "$run/tests.log";throw 'Host simulation failed'}
$result=[ordered]@{PASS=$true;scope='OFFLINE synthetic identities/clocks/callbacks and project-local journal files only';run=$run;inputHashes=@(Get-FileHash $inputs);output=(Get-Content "$run/tests.log" -Raw)}
$result|ConvertTo-Json -Depth 6|Set-Content "$run/result.json"
Set-Content "$project/latest-host-test.txt" $run
Get-Content "$run/tests.log"
