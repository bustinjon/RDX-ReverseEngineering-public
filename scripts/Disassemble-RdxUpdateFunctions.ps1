$ErrorActionPreference='Stop'
Add-Type -Path './scripts/RdxElf.cs'
$mc='C:/Program Files/Microsoft Visual Studio/2022/Community/MSBuild/Xamarin/Android/binutils/bin/llvm-mc.exe'
$out='./analysis/deployment-evidence/native-functions'
[IO.Directory]::CreateDirectory([IO.Path]::GetFullPath($out)) | Out-Null
$wanted='^(VDM_SWMC_PL_Security_|SWMC_Security_|SWM_DP_ValidateSignature$|SWM_DP_validate$|SWM_DP_checkDP$|SWM_DP_IO_(isRbDp|getRbDpPreambleSize)$|SWM_calc(Signature|UpdatedSignature)$|DMA_redbend_SCOMO_getConfigSignatureValidationVal$|VDM_SWMC_PL_Dp_validateExternalSignatureDp$|DMA_USBUPD_(validateUpdate|extractUpdate)$|verify_manifest$|verify_file$|JNI_.*(Root|Exec|Copy|Cert))'
foreach($lib in @('libsmm_release.so','libsmm_debug.so','libdevelupdate.so')){
    $elf=[RdxOffline.Elf32]::new([IO.File]::ReadAllBytes((Resolve-Path "./adb/RDX-Audit/full-system/lib/$lib")))
    if($lib-eq'libsmm_release.so'){
        # Unexported analysis ranges, bounded by observed neighboring function entries.
        foreach($range in @(@{name='SWMC_root_certificate_analysis_range';start=0x143FB4;end=0x144298},@{name='SWMC_entity_chain_analysis_range';start=0x1442EC;end=0x144940},@{name='SWMC_signature_algorithm_analysis_range';start=0x142F5C;end=0x1437A0},@{name='SWMC_expiry_analysis_range';start=0x141EB0;end=0x1420F0},@{name='SWMC_digest_algorithm_analysis_range';start=0x1420F0;end=0x1424A8},@{name='SWMC_digest_analysis_range';start=0x142C50;end=0x142F5C})){
            $symbol=[RdxOffline.ElfSymbol]::new();$symbol.Name=$range.name;$symbol.Value=$range.start;$symbol.Size=$range.end-$range.start;$symbol.Info=2;$symbol.Section=8;$elf.Symbols.Add($symbol)
        }
    }
    $elf.Relocations | ConvertTo-Json -Depth 4 | Set-Content "$out/$lib.relocations.json"
    foreach($symbol in @($elf.Symbols | Where-Object {($_.Name -match $wanted -or $_.Name-like'SWMC_*_analysis_range') -and $_.Section-ne0 -and ($_.Info-band15)-eq2 -and $_.Size-gt0})){
        $bytes=$elf.FunctionBytes($symbol)
        $hex=if($symbol.Thumb){($bytes | ForEach-Object {'0x{0:x2}' -f $_}) -join ' '}else{
            $hexLines=for($wordOffset=0;$wordOffset-lt$bytes.Length;$wordOffset+=4){($bytes[$wordOffset..([Math]::Min($wordOffset+3,$bytes.Length-1))] | ForEach-Object {'0x{0:x2}' -f $_}) -join ' '}
            $hexLines -join "`n"
        }
        $stem="$out/$lib.$($symbol.Name)"
        $hex | Set-Content -LiteralPath "$stem.hex"
        $triple=if($symbol.Thumb){'thumbv7-linux-android'}else{'armv7-linux-android'}
        & $mc --disassemble "--triple=$triple" --show-encoding --print-imm-hex "$stem.hex" > "$stem.asm" 2> "$stem.stderr.txt"
        $exit=$LASTEXITCODE
        $annotated=[Collections.Generic.List[string]]::new()
        $annotated.Add("Function $($symbol.Name) VA=0x$('{0:X}' -f $symbol.Address) size=$($symbol.Size) thumb=$($symbol.Thumb); llvm-mc exit=$exit")
        $relative=0
        $decoded=0
        $matchedAll=$true
        $invalidOffsets=[Collections.Generic.HashSet[int]]::new()
        if(-not$symbol.Thumb){foreach($errorLine in Get-Content -LiteralPath "$stem.stderr.txt"){if($errorLine-match':(\d+):\d+: warning: invalid instruction encoding'){$invalidOffsets.Add(([int]$Matches[1]-1)*4)|Out-Null}}}
        foreach($line in Get-Content -LiteralPath "$stem.asm"){
            if($line -match 'encoding: \[([^\]]+)\]'){
                $instructionBytes=@($Matches[1].Split(',') | ForEach-Object {[Convert]::ToByte($_.Trim().Substring(2),16)})
                # Match encodings back to input bytes, including skipped invalid words/literal data.
                if(-not$symbol.Thumb){while($invalidOffsets.Contains($relative)){$annotated.Add(('0x{0:X8} <undecoded 4-byte word; see raw hex and LLVM stderr>' -f ($symbol.Address+$relative)));$relative+=4}}
                $step=if($symbol.Thumb){2}else{4}
                $found=$false
                $searchOffset=$relative
                while($searchOffset+$instructionBytes.Count-le$bytes.Length){
                    $matchesInput=$true
                    for($byteIndex=0;$byteIndex-lt$instructionBytes.Count;$byteIndex++){if($bytes[$searchOffset+$byteIndex]-ne$instructionBytes[$byteIndex]){$matchesInput=$false;break}}
                    if($matchesInput){$found=$true;break}
                    $searchOffset+=$step
                }
                if(-not$symbol.Thumb){
                    # Fixed-width ARM plus source-line diagnostics establishes offsets even when
                    # LLVM canonicalizes an unpredictable instruction/literal on re-encoding.
                    if($instructionBytes.Count-ne4){throw "Unexpected ARM instruction width: $stem"}
                }elseif($found){$relative=$searchOffset}else{$matchedAll=$false;$annotated.Add('WARNING: LLVM re-encoding could not be mapped; following inferred offsets require raw-byte verification.')}
                $va=[uint32]($symbol.Address+$relative)
                $extra=''
                if(-not $symbol.Thumb -and $instructionBytes.Count-eq4){
                    $word=[BitConverter]::ToUInt32($bytes,$relative)
                    if(($word-band0x0F000000)-eq0x0B000000 -or ($word-band0xFF000000)-eq0xEA000000){
                        $delta=[long]($word-band0x00FFFFFF)*4;if($delta-ge0x02000000){$delta-=0x04000000}
                        $target=[uint32](([long]$va+8+$delta)-band0xFFFFFFFF)
                        $extra=" ; target=0x$('{0:X}' -f $target) $($elf.SymbolAt($target))"
                    }
                    # PC-relative literal value helps follow embedded offsets and data references.
                    if(($word-band0x0F7F0000)-eq0x051F0000){
                        $offset=$word-band0xFFF;$literalVa=if(($word-band0x00800000)-ne0){$va+8+$offset}else{$va+8-$offset}
                        try{$value=[BitConverter]::ToUInt32($elf.Bytes,$elf.FileOffset($literalVa));$extra+=" ; literal@0x$('{0:X}' -f $literalVa)=0x$('{0:X}' -f $value)"}catch{}
                    }
                }
                $annotated.Add(('0x{0:X8} ' -f $va)+$line+$extra)
                $relative+=$instructionBytes.Count
                $decoded+=$instructionBytes.Count
            }else{$annotated.Add($line)}
        }
        if(-not$symbol.Thumb -and $decoded+4*$invalidOffsets.Count-ne$symbol.Size){throw "ARM diagnostic/decoded-byte accounting mismatch: $stem"}
        $annotated | Set-Content -LiteralPath "$stem.annotated.txt"
        [pscustomobject]@{library=$lib;function=$symbol.Name;address=('0x{0:X}' -f $symbol.Address);size=$symbol.Size;decodedBytes=$decoded;undecodedBytes=$symbol.Size-$decoded;offsetsMatchedToInput=$matchedAll;exitCode=$exit}
    }
}
