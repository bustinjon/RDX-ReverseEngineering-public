$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../../..')).Path
$source = Join-Path $repoRoot 'analysis/parallel-aa-receiver/usb-helper/source/com/rdx/fullscreen/usbhelper/AaSessionService.java'
$jdkBin = 'C:/Program Files/Eclipse Adoptium/jdk-17.0.20.101-hotspot/bin'
$output = Join-Path $PSScriptRoot 'classes'
$before = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
New-Item -ItemType Directory -Path $output -Force | Out-Null
$probeSources = @(Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'src') -Recurse -Filter '*.java' | ForEach-Object FullName)
& (Join-Path $jdkBin 'javac.exe') -Xlint:-options -source 7 -target 7 -d $output @probeSources $source
if ($LASTEXITCODE -ne 0) { throw 'Host probe compilation failed' }
& (Join-Path $jdkBin 'java.exe') -cp $output SessionFailureProbe | Tee-Object -FilePath (Join-Path $PSScriptRoot 'results.txt')
if ($LASTEXITCODE -ne 0) { throw 'Host counterexample assertions failed' }
$after = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
if ($before -ne $after) { throw 'Inspected session source changed during probe' }
'Source unchanged: ' + $after
