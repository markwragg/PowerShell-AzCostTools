function Show-CostAnalysis {
    param(
        [Parameter(ValueFromPipeline)]
        $Cost,

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
        foreach ($SubscriptionName in ($CostObject.Name | Get-Unique)) {

            Write-Host "`n$SubscriptionName`n"

            $SubscriptionCost = $CostObject | Where-Object { $_.Name -eq $SubscriptionName }
            $Currency = ($SubscriptionCost | Select-Object -First 1).Currency

            Write-Host "Peak Daily Cost : $(($SubscriptionCost.DailyCost | Sort-Object Cost -Descending | Select-Object -First 1).Cost | Format-Currency -Currency $Currency)"

            $Budget = ($SubscriptionCost.ActiveBudgets.BudgetAmount | Select-Object -First 1)
            $DailyBudget = if ($Budget) { $Budget / 31 }

            if ($DailyBudget) {
                Write-Host "Daily Budget    : $($DailyBudget | Format-Currency -Currency $Currency)"
            }

            if ($Budget) {
                
                ($SubscriptionCost.DailyCost | Sort-Object { $_.Date -as [datetime] }).Cost | Get-Sparkline -NumLines $SparkLineSize -Emphasis @(
                        (New-Emphasis -Color Red -Predicate { param($x) $x -gt $DailyBudget })
                        (New-Emphasis -Color Green -Predicate { param($x) $x -le $DailyBudget })
                ) | Show-Sparkline
            }
            else {
                ($SubscriptionCost.DailyCost | Sort-Object { $_.Date -as [datetime] }).Cost | Get-Sparkline -NumLines $SparkLineSize | Show-Sparkline
            }
                
            ($SubscriptionCost | Group-Object BillingPeriod) | ForEach-Object { 
                $SpaceCount = if (($_.Group.DailyCost.Date.Count - ($_.Name.Length)) -ge 1) { $_.Group.DailyCost.Date.Count - $_.Name.Length } else { 1 }
                Write-Host "$($_.Name)" -NoNewline; Write-Host (' ' * $SpaceCount) -NoNewline 
            }

            Write-Host
        }
    }
}