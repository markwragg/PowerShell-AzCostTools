function Get-StorageProductCost ($Consumption) {

    $Consumption | Group-Object Product | ForEach-Object {
        [pscustomobject]@{
            Product = $_.Name
            Cost    = [decimal]($_.Group | Measure-Object PreTaxCost -Sum).Sum
        }
    }
}