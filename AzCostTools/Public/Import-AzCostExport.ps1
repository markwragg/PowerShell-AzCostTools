function Import-AzCostExport {
    <#
    .SYNOPSIS
        Loads Azure cost data from a Cost Management scheduled export held in a Storage Account.

    .DESCRIPTION
        Azure Cost Management can be configured (in the Azure Portal, under Cost Management > Exports) to routinely write
        "Actual Cost" CSV exports to a Storage Account container. Import-AzCostExport reads the export file/s for a given
        billing month directly from that container, and aggregates them into the same object shape returned by
        Get-SubscriptionCost, so the result can be piped to Show-CostAnalysis or Export-AzCostData like any other cost data
        -- without needing to query the Consumption API at all.

    .PARAMETER StorageAccountName
        The name of the Storage Account the scheduled export writes to.

    .PARAMETER ResourceGroupName
        The name of the Resource Group containing the Storage Account.

    .PARAMETER ContainerName
        The name of the blob container the scheduled export writes to.

    .PARAMETER Prefix
        An optional blob name prefix (e.g. the export name) to scope the search, useful if the container holds more than one export.

    .PARAMETER BillingMonth
        The billing month to load cost data for, specified as a [datetime] object. You can specify just month/year, e.g 10/2023. If not specified uses the current date.

    .PARAMETER PreviousMonths
        The number of previous billing months to load. Default: 0.

    .PARAMETER SparkLineSize
        The row height of sparklines to generate (requires PSparklines module). Default: 1.

    .PARAMETER Raw
        Switch: Include the mapped export rows as a property on the returned object.

    .EXAMPLE
        Import-AzCostExport -StorageAccountName 'mycostexports' -ResourceGroupName 'rg-cost' -ContainerName 'costexports'

        Description
        -----------
        Loads cost data for the current billing month from the specified Storage Account container.

    .EXAMPLE
        Import-AzCostExport -StorageAccountName 'mycostexports' -ResourceGroupName 'rg-cost' -ContainerName 'costexports' -BillingMonth 01/2024 -PreviousMonths 3

        Description
        -----------
        Loads cost data from October 2023 to January 2024 from the specified Storage Account container.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]
        $StorageAccountName,

        [Parameter(Mandatory)]
        [string]
        $ResourceGroupName,

        [Parameter(Mandatory)]
        [string]
        $ContainerName,

        [string]
        $Prefix,

        [Alias('Month')]
        [datetime]
        $BillingMonth = (Get-Date),

        [Alias('PrevMonths')]
        [int]
        $PreviousMonths = 0,

        [ValidateRange(1, 10)]
        [int]
        $SparkLineSize = 1,

        [switch]
        $Raw
    )
    process {
        if (-not (Test-AzStorageModule)) {
            Write-Error "This function requires the Az.Storage module. Install it via: Install-Module Az.Storage -Scope CurrentUser"
            return
        }

        try {
            $StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -ErrorAction Stop
            $Context = $StorageAccount.Context

            $BillingPeriods = for ($BillingMonthCount = 0; $BillingMonthCount -le $PreviousMonths; $BillingMonthCount++) {
                (Get-Date $BillingMonth).AddMonths(-$BillingMonthCount).ToString('yyyyMM')
            }

            $Blobs = Get-AzStorageBlob -Container $ContainerName -Prefix $Prefix -Context $Context -ErrorAction Stop |
                Where-Object { $_.Name -like '*.csv' }

            $MatchingBlobs = foreach ($Blob in $Blobs) {
                if ($Blob.Name -match '(?<Start>\d{8})-\d{8}') {
                    $FolderStartDate = [datetime]::ParseExact($Matches.Start, 'yyyyMMdd', $null)

                    if ($FolderStartDate.ToString('yyyyMM') -in $BillingPeriods) {
                        $Blob
                    }
                }
            }

            if (-not $MatchingBlobs) {
                Write-Error "No export blobs found in container '$ContainerName' matching billing period(s): $($BillingPeriods -join ', ')"
                return
            }

            $TempFolder = Join-Path ([System.IO.Path]::GetTempPath()) "AzCostTools_$([guid]::NewGuid())"
            New-Item -Path $TempFolder -ItemType Directory -Force | Out-Null

            try {
                $ConsumptionRecords = foreach ($Blob in $MatchingBlobs) {
                    $Destination = Join-Path $TempFolder (Split-Path $Blob.Name -Leaf)
                    Get-AzStorageBlobContent -Container $ContainerName -Blob $Blob.Name -Destination $Destination -Context $Context -Force -ErrorAction Stop | Out-Null

                    Import-Csv -Path $Destination | ConvertTo-ConsumptionRecord
                }
            }
            finally {
                Remove-Item -Path $TempFolder -Recurse -Force -ErrorAction SilentlyContinue
            }

            $Groups = $ConsumptionRecords | Group-Object -Property SubscriptionName, { $_.UsageStart.ToString('yyyyMM') }

            foreach ($Group in $Groups) {

                $Name = $Group.Group[0].SubscriptionName
                $BillingDate = $Group.Group[0].UsageStart

                $CostObject = New-CostSummaryObject -Name $Name -BillingDate $BillingDate -Consumption $Group.Group -SparkLineSize $SparkLineSize

                if ($Raw) {
                    $CostObject['Consumption_Raw'] = $Group.Group
                }

                [pscustomobject]$CostObject
            }
        }
        catch {
            Write-Error $_
        }
    }
}
