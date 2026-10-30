$ErrorActionPreference = 'Stop'
$adbPath = (Resolve-Path -LiteralPath './adb/adb.exe').Path
$outputDirectory = './logs/2026-10-22-investigation'
# Transaction numbers verified against current honda-manager/services classes.dex.
# Deliberately excludes all setter, reload and reapply transactions.
function Read-FactoryParcel {
    param([ValidateSet(1,2,3,14)][int]$Transaction, [string]$Property)
    $adbArguments = @('shell','service','call','factorysettings',"$Transaction")
    if ($Transaction -eq 14) { $adbArguments += @('s16', $Property) }
    $parcelText = & $adbPath @adbArguments | Out-String
    $fileName = if ($Transaction -eq 14) { "factory-value-$Property.parcel.txt" } else { "factory-list-$Transaction.parcel.txt" }
    $parcelText | Set-Content -LiteralPath (Join-Path $outputDirectory $fileName)
    @{ arguments=$adbArguments; exitCode=$LASTEXITCODE; startedUtc=[DateTime]::UtcNow.ToString('o') } | ConvertTo-Json -Compress | Add-Content -LiteralPath (Join-Path $outputDirectory 'commands.jsonl')
    $bytes = [Collections.Generic.List[byte]]::new()
    foreach ($line in ($parcelText -split "`n")) {
        if ($line -match '^\s*0x[0-9a-fA-F]+:\s*(.*)' -or $line -match '^Result:\s*Parcel\((.*)') {
            $words = ($Matches[1] -split "'",2)[0]
            foreach ($word in [regex]::Matches($words,'\b[0-9a-fA-F]{8}\b')) {
                $bytes.AddRange([BitConverter]::GetBytes([Convert]::ToUInt32($word.Value,16)))
            }
        }
    }
    $stream = [IO.MemoryStream]::new($bytes.ToArray())
    $reader = [IO.BinaryReader]::new($stream)
    try {
        $exceptionCode = $reader.ReadInt32()
        if ($exceptionCode -ne 0) { throw "Binder exception $exceptionCode for read transaction $Transaction" }
        $count = if ($Transaction -eq 14) { 1 } else { $reader.ReadInt32() }
        for ($index=0; $index -lt $count; $index++) {
            $length = $reader.ReadInt32()
            if ($length -lt 0) { $null; continue }
            $valueBytes = $reader.ReadBytes($length*2)
            $reader.ReadUInt16() | Out-Null
            $stream.Position = [long]([Math]::Ceiling($stream.Position/4.0)*4)
            [Text.Encoding]::Unicode.GetString($valueBytes)
        }
    } finally { $reader.Dispose(); $stream.Dispose() }
}
$properties = @(Read-FactoryParcel 3)
$properties | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $outputDirectory 'factory-property-names.json')
$values = foreach ($propertyName in $properties) {
    [pscustomobject]@{ name=$propertyName; value=(Read-FactoryParcel 14 $propertyName) }
}
$values | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $outputDirectory 'factory-property-values.json')
@(Read-FactoryParcel 1) | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $outputDirectory 'factory-ecu-names.json')
@(Read-FactoryParcel 2) | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $outputDirectory 'factory-app-names.json')
Write-Output "Read $($properties.Count) FactorySettings properties and values; ECU/app lists saved locally."
$values | Where-Object { $_.name -match 'ANDROID|GAL|PROJECTION|CARPLAY|DISPLAY|SCREEN|WIDE|FULL|BZONE|B_ZONE|RESOLUTION|DPI|VIDEO|USB|CERTIFICATION|REGION|MODEL|HMI|DEBUG|DEVELOP' } | Format-Table -AutoSize
