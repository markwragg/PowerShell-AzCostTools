Describe New-CostSummaryObject {

    Import-Module (Join-Path $PSScriptRoot "/../AzCostTools")

    InModuleScope AzCostTools {

        BeforeAll {
            function Get-AzConsumptionBudget {}
            function Get-Sparkline {}
            function Write-Sparkline {}

            Mock Get-AzConsumptionBudget {}
            Mock Get-Sparkline
            Mock Write-SparkLine
        }

        It 'Builds a Subscription.Cost object from consumption records' {
            # Arrange
            $Consumption = @(
                [pscustomobject]@{ ConsumedService = 'Microsoft.Compute'; Currency = 'EUR'; PretaxCost = 10; UsageStart = (Get-Date '2024-01-01') },
                [pscustomobject]@{ ConsumedService = 'Microsoft.Compute'; Currency = 'EUR'; PretaxCost = 20; UsageStart = (Get-Date '2024-01-02') }
            )

            # Act
            $Result = New-CostSummaryObject -Name 'SomeSubscription' -BillingDate (Get-Date '2024-01-15') -Consumption $Consumption

            # Assert
            $Result.PSTypeName | Should -Be 'Subscription.Cost'
            $Result.Name | Should -Be 'SomeSubscription'
            $Result.BillingPeriod | Should -Be '202401'
            $Result.Currency | Should -Be 'EUR'
            $Result.Cost | Should -Be 30
            $Result.DailyCost.Count | Should -Be 2
            $Result.CostPerService.Count | Should -Be 1
        }

        It 'Includes active budgets that overlap the billing date' {
            # Arrange
            Mock Get-AzConsumptionBudget {
                [pscustomobject]@{
                    TimePeriod = @{ StartDate = (Get-Date '2024-01-01'); EndDate = (Get-Date '2034-01-01') }
                    Amount     = 1000
                    TimeGrain  = 'Monthly'
                }
            }

            $Consumption = @([pscustomobject]@{ ConsumedService = 'Microsoft.Compute'; Currency = 'EUR'; PretaxCost = 10; UsageStart = (Get-Date '2024-01-01') })

            # Act
            $Result = New-CostSummaryObject -Name 'SomeSubscription' -BillingDate (Get-Date '2024-01-15') -Consumption $Consumption

            # Assert
            $Result.ActiveBudgets.Count | Should -Be 1
            $Result.ActiveBudgets[0].BudgetAmount | Should -Be 1000
        }
    }
}
