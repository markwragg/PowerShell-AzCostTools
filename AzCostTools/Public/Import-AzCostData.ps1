function Import-AzCostData {
    <#
    .SYNOPSIS
        Loads cost data previously saved with Export-AzCostData.

    .DESCRIPTION
        Reloads cost data that was saved to disk with Export-AzCostData. The returned objects are equivalent to the
        original output of Get-SubscriptionCost/Get-StorageCost/Get-CostAdvisor and can be piped directly to Show-CostAnalysis
        or Export-AzCostData again.

    .PARAMETER Path
        The JSON file previously created by Export-AzCostData. If a directory is specified instead, every *.json file within it is imported.

    .EXAMPLE
        Import-AzCostData -Path C:\Cost\SubscriptionCost.json | Show-CostAnalysis

        Description
        -----------
        Loads previously saved cost data and pipes it to Show-CostAnalysis.

    .EXAMPLE
        Import-AzCostData -Path C:\Cost

        Description
        -----------
        Loads and returns cost data from every JSON file within the specified directory.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]
        $Path
    )
    process {
        $Files = if (Test-Path $Path -PathType Container) {
            Get-ChildItem -Path $Path -Filter '*.json' -File
        }
        else {
            Get-Item -Path $Path
        }

        foreach ($File in $Files) {

            $ImportedObject = Get-Content -Path $File.FullName -Raw | ConvertFrom-Json

            foreach ($Item in $ImportedObject) {
                Restore-CostObjectType -InputObject $Item.Data -TypeName $Item.TypeName
            }
        }
    }
}
