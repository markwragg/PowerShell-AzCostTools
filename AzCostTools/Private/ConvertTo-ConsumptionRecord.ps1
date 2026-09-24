function ConvertTo-ConsumptionRecord {
    <#
    .SYNOPSIS
        Converts one row from an Azure Cost Management scheduled export CSV into the same shape returned by Get-AzConsumptionUsageDetail.

    .DESCRIPTION
        Used by Import-AzCostExport to normalise rows read from a Cost Management "Actual Cost" export so they can be
        aggregated by the same private helpers (Get-DailyCost, Get-ServiceCost, New-CostSummaryObject) used for live
        Get-AzConsumptionUsageDetail data -- the same normalisation approach Get-EaConsumptionUsageDetail already uses
        for Enterprise Agreement subscriptions. Column names are resolved defensively (trying several known aliases)
        since they vary slightly between Enterprise Agreement/Microsoft Customer Agreement exports and export API versions.

    .PARAMETER Row
        A single row object, as returned by Import-Csv, from a Cost Management scheduled export file.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [pscustomobject]
        $Row
    )
    process {
        function Get-RowValue ($Names) {
            foreach ($ColumnName in $Names) {
                if ($Row.PSObject.Properties.Name -contains $ColumnName -and $Row.$ColumnName) {
                    return $Row.$ColumnName
                }
            }
        }

        $UsageStart = Get-RowValue 'Date', 'UsageDateTime', 'UsageStart'
        $PreTaxCost = Get-RowValue 'CostInBillingCurrency', 'Cost', 'PreTaxCost'
        $UsageQuantity = Get-RowValue 'Quantity', 'UsageQuantity'

        [pscustomobject]@{
            SubscriptionGuid  = Get-RowValue 'SubscriptionId', 'SubscriptionGuid'
            SubscriptionName  = Get-RowValue 'SubscriptionName'
            InstanceName      = Get-RowValue 'ResourceId', 'ResourceName', 'InstanceId'
            ResourceGroupName = Get-RowValue 'ResourceGroup', 'ResourceGroupName'
            UsageStart        = if ($UsageStart) { [datetime]$UsageStart }
            ConsumedService   = Get-RowValue 'ConsumedService'
            Product           = Get-RowValue 'ProductName', 'Product'
            Currency          = Get-RowValue 'BillingCurrencyCode', 'BillingCurrency', 'Currency'
            MeterDetails      = @{
                MeterName        = Get-RowValue 'MeterName'
                MeterCategory    = Get-RowValue 'MeterCategory'
                MeterSubCategory = Get-RowValue 'MeterSubCategory'
                Unit             = Get-RowValue 'UnitOfMeasure'
            }
            UsageQuantity     = if ($UsageQuantity) { [decimal]$UsageQuantity } else { 0 }
            PreTaxCost        = if ($PreTaxCost) { [decimal]$PreTaxCost } else { 0 }
        }
    }
}
