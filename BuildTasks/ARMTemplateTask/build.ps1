param (
    [string[]]$TaskList,
    [String]$TestFilePath,
    [String]$TenantId,
    [String]$ClientId,
    [String]$ClientPassword
)

$file = Join-Path $PSScriptRoot 'default.ps1'
Invoke-Psake -buildFile $file -taskList $TaskList -properties @{ 
    'SourceDir'      = $Env:System_DefaultWorkingDirectory
    'TestFilePath'   = $TestFilePath
    'TenantId'       = $TenantId
    'ClientId'       = $ClientId
    'ClientPassword' = $ClientPassword
}