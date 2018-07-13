param (
    [string]$TenantId,
    [string]$ClientId,
    [string]$ClientPassword
)

$Credential = [PSCredential]::new($ClientId, (ConvertTo-SecureString -String $ClientPassword -AsPlainText -Force))
try {
    $null = Connect-AzureRmAccount -TenantId $TenantId -Credential $Credential -ServicePrincipal -ErrorAction Stop
} catch {
    Throw 'Could not login to Azure'
}
Describe "testing ARM Template" {

    It " Should not generate output" {
        $testParams = @{
            ResourceGroupName     = 'SENetworkingTests'
            Mode                  = 'Incremental'
            TemplateParameterFile = './azuredeploy.parameters.json'
            TemplateFile          = './azuredeploy.json'
        }
        $test = Test-AzureRmResourceGroupDeployment @testParams
        $test | Should BeNullOrEmpty
    }
}