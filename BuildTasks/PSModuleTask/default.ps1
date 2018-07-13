[string]$TestFile = 'Test-Pester.xml'

Properties {
    $SourceDir    = $SourceDir
    $PSModule     = $PSModule
    $UserName     = $UserName
    $Password     = $Password
}

task default -depends Deploy

task CheckDependencies -depends Clean {
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    Install-PackageProvider -Name Nuget -Force

    $requiredModules = @(
        'Pester'
        'Psake'
        'PSScriptAnalyzer'
        'AzureRM.NetCore'
        'VSTeam'
    )
    foreach ($module in $requiredModules) {
        $currentModule = Get-Module -Name $module -ListAvailable | Select-Object -First 1
        if (-not $currentModule) {
            Write-Output "Installing module $module"
            $null = Install-Module $module -Force -AllowClobber -SkipPublisherCheck -ErrorAction SilentlyContinue
            Write-Output "Module: $module installed"
        }
        $newestModule = Find-Module -Name $module

        if ($currentModule.Version.ToString() -eq $newestModule.Version) {
            Write-Output "Module: $module up-to-date"
        } else {
            Write-Output "Module $module needs to be updated from version: $($currentModule.Version.ToString()) to version: $($newestModule.Version)"
            Update-Module -Name $module -Force
        }
    }
}

task Test -depends CheckDependencies {
    if ($UserName) {
        $Credential = [PSCredential]::new($UserName,(ConvertTo-SecureString -String $Password -AsPlainText -Force))
        $testResults = Invoke-Pester -Script @{ Path = "$SourceDir\$PSModule\Tests\Unit\$PSModule.tests.ps1"; Parameters = @{ Credential = $Credential }} -OutputFile "$SourceDir\$TestFile" -OutputFormat NUnitXml -PassThru
    } else {
        $testResults = Invoke-Pester -Script "$SourceDir\$PSModule\Tests\Unit\$PSModule.tests.ps1" -OutputFile "$SourceDir\$TestFile" -OutputFormat NUnitXml -PassThru
    }
    if ($testResults.FailedCount -gt 0) {
        Write-Host "##vso[task.logissue type=error;] Tests failed. Build cannot continue"
        Write-Host "##vso[task.complete result=Failed;]"
    }
}

task Deploy -depends Test {
    #copy the items to the powershell modules folder on the build server
    if (-not (Test-Path -Path "C:\Program Files\WindowsPowerShell\Modules\$PSModule")) {
        New-Item -Path "C:\Program Files\WindowsPowerShell\Modules\$PSModule" -ItemType Directory
    }
    try {
        Copy-Item -Path $SourceDir\$PSModule\* -Destination "C:\Program Files\WindowsPowerShell\Modules\$PSModule" -Recurse -Force -Exclude build.ps1,default.ps1,test-pester.xml -ErrorAction Stop
    } catch {
        $err = $_
        Write-Error $err
        Write-Host "##vso[task.logissue type=error;] Could not copy module $PSModule to Modules folder"
        Write-Host "##vso[task.complete result=Failed;]"
    }
}

task Clean {
    if (Test-Path $SourceDir\$TestFile) { Remove-Item $SourceDir\$TestFile}
}