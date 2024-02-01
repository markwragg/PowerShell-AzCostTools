function Get-StorageCost {
    <#
    .SYNOPSIS
        Retrieves the Azure costs for one or more billing months for one or more storage accounts.

    .DESCRIPTION
        Invokes the Get-AzConsumptionUsageDetail cmdlet against one or more storage accounts to return billing data for a specified number of months.
        If you are interested to see how costs have changed since the previous mont use the -ComparePrevious switch to return additional properties
        that contain the cost data for the previous month and properties that calculate the cost difference.

    .PARAMETER AccountName
        The name or name/s of the Storage Account/s to query. If not specified all subscriptions available in the current context will be used.

    .PARAMETER BillingMonth
        The billing month to query for cost data, specified as a [datetime] object. You can specify just month/year, e.g 10/2023. If not specified uses the current date.
        
    .PARAMETER PreviousMonths
        The number of previous billing months to query. Default: 0.

    .PARAMETER SparkLineSize
        The row height of sparklines to generate (requires PSparkines module). Default: 1.

    .PARAMETER ComparePrevious
        Switch: Include values for the previous billing month and adds additional properties that compare the current month to the previous.

    .PARAMETER ComparePreviousOffset
        The number of months prior you want to compare the current billing month to, when using -ComparePrevious, e.g set to 3 to compare to 3 months prior.

    .PARAMETER ExcludeSparklines
        Switch: Do not generate/include Sparklines in the output.

    .PARAMETER Raw
        Switch: Include the raw cost consumption data as a property on the returned object.

    .EXAMPLE
        Get-StorageCost

        Description
        -----------
        Returns costs for the current billing month for all Storage accounts in the current Azure context.

    .EXAMPLE
        Get-StorageCost -AccountName 'MyStorageAccount'

        Description
        -----------
        Returns costs for the current billing month for the specified Storage Account name.

    .EXAMPLE
        Get-StorageCost -AccountName 'MyStorageAccountA','MyStorageAccountB'

        Description
        -----------
        Returns costs for the current billing month for the specified Storage Account names.

    .EXAMPLE
        Get-StorageCost -BillingMonth 01/2024 -PreviousMonths 3

        Description
        -----------
        Returns costs from October 2023 to January 2024 for all Storage Accounts in the current Azure context.

    .EXAMPLE
        Get-StorageCost -BillingMonth 01/2024 -PreviousMonths 3 -ComparePrevious

        Description
        -----------
        Returns costs from October 2023 to January 2024 for all Storage Accounts in the current Azure context and includes properties
        for comparing each month with the one prior.

    .EXAMPLE
        Get-StorageCost -BillingMonth 01/2024 -PreviousMonths 3 -ComparePrevious -ComparePreviousOffset 12

        Description
        -----------
        Returns costs from October 2023 to January 2024 for all Storage Accounts in the current Azure context and includes properties
        for comparing each month with the one 12 months prior
    #>
    [CmdletBinding()]
    param(
        [Alias('Name', 'Account')]
        [string[]]
        $AccountName,

        [Alias('Month')]
        [datetime]
        $BillingMonth = (Get-Date),

        [Alias('PrevMonths')]
        [int]
        $PreviousMonths = 0,

        [ValidateRange(1, 10)]
        [int]
        $SparkLineSize = 1,

        [Alias('ComparePrev')]
        [switch]
        $ComparePrevious,

        [Alias('ComparePrevOffset')]
        [int]
        $ComparePreviousOffset,

        [switch]
        $ExcludeSparklines,

        [switch]
        $Raw
    )
    process {
        
        for ($BillingMonthCount = 0; $BillingMonthCount -le $PreviousMonths; $BillingMonthCount++) {

            $BillingDate = (Get-Date $BillingMonth).AddMonths(-$BillingMonthCount)
            $BillingPeriod = $BillingDate.ToString('yyyyMM')

            if (-not $ComparePreviousOffset) { $ComparePreviousOffset = 1 }
            
            try {
                $StorageConsumption = if ($PrevStorageConsumption -and $ComparePreviousOffset -eq 1) {
                    $PrevStorageConsumption
                }
                else {
                    Write-Progress -Activity "Getting data for billing period $BillingPeriod" -Status 'Microsoft.Storage'
                    Get-AzConsumptionUsageDetail -BillingPeriodName $BillingPeriod | Where-Object { $_.ConsumedService -eq 'Microsoft.Storage' }
                }

                if ($ComparePrevious) {
                    $PrevBillingDate = (Get-Date $BillingMonth).AddMonths( - ($ComparePreviousOffset + $BillingMonthCount))
                    $PrevBillingPeriod = $PrevBillingDate.ToString('yyyyMM')

                    $PrevStorageConsumption = Get-AzConsumptionUsageDetail -BillingPeriodName $PrevBillingPeriod | Where-Object { $_.ConsumedService -eq 'Microsoft.Storage' }
                    Write-Progress -Activity "Getting data for previous billing period $PrevBillingPeriod" -Status 'Microsoft.Storage'
                }

                if (-not $AccountName) {
                    $AccountName = ($StorageConsumption.InstanceName | Sort-Object -Unique)
                }

                foreach ($Name in $AccountName) {

                    $Consumption = $null
                    $PrevConsumption = $null            

                    $Consumption = $StorageConsumption | Where-Object { $_.InstanceName -eq $Name }

                    $CostInstance = $Consumption | Where-Object { $_.InstanceId } | Select-Object -First 1

                    if ($CostInstance) {
                        $Currency = $CostInstance.Currency
                        $InstanceIdArray = $CostInstance.InstanceId -split '/'
                        $ResourceGroupName = if ($InstanceIdArray.count -ge 4) { $InstanceIdArray[4] } else { $null }
                    }
                    else {
                        $Currency = $null
                        $ResourceGroupName = $null
                    }
                       
                    $Cost = ($Consumption | Measure-Object -Property PretaxCost -Sum).Sum

                    $DailyCost = Get-DailyCost -Consumption $Consumption
                    
                    $DailyCostCalc = $DailyCost.Cost | Measure-Object -Maximum -Minimum -Average -Sum

                    $CostPerProduct = Get-StorageProductCost -Consumption $Consumption
                                              
                    if (Test-PSparklinesModule -and -not $ExcludeSparklines) {
                        $CostSparkLine = if ($DailyCost.Count -gt 1) {
                            Get-Sparkline $DailyCost.Cost -NumLines $SparkLineSize | Write-Sparkline
                        }
                    }

                    $CostObject = [ordered]@{
                        PSTypeName          = 'Storage.Cost'
                        StorageAccountName  = $Name
                        ResourceGroupName   = $ResourceGroupName
                        SubscriptionName    = $CostInstance.SubscriptionName
                        BillingPeriod       = $BillingPeriod
                        Currency            = $Currency
                        Cost                = [math]::Round($Cost, 2)
                        DailyCost_SparkLine = ($CostSparkLine -join "`n")
                        DailyCost_Min       = [math]::Round(($DailyCostCalc).Minimum, 2)
                        DailyCost_Max       = [math]::Round(($DailyCostCalc).Maximum, 2)
                        DailyCost_Avg       = [math]::Round(($DailyCostCalc).Average, 2)
                        MostExpensive_Date  = ($DailyCost | Sort-Object Cost -Descending | Select-Object -First 1).Date
                        LeastExpensive_Date = ($DailyCost | Sort-Object Cost | Select-Object -First 1).Date
                        DailyCost           = $DailyCost
                        CostPerProduct      = $CostPerProduct
                    }

                    if ($ExcludeSparklines) { 
                        $CostObject.Remove('DailyCost_SparkLine') 
                        $CostObject['PSTypeName'] = 'Storage.CostNoSparkLines'
                    }

                    if ($ComparePrevious) {

                        $PrevConsumption = $PrevStorageConsumption | Where-Object { $_.InstanceName -eq $Name }

                        if ($PrevConsumption) {
                            $PrevCost = ($PrevConsumption | Measure-Object -Property PretaxCost -Sum).Sum
                        }
                        else {
                            $PrevCost = $null
                        }
                        
                        $PrevDailyCost = Get-DailyCost -Consumption $PrevConsumption
                        $PrevDailyCostCalc = $PrevDailyCost.Cost | Measure-Object -Maximum -Minimum -Average -Sum        
                        $PrevCostPerProduct = Get-StorageProductCost -Consumption $PrevConsumption
                      
                        $CostChange = $Cost - $PrevCost

                        if ($PrevCost -gt 0) {
                            $ChangePct = $CostChange / $PrevCost
                        }
                        else {
                            $ChangePct = $null
                        }

                        $DailyCostChange = Get-DailyCostChange -DailyCost $DailyCost -PrevDailyCost $PrevDailyCost -ComparePreviousOffset $ComparePreviousOffset

                        if (Test-PSparklinesModule -and -not $ExcludeSparklines) {
                            $PrevCostSparkLine = if ($PrevDailyCost.Count -gt 1) {
                                Get-Sparkline $PrevDailyCost.Cost -NumLines $SparkLineSize | Write-Sparkline
                            }
                        }

                        $ComparePreviousCostObject = [ordered]@{
                            PrevBillingPeriod       = $PrevBillingPeriod
                            PrevCost                = [math]::Round($PrevCost, 2)
                            PrevDailyCost_SparkLine = ($PrevCostSparkLine -join "`n")
                            PrevDailyCost_Min       = [math]::Round(($PrevDailyCostCalc).Minimum, 2)
                            PrevDailyCost_Max       = [math]::Round(($PrevDailyCostCalc).Maximum, 2)
                            PrevDailyCost_Avg       = [math]::Round(($PrevDailyCostCalc).Average, 2)
                            PrevMostExpensiveDate   = ($DailyCost | Sort-Object Cost -Descending | Select-Object -First 1).Date
                            PrevLeastExpensiveDate  = ($DailyCost | Sort-Object Cost | Select-Object -First 1).Date
                            PrevDailyCost           = $PrevDailyCost
                            PrevCostPerProduct      = $PrevCostPerProduct
                            CostChange              = [math]::Round($CostChange, 2)
                            CostChange_Pct          = "{0:p2}" -f $ChangePct
                            DailyCostChange         = $DailyCostChange
                        }

                        if ($ExcludeSparklines) { 
                            $ComparePreviousCostObject.Remove('PrevDailyCost_SparkLine')
                            $CostObject['PSTypeName'] = 'Storage.Cost.ComparePrevNoSparklines'
                        }
                        else {
                            $CostObject['PSTypeName'] = 'Storage.Cost.ComparePrev'
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
            }
            catch {
                Write-Error $_
            }
        }
    }
}