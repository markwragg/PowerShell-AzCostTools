Describe Get-SubscriptionCost {

    Import-Module $PSScriptRoot\..\AzCostTools
    
    InModuleScope AzCostTools {

        BeforeAll {
            
            Mock Get-AzContext {
                New-MockObject -Type Microsoft.Azure.Commands.Profile.Models.Core.PSAzureContext -Properties @{
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
                New-MockObject -Type Microsoft.Azure.Commands.Profile.Models.Core.PSAzureContext -Properties @{
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
                @{
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
                @{
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
                @{
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
            }

            Mock Get-AzConsumptionBudget {
                @{
                    TimePeriod = @{
                        StartDate = (Get-Date '01/01/2024') 
                        EndDate   = (Get-Date '01/01/2034') 
                    }
                    Amount     = '1000'
                    TimeGrain  = 'Monthly'
                }
            }
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
}