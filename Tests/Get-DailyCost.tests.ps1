Describe 'Get-DailyCost' {

    BeforeAll {
        . $PSScriptRoot/../AzCostTools/Private/Get-DailyCost.ps1
    }

    Context 'When given a valid input' {

        It 'Returns the expected output' {
            # Arrange
            $consumption = @(
                [pscustomobject]@{
                    UsageStart = '2022-01-01'
                    PreTaxCost = 10
                },
                [pscustomobject]@{
                    UsageStart = '2022-01-01'
                    PreTaxCost = 20
                },
                [pscustomobject]@{
                    UsageStart = '2022-01-02'
                    PreTaxCost = 30
                }
            )

            # Act
            $result = Get-DailyCost -Consumption $consumption

            # Assert
            $result | Should -BeOfType 'pscustomobject'
            $result.Count | Should -Be 2
            $result[0].Date | Should -Be (Get-Date '2022-01-01')
            $result[0].Cost | Should -Be 30
            $result[1].Date | Should -Be (Get-Date '2022-01-02')
            $result[1].Cost | Should -Be 30
        }
    }
}
