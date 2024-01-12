Describe 'Get-DailyCostChange' {

    BeforeAll {
        . $PSScriptRoot/../AzCostTools/Private/Get-DailyCostChange.ps1
    }

    Context 'When given a valid input' {

        It 'Returns the expected output' {
            # Arrange
            $DailyCost = @(
                [pscustomobject]@{
                    Date = Get-Date ('2022-02-01')
                    Cost = 10
                },
                [pscustomobject]@{
                    Date = Get-Date ('2022-02-02')
                    Cost = 20
                }
            )

            $PrevDailyCost = @(
                [pscustomobject]@{
                    Date = Get-Date ('2022-01-01')
                    Cost = 5
                }
            )

            # Act
            $result = Get-DailyCostChange -DailyCost $DailyCost -PrevDailyCost $PrevDailyCost

            # Assert
            $result | Should -BeOfType 'pscustomobject'
            $result.Count | Should -Be 2
            $result[0].Date | Should -Be (Get-Date '2022-02-01')
            $result[0].PrevDate | Should -Be (Get-Date '2022-01-01')
            $result[0].Cost | Should -Be 10
            $result[0].PrevCost | Should -Be 5
            $result[0].CostChange | Should -Be 5

            $result[1].Date | Should -Be (Get-Date '2022-02-02')
            $result[1].PrevDate | Should -Be $null
            $result[1].Cost | Should -Be 20
            $result[1].PrevCost | Should -Be 0
            $result[1].CostChange | Should -Be 20
        }
    }
}
