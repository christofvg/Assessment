
function New-SEResourceGroup {
    <#
    .SYNOPSIS
        This command is used Create a new Resource Group for Sentia.
    .DESCRIPTION
        This command is used Create a new Resource Group for Sentia.
        It will also apply two tags for Environment and Company.
    .EXAMPLE
        PS C:\> New-SEResourceGroup -ResourceGroupName SENetworking -Environment Test
        This command will create a new resource group 'SENetworking' and will add the value Test to the Environment Tag.
        It will also add the value Sentia to the company Tag, as it is the default value.
    .EXAMPLE
        PS C:\> New-SEResourceGroup -ResourceGroupName SENetworking -Environment Test -Company dev
        This command will create a new resource group 'SENetworking' and will add the value Test to the Environment Tag.
        it will also add the value dev to the company Tag.
    .PARAMETER ResourceGroupName
        The name of the new Azure Resource Group.
    .PARAMETER Environment
        The name of the Environment. This will be used to add an Environment tag to the Azure Resource Group.
    .PARAMETER Company
        The name of the Company. This will be used to add a Company tag to the Azure Resource Group.
    .NOTES
        Help 1.0 is written on 13/07/2018.
    #>
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
        $resourceGroups = Get-AzureRmResourceGroup
        if ($ResourceGroupName -in $resourceGroups.ResourceGroupName) {
            Write-Output "ResourceGroup: $ResourceGroupName already exists"
            return
        } else {
            try {
                Write-Verbose "Creating new resource group with name $ResourceGroupName"
                if ($PSCmdlet.ShouldProcess("Creating Resource Group: $ResourceGroupName with tags: [Environment=$Environment]; [Company=$Company]")) {
                    $RG = New-AzureRmResourceGroup -Name $ResourceGroupName -Location "West Europe" -Tag @{
                        Environment = $Environment
                        Company = $Company
                    } -ErrorAction Stop
                    Write-Verbose "Resource Group: $ResourceGroupName created Successfully"

                    return (
                        [PSCustomObject]@{
                            ResourceGroupName = $RG.ResourceGroupName
                            Location          = $RG.Location
                            ProvisioningState = $RG.ProvisioningState
                        }
                    )
                }
            } catch {
                $err = $_
                Write-Error $err
                throw "ResourceGroup $ResourceGroupName could not be deployed, exiting"
            }
        }
    }
    END {}
}

function New-SEPolicyDefintion {}

function Publish-SEPolicyDefinition {}
