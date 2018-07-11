function Connect-SEAzureAccount {}

function New-SEResourceGroup {
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [String]$ResourceGroupName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateSet('Test','QA','Prod')]
        [string]$Environment,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Company = 'Sentia'
    )
    BEGIN {}
    PROCESS {
        try {
            Write-Verbose "Creating new resource group with name $ResourceGroupName"
            $RG = New-AzureRmResourceGroup -Name $ResourceGroupName -Location "West Europe" -Tag @{
                Environment = $Environment
                Company = $Company
            } -ErrorAction Stop
        } catch {
            $err = $_
            Write-Error $err
            throw "ResourceGroup $ResourceGroupName could not be deployed, exiting"
        }
        return (
            [PSCustomObject]@{
                ResourceGroupName = $RG.ResourceGroupName
                Location          = $RG.Location
                ProvisioningState = $RG.ProvisioningState
            }
        )
    }
    END {}
}

function New-SEPolicyDefintion {}

function Publish-SEPolicyDefinition {}
