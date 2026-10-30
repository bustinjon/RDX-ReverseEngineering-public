param([Parameter(Mandatory=$true)][string]$SessionDirectory,[Parameter(Mandatory=$true)][string]$Serial,[Parameter(Mandatory=$true)][ValidateSet('M5_PERMISSION_ONLY')][string]$LiveAuthorization)
& "$PSScriptRoot/Invoke-M5FutureSession.ps1" -Stage RETRIEVE -SessionDirectory $SessionDirectory -Serial $Serial -LiveAuthorization $LiveAuthorization
