function New-CostSummaryObject {
    <#
    .SYNOPSIS
        Builds a Subscription.Cost object by aggregating a set of consumption records for a billing period.

    .DESCRIPTION
        Shared aggregation logic used by Get-SubscriptionCost (querying Azure directly) and Import-AzCostExport
        (reading a Cost Management scheduled export from a Storage Account), so both produce an identically shaped
        Subscription.Cost object that works with Show-CostAnalysis and the Subscription.Cost.Format.ps1xml view.

    .PARAMETER Name
        The name of the subscription the consumption records belong to.

    .PARAMETER BillingDate
        The billing month the consumption records belong to. Used to derive BillingPeriod and to determine which budgets are currently active.

    .PARAMETER Consumption
        The consumption records to aggregate (in the same shape as Get-AzConsumptionUsageDetail/Get-EaConsumptionUsageDetail output).

    .PARAMETER SparkLineSize
        The row height of sparklines to generate (requires PSparklines module). Default: 1.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]
        $Name,

        [Parameter(Mandatory)]
        [datetime]
        $BillingDate,

        $Consumption,

        [ValidateRange(1, 10)]
        [int]
        $SparkLineSize = 1
    )

    $BillingPeriod = $BillingDate.ToString('yyyyMM')

    $Currency = ($Consumption | Select-Object -First 1).Currency
    $Cost = ($Consumption | Measure-Object -Property PretaxCost -Sum).Sum

    $DailyCost = Get-DailyCost -Consumption $Consumption
    $DailyCostCalc = $DailyCost.Cost | Measure-Object -Maximum -Minimum -Average -Sum
    $CostPerService = Get-ServiceCost -Consumption $Consumption
    $Budgets = Get-AzConsumptionBudget -ErrorAction SilentlyContinue

    $ActiveBudgets = foreach ($Budget in $Budgets) {

        if ($BillingDate -ge $Budget.TimePeriod.StartDate -and $Budget.TimePeriod.EndDate -ge $BillingDate) {
            [pscustomobject]@{
                BudgetAmount    = $Budget.Amount
                BudgetTimeGrain = $Budget.TimeGrain
            }
        }
    }

    if (Test-PSparklinesModule) {
        $CostSparkLine = if ($DailyCost.Count -gt 1) {
            Get-Sparkline $DailyCost.Cost -NumLines $SparkLineSize | Write-Sparkline
        }
    }

    [ordered]@{
        PSTypeName                 = 'Subscription.Cost'
        Name                       = $Name
        BillingPeriod              = $BillingPeriod
        Currency                   = $Currency
        Cost                       = [math]::Round($Cost, 2)
        DailyCost_SparkLine        = ($CostSparkLine -join "`n")
        DailyCost_Min              = [math]::Round(($DailyCostCalc).Minimum, 2)
        DailyCost_Max              = [math]::Round(($DailyCostCalc).Maximum, 2)
        DailyCost_Avg              = [math]::Round(($DailyCostCalc).Average, 2)
        MostExpensive_Date         = ($DailyCost | Sort-Object Cost -Descending | Select-Object -First 1).Date
        LeastExpensive_Date        = ($DailyCost | Sort-Object Cost | Select-Object -First 1).Date
        DailyCost                  = $DailyCost
        CostPerService             = $CostPerService
        MostExpensiveService       = ($CostPerService | Sort-Object Cost -Descending | Select-Object -First 1).Service
        MostExpensiveService_Cost  = [math]::Round(($CostPerService | Sort-Object Cost -Descending | Select-Object -First 1).Cost, 2)
        LeastExpensiveService      = ($CostPerService | Sort-Object Cost | Select-Object -First 1).Service
        LeastExpensiveService_Cost = [math]::Round(($CostPerService | Sort-Object Cost | Select-Object -First 1).Cost, 2)
        ActiveBudgets              = $ActiveBudgets
    }
}
