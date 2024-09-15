Describe Get-StorageCost {

    Import-Module (Join-Path $PSScriptRoot "/../AzCostTools")
    
    InModuleScope AzCostTools {

        BeforeAll {
            function Get-AzConsumptionUsageDetail {}
            function Get-Sparkline {}
            function Write-Sparkline {}

            Mock Write-Progress {}

            Mock Get-AzConsumptionUsageDetail {
                @(
                    [pscustomobject]@{
                        AccountName       = 'SomeAccount'
                        InstanceName      = 'SomeAccount'
                        BillingPeriodName = '20240101'
                        ConsumedService   = 'Microsoft.Storage'
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
                        InstanceName      = 'SomeAccount'
                        BillingPeriodName = '20240101'
                        ConsumedService   = 'Microsoft.Storage'
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
                        InstanceName      = 'SomeAccount'
                        BillingPeriodName = '20240101'
                        ConsumedService   = 'Microsoft.Storage'
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

            Mock Get-Sparkline
            Mock Write-SparkLine
        }

        It 'Should return costs for the a specified subscription' {
            $Result = Get-StorageCost -AccountName 'SomeAccount'
            $Result.Cost | Should -Be 30
        }

        It 'Should return costs for the a specified subscription and compare to previous' {
            $Result = Get-StorageCost -AccountName 'SomeAccount' -ComparePrevious
            $Result.Cost | Should -Be 30
        }

        It 'Should return costs all current subscriptions' {
            $Result = Get-StorageCost
            $Result.Cost | Should -Be 30
        }

        It 'Should return costs for the a specified subscription and include the raw consumption data' {
            $Result = Get-StorageCost -AccountName 'SomeAccount' -Raw
            $Result.Cost | Should -Be 30
        }

        It 'Should return costs for the a specified subscription and size the Sparklines at a height of 3' {
            $Result = Get-StorageCost -AccountName 'SomeAccount' -SparkLineSize 3
            $Result.Cost | Should -Be 30
        }

        It 'Should return costs for the a specified subscription and the previous 2 months' {
            $Result = Get-StorageCost -AccountName 'SomeAccount' -PreviousMonths 2
            ($Result.Cost | Measure-Object -Sum).Sum | Should -Be 90
        }

        It 'Should return costs for the a specified subscription and the previous 2 months and compare to previous' {
            $Result = Get-StorageCost -AccountName 'SomeAccount' -PreviousMonths 2 -ComparePrevious
            ($Result.Cost | Measure-Object -Sum).Sum | Should -Be 90
        }

        It 'Should return costs for the a specified subscription and compare to previous and return the raw consumption data' {
            $Result = Get-StorageCost -AccountName 'SomeAccount' -ComparePrevious -Raw
            $Result.Cost | Should -Be 30
        }
    }
}