Describe 'Get-StorageProductCost' {

    BeforeAll {
        . $PSScriptRoot/../AzCostTools/Private/Get-StorageProductCost.ps1
    }

    Context 'When given a valid input' {

        It 'Returns the expected output' {
            # Arrange
            $consumption = @(
                [pscustomobject]@{
                    UsageStart      = '2022-01-01'
                    ConsumedService = 'Microsoft.Storage'
                    Product         = 'SomeProduct'
                    PreTaxCost      = 10
                },
                [pscustomobject]@{
                    UsageStart      = '2022-01-01'
                    ConsumedService = 'Microsoft.Storage'
                    Product         = 'SomeProduct'
                    PreTaxCost      = 20
                },
                [pscustomobject]@{
                    UsageStart      = '2022-01-02'
                    ConsumedService = 'Microsoft.Network'
                    Product         = 'SomeOtherProduct'
                    PreTaxCost      = 50
                }
            )

            # Act
            $result = Get-StorageProductCost -Consumption $consumption

            # Assert
            $result | Should -BeOfType 'pscustomobject'
            $result.Count | Should -Be 2
            ($result | Where-Object { $_.Product -eq 'SomeProduct' }).Cost | Should -Be 30
            ($result | Where-Object { $_.Product -eq 'SomeOtherProduct' }).Cost | Should -Be 50
        }
    }
}
