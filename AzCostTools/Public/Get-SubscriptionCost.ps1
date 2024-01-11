function Get-SubscriptionCost {
    <#
    .SYNOPSIS
        Retrieves the Azure costs for one or more billing months for one or more subscriptions.

    .DESCRIPTION
        Invokes the Get-AzConsumptionUsageDetail cmdlet against one or more subscriptions to return billing data for a specified number of months.
        If you are interested to see how costs have changed since the previous mont use the -ComparePrevious switch to return additional properties
        that contain the cost data for the previous month and properties that calculate the cost difference.

    .PARAMETER SubscriptionName
        The name or name/s of the Subscriptions to query. If not specified all subscriptions available in the current context will be used.

    .PARAMETER BillingMonth
        The billing month to query for cost data, specified as a [datetime] object. You can specify just month/year, e.g 10/2023. If not specified uses the current date.
        
    .PARAMETER PreviousMonths
        The number of previous billing months to query. Default: 0.

    .PARAMETER SparkLineSize
        The row height of sparklines to generate (requires PSparkines module). Default: 1.

    .PARAMETER ComparePrevious
        Switch: Include values for the previous billing month and adds additional properties that compare the current month to the previous.

    .PARAMETER Raw
        Switch: Include the raw cost consumption data as a property on the returned object.

    .EXAMPLE
        Get-SubscriptionCost

        Description
        -----------
        Returns costs for the current billing month for all subscriptions in the current Azure context.

    .EXAMPLE
        Get-SubscriptionCost -SubscriptionName 'MySubscriptionA'

        Description
        -----------
        Returns costs for the current billing month for the specified subscription name.

    .EXAMPLE
        Get-SubscriptionCost -SubscriptionName 'MySubscriptionA','MySubscriptionB'

        Description
        -----------
        Returns costs for the current billing month for the specified subscription names.

    .EXAMPLE
        Get-SubscriptionCost -BillingMonth 01/2024 -PreviousMonths 3

        Description
        -----------
        Returns costs from October 2023 to January 2024 for all subscriptions in the current Azure context.

    .EXAMPLE
        Get-SubscriptionCost -BillingMonth 01/2024 -PreviousMonths 3 -ComparePrevious

        Description
        -----------
        Returns costs from October 2023 to January 2024 for all subscriptions in the current Azure context and includes properties
        for comparing each month with the one prior.
    #>
    [CmdletBinding()]
    param(
        [string[]]
        $SubscriptionName,

        [datetime]
        $BillingMonth = (Get-Date),

        [ValidateRange(0, 12)]
        [int]
        $PreviousMonths = 0,

        [ValidateRange(1, 10)]
        [int]
        $SparkLineSize = 1,

        [switch]
        $ComparePrevious,

        [switch]
        $Raw
    )

    # Store the users current AZ context before we start
    $PreAzContext = Get-AzContext

    try {

        if (-not $SubscriptionName) {
            $SubscriptionName = (Get-AzSubscription).Name
        }

        foreach ($Name in $SubscriptionName) {

            $Consumption = $null
            $PrevConsumption = $null

            for ($BillingMonthCount = 0; $BillingMonthCount -le $PreviousMonths; $BillingMonthCount++) {

                $BillingDate = (Get-Date $BillingMonth).AddMonths(-$BillingMonthCount)
                $BillingPeriod = $BillingDate.ToString('yyyyMM')

                $PrevBillingDate = (Get-Date $BillingMonth).AddMonths( - (1 + $BillingMonthCount))
                $PrevBillingPeriod = $PrevBillingDate.ToString('yyyyMM')
            
                try {
                    Set-AzContext -Subscription $Name | Out-Null
                
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
                                BudgetAmount    = $Budget.Amount
                                BudgetTimeGrain = $Budget.TimeGrain
                            }
                        }
                    }

                    if (Test-PSparklinesModule) {
                        $CostSparkLine = Get-Sparkline $DailyCost.Cost -NumLines $SparkLineSize | Write-Sparkline
                    }
            
                    $CostObject = [ordered]@{
                        Name                       = $Name
                        BillingPeriod              = $BillingPeriod
                        PrevBillingPeriod          = $PrevBillingPeriod
                        Currency                   = $Currency
                        Cost                       = [math]::Round($Cost)
                        DailyCost_SparkLine        = ($CostSparkLine -join "`n")
                        DailyCost_Min              = [math]::Round(($DailyCostCalc).Minimum)
                        DailyCost_Max              = [math]::Round(($DailyCostCalc).Maximum)
                        DailyCost_Avg              = [math]::Round(($DailyCostCalc).Average)
                        MostExpensive_Date         = ($DailyCost | Sort-Object Cost -Descending | Select-Object -First 1).Date
                        LeastExpensive_Date        = ($DailyCost | Sort-Object Cost | Select-Object -First 1).Date
                        DailyCost                  = $DailyCost
                        CostPerService             = $CostPerService
                        MostExpensiveService       = ($CostPerService | Sort-Object Cost -Descending | Select-Object -First 1).Service
                        MostExpensiveService_Cost  = [math]::Round(($CostPerService | Sort-Object Cost -Descending | Select-Object -First 1).Cost)
                        LeastExpensiveService      = ($CostPerService | Sort-Object Cost | Select-Object -First 1).Service
                        LeastExpensiveService_Cost = [math]::Round(($CostPerService | Sort-Object Cost | Select-Object -First 1).Cost)
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
            
                        if (Test-PSparklinesModule) {
                            $PrevCostSparkLine = Get-Sparkline $PrevDailyCost.Cost -NumLines $SparkLineSize | Write-Sparkline
                        }

                        $ComparePreviousCostObject = [ordered]@{
                            PrevCost                       = [math]::Round($PrevCost, 2)
                            PrevDailyCost_SparkLine        = ($PrevCostSparkLine -join "`n")
                            PrevDailyCost_Min              = [math]::Round(($PrevDailyCostCalc).Minimum)
                            PrevDailyCost_Max              = [math]::Round(($PrevDailyCostCalc).Maximum)
                            PrevDailyCost_Avg              = [math]::Round(($PrevDailyCostCalc).Average)
                            PrevMostExpensiveDate          = ($DailyCost | Sort-Object Cost -Descending | Select-Object -First 1).Date
                            PrevLeastExpensiveDate         = ($DailyCost | Sort-Object Cost | Select-Object -First 1).Date
                            PrevDailyCost                  = $PrevDailyCost
                            PrevCostPerService             = $PrevCostPerService
                            PrevMostExpensiveService       = ($PrevCostPerService | Sort-Object Cost -Descending | Select-Object -First 1).Service
                            PrevMostExpensiveService_Cost  = [math]::Round(($PrevCostPerService | Sort-Object Cost -Descending | Select-Object -First 1).Cost)
                            PrevLeastExpensiveService      = ($PrevCostPerService | Sort-Object Cost | Select-Object -First 1).Service
                            PrevLeastExpensiveService_Cost = [math]::Round(($PrevCostPerService | Sort-Object Cost | Select-Object -First 1).Cost)
                            CostChange                     = [math]::Round($CostChange)
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
    catch {
        throw $_
    }
    finally {
        # Return the user to their previous AZ context (in case it has changed).
        $PreAzContext | Set-AzContext | Out-Null
    }
}