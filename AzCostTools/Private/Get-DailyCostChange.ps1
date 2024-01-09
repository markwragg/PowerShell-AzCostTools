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