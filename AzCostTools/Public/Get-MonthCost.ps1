function Get-MonthCost {
    <#
    .SYNOPSIS
        Retrieves the cost for a specified month for one or more subscriptions and compares them to the month prior.

    .EXAMPLE
        Get-MonthCost
    #>
    [CmdletBinding()]
    param(
        [string[]]
        $SubscriptionName,

        [datetime]
        $Month = (Get-Date),

        [int]
        $PreviousMonths = 0,

        [int]
        $SparkLineSize = 1,

        [switch]
        $ComparePrevious,

        [switch]
        $Raw
    )

    if (-not (Get-Module PSparklines -ListAvailable)) {
        Write-Warning 'PSparklines module not installed. Sparklines will not be generated. To fix execute: Install-Module PSparkines'
    }

    function Get-DailyCost ($Consumption) {

        $Consumption | Group-Object UsageStart | ForEach-Object {
            [pscustomobject]@{ 
                Date = (Get-Date $_.Name)
                Cost = ($_.Group | Measure-Object PreTaxCost -Sum).Sum 
            }
        }
    }

    function Get-DailyCostChange ($DailyCost, $PrevDailyCost) {

        foreach ($DCost in $DailyCost) {

            $PrevDate = $PrevDailyCost | where-Object { $_.Date.AddMonths(1) -eq $DCost.Date }
            $PrevCost = ($PrevDate.Cost | Measure-Object -Sum).Sum

            if (-not $PrevCost) { $PrevCost = 0 }

            [pscustomobject]@{ 
                Date       = $DCost.Date
                PrevDate   = $PrevDate.Date
                Cost       = $DCost.Cost
                PrevCost   = $PrevCost
                CostChange = ($DCost.Cost - $PrevCost)
            }
        }
    }

    function Get-ServiceCost ($Consumption) {

        $Consumption | Group-Object ConsumedService | ForEach-Object {
            [pscustomobject]@{
                Service = $_.Name
                Cost    = ($_.Group | Measure-Object PreTaxCost -Sum).Sum
            }
        }
    }

    if (-not $SubscriptionName) {
        $SubscriptionName = (Get-AzSubscription).Name
    }

    
    foreach ($Name in $SubscriptionName) {

        $Consumption = $null
        $PrevConsumption = $null

        for ($MonthCount = 0; $MonthCount -le $PreviousMonths; $MonthCount++) {

            $BillingDate = (Get-Date $Month).AddMonths(-$MonthCount)
            $BillingPeriod = $BillingDate.ToString('yyyyMM')

            $PrevBillingDate = (Get-Date $Month).AddMonths( - (1 + $MonthCount))
            $PrevBillingPeriod = $PrevBillingDate.ToString('yyyyMM')
            
            try {
                Select-AzSubscription -Subscription $Name | Out-Null
                
                $Consumption = if ($PrevConsumption) {
                    $PrevConsumption
                }
                else {
                    Write-Progress -Activity "Getting data for billing period $BillingPeriod" -Status $Name
                    Get-AzConsumptionUsageDetail -BillingPeriodName $BillingPeriod -ErrorAction Stop
                }
            
                $Currency = ($Consumption | Select-Object -First 1).Currency
                $Cost = ($Consumption | Measure-Object -Property PretaxCost -Sum).Sum

                $DailyCost = Get-DailyCost -Consumption $Consumption
                $DailyCostCalc = $DailyCost.Cost | Measure-Object -Maximum -Minimum -Average -Sum
                $CostPerService = Get-ServiceCost -Consumption $Consumption
                $Budgets = Get-AzConsumptionBudget

                $ActiveBudgets = foreach ($Budget in $Budgets) {

                    if ($BillingDate -ge $Budget.TimePeriod.StartDate -and $Budget.TimePeriod.EndDate -ge $BillingDate) {
                        [pscustomobject]@{
                            BudgetAmount = $Budget.Amount
                            BudgetTimeGrain = $Budget.TimeGrain
                        }
                    }
                }

                if (Get-Module PSparklines -ListAvailable) {
                    $CostSparkLine = Get-Sparkline $DailyCost.Cost -NumLines $SparkLineSize | Write-Sparkline
                }
            
                $CostObject = [ordered]@{
                    Name                       = $Name
                    BillingPeriod              = $BillingPeriod
                    PrevBillingPeriod          = $PrevBillingPeriod
                    Currency                   = $Currency
                    Cost                       = "{0:n2}" -f $Cost
                    DailyCost_SparkLine        = ($CostSparkLine -join "`n")
                    DailyCost_Min              = "{0:n2}" -f ($DailyCostCalc).Minimum
                    DailyCost_Max              = "{0:n2}" -f ($DailyCostCalc).Maximum
                    DailyCost_Avg              = "{0:n2}" -f ($DailyCostCalc).Average
                    MostExpensive_Date         = ($DailyCost | Sort-Object Cost -Descending | Select-Object -First 1).Date
                    LeastExpensive_Date        = ($DailyCost | Sort-Object Cost | Select-Object -First 1).Date
                    DailyCost                  = $DailyCost
                    CostPerService             = $CostPerService
                    MostExpensiveService       = ($CostPerService | Sort-Object Cost -Descending | Select-Object -First 1).Service
                    MostExpensiveService_Cost  = "{0:n2}" -f ($CostPerService | Sort-Object Cost -Descending | Select-Object -First 1).Cost
                    LeastExpensiveService      = ($CostPerService | Sort-Object Cost | Select-Object -First 1).Service
                    LeastExpensiveService_Cost = "{0:n2}" -f ($CostPerService | Sort-Object Cost | Select-Object -First 1).Cost
                    ActiveBudgets              = $ActiveBudgets
                }

                if ($ComparePrevious) {
                    Write-Progress -Activity "Getting data for previous billing period $PrevBillingPeriod" -Status $Name
                    $PrevConsumption = Get-AzConsumptionUsageDetail -BillingPeriodName $PrevBillingPeriod -ErrorAction Stop

                    $PrevCost = ($PrevConsumption | Measure-Object -Property PretaxCost -Sum).Sum
                    $PrevDailyCost = Get-DailyCost -Consumption $PrevConsumption
                    $PrevDailyCostCalc = $PrevDailyCost.Cost | Measure-Object -Maximum -Minimum -Average -Sum        
                    $PrevCostPerService = Get-ServiceCost -Consumption $PrevConsumption

                    $CostChange = $Cost - $PrevCost
                    $ChangePct = $CostChange / $PrevCost
                    $DailyCostChange = Get-DailyCostChange -DailyCost $DailyCost -PrevDailyCost $PrevDailyCost
            
                    if (Get-Module PSparklines -ListAvailable) {
                        $PrevCostSparkLine = Get-Sparkline $PrevDailyCost.Cost -NumLines $SparkLineSize | Write-Sparkline
                    }
                }

                if ($ComparePrevious) {

                    $ComparePreviousCostObject = [ordered]@{
                        PrevCost                       = "{0:n2}" -f $PrevCost
                        PrevDailyCost_SparkLine        = ($PrevCostSparkLine -join "`n")
                        PrevDailyCost_Min              = "{0:n2}" -f ($PrevDailyCostCalc).Minimum
                        PrevDailyCost_Max              = "{0:n2}" -f ($PrevDailyCostCalc).Maximum
                        PrevDailyCost_Avg              = "{0:n2}" -f ($PrevDailyCostCalc).Average
                        PrevMostExpensiveDate          = ($DailyCost | Sort-Object Cost -Descending | Select-Object -First 1).Date
                        PrevLeastExpensiveDate         = ($DailyCost | Sort-Object Cost | Select-Object -First 1).Date
                        PrevDailyCost                  = $PrevDailyCost
                        PrevCostPerService             = $PrevCostPerService
                        PrevMostExpensiveService       = ($PrevCostPerService | Sort-Object Cost -Descending | Select-Object -First 1).Service
                        PrevMostExpensiveService_Cost  = "{0:n2}" -f ($PrevCostPerService | Sort-Object Cost -Descending | Select-Object -First 1).Cost
                        PrevLeastExpensiveService      = ($PrevCostPerService | Sort-Object Cost | Select-Object -First 1).Service
                        PrevLeastExpensiveService_Cost = "{0:n2}" -f ($PrevCostPerService | Sort-Object Cost | Select-Object -First 1).Cost
                        CostChange                     = "{0:n2}" -f $CostChange
                        CostChange_Pct                 = "{0:p2}" -f $ChangePct
                        DailyCostChange                = $DailyCostChange
                    }

                    $CostObject += $ComparePreviousCostObject
                }

                if ($Raw) {

                    $RawCostObject = [ordered]@{
                        Consumption_Raw = $Consumption
                    }

                    $CostObject += $RawCostObject
                }

                if ($ComparePrevious -and $Raw) {

                    $PrevRawCostObject = [ordered]@{
                        PrevConsumption_Raw = $PrevConsumption
                    }

                    $CostObject += $PrevRawCostObject
                }

                [pscustomobject]$CostObject
            }
            catch {
                Write-Error "Error retrieving costs for subscription ${Name}: $($_.Exception)"
            }
        }
    }
}