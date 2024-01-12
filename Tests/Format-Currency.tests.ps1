Describe 'Format-Currency' {

    BeforeAll {
        . $PSScriptRoot/../AzCostTools/Private/Format-Currency.ps1
    }

    Context 'When given a valid currency and value' {

        It 'Returns the currency sympbol and formatted value' {

            $result = Format-Currency -Currency 'USD' -Value 1234.5678
            $result | Should -Be '$1,234.57'
        }
    }
}