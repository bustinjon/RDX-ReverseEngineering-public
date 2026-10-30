param([string]$Output)
$ErrorActionPreference='Stop';$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$project=Join-Path $root 'analysis/parallel-aa-receiver/m5-permission';$apk=Join-Path $project 'build/20261023-180320-335/rdx-m5-permission-0.2.0-m5-single-port-300s-development.apk';$expected='A22E96490B9557AFF022893A8B8B7A08BB13CEC236E52704CDDAFA90A8EE8F40'
if((Get-FileHash -LiteralPath $apk).Hash-ne$expected){throw 'STOP: frozen M5 hash mismatch; do not rebuild or install'}
$auditDir=(Get-Content "$project/latest-audit.txt" -Raw).Trim();$audit=Get-Content "$auditDir/audit.json" -Raw|ConvertFrom-Json
if(-not$audit.PASS-or$audit.sha256-ne$expected){throw 'Matching final independent APK audit missing'}
$aapt='C:/Program Files (x86)/Android/android-sdk/build-tools/32.0.0/aapt.exe';$badging=& $aapt dump badging $apk
if($LASTEXITCODE-ne0-or($badging-join"`n")-notmatch"package: name='com.rdx.fullscreen.m5permission' versionCode='3' versionName='0.2.0-m5-single-port-300s'"){throw 'Frozen package/version mismatch'}
if(@(Get-Content "$auditDir/dexdump.txt"|Where-Object {$_-match'invoke-.*Landroid/hardware/usb/UsbManager;\.requestPermission:'}).Count-ne1){throw 'Expected exactly one SDK permission invoke'}
$r=[ordered]@{PASS=$true;scope='OFFLINE ONLY: no ADB invocation or installation';apk=$apk;sha256=$expected;package='com.rdx.fullscreen.m5permission';version='0.2.0-m5-single-port-300s';service='com.rdx.fullscreen.m5permission/.PermissionService';windowSeconds=300;targetVID=6353;targetPID=11521;adb=Join-Path $root 'adb/adb.exe';adbPathExists=Test-Path (Join-Path $root 'adb/adb.exe');independentAudit=$auditDir;ready='One fresh install and one explicit run only; operator/cable/phone/UI ready BEFORE ARM'}
if($Output){$r|ConvertTo-Json|Set-Content -LiteralPath $Output};$r|ConvertTo-Json
