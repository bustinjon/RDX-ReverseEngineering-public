param([Parameter(Mandatory=$true)][string]$Journal,[Parameter(Mandatory=$true)][string]$Summary,[Parameter(Mandatory=$true)][string]$Output)
$ErrorActionPreference='Stop';$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent;$p="$root/analysis/parallel-aa-receiver/m6-aoa";$f=Get-Content "$p/FROZEN.json" -Raw|ConvertFrom-Json
if(-not(Test-Path -LiteralPath $Journal)-or-not(Test-Path -LiteralPath $Summary)-or(Get-Item -LiteralPath $Journal).Length-eq0-or(Get-Item -LiteralPath $Summary).Length-eq0){[ordered]@{schema=1;verdict='INCONCLUSIVE_MISSING_EVIDENCE';automaticM7=$false;retryStart=$false}|ConvertTo-Json|Set-Content -LiteralPath $Output;Write-Output 'INCONCLUSIVE: preserve retrieval failure evidence; no retry';return}
& 'C:/Program Files/Eclipse Adoptium/jdk-17.0.20.101-hotspot/bin/java.exe' -cp "$($f.build)/host" M6EvidenceTool $Journal $Summary $Output
if($LASTEXITCODE-ne0){throw 'M6 evidence checksum/order/accounting not valid; preserve and review'}
