Describe Get-SubscriptionCost {

    Import-Module (Join-Path $PSScriptRoot "/../AzCostTools")
    
    InModuleScope AzCostTools {

        BeforeAll {

            function Get-AzContext {}
            function Get-AzSubscription {}
            function Set-AzContext {}
            function Get-AzConsumptionUsageDetail ($BillingPeriodName) {}
            function Get-AzConsumptionBudget {}
            function Get-Sparkline {}
            function Write-Sparkline {}

            Mock Get-AzContext {
                @{
                    Name           = 'SomeExistingSubscription'
                    Account        = 'SomeAccount'
                    Environment    = 'AzureCloud'
                    Subscription   = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
                    Tenant         = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
                    TokenCache     = $null
                    VersionProfile = $null
                }
            }

            Mock Get-AzSubscription {
                @{
                    Name = 'SomeSubscription'
                }
            }

            Mock Set-AzContext {
                @{
                    Name           = 'SomeSubscription'
                    Account        = 'SomeAccount'
                    Environment    = 'AzureCloud'
                    Subscription   = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
                    Tenant         = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
                    TokenCache     = $null
                    VersionProfile = $null
                }
            }

            Mock Write-Progress {}

            Mock Get-AzConsumptionUsageDetail {
                @(
                    [pscustomobject]@{
                        AccountName       = 'SomeAccount'
                        BillingPeriodName = '20240101'
                        ConsumedService   = 'Microsoft.Compute'
                        Currency          = 'EUR'
                        Id                = '/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/providers/Microsoft.Billing/billingPeriods/20240101/providers/Microsoft.Consumption/usageDetails/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
                        IsEstimated       = $True
                        MeterId           = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
                        Name              = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
                        PretaxCost        = 10
                        Product           = 'Premium SSD Managed Disks - P15 LRS - EU West'
                        SubscriptionGuid  = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
                        SubscriptionName  = 'SomeSubscription'
                        UsageEnd          = (Get-Date '02/01/2024 23:59:59')
                        UsageQuantity     = 0.25
                        UsageStart        = (Get-Date '02/01/2024 00:00:00')
                    },
                    [pscustomobject]@{
                        AccountName       = 'SomeAccount'
                        BillingPeriodName = '20240101'
                        ConsumedService   = 'Microsoft.Compute'
                        Currency          = 'EUR'
                        Id                = '/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/providers/Microsoft.Billing/billingPeriods/20240101/providers/Microsoft.Consumption/usageDetails/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
                        IsEstimated       = $True
                        MeterId           = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
                        Name              = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
                        PretaxCost        = 10
                        Product           = 'Premium SSD Managed Disks - P15 LRS - EU West'
                        SubscriptionGuid  = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
                        SubscriptionName  = 'SomeSubscription'
                        UsageEnd          = (Get-Date '02/01/2024 23:59:59')
                        UsageQuantity     = 0.25
                        UsageStart        = (Get-Date '02/01/2024 00:00:00')
                    },
                    [pscustomobject]@{
                        AccountName       = 'SomeAccount'
                        BillingPeriodName = '20240101'
                        ConsumedService   = 'Microsoft.Compute'
                        Currency          = 'EUR'
                        Id                = '/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/providers/Microsoft.Billing/billingPeriods/20240101/providers/Microsoft.Consumption/usageDetails/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
                        IsEstimated       = $True
                        MeterId           = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
                        Name              = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
                        PretaxCost        = 10
                        Product           = 'Premium SSD Managed Disks - P15 LRS - EU West'
                        SubscriptionGuid  = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
                        SubscriptionName  = 'SomeSubscription'
                        UsageEnd          = (Get-Date '02/01/2024 23:59:59')
                        UsageQuantity     = 0.25
                        UsageStart        = (Get-Date '02/01/2024 00:00:00')
                    }
                )
            }

            Mock Get-AzConsumptionBudget {
                [pscustomobject]@{
                    TimePeriod = @{
                        StartDate = (Get-Date '01/01/2024') 
                        EndDate   = (Get-Date '01/01/2034') 
                    }
                    Amount     = '1000'
                    TimeGrain  = 'Monthly'
                }
            }

            Mock Get-Sparkline
            Mock Write-SparkLine
        }

        It 'Should return costs for the a specified subscription' {
            $Result = Get-SubscriptionCost -SubscriptionName 'SomeSubscription'
            $Result.Cost | Should -Be 30
        }

        It 'Should return costs for the a specified subscription and compare to previous' {
            $Result = Get-SubscriptionCost -SubscriptionName 'SomeSubscription' -ComparePrevious
            $Result.Cost | Should -Be 30
        }

        It 'Should return costs all current subscriptions' {
            $Result = Get-SubscriptionCost
            $Result.Cost | Should -Be 30
        }

        It 'Should return costs for the a specified subscription and include the raw consumption data' {
            $Result = Get-SubscriptionCost -SubscriptionName 'SomeSubscription' -Raw
            $Result.Cost | Should -Be 30
        }

        It 'Should return costs for the a specified subscription and size the Sparklines at a height of 3' {
            $Result = Get-SubscriptionCost -SubscriptionName 'SomeSubscription' -SparkLineSize 3
            $Result.Cost | Should -Be 30
        }

        It 'Should return costs for the a specified subscription and the previous 2 months' {
            $Result = Get-SubscriptionCost -SubscriptionName 'SomeSubscription' -PreviousMonths 2
            ($Result.Cost | Measure-Object -Sum).Sum | Should -Be 90
        }

        It 'Should return costs for the a specified subscription and the previous 2 months and compare to previous' {
            $Result = Get-SubscriptionCost -SubscriptionName 'SomeSubscription' -PreviousMonths 2 -ComparePrevious
            ($Result.Cost | Measure-Object -Sum).Sum | Should -Be 90
        }

        It 'Should return costs for the a specified subscription and compare to previous and return the raw consumption data' {
            $Result = Get-SubscriptionCost -SubscriptionName 'SomeSubscription' -ComparePrevious -Raw
            $Result.Cost | Should -Be 30
        }
    }

    InModuleScope AzCostTools {

        Context 'BillingPeriodName arguments' {

            BeforeAll {
                function Get-AzContext {}
                function Get-AzSubscription {}
                function Set-AzContext {}
                function Get-AzConsumptionUsageDetail ($BillingPeriodName) {}
                function Get-AzConsumptionBudget {}

                Mock Get-AzContext {
                    @{ Subscription = @{ Id = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx' } }
                }
                Mock Get-AzSubscription {
                    @{ Name = 'SomeSubscription' }
                }
                Mock Set-AzContext {}
                Mock Write-Progress {}
                Mock Get-AzConsumptionBudget {}
            }

            It 'Requests the current and previous billing periods using their own distinct BillingPeriodName' {
                $script:RequestedBillingPeriods = [System.Collections.Generic.List[string]]::new()

                Mock Get-AzConsumptionUsageDetail {
                    $script:RequestedBillingPeriods.Add($BillingPeriodName)
                    @(
                        [pscustomobject]@{
                            ConsumedService = 'Microsoft.Compute'
                            Currency        = 'EUR'
                            PretaxCost      = 10
                            UsageStart      = (Get-Date '02/01/2024 00:00:00')
                        }
                    )
                }

                Get-SubscriptionCost -SubscriptionName 'SomeSubscription' -BillingMonth '02/2024' -ComparePrevious | Out-Null

                $script:RequestedBillingPeriods | Should -Be @('202402', '202401')
            }
        }
    }

    InModuleScope AzCostTools {

        Context 'Multi-day consumption spanning both the current and previous billing period' {

            BeforeAll {
                function Get-AzContext {}
                function Get-AzSubscription {}
                function Set-AzContext {}
                function Get-AzConsumptionUsageDetail {}
                function Get-AzConsumptionBudget {}
                function Get-Sparkline {}
                function Write-Sparkline {}

                Mock Get-AzContext {
                    @{ Subscription = @{ Id = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx' } }
                }
                Mock Set-AzContext {}
                Mock Write-Progress {}
                Mock Get-Sparkline
                Mock Write-SparkLine
                Mock Get-AzConsumptionBudget {}

                # Pin this rather than relying on the real PSparklines module being installed on the
                # agent -- the Sparkline assertion below needs the generation branch to be deterministic.
                Mock Test-PSparklinesModule { $true }

                Mock Get-AzConsumptionUsageDetail {
                    @(
                        [pscustomobject]@{
                            ConsumedService = 'Microsoft.Compute'
                            Currency        = 'EUR'
                            PretaxCost      = 10
                            UsageStart      = (Get-Date '02/01/2024 00:00:00')
                        },
                        [pscustomobject]@{
                            ConsumedService = 'Microsoft.Compute'
                            Currency        = 'EUR'
                            PretaxCost      = 20
                            UsageStart      = (Get-Date '03/01/2024 00:00:00')
                        }
                    )
                }
            }

            It 'Generates Sparklines for the current and previous period when both span multiple days' {
                Get-SubscriptionCost -SubscriptionName 'SomeSubscription' -ComparePrevious | Out-Null
                Should -Invoke Get-Sparkline -Times 2 -Exactly
            }
        }

        Context 'When the Az consumption cmdlet fails with a BadRequest for an Enterprise Agreement subscription' {

            BeforeAll {
                function Get-AzContext {}
                function Get-AzSubscription {}
                function Set-AzContext {}
                function Get-AzConsumptionUsageDetail {}
                function Get-AzConsumptionBudget {}
                function Get-EaConsumptionUsageDetail {}

                Mock Get-AzContext {
                    @{ Subscription = @{ Id = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx' } }
                }
                Mock Set-AzContext {}
                Mock Write-Progress {}
                Mock Get-AzConsumptionBudget {}

                Mock Get-EaConsumptionUsageDetail {
                    @(
                        [pscustomobject]@{
                            ConsumedService = 'Microsoft.Compute'
                            Currency        = 'EUR'
                            PretaxCost      = 15
                            UsageStart      = (Get-Date '02/01/2024 00:00:00')
                        }
                    )
                }
            }

            It 'Falls back to Get-EaConsumptionUsageDetail for the current billing period' {
                Mock Get-AzConsumptionUsageDetail { throw [System.Exception]::new('Response status code does not indicate success: 400 (BadRequest).') }

                $Result = Get-SubscriptionCost -SubscriptionName 'SomeSubscription'

                $Result.Cost | Should -Be 15
                Should -Invoke Get-EaConsumptionUsageDetail -Times 1 -Exactly
            }

            It 'Falls back to Get-EaConsumptionUsageDetail for the previous billing period when only the previous-period call fails' {
                $script:CallCount = 0

                Mock Get-AzConsumptionUsageDetail {
                    $script:CallCount++
                    if ($script:CallCount -eq 1) {
                        @(
                            [pscustomobject]@{
                                ConsumedService = 'Microsoft.Compute'
                                Currency        = 'EUR'
                                PretaxCost      = 10
                                UsageStart      = (Get-Date '02/01/2024 00:00:00')
                            }
                        )
                    }
                    else {
                        throw [System.Exception]::new('Response status code does not indicate success: 400 (BadRequest).')
                    }
                }

                $Result = Get-SubscriptionCost -SubscriptionName 'SomeSubscription' -ComparePrevious

                $Result.Cost | Should -Be 10
                $Result.PrevCost | Should -Be 15
                Should -Invoke Get-EaConsumptionUsageDetail -Times 1 -Exactly
            }
        }

        Context 'Error handling' {

            BeforeAll {
                function Get-AzContext {}
                function Get-AzSubscription {}
                function Set-AzContext ($Subscription) {}
                function Get-AzConsumptionUsageDetail {}
                function Get-AzConsumptionBudget {}

                Mock Get-AzContext {
                    @{ Subscription = @{ Id = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx' } }
                }
                Mock Write-Progress {}
                Mock Write-Error {}
                Mock Get-AzConsumptionBudget {}

                Mock Get-AzConsumptionUsageDetail {
                    @(
                        [pscustomobject]@{
                            ConsumedService = 'Microsoft.Compute'
                            Currency        = 'EUR'
                            PretaxCost      = 10
                            UsageStart      = (Get-Date '02/01/2024 00:00:00')
                        }
                    )
                }
            }

            It 'Writes a non-terminating error and continues when Set-AzContext fails for a subscription' {
                # Only fail the first (explicit context switch) call -- the unconditional restore in the
                # function's `finally` block also calls Set-AzContext, and that call must keep succeeding
                # or the exception it would raise escapes uncaught, which is not what this test exercises.
                $script:SetContextCallCount = 0
                Mock Set-AzContext {
                    $script:SetContextCallCount++
                    if ($script:SetContextCallCount -eq 1) { throw 'Simulated context switch failure' }
                }

                { Get-SubscriptionCost -SubscriptionName 'SomeSubscription' } | Should -Not -Throw
                Should -Invoke Write-Error -Times 1 -Exactly
            }

            It 'Writes a non-terminating error and continues when calculating cost data fails' {
                Mock Set-AzContext {}
                Mock Get-DailyCost { throw 'Simulated cost calculation failure' }

                { Get-SubscriptionCost -SubscriptionName 'SomeSubscription' } | Should -Not -Throw
                Should -Invoke Write-Error -Times 1 -Exactly
            }

            It 'Restores the previous Az context and re-throws when retrieving subscriptions fails' {
                Mock Get-AzSubscription { throw 'Simulated subscription lookup failure' }

                { Get-SubscriptionCost } | Should -Throw
                Should -Invoke Set-AzContext -Times 1 -Exactly
            }
        }
    }
}