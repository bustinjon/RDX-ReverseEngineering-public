param([Parameter(Mandatory=$true)][string]$SessionDirectory,[Parameter(Mandatory=$true)][string]$Serial,[Parameter(Mandatory=$true)][ValidateSet('M5_PERMISSION_ONLY')][string]$LiveAuthorization)
$ErrorActionPreference='Stop'
& "$PSScriptRoot/Invoke-M5FutureSession.ps1" -Stage UNINSTALL -SessionDirectory $SessionDirectory -Serial $Serial -LiveAuthorization $LiveAuthorization
& "$PSScriptRoot/Invoke-M5FutureSession.ps1" -Stage POSTCHECK -SessionDirectory $SessionDirectory -Serial $Serial -LiveAuthorization $LiveAuthorization
