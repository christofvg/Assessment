param (
    [Parameter(Mandatory)]
    [String]$ClientId,

    [Parameter(Mandatory)]
    [String]$ClientPassword,

    [Parameter(Mandatory)]
    [String]$TenantId,

    [Parameter(Mandatory)]
    [String]$ResourceGroupName,

    [Parameter(Mandatory)]
    [ValidateSet('Test','QA','Prod')]
    [String]$Environment
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

$Credential = [PSCredential]::new($ClientId, (ConvertTo-SecureString -String $ClientPassword -AsPlainText -Force))
try {
    $connectParams = @{
        Credential  = $Credential
        TenantId    = $TenantId
        ErrorAction = 'Stop'
    }
    Connect-AzureRmAccount @connectParams
} catch {
    $err = $_
    Write-Error $err
    throw "Could not connect to Azure"
}

New-SEResourceGroup -ResourceGroupName $ResourceGroupName -Environment $Environment