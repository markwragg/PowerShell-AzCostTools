function Format-Currency {
    <#
    .SYNOPSIS
        Helper function returns the currency symbol for a specified Azure supported currency.
    #>
    param(
        [string]
        [ValidateLength(3)]
        [parameter(Mandatory)]
        $Currency,

        [parameter(ValueFromPipeline)]
        [parameter(Mandatory)]
        $Value
    )

    process {
        $CurrencySymbols = @{
            'AED' = 'د.إ'
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
            'INR' = '₹'
            'JPY' = '¥'
            'KRW' = '₩'
            'MXN' = '$'
            'MYR' = 'RM'
            'NOK' = 'kr'
            'NZD' = '$'
            'OMR' = 'ر.ع.'
            'PKR' = 'Rs'
            'QAR' = 'ق.ر'
            'RUB' = '₽'
            'SAR' = '﷼'
            'SEK' = 'kr'
            'TWD' = 'NT$'
            'TRY' = '₺'
            'USD' = '$'
            'UZS' = 'лв'
            'ZAR' = 'R'
        }

        "$($CurrencySymbols[$Currency]){0:n2}" -f $Value
    }
}