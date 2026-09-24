Describe 'Restore-CostObjectType' {

    BeforeAll {
        . $PSScriptRoot/../AzCostTools/Private/Restore-CostObjectType.ps1
    }

    Context 'When given a deserialized cost object' {

        It 'Restores the PSTypeName and recasts Date-suffixed properties to [datetime], including within nested arrays' {
            # Arrange
            $InputObject = [pscustomobject]@{
                Name                = 'SomeSubscription'
                BillingPeriod       = '202401'
                MostExpensive_Date  = '2024-01-02T00:00:00'
                LeastExpensive_Date = '2024-01-05T00:00:00'
                DailyCost           = @(
                    [pscustomobject]@{ Date = '2024-01-01T00:00:00'; Cost = 10 },
                    [pscustomobject]@{ Date = '2024-01-02T00:00:00'; Cost = 20 }
                )
                DailyCostChange     = @(
                    [pscustomobject]@{ Date = '2024-01-01T00:00:00'; PrevDate = '2023-12-01T00:00:00'; Cost = 10; PrevCost = 5; CostChange = 5 }
                )
                ActiveBudgets       = @(
                    [pscustomobject]@{ BudgetAmount = 1000; BudgetTimeGrain = 'Monthly' }
                )
            }

            # Act
            $Result = Restore-CostObjectType -InputObject $InputObject -TypeName 'Subscription.Cost'

            # Assert
            $Result.PSObject.TypeNames[0] | Should -Be 'Subscription.Cost'

            # Not a Date-suffixed property -- left as a string (billing periods are yyyyMM strings, not dates)
            $Result.BillingPeriod | Should -Be '202401'

            $Result.MostExpensive_Date | Should -BeOfType 'datetime'
            $Result.MostExpensive_Date | Should -Be (Get-Date '2024-01-02T00:00:00')
            $Result.LeastExpensive_Date | Should -BeOfType 'datetime'

            $Result.DailyCost[0].Date | Should -BeOfType 'datetime'
            $Result.DailyCost[0].Date | Should -Be (Get-Date '2024-01-01T00:00:00')
            $Result.DailyCost[1].Date | Should -BeOfType 'datetime'

            $Result.DailyCostChange[0].Date | Should -BeOfType 'datetime'
            $Result.DailyCostChange[0].PrevDate | Should -BeOfType 'datetime'

            # Non-date nested property left untouched
            $Result.ActiveBudgets[0].BudgetAmount | Should -Be 1000
        }
    }
}
