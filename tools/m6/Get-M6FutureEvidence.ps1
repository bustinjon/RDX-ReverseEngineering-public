param([Parameter(Mandatory=$true)][string]$SessionDirectory,[Parameter(Mandatory=$true)][string]$ProofDirectory,[string]$Serial,[string]$LiveAuthorization)
& "$PSScriptRoot/Invoke-M6FutureSession.ps1" -Stage RETRIEVE -SessionDirectory $SessionDirectory -ProofDirectory $ProofDirectory -Serial $Serial -LiveAuthorization $LiveAuthorization
