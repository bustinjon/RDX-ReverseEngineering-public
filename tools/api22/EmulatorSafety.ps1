# Pure validation functions only. Dot-sourcing this file performs no process/device operation.
function Assert-OnlyEmulatorInventory {
 param([string]$Serial,[string]$Inventory)
 if($Serial-notmatch'^emulator-[0-9]{4,5}$'){throw 'Explicit official emulator serial required'}
 $rows=@($Inventory-split'\r?\n'|ForEach-Object {$_.Trim()}|Where-Object {$_-and$_-notmatch'^List of devices attached'-and$_-notmatch'^\*'-and$_-match'^\S+\s+\S+'})
 foreach($row in $rows){if(($row-split'\s+')[0]-notmatch'^emulator-[0-9]{4,5}$'){throw 'Physical/unknown ADB device present: no further ADB commands permitted'}}
 if(@($rows|Where-Object {$_-match('^'+[regex]::Escape($Serial)+'\s+device\b')}).Count-ne1){throw 'Selected emulator is not uniquely online'}
}
function Assert-Api22EmulatorIdentity {
 param([string]$Qemu,[string]$API,[string]$Release,[string]$Hardware)
 if($Qemu-ne'1'-or$API-ne'22'-or$Release-notmatch'^5\.1(\.1)?$'-or$Hardware-notin@('goldfish','ranchu')){throw 'REFUSED: isolated API22 goldfish/ranchu emulator identity not established'}
}
