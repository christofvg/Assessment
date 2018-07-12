[string]$TestFile = 'Test-Pester.xml'

Properties {
    $SourceDir      = $SourceDir
    $TestFilePath   = $TestFilePath
    $TenantId       = $TenantId
    $ClientId       = $ClientId
    $ClientPassword = $ClientPassword
}

task default -depends Deploy

task Test -depends Clean {
    $testResults = Invoke-Pester -Script @{Path = "$TestFilePath"; Parameters = @{ TenantId = "$TenantId"; ClientID = "$ClientID"; ClientPassword = "$ClientPassword"}} -OutputFile "$SourceDir\$TestFile" -OutputFormat NUnitXml -PassThru
    if ($testResults.FailedCount -gt 0) {
        Write-Host "##vso[task.logissue type=error;] Tests failed. Build cannot continue"
        Write-Host "##vso[task.complete result=Failed;]"
    }
}

task Clean {
    if (Test-Path $SourceDir\$TestFile) { Remove-Item $SourceDir\$TestFile}
}