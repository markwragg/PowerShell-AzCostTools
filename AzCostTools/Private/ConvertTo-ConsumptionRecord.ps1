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
        function Get-RowValue ($Row, $Names) {
            foreach ($ColumnName in $Names) {
                if ($Row.PSObject.Properties.Name -contains $ColumnName -and $Row.$ColumnName) {
                    return $Row.$ColumnName
                }
            }
        }

        $UsageStart = Get-RowValue $Row 'Date', 'UsageDateTime', 'UsageStart'
        $PreTaxCost = Get-RowValue $Row 'CostInBillingCurrency', 'Cost', 'PreTaxCost'
        $UsageQuantity = Get-RowValue $Row 'Quantity', 'UsageQuantity'

        [pscustomobject]@{
            SubscriptionGuid  = Get-RowValue $Row 'SubscriptionId', 'SubscriptionGuid'
            SubscriptionName  = Get-RowValue $Row 'SubscriptionName'
            InstanceName      = Get-RowValue $Row 'ResourceId', 'ResourceName', 'InstanceId'
            ResourceGroupName = Get-RowValue $Row 'ResourceGroup', 'ResourceGroupName'
            UsageStart        = if ($UsageStart) { [datetime]$UsageStart }
            ConsumedService   = Get-RowValue $Row 'ConsumedService'
            Product           = Get-RowValue $Row 'ProductName', 'Product'
            Currency          = Get-RowValue $Row 'BillingCurrencyCode', 'BillingCurrency', 'Currency'
            MeterDetails      = @{
                MeterName        = Get-RowValue $Row 'MeterName'
                MeterCategory    = Get-RowValue $Row 'MeterCategory'
                MeterSubCategory = Get-RowValue $Row 'MeterSubCategory'
                Unit             = Get-RowValue $Row 'UnitOfMeasure'
            }
            UsageQuantity     = if ($UsageQuantity) { [decimal]$UsageQuantity } else { 0 }
            PreTaxCost        = if ($PreTaxCost) { [decimal]$PreTaxCost } else { 0 }
        }
    }
}
