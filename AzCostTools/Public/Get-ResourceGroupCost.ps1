function Get-ResourceGroupCost {
    <#
    .SYNOPSIS
        Retrieves the Azure costs for one or more billing months for one or more resource groups.

    .DESCRIPTION
        Invokes the Get-AzConsumptionUsageDetail cmdlet and groups the results by resource group to return billing data for a specified number of months.
        If you are interested to see how costs have changed since the previous month use the -ComparePrevious switch to return additional properties
        that contain the cost data for the previous month and properties that calculate the cost difference. Specify multiple resource group names to
        return an object for each so that their costs can be compared against each other. When one or more resource group names are specified, each
        is queried directly (filtered server-side) rather than pulling every resource in the subscription and filtering locally, which is significantly
        faster. If no resource group name is specified every resource group in the billing data is discovered and returned instead, which requires an
        unfiltered pull.

    .PARAMETER ResourceGroupName
        The name or name/s of the Resource Group/s to query. If not specified every resource group found in the billing data will be used.

    .PARAMETER SubscriptionName
        The name or name/s of the Subscription/s to query the Resource Group/s within. If not specified the current Azure context's subscription is used.

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

    .PARAMETER EaSubscription
        Switch: Force use of alternative consumption collection script for Enterprise Agreement subscriptions.

    .PARAMETER EaSubscriptionKind
        Specify the kind of Enterprise Agreement, modern or legacy. Default: modern.

    .EXAMPLE
        Get-ResourceGroupCost

        Description
        -----------
        Returns costs for the current billing month for every Resource Group found in the current Azure context's billing data.

    .EXAMPLE
        Get-ResourceGroupCost -ResourceGroupName 'MyResourceGroup'

        Description
        -----------
        Returns costs for the current billing month for the specified Resource Group name.

    .EXAMPLE
        Get-ResourceGroupCost -ResourceGroupName 'MyResourceGroupA','MyResourceGroupB'

        Description
        -----------
        Returns costs for the current billing month for the specified Resource Group names, so that they can be compared against each other.

    .EXAMPLE
        Get-ResourceGroupCost -ResourceGroupName 'MyResourceGroup' -SubscriptionName 'MySubscriptionA','MySubscriptionB'

        Description
        -----------
        Returns costs for the current billing month for the specified Resource Group name, queried within each of the specified subscriptions.

    .EXAMPLE
        Get-ResourceGroupCost -BillingMonth 01/2024 -PreviousMonths 3

        Description
        -----------
        Returns costs from October 2023 to January 2024 for every Resource Group found in the current Azure context's billing data.

    .EXAMPLE
        Get-ResourceGroupCost -BillingMonth 01/2024 -PreviousMonths 3 -ComparePrevious

        Description
        -----------
        Returns costs from October 2023 to January 2024 for every Resource Group found in the current Azure context's billing data and includes properties
        for comparing each month with the one prior.

    .EXAMPLE
        Get-ResourceGroupCost -BillingMonth 01/2024 -PreviousMonths 3 -ComparePrevious -ComparePreviousOffset 12

        Description
        -----------
        Returns costs from October 2023 to January 2024 for every Resource Group found in the current Azure context's billing data and includes properties
        for comparing each month with the one 12 months prior
    #>
    [CmdletBinding()]
    param(
        [Alias('Name', 'RG')]
        [string[]]
        $ResourceGroupName,

        [Alias('Subscription')]
        [string[]]
        $SubscriptionName,

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
        $Raw,

        [switch]
        $EaSubscription,

        [ValidateSet('Legacy', 'Modern')]
        [string]
        $EaSubscriptionKind = 'Modern'
    )
    begin {
        # Store the user's current AZ context before we start, so it can be restored after querying other subscriptions
        $PreAzContext = Get-AzContext
    }
    process {

        # An empty string (rather than $null) is used as the "no -SubscriptionName given" sentinel -- a single-element
        # array whose only element is $null collapses to a bare $null when returned from the if/else expression below,
        # which would make the foreach loop skip its one iteration entirely.
        $SubscriptionsToQuery = if ($SubscriptionName) { $SubscriptionName } else { , '' }

        try {
            foreach ($Sub in $SubscriptionsToQuery) {

                try {
                    if ($Sub -and $PreAzContext.Subscription.Name -ne $Sub) {
                        Set-AzContext -Subscription $Sub -ErrorAction Stop | Out-Null
                    }

                    $isEaSubscription = $EaSubscription
                    $RGNames = $ResourceGroupName
                    $PrevConsumption = $null

                    for ($BillingMonthCount = 0; $BillingMonthCount -le $PreviousMonths; $BillingMonthCount++) {

                        $BillingDate = (Get-Date $BillingMonth).AddMonths(-$BillingMonthCount)
                        $BillingPeriod = $BillingDate.ToString('yyyyMM')

                        if (-not $ComparePreviousOffset) { $ComparePreviousOffset = 1 }

                        try {
                            $Consumption = if ($PrevConsumption -and $ComparePreviousOffset -eq 1) {
                                $PrevConsumption
                            }
                            else {
                                Write-Progress -Activity "Getting data for billing period $BillingPeriod" -Status $(if ($Sub) { $Sub } else { 'ResourceGroups' })

                                $Result = Get-ResourceGroupConsumption -BillingPeriod $BillingPeriod -ResourceGroupName $RGNames -IsEaSubscription $isEaSubscription -EaSubscriptionKind $EaSubscriptionKind
                                $isEaSubscription = $Result.IsEaSubscription
                                $Result.Consumption
                            }

                            if ($ComparePrevious) {
                                $PrevBillingDate = (Get-Date $BillingMonth).AddMonths( - ($ComparePreviousOffset + $BillingMonthCount))
                                $PrevBillingPeriod = $PrevBillingDate.ToString('yyyyMM')

                                Write-Progress -Activity "Getting data for previous billing period $PrevBillingPeriod" -Status $(if ($Sub) { $Sub } else { 'ResourceGroups' })

                                $PrevResult = Get-ResourceGroupConsumption -BillingPeriod $PrevBillingPeriod -ResourceGroupName $RGNames -IsEaSubscription $isEaSubscription -EaSubscriptionKind $EaSubscriptionKind
                                $isEaSubscription = $PrevResult.IsEaSubscription
                                $PrevConsumption = $PrevResult.Consumption
                            }

                            if (-not $RGNames) {
                                $RGNames = $Consumption | ForEach-Object {
                                    Get-ResourceGroupNameFromInstanceId $_.InstanceId
                                } | Where-Object { $_ } | Sort-Object -Unique
                            }

                            foreach ($Name in $RGNames) {

                                $GroupConsumption = $null
                                $PrevGroupConsumption = $null

                                $GroupConsumption = $Consumption | Where-Object { (Get-ResourceGroupNameFromInstanceId $_.InstanceId) -eq $Name }

                                $CostInstance = $GroupConsumption | Where-Object { $_.InstanceId } | Select-Object -First 1

                                $Currency = $CostInstance.Currency
                                $CostSubscriptionName = if ($Sub) { $Sub } else { $CostInstance.SubscriptionName }

                                $Cost = ($GroupConsumption | Measure-Object -Property PretaxCost -Sum).Sum

                                $DailyCost = Get-DailyCost -Consumption $GroupConsumption

                                $DailyCostCalc = $DailyCost.Cost | Measure-Object -Maximum -Minimum -Average -Sum

                                $CostPerService = Get-ServiceCost -Consumption $GroupConsumption

                                if (Test-PSparklinesModule -and -not $ExcludeSparklines) {
                                    $CostSparkLine = if ($DailyCost.Count -gt 1) {
                                        Get-Sparkline $DailyCost.Cost -NumLines $SparkLineSize | Write-Sparkline
                                    }
                                }

                                $CostObject = [ordered]@{
                                    PSTypeName          = 'ResourceGroup.Cost'
                                    ResourceGroupName   = $Name
                                    SubscriptionName    = $CostSubscriptionName
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
                                    CostPerService      = $CostPerService
                                }

                                if ($ExcludeSparklines) {
                                    $CostObject.Remove('DailyCost_SparkLine')
                                    $CostObject['PSTypeName'] = 'ResourceGroup.CostNoSparkLines'
                                }

                                if ($ComparePrevious) {

                                    $PrevGroupConsumption = $PrevConsumption | Where-Object { (Get-ResourceGroupNameFromInstanceId $_.InstanceId) -eq $Name }

                                    if ($PrevGroupConsumption) {
                                        $PrevCost = ($PrevGroupConsumption | Measure-Object -Property PretaxCost -Sum).Sum
                                    }
                                    else {
                                        $PrevCost = $null
                                    }

                                    $PrevDailyCost = Get-DailyCost -Consumption $PrevGroupConsumption
                                    $PrevDailyCostCalc = $PrevDailyCost.Cost | Measure-Object -Maximum -Minimum -Average -Sum
                                    $PrevCostPerService = Get-ServiceCost -Consumption $PrevGroupConsumption

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
                                        PrevCostPerService      = $PrevCostPerService
                                        CostChange              = [math]::Round($CostChange, 2)
                                        CostChange_Pct          = "{0:p2}" -f $ChangePct
                                        DailyCostChange         = $DailyCostChange
                                    }

                                    if ($ExcludeSparklines) {
                                        $ComparePreviousCostObject.Remove('PrevDailyCost_SparkLine')
                                        $CostObject['PSTypeName'] = 'ResourceGroup.Cost.ComparePrevNoSparklines'
                                    }
                                    else {
                                        $CostObject['PSTypeName'] = 'ResourceGroup.Cost.ComparePrev'
                                    }

                                    $CostObject += $ComparePreviousCostObject
                                }

                                if ($Raw) {

                                    $RawCostObject = [ordered]@{
                                        Consumption_Raw = $GroupConsumption
                                    }

                                    $CostObject += $RawCostObject
                                }

                                if ($ComparePrevious -and $Raw) {

                                    $PrevRawCostObject = [ordered]@{
                                        PrevConsumption_Raw = $PrevGroupConsumption
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
                catch {
                    Write-Error $_
                }
            }
        }
        finally {
            if ($SubscriptionName) {
                $PreAzContext | Set-AzContext | Out-Null
            }
        }
    }
}
