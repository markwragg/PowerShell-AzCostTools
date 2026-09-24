Describe Set-SubscriptionBudget {

    Import-Module (Join-Path $PSScriptRoot "/../AzCostTools")

    InModuleScope AzCostTools {

        BeforeAll {

            function Get-AzContext {}
            function Get-AzSubscription {}
            function Set-AzContext {}
            function Get-AzConsumptionUsageDetail {}
            function Get-AzConsumptionBudget {}
            function Set-AzConsumptionBudget {
                param($InputObject, $Amount)
            }
            function New-AzConsumptionBudget {
                param($Name, $Amount, $Category, $TimeGrain, $StartDate)
            }
            function Get-Sparkline {}
            function Write-Sparkline {}

            Mock Get-AzContext {
                @{
                    Subscription = @{ Name = 'SomeSubscription'; Id = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx' }
                }
            }

            Mock Get-AzSubscription {
                @{ Name = 'SomeSubscription' }
            }

            Mock Set-AzContext {}

            Mock Write-Progress {}

            Mock Get-AzConsumptionUsageDetail {
                @(
                    [pscustomobject]@{
                        ConsumedService  = 'Microsoft.Compute'
                        Currency         = 'EUR'
                        PretaxCost       = 15
                        SubscriptionName = 'SomeSubscription'
                        UsageStart       = (Get-Date '02/01/2024 00:00:00')
                    },
                    [pscustomobject]@{
                        ConsumedService  = 'Microsoft.Compute'
                        Currency         = 'EUR'
                        PretaxCost       = 15
                        SubscriptionName = 'SomeSubscription'
                        UsageStart       = (Get-Date '02/01/2024 00:00:00')
                    }
                )
            }

            Mock Get-AzConsumptionBudget {
                [pscustomobject]@{
                    Name       = 'ExistingBudget'
                    Amount     = 100
                    TimeGrain  = 'Monthly'
                    TimePeriod = @{
                        StartDate = (Get-Date '01/01/2024')
                        EndDate   = (Get-Date '01/01/2034')
                    }
                }
            }

            Mock Set-AzConsumptionBudget {}
            Mock New-AzConsumptionBudget {
                [pscustomobject]@{ Name = $Name; Amount = $Amount }
            }

            Mock Get-Sparkline
            Mock Write-SparkLine
        }

        It 'Updates the existing budget to the average cost across the default number of months' {
            Set-SubscriptionBudget -SubscriptionName 'SomeSubscription'

            Should -Invoke Set-AzConsumptionBudget -Times 1 -Exactly -ParameterFilter { $Amount -eq 30 }
        }

        It 'Does not update the budget when -WhatIf is specified' {
            Set-SubscriptionBudget -SubscriptionName 'SomeSubscription' -WhatIf

            Should -Invoke Set-AzConsumptionBudget -Times 0 -Exactly
        }

        It 'Applies a buffer percentage to the calculated amount' {
            Set-SubscriptionBudget -SubscriptionName 'SomeSubscription' -BufferPercent 10

            Should -Invoke Set-AzConsumptionBudget -Times 1 -Exactly -ParameterFilter { $Amount -eq 33 }
        }

        It 'Does not set the budget below the specified minimum amount' {
            Set-SubscriptionBudget -SubscriptionName 'SomeSubscription' -MinimumAmount 500

            Should -Invoke Set-AzConsumptionBudget -Times 1 -Exactly -ParameterFilter { $Amount -eq 500 }
        }

        It 'Returns an object describing the change when -PassThru is specified' {
            $Result = Set-SubscriptionBudget -SubscriptionName 'SomeSubscription' -PassThru

            $Result.SubscriptionName | Should -Be 'SomeSubscription'
            $Result.BudgetName | Should -Be 'ExistingBudget'
            $Result.PreviousAmount | Should -Be 100
            $Result.NewAmount | Should -Be 30
        }

        It 'Targets a specific budget by name when specified' {
            Mock Get-AzConsumptionBudget {
                @(
                    [pscustomobject]@{ Name = 'BudgetA'; Amount = 100; TimeGrain = 'Monthly'; TimePeriod = @{ StartDate = (Get-Date '01/01/2024'); EndDate = (Get-Date '01/01/2034') } },
                    [pscustomobject]@{ Name = 'BudgetB'; Amount = 200; TimeGrain = 'Monthly'; TimePeriod = @{ StartDate = (Get-Date '01/01/2024'); EndDate = (Get-Date '01/01/2034') } }
                )
            }

            $Result = Set-SubscriptionBudget -SubscriptionName 'SomeSubscription' -BudgetName 'BudgetB' -PassThru

            $Result.BudgetName | Should -Be 'BudgetB'
            $Result.PreviousAmount | Should -Be 200
        }
    }

    InModuleScope AzCostTools {

        Context 'When no budget exists for the subscription' {

            BeforeAll {
                function Get-AzContext {}
                function Get-AzSubscription {}
                function Set-AzContext {}
                function Get-AzConsumptionUsageDetail {}
                function Get-AzConsumptionBudget {}
                function Set-AzConsumptionBudget {
                    param($InputObject, $Amount)
                }
                function New-AzConsumptionBudget {
                    param($Name, $Amount, $Category, $TimeGrain, $StartDate)
                }

                Mock Get-AzContext {
                    @{ Subscription = @{ Name = 'SomeSubscription'; Id = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx' } }
                }
                Mock Get-AzSubscription { @{ Name = 'SomeSubscription' } }
                Mock Set-AzContext {}
                Mock Write-Progress {}
                Mock Get-AzConsumptionBudget {}
                Mock Set-AzConsumptionBudget {}
                Mock New-AzConsumptionBudget {
                    [pscustomobject]@{ Name = $Name; Amount = $Amount }
                }

                Mock Get-AzConsumptionUsageDetail {
                    @(
                        [pscustomobject]@{
                            ConsumedService  = 'Microsoft.Compute'
                            Currency         = 'EUR'
                            PretaxCost       = 15
                            SubscriptionName = 'SomeSubscription'
                            UsageStart       = (Get-Date '02/01/2024 00:00:00')
                        }
                    )
                }
            }

            It 'Warns and does not create a budget by default' {
                Mock Write-Warning {}

                Set-SubscriptionBudget -SubscriptionName 'SomeSubscription'

                Should -Invoke New-AzConsumptionBudget -Times 0 -Exactly
                Should -Invoke Write-Warning -Times 1 -Exactly
            }

            It 'Creates a new budget when -CreateIfMissing is specified' {
                Set-SubscriptionBudget -SubscriptionName 'SomeSubscription' -CreateIfMissing -BudgetName 'NewBudget'

                Should -Invoke New-AzConsumptionBudget -Times 1 -Exactly -ParameterFilter { $Name -eq 'NewBudget' -and $Amount -eq 15 }
            }
        }
    }
}
