param (
    [string[]]$TaskList,
    [String]$PSModule,
    [string]$UserName,
    [string]$Password
)

$file = Join-Path $PSScriptRoot 'default.ps1'
Invoke-Psake -buildFile $file -taskList $TaskList -properties @{ 
    'SourceDir'    = $Env:System_DefaultWorkingDirectory
    'PSModule'     = $PSModule
    'UserName'     = $UserName
    'Password'     = $Password
}