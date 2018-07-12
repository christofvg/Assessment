param (
    [string]$TenantId,
    [string]$ClientId,
    [string]$ClientPassword
)
Import-Module AzureRM.Resources.Netcore

$Credential = [PSCredential]::new($ClientId, (ConvertTo-SecureString -String $ClientPassword -AsPlainText -Force))
try {
    $null = Connect-AzureRmAccount -TenantId $TenantId -Credential $Credential -ServicePrincipal -ErrorAction Stop
} catch {
    Throw 'Could not login to Azure'
}
Describe "testing ARM Template" {
    It " Should not generate output" {
        $testParams = @{
            ResourceGroupName     = 'SEStorageTests'
            Mode                  = 'Incremental'
            TemplateParameterFile = './azuredeploy.parameters.json'
            TemplateFile          = './azuredeploy.json'
            Location              = 'West Europe'
        }
        $test = Test-AzureRmResourceGroupDeployment @testParams
        $test | Should BeNullOrEmpty
    }
}