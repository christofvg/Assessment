param (
    [Parameter(Mandatory)]
    [String]$ApplicationId,

    [Parameter(Mandatory)]
    [String]$ServicePrincipal,

    [Parameter(Mandatory)]
    [String]$TenantId
)
$ModuleName = 'SEAzure'
$ModulePath = (Resolve-Path $PSScriptRoot\$ModuleName).Path
try {
    Import-Module (Join-Path $ModulePath "$ModuleName.psd1") -ErrorAction Stop
} catch {
    $err = $_
    Write-Error $err
    Throw "Could not import module $ModuleName"
}

try {
    $connectParams = @{
        ApplicationId    = $ApplicationId
        ServicePrincipal = $ServicePrincipal
        TenantId         = $TenantId
        ErrorAction      = 'Stop'
    }
    Connect-AzureRmAccount @connectParams
} catch {
    $err = $_
    Write-Error $err
    throw "Could not connect to Azure"
}

New-SEResourceGroup -ResourceGroupName $ResourceGroupName -Environment $Environment