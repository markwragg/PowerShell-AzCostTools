function Format-Currency {
    <#
    .SYNOPSIS
        Returns the currency symbol for a specified Azure supported currency.
    #>
    param(
        [parameter(Mandatory)]
        [string]
        $Currency,

        [parameter(ValueFromPipeline,Mandatory)]
        [decimal]
        $Value
    )

    process {
        $CurrencySymbols = @{
            'AED' = 'DH'
            'ARS' = '$'
            'AUD' = '$'
            'BRL' = 'R$'
            'CAD' = '$'
            'CHF' = 'CHF'
            'DKK' = 'kr.'
            'EUR' = '€'
            'GBP' = '£'
            'HKD' = '$'
            'IDR' = 'Rp'
        }

        "$($CurrencySymbols[$Currency]){0:n2}" -f $Value
    }
}