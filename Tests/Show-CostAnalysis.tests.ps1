Describe Show-CostAnalysis {

    Import-Module $PSScriptRoot\..\AzCostTools
    
    InModuleScope AzCostTools {

        BeforeAll {
            $Cost = [PSCustomObject]@{
                Name                       = 'SomeSubscription'
                BillingPeriod              = '202401'
                Currency                   = 'EUR'
                Cost                       = '500'
                DailyCost_SparkLine        = '▃▇▇▇▇▃▄▇███▁'
                DailyCost_Min              = '18'
                DailyCost_Max              = '50'
                DailyCost_Avg              = '40'
                MostExpensive_Date         = (Get-Date '09/01/2024 00:00:00')
                LeastExpensive_Date        = (Get-Date '12/01/2024 00:00:00')
                DailyCost                  = @(
                    @{
                        Date = (Get-Date '01/01/2024 00:00:00')
                        Cost = 100
                    },
                    @{
                        Date = (Get-Date '02/01/2024 00:00:00')
                        Cost = 200
                    },
                    @{
                        Date = (Get-Date '03/01/2024 00:00:00')
                        Cost = 200
                    }
                )
                CostPerService             = @( 
                    @{
                        Service = 'Microsoft.Automation'
                        Cost    = 0.007885 
                    } 
                )
                MostExpensiveService       = 'Microsoft.Compute'
                MostExpensiveService_Cost  = 250
                LeastExpensiveService      = 'microsoft.insights'
                LeastExpensiveService_Cost = 0
                ActiveBudgets              = @(
                    @{
                        BudgetAmount    = 1000
                        BudgetTimeGrain = 'Monthly'
                    }
                )
            }

            Mock Write-Host {}

            function New-Emphasis {}
            function Get-Sparkline {}
            function Show-Sparkline {}

            Mock New-Emphasis
            Mock Get-Sparkline
            Mock Show-SparkLine
        }

        It 'Should return cost analysis when the input is sent via the pipeline' {
            
            $Cost | Show-CostAnalysis
            Should -Invoke Write-Host -Times 24 -Exactly
        }

    }
}