function Show-CostAnalysis {
    <#
    .SYNOPSIS
        Performs analysis of the data returned by Get-SubscriptionCost and generates charts and statistics.

    .DESCRIPTION
        Use with Get-SubscriptionCost to generate charts and statistics for Azure consumption data. Useful for
        getting a quick view of the historical costs of one of more Azure subscriptions across one or more months
        and to see the current Total costs, cost by day (as a chart), Top 15 most expensive service types, etc.

    .PARAMETER Cost
        The cost object returned by Get-SubscriptionCost

    .PARAMETER SparkLineSize
        The row height of sparklines to generate (requires PSparkines module). Default: 3.

    .EXAMPLE
        Get-SubscriptionCost | Show-CostAnalysis

        Description
        -----------
        Returns cost analysis information for the current billing month for all subscriptions in the current Azure context.

    .EXAMPLE
        Show-CostAnalysis -Cost $Cost -SparkLineSize 5

        Description
        -----------
        Returns cost analysis information for the cost data in $Cost with Sparkline charts that are 5 rows in height.
    #>
    param(
        [Parameter(ValueFromPipeline)]
        $Cost,

        [ValidateRange(1,10)]
        [int]
        $SparkLineSize = 3
    )
    Begin {
        $CostObject = @()
    }
    Process {
        $CostObject += $Cost
    }
    End {
        $SubscriptionNames = ($CostObject.Name | Get-Unique)

        foreach ($SubscriptionName in $SubscriptionNames) {

            Write-Host "`n$SubscriptionName`n"

            $SubscriptionCost = $CostObject | Where-Object { $_.Name -eq $SubscriptionName }

            $Currency = ($SubscriptionCost | Select-Object -First 1).Currency
            $StartDate = ($SubscriptionCost.DailyCost.Date | Sort-Object { $_ -As [datetime] } | Select-Object -First 1)
            $EndDate = ($SubscriptionCost.DailyCost.Date | Sort-Object { $_ -As [datetime] } -Descending | Select-Object -First 1)
            $TotalDays = ($EndDate - $StartDate).Days
            $Budget = ($SubscriptionCost.ActiveBudgets.BudgetAmount | Select-Object -First 1)
            $DailyBudget = if ($Budget) { $Budget * 12 / 365 }
            $TotalBudget = $DailyBudget * $TotalDays
            $TotalCost = ($SubscriptionCost.Cost | Measure-Object -Sum).Sum 

            $DatePeriodString = "($($StartDate.ToShortDateString()) ~ $($EndDate.ToShortDateString()))"

            Write-Host "Peak Daily Cost                    : $(($SubscriptionCost.DailyCost | Sort-Object Cost -Descending | Select-Object -First 1).Cost | Format-Currency -Currency $Currency)"
            Write-Host "Daily Budget                       :" $(if ($DailyBudget) { "$($DailyBudget | Format-Currency -Currency $Currency)" } else { "(no budget set)" }) 
            Write-Host "Total Budget                       :" $(if ($DailyBudget) { "$($TotalBudget | Format-Currency -Currency $Currency) $DatePeriodString" } else { "(no budget set)" }) 
            Write-Host "Most Expensive Date                : $(($SubscriptionCost.DailyCost | Sort-Object Cost -Descending | Select-Object -First 1).Date.ToShortDateString())"
            Write-Host "Least Expensive Date               : $(($SubscriptionCost.DailyCost | Sort-Object Cost | Select-Object -First 1).Date.ToShortDateString())"
            Write-Host "Total Cost                         : " -NoNewline
            
            $TotalCostColour = if ($Budget -and $TotalCost -gt $TotalBudget) { 'Red' } elseif ($Budget) { 'Green' } else { 'White' }

            Write-Host "$($TotalCost | Format-Currency -Currency $Currency)" -NoNewline -ForegroundColor $TotalCostColour
            Write-Host " $DatePeriodString"
            Write-Host
            
            if (Test-PSparklinesModule) {

                $Emphasis = if ($Budget) {
                    @(
                        (New-Emphasis -Color 'Red' -Predicate { param($x) $x -gt $DailyBudget })
                        (New-Emphasis -Color 'Green' -Predicate { param($x) $x -le $DailyBudget })
                    )
                }
                else {
                    @(
                        (New-Emphasis -Color 'White' -Predicate { $true })
                    )
                }

                # Could use $Host.UI.RawUI.MaxWindowSize here to ensure the charts are neatly wrapped to the current window width

                ($SubscriptionCost.DailyCost | Sort-Object { $_.Date -as [datetime] }).Cost | Get-Sparkline -NumLines $SparkLineSize -Emphasis $Emphasis | Show-Sparkline
                
                ($SubscriptionCost | Group-Object BillingPeriod) | ForEach-Object { 
                    $SpaceCount = if (($_.Group.DailyCost.Date.Count - ($_.Name.Length)) -ge 1) { $_.Group.DailyCost.Date.Count - $_.Name.Length } else { 1 }
                    Write-Host "$($_.Name)" -NoNewline; Write-Host (' ' * $SpaceCount) -NoNewline 
                }

                Write-Host
                Write-Host
            }

            $TotalCostPerService = $SubscriptionCost.CostPerService | Group-Object Service | ForEach-Object { 
                [pscustomobject]@{
                    Service = $_.Name
                    Cost    = ($_.Group.Cost | Measure-Object -Sum).Sum
                }
            } | Sort-Object Cost -Descending

            $MostExpensiveService = $TotalCostPerService | Sort-Object Cost -Descending | Select-Object -First 1
            $LeastExpensiveService = $TotalCostPerService | Where-Object { $_.Cost -gt 0 } | Sort-Object Cost | Select-Object -First 1

            Write-Host "Most Expensive Service             : $($MostExpensiveService.Service)"
            Write-Host "Most Expensive Service Cost        : $($MostExpensiveService.Cost | Format-Currency -Currency $Currency)"
            Write-Host "Least Expensive Service            : $($LeastExpensiveService.Service)"
            Write-Host "Least Expensive Service Cost       : $($LeastExpensiveService.Cost | Format-Currency -Currency $Currency)"
            Write-Host

            $colorArray = [enum]::GetValues([System.ConsoleColor]) | Where-Object { $_ -ne 'Black' }

            $TopServiceCost = $TotalCostPerService | Select-Object -First 15

            if (Test-PSparklinesModule) {
                $TopCostSparkLine = $TopServiceCost.Cost | Get-Sparkline -NumLines $SparkLineSize
                $TopCostSparkLine | ForEach-Object { $_.Color = $colorArray[$_.Col]; $_ } | Show-Sparkline
            }

            Write-Host
            
            $i = 0

            foreach ($TopService in $TopServiceCost) {

                $SpaceCount = if (35 - $TopService.Service.Length -ge 1) { 35 - $TopService.Service.Length } else { 1 }
                Write-Host "$($TopService.Service)" -ForegroundColor $colorArray[$i] -NoNewline; Write-Host $(' ' * $SpaceCount) -NoNewline
                Write-Host ": " -NoNewline; Write-Host "$($TopService.Cost | Format-Currency -Currency $Currency)" -ForegroundColor $colorArray[$i]

                $i++
                if ($i -ge 15) { $i = 0 }
            }
        }

        if ($SubscriptionNames.count -gt 1) {

            $TotalCostPerSubscription = $CostObject | Group-Object Name | ForEach-Object { 
                [pscustomobject]@{
                    Name = $_.Name
                    Cost = ($_.Group.Cost | Measure-Object -Sum).Sum
                }
            } | Sort-Object Cost -Descending

            $MostExpensiveSubscription = $TotalCostPerSubscription | Sort-Object Cost -Descending | Select-Object -First 1
            $LeastExpensiveSubscription = $TotalCostPerSubscription | Where-Object { $_.Cost -gt 0 } | Sort-Object Cost | Select-Object -First 1

            Write-Host
            Write-Host
            Write-Host "Total cost summary $DatePeriodString"
            Write-Host
            Write-Host "Most Expensive Subscription        : $($MostExpensiveSubscription.Name)"
            Write-Host "Most Expensive Subscription Cost   : $($MostExpensiveSubscription.Cost | Format-Currency -Currency $Currency)"
            Write-Host "Least Expensive Subscription       : $($LeastExpensiveSubscription.Name)"
            Write-Host "Least Expensive Subscription Cost  : $($LeastExpensiveSubscription.Cost | Format-Currency -Currency $Currency)"
            Write-Host
            Write-Host "Total Subscription Cost            : $(($TotalCostPerSubscription.Cost | Measure-Object -Sum).Sum | Format-Currency -Currency $Currency)"
            Write-Host

            $TopSubscriptionCost = $TotalCostPerSubscription | Select-Object -First 15

            if (Test-PSparklinesModule) {
                $TopCostSparkLine = $TopSubscriptionCost.Cost | Get-Sparkline -NumLines $SparkLineSize
                $TopCostSparkLine | ForEach-Object { $_.Color = $colorArray[$_.Col]; $_ } | Show-Sparkline
            }

            Write-Host
            
            $i = 0

            foreach ($TopSubscription in $TopSubscriptionCost) {

                $SpaceCount = if (35 - $TopSubscription.Name.Length -ge 1) { 35 - $TopSubscription.Name.Length } else { 1 }
                Write-Host "$($TopSubscription.Name)" -ForegroundColor $colorArray[$i] -NoNewline; Write-Host $(' ' * $SpaceCount) -NoNewline
                Write-Host ": " -NoNewline; Write-Host "$($TopSubscription.Cost | Format-Currency -Currency $Currency)" -ForegroundColor $colorArray[$i]

                $i++
                if ($i -ge 15) { $i = 0 }
            }

            Write-Host
        }
    }
}