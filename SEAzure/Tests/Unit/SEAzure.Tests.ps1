$Module = 'SEAzure'
$root = (Resolve-Path $PSScriptRoot\..\..).Path

try {
    Import-Module (Join-Path $root "$module.psm1")
} catch {
    Write-Output "error in script $_"
}

Describe -Tag 'Linting' "$module Module Linting Tests" {
    Context ' PS Script Analyzer Rules' {
        $rulesToExclude = @(
            'PSDSCDscExamplesPresent',
            'PSDSCDscTestsPresent',
            'PSDSCReturnCorrectTypesForDSCFunctions',
            'PSDSCUseIdenticalMandatoryParametersForDSC',
            'PSDSCUseIdenticalParametersForDSC',
            'PSDSCStandardDSCFunctionsInResource',
            'PSDSCUseVerboseMessageInDSCResource'
        )
        $analysis = Invoke-ScriptAnalyzer -Path "$root\$module.psm1" -ExcludeRule $rulesToExclude
        $scriptAnalyzerRules = Get-ScriptAnalyzerRule

        foreach ($rule in $scriptAnalyzerRules.RuleName) {
            if (-not ($rule -in $rulesToExclude)) {
                It " Should pass $rule" {
                    if ($analysis.RuleName -eq $rule) {
                        $analysis | Where-Object { $_.RuleName -eq $rule } -OutVariable failures | Out-Default
                        $failures.Count | Should Be 0
                    }
                }
            }
        }
    }
}

$ManifestFile = Join-Path $root "$Module.psd1"

$ModuleInformation = Test-ModuleManifest $ManifestFile

$ExportedFunctions = $ModuleInformation.ExportedFunctions.Values.name

$code = Get-Content (Join-Path $root "$Module.psm1")
$ParsedCode = [System.Management.Automation.PSParser]::Tokenize($code,[ref]$null)
$functionlist = New-Object System.Collections.ArrayList
foreach ($parse in $ParsedCode) {
    if ($parse.Type -eq "CommandArgument" -and $parse.Content -like "*-SE*") {
        [void]$functionlist.Add($parse.Content)
    }
}

Describe "Module manifest file (.psd1)" {
    Context " Manifest" {
        It " Should contains RootModule"{
            $ModuleInformation.RootModule | Should not BeNullOrEmpty
        }
        It " Should contains Author"{
            $ModuleInformation.Author | Should not BeNullOrEmpty
        }
        It " Should contains Company Name"{
            $ModuleInformation.CompanyName | Should not BeNullOrEmpty
        }
        It " Should contains Description"{
            $ModuleInformation.Description | Should not BeNullOrEmpty
        }
        It " Should contains Copyright"{
            $ModuleInformation.Copyright | Should not BeNullOrEmpty
        }
        It " Compare count of exported functions to functions in .psm1" {
            $ExportedFunctions.count -eq $functionlist.Count | Should BeGreaterthan 0
        }
        It " Compare exported functions to functions in .psm1" {
            $compare = Compare-Object -ReferenceObject $ExportedFunctions -DifferenceObject $functionlist
            $compare.inputobject -join ',' | Should BeNullOrEmpty
        }
    }
}
