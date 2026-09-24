function Export-AzCostData {
    <#
    .SYNOPSIS
        Saves cost data returned by Get-SubscriptionCost, Get-StorageCost or Get-CostAdvisor to a JSON file for later reloading.

    .DESCRIPTION
        Retrieving cost data from Azure can take a few minutes to run. Export-AzCostData lets you persist the result to disk
        so it can be reloaded later with Import-AzCostData for analysis or comparison, without needing to query Azure again.

    .PARAMETER Cost
        The cost object/s returned by Get-SubscriptionCost, Get-StorageCost or Get-CostAdvisor.

    .PARAMETER Path
        The file to save the cost data to. If a directory is specified instead, a file named AzCostData_<timestamp>.json is created within it.

    .EXAMPLE
        Get-SubscriptionCost -ComparePrevious | Export-AzCostData -Path C:\Cost\SubscriptionCost.json

        Description
        -----------
        Retrieves subscription cost data and saves it to the specified file.

    .EXAMPLE
        $Cost | Export-AzCostData -Path C:\Cost

        Description
        -----------
        Saves the cost data held in $Cost to a timestamped file within the specified directory.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        $Cost,

        [Parameter(Mandatory)]
        [string]
        $Path
    )
    begin {
        $CostObject = @()
    }
    process {
        $CostObject += $Cost
    }
    end {
        if (Test-Path $Path -PathType Container) {
            $Path = Join-Path $Path "AzCostData_$(Get-Date -Format 'yyyyMMddHHmmss').json"
        }

        $ExportObject = foreach ($Item in $CostObject) {
            [pscustomobject]@{
                TypeName = $Item.PSObject.TypeNames[0]
                Data     = $Item
            }
        }

        $ExportObject | ConvertTo-Json -Depth 10 | Out-File -FilePath $Path -Encoding utf8 -Force

        Write-Verbose "Exported $($CostObject.Count) cost object(s) to $Path"
    }
}
