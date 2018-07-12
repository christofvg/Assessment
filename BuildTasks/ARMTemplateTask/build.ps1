param (
    [string[]]$TaskList,
    [String]$TestFilePath
)

$file = Join-Path $PSScriptRoot 'default.ps1'
Invoke-Psake -buildFile $file -taskList $TaskList -properties @{ 
    'SourceDir'    = $Env:System_DefaultWorkingDirectory
    'TestFilePath' = $TestFilePath
}