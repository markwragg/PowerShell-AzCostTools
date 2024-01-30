function Get-DailyCost ($Consumption) {

    $Consumption | Group-Object UsageStart | ForEach-Object {
        [pscustomobject]@{ 
            Date = (Get-Date $_.Name)
            Cost = [decimal]($_.Group | Measure-Object PreTaxCost -Sum).Sum 
        }
    }
}