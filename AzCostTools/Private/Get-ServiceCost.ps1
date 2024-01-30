function Get-ServiceCost ($Consumption) {

    $Consumption | Group-Object ConsumedService | ForEach-Object {
        [pscustomobject]@{
            Service = $_.Name
            Cost    = [decimal]($_.Group | Measure-Object PreTaxCost -Sum).Sum
        }
    }
}