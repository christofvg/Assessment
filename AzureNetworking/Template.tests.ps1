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
            TemplateParameterFile = "$Env:System_DefaultWorkingDirectory/AzureNetworking/azuredeploy.parameters.json"
            TemplateFile          = "$Env:System_DefaultWorkingDirectory/AzureNetworking/azuredeploy.json"
        }
        $test = Test-AzureRmResourceGroupDeployment @testParams
        $test | Should BeNullOrEmpty
    }
}