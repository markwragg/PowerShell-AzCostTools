Describe 'Get-ServiceCost' {

    BeforeAll {
        . $PSScriptRoot/../AzCostTools/Private/Get-ServiceCost.ps1
    }

    Context 'When given a valid input' {

        It 'Returns the expected output' {
            # Arrange
            $consumption = @(
                [pscustomobject]@{
                    UsageStart = '2022-01-01'
                    ConsumedService = 'Microsoft.Storage'
                    PreTaxCost = 10
                },
                [pscustomobject]@{
                    UsageStart = '2022-01-01'
                    ConsumedService = 'Microsoft.Storage'
                    PreTaxCost = 20
                },
                [pscustomobject]@{
                    UsageStart = '2022-01-02'
                    ConsumedService = 'Microsoft.Network'
                    PreTaxCost = 50
                }
            )

            # Act
            $result = Get-ServiceCost -Consumption $consumption

            # Assert
            $result | Should -BeOfType 'pscustomobject'
            $result.Count | Should -Be 2
            $result[0].Service | Should -Be 'Microsoft.Network'
            $result[0].Cost | Should -Be 50
            $result[1].Service | Should -Be 'Microsoft.Storage'
            $result[1].Cost | Should -Be 30
        }
    }
}
