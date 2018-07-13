
function New-SEResourceGroup {
    <#
    .SYNOPSIS
        This command is used to Create a new Resource Group for Sentia.
    .DESCRIPTION
        This command is used to Create a new Resource Group for Sentia.
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
        Help is written on 13/07/2018.
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

function New-SEPolicyDefintionForResourceType {
    <#
    .SYNOPSIS
        This command is used to create a new Azure Policy Definition to restrict the Resource Types that are allowed to create.
    .DESCRIPTION
        This command is used to create a new Azure Policy Definition to restrict the Resource Types that are allowed to create.
    .EXAMPLE
        PS C:\> New-SEPolicyDefinitionForResourceType -PolicyDefinitionName SEResourceTypes
        This command will create a new Azure Policy Definition 'SEResourceTypes'.
    .PARAMETER PolicyDefinitionName
        The name of the Policy Definition.
    .NOTES
        Help is written on 13/07/2018.
    #>
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
    param (
        [Parameter()]
        [String]$PolicyDefinitionName = "SEResourceTypes"
    )
    BEGIN {}

    PROCESS {
        $authHeader = GenerateHeader
        $azContext = Get-AzureRmContext
        $BaseUri = GetPolicyDefinitionBaseUri -SubscriptionId $azContext.Subscription.Id

        $Definition = Get-SEPolicyDefinition -PolicyDefinitionName $PolicyDefinitionName
        if ($Definition.Name -ne $PolicyDefinitionName) {
            $policyDefinitionBody = @{
                properties = @{
                    mode = "all"
                    displayname = "Allowed Resource Types"
                    description = "This policy enables you to restrict Resource Types that could be deployed"
                    parameters = @{
                        listOfResourceTypesAllowed = @{
                            type = "array"
                            metadata = @{
                                description = "the list of allowed resource types"
                                displayname = "Allowed resource types"
                                strongType = "resourceTypes"
                            }
                        }
                    }
                    policyRule = @{
                        "if" = @{
                            "not" = @{
                                "field" = "type"
                                "in" = "[Parameters('listOfResourceTypesAllowed')]"
                            }
                        }
                        "then" = @{
                            "effect" = "deny"
                        }
                    }
                }
            }
            $paramsPolicyDefintion = @{
                Uri         = "$($BaseUri.Uri)/$($PolicyDefinitionName)?api-version=2018-03-01"
                Body        = $policyDefinitionBody | ConvertTo-Json -Depth 10
                Method      = 'PUT'
                Header      = $authHeader
                ErrorAction = 'Stop'
            }
            try {
                if ($PSCmdlet.ShouldProcess("New Policy Definition: $PolicyDefinitionName")) {
                    Invoke-WebRequest @paramsPolicyDefintion
                }
            } catch {
                $err = $_
                Write-Error $err
                throw "Could not create a new Azure Policy Defintion"
            }
        } else {
            Write-Output "Policy Definition: $PolicyDefinitionName already exists"
        }
    }

    END {}
}

function Get-SEPolicyDefinition {
    <#
    .SYNOPSIS
        This command is used to get an existing Azure Policy Definition.
    .DESCRIPTION
        This command is used to get an existing Azure Policy Definition.
    .EXAMPLE
        PS C:\> Get-SEPolicyDefinition -PolicyDefinitionName SEResourceTypes
        This command will get an existing Azure Policy Definition 'SEResourceTypes'.
    .PARAMETER PolicyDefinitionName
        The name of the Policy Definition.
    .NOTES
        Help is written on 13/07/2018.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String]$PolicyDefinitionName
    )
    $authHeader = GenerateHeader
    $azContext = Get-AzureRmContext
    $BaseUri = GetPolicyDefinitionBaseUri -SubscriptionId $azContext.Subscription.Id

    $paramsPolicyDefinition = @{
        Uri         = "$($BaseUri.Uri)/$($PolicyDefinitionName)?api-version=2018-03-01"
        Method      = 'Get'
        Header      = $authHeader
        ErrorAction = 'Stop'
    }
    try {
        $request = Invoke-WebRequest @paramsPolicyDefinition
        $properties = $request.Content | ConvertFrom-Json
        return (
            [PSCustomObject]@{
                Name        = $properties.name
                Id          = $properties.id
                DisplayName = $properties.properties.displayName
                PolicyType  = $properties.properties.policyType
                Mode        = $properties.properties.mode
                Description = $properties.properties.description
                Parameters  = $properties.properties.parameters
                PolicyRule  = $properties.properties.policyRule
            }
        )
    } catch {
        $err = $_
        Write-Error $err
        throw "Could not get a Azure Policy Defintion"
    }

}

function GetPolicyDefinitionBaseUri {
    param (
        [string]$SubscriptionId
    )
    return (
        [PSCustomObject]@{
            Uri = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.Authorization/policyDefinitions"
        }
    )
}

function GetPolicyAssignmentBaseUri {
    param (
        [string]$SubscriptionId
    )
    return (
        [PSCustomObject]@{
            Uri = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.Authorization/policyAssignments"
        }
    )
}

function GenerateHeader {
    $azContext = Get-AzureRmContext
    $azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
    $profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList ($azProfile)
    $token = $profileClient.AcquireAccessToken($azContext.Subscription.TenantId)
    return (
        @{
            'Content-Type'  = 'application/json'
            'Authorization' = 'Bearer ' + $token.AccessToken
        }
    )
}

function Get-SEPolicyAssignment {
    <#
    .SYNOPSIS
        This command is used to get an existing Azure Policy Assignment.
    .DESCRIPTION
        This command is used to get an existing Azure Policy Assignment.
    .EXAMPLE
        PS C:\> Get-SEPolicyAssignment -PolicyAssignmentName EnforceResourceTypes
        This command will get an existing Azure Policy Assignment 'EnforceResourceTypes'.
    .PARAMETER PolicyAssignmentName
        The name of the Policy Assignment.
    .NOTES
        Help is written on 13/07/2018.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [String]$PolicyAssignmentName
    )
    $authHeader = GenerateHeader
    $azContext = Get-AzureRmContext
    $BaseUri = GetPolicyAssignmentBaseUri -SubscriptionId $azContext.Subscription.Id
    $paramsPolicyAssignment = @{
        Uri         = "$($BaseUri.Uri)/$($PolicyAssignmentName)?api-version=2018-03-01"
        Method      = 'Get'
        Header      = $authHeader
        ErrorAction = 'Stop'
    }
    try {
        $request = Invoke-WebRequest @paramsPolicyAssignment
        $properties = $request.Content | ConvertFrom-Json
        return (
            [PSCustomObject]@{
                Name        = $properties.name
                Id          = $properties.id
                DisplayName = $properties.properties.displayName
                PolicyType  = $properties.properties.policyType
                Mode        = $properties.properties.mode
                Description = $properties.properties.description
                Parameters  = $properties.properties.parameters
                PolicyRule  = $properties.properties.policyRule
            }
        )
    } catch {
        $err = $_
        Write-Error $err
        throw "Could not get a Azure Policy Defintion"
    }
}
function New-SEPolicyAssignmentForResourceType {
    <#
    .SYNOPSIS
        This command is used Create a new Azure Policy Assignment for Resource Types.
    .DESCRIPTION
        This command is used Create a new Azure Policy Assignment for Resource Types.
    .EXAMPLE
        PS C:\> New-SEPolicyAssignmentForResourceType -PolicyAssignmentName EnforceResourceTypes -PolicyDefinitionName SEResourceTypes -ResourceTypes 'Microsoft.Compute', 'Microsoft.Network', 'Microsoft.Storage'
        This will create a new Policy Assignment for the resource types compute, network and storage.
    .PARAMETER PolicyAssignmentName
        The new name of the Policy Assignment.
    .PARAMETER PolicyDefinitionName
        The name of the Policy Definition that you want to assign.
    .PARAMETER ResourceTypes
        The Resource Types that must be restricted.
    .NOTES
        Help is written on 13/07/2018.
    #>
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
    param (
        [Parameter(Mandatory)]
        [string]$PolicyAssignmentName,

        [Parameter(Mandatory)]
        [String]$PolicyDefinitionName,

        [Parameter(Mandatory)]
        [ValidateSet('Microsoft.Compute', 'Microsoft.Network', 'Microsoft.Storage')]
        [String[]]$ResourceTypes
    )
    $authHeader = GenerateHeader
    $azContext = Get-AzureRmContext
    $BaseUri = GetPolicyAssignmentBaseUri -SubscriptionId $azContext.Subscription.Id

    $PolicyDefinition = Get-SEPolicyDefinition -PolicyDefinitionName $PolicyDefinitionName
    $Assignment = Get-SEPolicyAssignment -PolicyAssignmentName $PolicyAssignmentName -ErrorAction SilentlyContinue

    if (-not $Assignment -and $PolicyDefinition) {
        $policyAssignmentBody = @{
            properties = @{
                displayname = "Enforce Allowed Resource Types"
                description = "Enforce Allowed Resource Types to $ResourceTypes"
                metadata = @{
                    assignedBy = "Kenny Van Hoylandt"
                }
                parameters = @{
                    listOfResourceTypesAllowed = @{
                        value = $ResourceTypes
                    }
                }
                policyDefinitionId = $PolicyDefinition.Id
            }
        }

        $paramsPolicyAssignment = @{
            Uri         = "$($BaseUri.Uri)/$($PolicyAssignmentName)?api-version=2018-03-01"
            Method      = 'PUT'
            Body        = $policyAssignmentBody | ConvertTo-Json -Depth 10
            Header      = $authHeader
            ErrorAction = 'Stop'
        }

        try {
            if ($PSCmdlet.ShouldProcess("New Policy Assignment: $PolicyAssignmentName")) {
                Invoke-WebRequest @paramsPolicyAssignment
            }
        } catch {
            $err = $_
            Write-Error $err
            throw "Could not create a new Azure Policy Defintion"
        }
    }
}
