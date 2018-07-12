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