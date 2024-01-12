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
            'INR' = '₹'
            'JPY' = '¥'
            'KRW' = '₩'
            'MXN' = '$'
            'MYR' = 'RM'
            'NOK' = 'kr'
            'NZD' = '$'
            'OMR' = 'R.O'
            'PKR' = 'Rs'
            'QAR' = 'QR'
            'RUB' = '₽'
            'SAR' = 'SR'
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