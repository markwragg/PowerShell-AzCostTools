function Get-DailyCostChange ($DailyCost, $PrevDailyCost, $ComparePreviousOffset = 1) {

    foreach ($DCost in $DailyCost) {

        $PrevDate = $DCost.Date.AddMonths(-$ComparePreviousOffset)
        $PrevCost = (($PrevDailyCost | Where-Object { $_.Date -eq $PrevDate }).Cost | Measure-Object -Sum).Sum

        if (-not $PrevCost) { $PrevCost = 0 }

        [pscustomobject]@{
            Date       = $DCost.Date
            PrevDate   = $PrevDate.Date
            Cost       = [decimal]$DCost.Cost
            PrevCost   = [decimal]$PrevCost
            CostChange = [decimal]($DCost.Cost - $PrevCost)
        }
    }
}