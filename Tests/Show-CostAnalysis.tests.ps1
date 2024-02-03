Describe Show-CostAnalysis {

    Import-Module $PSScriptRoot\..\AzCostTools
    
    InModuleScope AzCostTools {

        BeforeAll {
            $Cost = @(
                [PSCustomObject]@{
                    PSTypeName                 = 'Subscription.Cost'
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
                            Service = 'Microsoft.Network'
                            Cost    = 100 
                        } 
                    )
                    MostExpensiveService       = 'Microsoft.Compute'
                    MostExpensiveService_Cost  = 250
                    LeastExpensiveService      = 'microsoft.insights'
                    LeastExpensiveService_Cost = 0
                    ActiveBudgets              = @(
                        @{
                            BudgetAmount    = 400
                            BudgetTimeGrain = 'Monthly'
                        }
                    )
                }
                [PSCustomObject]@{
                    PSTypeName                 = 'Subscription.Cost'
                    Name                       = 'SomeOtherSubscription'
                    BillingPeriod              = '202401'
                    Currency                   = 'EUR'
                    Cost                       = '5000'
                    DailyCost_SparkLine        = '▃▇▇▇▇▃▄▇███▁'
                    DailyCost_Min              = '18'
                    DailyCost_Max              = '50'
                    DailyCost_Avg              = '40'
                    MostExpensive_Date         = (Get-Date '09/01/2024 00:00:00')
                    LeastExpensive_Date        = (Get-Date '12/01/2024 00:00:00')
                    DailyCost                  = @(
                        @{
                            Date = (Get-Date '01/01/2024 00:00:00')
                            Cost = 10
                        },
                        @{
                            Date = (Get-Date '02/01/2024 00:00:00')
                            Cost = 20
                        },
                        @{
                            Date = (Get-Date '03/01/2024 00:00:00')
                            Cost = 30
                        }
                    )
                    CostPerService             = @( 
                        @{
                            Service = 'Microsoft.Compute'
                            Cost    = 10 
                        } 
                    )
                    MostExpensiveService       = 'Microsoft.Compute'
                    MostExpensiveService_Cost  = 250
                    LeastExpensiveService      = 'microsoft.insights'
                    LeastExpensiveService_Cost = 0
                    ActiveBudgets              = @()
                }
            )

            $ComparePrevCost = @(
                [PSCustomObject]@{
                    PSTypeName                 = 'Subscription.Cost'
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
                            Service = 'Microsoft.Network'
                            Cost    = 100 
                        } 
                    )
                    MostExpensiveService       = 'Microsoft.Compute'
                    MostExpensiveService_Cost  = 250
                    LeastExpensiveService      = 'microsoft.insights'
                    LeastExpensiveService_Cost = 0
                    ActiveBudgets              = @(
                        @{
                            BudgetAmount    = 400
                            BudgetTimeGrain = 'Monthly'
                        }
                    )
                    PrevBillingPeriod              = '202312'
                    PrevCost                       = 500
                    PrevDailyCost_SparkLine        = '▃▇▇▇▇▃▄▇███▁'
                    PrevDailyCost_Min              = 10.00
                    PrevDailyCost_Max              = 100.00
                    PrevDailyCost_Avg              = 50.00
                    PrevMostExpensiveDate          = '01/12/2023'
                    PrevLeastExpensiveDate         = '02/12/2023'
                    PrevDailyCost                  = @(
                        @{
                            Date = (Get-Date '01/12/2023 00:00:00')
                            Cost = 100
                        },
                        @{
                            Date = (Get-Date '02/12/2023 00:00:00')
                            Cost = 200
                        },
                        @{
                            Date = (Get-Date '03/12/2023 00:00:00')
                            Cost = 200
                        }
                    )
                    PrevCostPerService             = @( 
                        @{
                            Service = 'Microsoft.Network'
                            Cost    = 100 
                        } 
                    )
                    PrevMostExpensiveService       = 'Microsoft.Network'
                    PrevMostExpensiveService_Cost  = 100.00
                    PrevLeastExpensiveService      = 'Microsoft.Network'
                    PrevLeastExpensiveService_Cost = 100.00
                    CostChange                     = 100.00
                    CostChange_Pct                 = 50
                    DailyCostChange                = 100.00
                }
            )

            Mock Write-Host {}

            function New-Emphasis {}
            function Get-Sparkline {}
            function Show-Sparkline {}

            Mock New-Emphasis

            Mock Get-Sparkline { 
                @{
                    Row   = 0
                    Col   = 0
                    Val   = 1
                    Block = '▁'
                    Color = @{
                        ConsoleColor = 'Gray'
                    }
                }
                @{
                    Row   = 0
                    Col   = 1
                    Val   = 4
                    Block = '▄'
                    Color = @{
                        ConsoleColor = 'Gray'
                    }
                }
                @{
                
                    Row   = 0
                    Col   = 2
                    Val   = 8
                    Block = '█'
                    Color = @{
                        ConsoleColor = 'Gray'
                    }
                }
            }

            Mock Show-SparkLine
        }

        It 'Should return cost analysis when the input is sent via the pipeline without drawing Sparklines if the module is not installed' {
            
            Mock Test-PSparklinesModule {
                $false
            }

            $Cost | Show-CostAnalysis
            Should -Invoke Write-Host
        }

        It 'Should return cost analysis when the input is sent via the pipeline and draw Sparklines' {
            
            Mock Test-PSparklinesModule {
                $true
            }
    
            $Cost | Show-CostAnalysis
            Should -Invoke Write-Host
        }

        It 'Should return compare previous cost analysis when the input is sent via the pipeline without drawing Sparklines if the module is not installed' {
            
            Mock Test-PSparklinesModule {
                $false
            }

            $ComparePrevCost | Show-CostAnalysis -ComparePrevious
            Should -Invoke Write-Host
        }

        It 'Should return compare previous cost analysis when the input is sent via the pipeline and draw Sparklines' {
            
            Mock Test-PSparklinesModule {
                $true
            }
    
            $ComparePrevCost | Show-CostAnalysis -ComparePrevious
            Should -Invoke Write-Host
        }

        It 'Should calculate different budget types' {

            $Cost = @(
                [PSCustomObject]@{
                    PSTypeName                 = 'Subscription.Cost'
                    Name                       = 'Subscription1'
                    BillingPeriod              = '202401'
                    Currency                   = 'EUR'
                    Cost                       = '5000'
                    DailyCost_SparkLine        = '▃▇▇▇▇▃▄▇███▁'
                    DailyCost_Min              = '18'
                    DailyCost_Max              = '50'
                    DailyCost_Avg              = '40'
                    MostExpensive_Date         = (Get-Date '09/01/2024 00:00:00')
                    LeastExpensive_Date        = (Get-Date '12/01/2024 00:00:00')
                    DailyCost                  = @(
                        @{
                            Date = (Get-Date '01/01/2024 00:00:00')
                            Cost = 10
                        },
                        @{
                            Date = (Get-Date '02/01/2024 00:00:00')
                            Cost = 20
                        },
                        @{
                            Date = (Get-Date '03/01/2024 00:00:00')
                            Cost = 30
                        }
                    )
                    CostPerService             = @( 
                        @{
                            Service = 'Microsoft.Compute'
                            Cost    = 10 
                        } 
                    )
                    MostExpensiveService       = 'Microsoft.Compute'
                    MostExpensiveService_Cost  = 250
                    LeastExpensiveService      = 'microsoft.insights'
                    LeastExpensiveService_Cost = 0
                    ActiveBudgets              = @(
                        @{
                            BudgetAmount    = 400
                            BudgetTimeGrain = 'Monthly'
                        }
                    )
                }
                [PSCustomObject]@{
                    PSTypeName                 = 'Subscription.Cost'
                    Name                       = 'Subscription2'
                    BillingPeriod              = '202401'
                    Currency                   = 'EUR'
                    Cost                       = '5000'
                    DailyCost_SparkLine        = '▃▇▇▇▇▃▄▇███▁'
                    DailyCost_Min              = '18'
                    DailyCost_Max              = '50'
                    DailyCost_Avg              = '40'
                    MostExpensive_Date         = (Get-Date '09/01/2024 00:00:00')
                    LeastExpensive_Date        = (Get-Date '12/01/2024 00:00:00')
                    DailyCost                  = @(
                        @{
                            Date = (Get-Date '01/01/2024 00:00:00')
                            Cost = 10
                        },
                        @{
                            Date = (Get-Date '02/01/2024 00:00:00')
                            Cost = 20
                        },
                        @{
                            Date = (Get-Date '03/01/2024 00:00:00')
                            Cost = 30
                        }
                    )
                    CostPerService             = @( 
                        @{
                            Service = 'Microsoft.Compute'
                            Cost    = 10 
                        } 
                    )
                    MostExpensiveService       = 'Microsoft.Compute'
                    MostExpensiveService_Cost  = 250
                    LeastExpensiveService      = 'microsoft.insights'
                    LeastExpensiveService_Cost = 0
                    ActiveBudgets              = @(
                        @{
                            BudgetAmount    = 1200
                            BudgetTimeGrain = 'Quarterly'
                        }
                    )
                }
                [PSCustomObject]@{
                    PSTypeName                 = 'Subscription.Cost'
                    Name                       = 'Subscription3'
                    BillingPeriod              = '202401'
                    Currency                   = 'EUR'
                    Cost                       = '5000'
                    DailyCost_SparkLine        = '▃▇▇▇▇▃▄▇███▁'
                    DailyCost_Min              = '18'
                    DailyCost_Max              = '50'
                    DailyCost_Avg              = '40'
                    MostExpensive_Date         = (Get-Date '09/01/2024 00:00:00')
                    LeastExpensive_Date        = (Get-Date '12/01/2024 00:00:00')
                    DailyCost                  = @(
                        @{
                            Date = (Get-Date '01/01/2024 00:00:00')
                            Cost = 10
                        },
                        @{
                            Date = (Get-Date '02/01/2024 00:00:00')
                            Cost = 20
                        },
                        @{
                            Date = (Get-Date '03/01/2024 00:00:00')
                            Cost = 30
                        }
                    )
                    CostPerService             = @( 
                        @{
                            Service = 'Microsoft.Compute'
                            Cost    = 10 
                        } 
                    )
                    MostExpensiveService       = 'Microsoft.Compute'
                    MostExpensiveService_Cost  = 250
                    LeastExpensiveService      = 'microsoft.insights'
                    LeastExpensiveService_Cost = 0
                    ActiveBudgets              = @(
                        @{
                            BudgetAmount    = 40000
                            BudgetTimeGrain = 'Annually'
                        }
                    )
                }
            )

            $Cost | Show-CostAnalysis
            Should -Invoke Write-Hosts
        }
    }
}