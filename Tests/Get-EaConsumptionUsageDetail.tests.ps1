Describe Get-EaConsumptionUsageDetail {

    Import-Module (Join-Path $PSScriptRoot "/../AzCostTools")

    InModuleScope AzCostTools {

        BeforeAll {

            function Get-AzContext {}

            Mock Get-AzContext {
                @{
                    Subscription = @{
                        Id = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
                    }
                }
            }

            Mock Get-EaAccessToken { 'SomeAccessToken' }
        }

        Context 'Modern subscriptions' {

            BeforeAll {
                Mock Invoke-RestMethod {
                    @{
                        nextLink = $null
                        value    = @(
                            [pscustomobject]@{
                                properties = @{
                                    subscriptionGuid       = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
                                    instanceName            = '/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/SomeGroup/providers/Microsoft.Storage/storageAccounts/SomeAccount'
                                    billingAccountName      = 'SomeBillingAccount'
                                    billingProfileName      = 'SomeBillingProfile'
                                    costCenter              = 'SomeCostCenter'
                                    billingPeriodStartDate  = '2024-01-01'
                                    date                    = '2024-01-15'
                                    consumedService         = 'Microsoft.Storage'
                                    product                 = 'Premium SSD Managed Disks - P15 LRS - EU West'
                                    billingCurrencyCode     = 'EUR'
                                    quantity                = 0.25
                                    costInBillingCurrency   = 10
                                    meterDetails            = @{
                                        meterName        = 'P15 LRS'
                                        meterCategory    = 'Storage'
                                        meterSubCategory = 'Premium SSD Managed Disks'
                                        unitOfMeasure    = '1/Month'
                                    }
                                    resourceLocation        = 'EU West'
                                }
                            }
                        )
                    }
                }
            }

            It 'Uses the current Az context Subscription Id when one is not specified' {
                Get-EaConsumptionUsageDetail -BillingPeriodName '202401' | Out-Null
                Should -Invoke Invoke-RestMethod -ParameterFilter { $Uri -like '*subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx*' }
            }

            It 'Builds a modern startDate/endDate query for the requested billing period' {
                Get-EaConsumptionUsageDetail -SubscriptionId 'SomeSubscriptionId' -BillingPeriodName '202401' | Out-Null
                Should -Invoke Invoke-RestMethod -ParameterFilter { $Uri -like '*subscriptions/SomeSubscriptionId*' -and $Uri -like '*startDate=2024-01-01*' -and $Uri -like '*endDate=2024-01-31*' }
            }

            It 'Passes the access token as a bearer token header' {
                Get-EaConsumptionUsageDetail -SubscriptionId 'SomeSubscriptionId' -BillingPeriodName '202401' | Out-Null
                Should -Invoke Invoke-RestMethod -ParameterFilter { $Headers.Authorization -eq 'Bearer SomeAccessToken' }
            }

            It 'Maps modern usage detail properties to the common output shape' {
                $Result = Get-EaConsumptionUsageDetail -SubscriptionId 'SomeSubscriptionId' -BillingPeriodName '202401'

                $Result.SubscriptionGuid | Should -Be 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
                $Result.InstanceName | Should -Be 'SomeAccount'
                $Result.AccountName | Should -Be 'SomeBillingAccount'
                $Result.DepartmentName | Should -Be 'SomeBillingProfile'
                $Result.Currency | Should -Be 'EUR'
                $Result.PreTaxCost | Should -Be 10
            }
        }

        Context 'Legacy subscriptions' {

            BeforeAll {
                Mock Invoke-RestMethod {
                    @{
                        nextLink = $null
                        value    = @(
                            [pscustomobject]@{
                                properties = @{
                                    subscriptionId         = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
                                    resourceName            = 'SomeAccount'
                                    accountName             = 'SomeAccountName'
                                    invoiceSection          = 'SomeInvoiceSection'
                                    costCenter              = 'SomeCostCenter'
                                    billingPeriodStartDate  = '2024-01-01'
                                    date                    = '2024-01-15'
                                    consumedService         = 'Microsoft.Storage'
                                    product                 = 'Premium SSD Managed Disks - P15 LRS - EU West'
                                    billingCurrency         = 'GBP'
                                    quantity                = 0.5
                                    cost                    = 20
                                    meterDetails            = @{
                                        meterName        = 'P15 LRS'
                                        meterCategory    = 'Storage'
                                        meterSubCategory = 'Premium SSD Managed Disks'
                                        unitOfMeasure    = '1/Month'
                                    }
                                    resourceLocation        = 'UK South'
                                }
                            }
                        )
                    }
                }
            }

            It 'Builds a legacy filter query for the requested billing period' {
                Get-EaConsumptionUsageDetail -SubscriptionId 'SomeSubscriptionId' -SubscriptionKind 'Legacy' -BillingPeriodName '202401' | Out-Null
                Should -Invoke Invoke-RestMethod -ParameterFilter { $Uri -like "*`$filter=properties/usageStart ge '2024-01-01' and properties/usageEnd le '2024-01-31'*" }
            }

            It 'Maps legacy usage detail properties to the common output shape' {
                $Result = Get-EaConsumptionUsageDetail -SubscriptionId 'SomeSubscriptionId' -SubscriptionKind 'Legacy' -BillingPeriodName '202401'

                $Result.SubscriptionGuid | Should -Be 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
                $Result.InstanceName | Should -Be 'SomeAccount'
                $Result.AccountName | Should -Be 'SomeAccountName'
                $Result.DepartmentName | Should -Be 'SomeInvoiceSection'
                $Result.Currency | Should -Be 'GBP'
                $Result.PreTaxCost | Should -Be 20
            }
        }

        Context 'Pagination' {

            BeforeAll {
                $script:InvokeCount = 0

                Mock Invoke-RestMethod {
                    $script:InvokeCount++

                    if ($script:InvokeCount -eq 1) {
                        @{
                            nextLink = 'https://management.azure.com/nextpage'
                            value    = @(
                                [pscustomobject]@{
                                    properties = @{
                                        subscriptionGuid      = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
                                        instanceName           = 'SomeAccountA'
                                        billingCurrencyCode    = 'EUR'
                                        costInBillingCurrency  = 10
                                        meterDetails           = @{}
                                    }
                                }
                            )
                        }
                    }
                    else {
                        @{
                            nextLink = $null
                            value    = @(
                                [pscustomobject]@{
                                    properties = @{
                                        subscriptionGuid      = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
                                        instanceName           = 'SomeAccountB'
                                        billingCurrencyCode    = 'EUR'
                                        costInBillingCurrency  = 15
                                        meterDetails           = @{}
                                    }
                                }
                            )
                        }
                    }
                }
            }

            It 'Follows nextLink until no further pages are returned' {
                $script:InvokeCount = 0
                $Result = Get-EaConsumptionUsageDetail -SubscriptionId 'SomeSubscriptionId' -BillingPeriodName '202401'

                $Result.Count | Should -Be 2
                $Result.InstanceName | Should -Be @('SomeAccountA', 'SomeAccountB')
                Should -Invoke Invoke-RestMethod -Times 2 -Exactly
                Should -Invoke Invoke-RestMethod -ParameterFilter { $Uri -eq 'https://management.azure.com/nextpage' }
            }
        }
    }
}
