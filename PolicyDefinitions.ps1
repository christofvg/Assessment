param (
    [Parameter(Mandatory)]
    [String]$PolicyDefinitionName,

    [Parameter(Mandatory)]
    [String]$PolicyAssignmentName
)
Write-Output "Creating a new Policy Definition with name: $PolicyDefinitionName"
New-SEPolicyDefintionForResourceType -PolicyDefinitionName $PolicyDefinitionName
Write-Output "Policy Definition: $PolicyDefinitionName Created"

Write-Output "Creating Policy Assignment: $PolicyAssignmentName"
$paramsPolicyAssignment = @{
    PolicyAssignmentName = $PolicyAssignmentName
    PolicyDefinitionName = $PolicyDefinitionName
    ResourceTypes        = 'Microsoft.Compute', 'Microsoft.Network', 'Microsoft.Storage'
}
New-SEPolicyAssignmentForResourceType @paramsPolicyAssignment
Write-Output "Policy Assignment: $PolicyAssignmentName Created"