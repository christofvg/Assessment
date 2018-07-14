param (
    [Parameter(Mandatory)]
    [String]$ResourceGroupName,

    [Parameter(Mandatory)]
    [ValidateSet('Test','QA','Prod')]
    [String]$Environment
)

Write-Output "Creating Resource Group: $ResourceGroupName for Environment $Environment"
New-SEResourceGroup -ResourceGroupName $ResourceGroupName -Environment $Environment