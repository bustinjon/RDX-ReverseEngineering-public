$ErrorActionPreference='Stop'
$out='./analysis/recovery-root-evidence'
[IO.Directory]::CreateDirectory([IO.Path]::GetFullPath($out))|Out-Null
$b=[IO.File]::ReadAllBytes((Resolve-Path './adb/RDX-Audit/security/sepolicy'))
$text=[Text.Encoding]::Latin1.GetString($b)
function U32([int]$p){[BitConverter]::ToUInt32($b,$p)}
function U16([int]$p){[BitConverter]::ToUInt16($b,$p)}
# Structural extraction only: do not treat missing direct AVTAB entries as an effective denial.
$typeRecords=@{}
for($p=0;$p-lt$b.Length-16;$p++){
    $length=U32 $p
    if($length-lt2 -or $length-gt90 -or $p+16+$length-gt$b.Length){continue}
    $value=U32 ($p+4);$primary=U32 ($p+8);$flags=U32 ($p+12)
    if($value-lt1 -or $value-gt1000 -or $primary-gt3 -or $flags-gt1){continue}
    $name=$text.Substring($p+16,$length)
    if($name-notmatch'^[a-zA-Z_][a-zA-Z0-9_]*$'){continue}
    $typeRecords[$p]=[pscustomobject]@{offset=$p;name=$name;value=$value;primary=$primary;flags=$flags;next=($p+16+$length)}
}
$best=@()
foreach($start in @($typeRecords.Keys|Sort-Object)){
    $chain=[Collections.Generic.List[object]]::new();$position=$start;$prior=0
    while($typeRecords.ContainsKey($position)){
        $record=$typeRecords[$position]
        $chain.Add($record);$prior=$record.value;$position=[int]$record.next
    }
    if($chain.Count-gt$best.Count){$best=$chain.ToArray()}
}
if($best.Count-lt300 -or ($best.value|Measure-Object -Minimum).Minimum-ne1){throw 'Type-table structural validation failed'}
$typeById=@{};$typeByName=@{}
foreach($record in $best){if($record.primary-ne0){$typeById[[int]$record.value]=$record};$typeByName[$record.name]=$record}
$classes=@()
foreach($name in @('process','file','dir','fd','filesystem','capability','capability2','property_service','security')){
    foreach($match in [regex]::Matches($text,'(?<![a-zA-Z0-9_])'+[regex]::Escape($name)+'(?![a-zA-Z0-9_])')){
        $p=$match.Index-24
        if($p-lt0 -or (U32 $p)-ne$name.Length){continue}
        $commonLength=U32 ($p+4);$value=U32 ($p+8);$nprim=U32 ($p+12);$nel=U32 ($p+16);$ncons=U32 ($p+20)
        if($commonLength-gt50 -or $value-lt1 -or $value-gt128 -or $nprim-gt32 -or $nel-gt32 -or $ncons-gt100){continue}
        $cursor=$match.Index+$name.Length+$commonLength;$permissions=@();$valid=$true
        for($i=0;$i-lt$nel;$i++){
            $len=U32 $cursor;$permValue=U32 ($cursor+4)
            if($len-lt1 -or $len-gt50 -or $permValue-lt1 -or $permValue-gt32){$valid=$false;break}
            $perm=$text.Substring($cursor+8,$len)
            if($perm-notmatch'^[a-zA-Z_][a-zA-Z0-9_]*$'){$valid=$false;break}
            $permissions+=@{name=$perm;value=$permValue;mask=[uint32]([long]1-shl($permValue-1))};$cursor+=8+$len
        }
        if($valid){$classes+=[pscustomobject]@{name=$name;value=$value;commonName=$text.Substring($match.Index+$name.Length,$commonLength);permissions=$permissions;offset=$p}}
    }
}
$candidates=@()
$typesEnd=$best[-1].next
for($p=$typesEnd;$p-lt$b.Length-1200;$p++){
    $count=U32 $p
    if($count-lt100 -or $count-gt15000 -or $p+4+12*$count-gt$b.Length){continue}
    $valid=$true
    for($i=0;$i-lt$count;$i++){
        $q=$p+4+12*$i;$s=U16 $q;$t=U16 ($q+2);$c=U16 ($q+4);$specified=U16 ($q+6)
        if(-not$typeById.ContainsKey([int]$s) -or -not$typeById.ContainsKey([int]$t) -or $c-lt1 -or $c-gt100 -or $specified-notin1,2,4,16,32,64){$valid=$false;break}
    }
    if($valid){$candidates+=@{offset=$p;entries=$count};break}
}
$avtab=@()
if($candidates.Count-eq1){
    $candidate=$candidates[0]
    $wanted=@('shell','system_app','system_server','adbd','zygote','init','devupdate','devupdate_bin','untrusted_app')
    foreach($i in 0..($candidate.entries-1)){
        $q=$candidate.offset+4+12*$i;$s=U16 $q;$t=U16 ($q+2);$c=U16 ($q+4);$specified=U16 ($q+6);$data=U32 ($q+8)
        $source=$typeById[[int]$s].name;$target=$typeById[[int]$t].name
        $class=$classes|Where-Object {$_.value-eq$c}|Select-Object -First 1
        if($source-notin$wanted -or $null-eq$class){continue}
        if($class.name-notin'property_service','capability','capability2','process','filesystem','security' -and $target-notin'shell_data_file','system_file','persist_app_file'){continue}
        $permissions=if(($specified-band7)-ne0){@($class.permissions|Where-Object {($data-band$_.mask)-ne0}|ForEach-Object {$_.name})}else{@()}
        $transitionTarget=if($specified-in16,32,64 -and $typeById.ContainsKey([int]$data)){$typeById[[int]$data].name}else{$null}
        $avtab+=[pscustomobject]@{offset=$q;source=$source;target=$target;class=$class.name;specified=$specified;datum=('0x{0:X8}'-f$data);localPermissions=@($permissions);transitionTarget=$transitionTarget;commonPermissionsNotExpanded=($class.commonName-ne'')}
    }
}
[ordered]@{policySHA256=(Get-FileHash './adb/RDX-Audit/security/sepolicy').Hash;magic=('0x{0:X8}'-f(U32 0));version=(U32 16);typeTableStart=$best[0].offset;typeCount=$best.Count;types=$best;selectedClasses=$classes;avtabCandidates=$candidates;selectedDirectEntries=$avtab;limitations='Partial structural extraction, not an authoritative policydb decoder. No conditional rule tables, attribute membership/type maps, constraints, permissive maps, MLS/booleans, policy reload or live AVC interpretation. Positive direct entries are scoped clues; absence is NOT proof of effective denial. Common inherited file permissions are not expanded. No vehicle calls.'}|ConvertTo-Json -Depth 8|Set-Content "$out/policy-structure.json"
[pscustomobject]@{types=$best.Count;classes=$classes.Count;avtabCandidateCount=$candidates.Count;firstStructurallyValidTable=$candidates[0];selectedEntries=$avtab.Count}|ConvertTo-Json -Depth 4
