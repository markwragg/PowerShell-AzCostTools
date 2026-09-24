Describe Get-ResourceGroupConsumption {

    Import-Module (Join-Path $PSScriptRoot "/../AzCostTools")

    InModuleScope AzCostTools {

        BeforeAll {
            function Get-AzConsumptionUsageDetail ($BillingPeriodName, $ResourceGroup) {}
            function Get-EaConsumptionUsageDetail ($BillingPeriodName, $SubscriptionKind) {}
        }

        Context 'No resource group names specified' {

            BeforeAll {
                Mock Get-AzConsumptionUsageDetail {
                    @([pscustomobject]@{ InstanceId = '/subscriptions/xxxx/resourceGroups/RGA/providers/Microsoft.Storage/storageAccounts/A'; PretaxCost = 10 })
                }
            }

            It 'Makes a single unfiltered call' {
                $Result = Get-ResourceGroupConsumption -BillingPeriod '202401' -IsEaSubscription $false -EaSubscriptionKind 'Modern'

                @($Result.Consumption).Count | Should -Be 1
                $Result.IsEaSubscription | Should -Be $false
                Should -Invoke Get-AzConsumptionUsageDetail -Times 1 -Exactly -ParameterFilter { -not $ResourceGroup }
            }
        }

        Context 'Resource group names specified' {

            BeforeAll {
                Mock Get-AzConsumptionUsageDetail {
                    @([pscustomobject]@{ InstanceId = "/subscriptions/xxxx/resourceGroups/$ResourceGroup/providers/Microsoft.Storage/storageAccounts/A"; PretaxCost = 10 })
                }
            }

            It 'Makes one server-side filtered call per resource group name' {
                $Result = Get-ResourceGroupConsumption -BillingPeriod '202401' -ResourceGroupName 'RGA', 'RGB' -IsEaSubscription $false -EaSubscriptionKind 'Modern'

                @($Result.Consumption).Count | Should -Be 2
                Should -Invoke Get-AzConsumptionUsageDetail -Times 1 -Exactly -ParameterFilter { $ResourceGroup -eq 'RGA' }
                Should -Invoke Get-AzConsumptionUsageDetail -Times 1 -Exactly -ParameterFilter { $ResourceGroup -eq 'RGB' }
            }
        }

        Context 'The direct cmdlet returns a BadRequest partway through the per-resource-group calls' {

            BeforeAll {
                Mock Get-EaConsumptionUsageDetail {
                    @(
                        [pscustomobject]@{ InstanceId = '/subscriptions/xxxx/resourceGroups/RGA/providers/Microsoft.Storage/storageAccounts/A'; PretaxCost = 10 },
                        [pscustomobject]@{ InstanceId = '/subscriptions/xxxx/resourceGroups/RGB/providers/Microsoft.Storage/storageAccounts/B'; PretaxCost = 20 }
                    )
                }
            }

            It 'Falls back to a single unfiltered EA pull, filtered client-side to the requested resource groups' {
                Mock Get-AzConsumptionUsageDetail {
                    if ($ResourceGroup -eq 'RGA') {
                        @([pscustomobject]@{ InstanceId = '/subscriptions/xxxx/resourceGroups/RGA/providers/Microsoft.Storage/storageAccounts/A'; PretaxCost = 10 })
                    }
                    else {
                        throw [System.Exception]::new('Response status code does not indicate success: 400 (BadRequest).')
                    }
                }

                $Result = Get-ResourceGroupConsumption -BillingPeriod '202401' -ResourceGroupName 'RGA', 'RGB' -IsEaSubscription $false -EaSubscriptionKind 'Modern'

                $Result.IsEaSubscription | Should -Be $true
                @($Result.Consumption).Count | Should -Be 2
                Should -Invoke Get-EaConsumptionUsageDetail -Times 1 -Exactly
            }
        }

        Context 'Already known to be an Enterprise Agreement subscription' {

            BeforeAll {
                function Get-AzConsumptionUsageDetail ($BillingPeriodName, $ResourceGroup) { throw 'Should not be called' }

                Mock Get-EaConsumptionUsageDetail {
                    @(
                        [pscustomobject]@{ InstanceId = '/subscriptions/xxxx/resourceGroups/RGA/providers/Microsoft.Storage/storageAccounts/A'; PretaxCost = 10 },
                        [pscustomobject]@{ InstanceId = '/subscriptions/xxxx/resourceGroups/RGB/providers/Microsoft.Storage/storageAccounts/B'; PretaxCost = 20 }
                    )
                }
            }

            It 'Makes a single unfiltered EA pull rather than one per resource group' {
                $Result = Get-ResourceGroupConsumption -BillingPeriod '202401' -ResourceGroupName 'RGA', 'RGB' -IsEaSubscription $true -EaSubscriptionKind 'Modern'

                @($Result.Consumption).Count | Should -Be 2
                Should -Invoke Get-EaConsumptionUsageDetail -Times 1 -Exactly
            }

            It 'Filters the unfiltered EA pull client-side to only the requested resource group' {
                $Result = Get-ResourceGroupConsumption -BillingPeriod '202401' -ResourceGroupName 'RGA' -IsEaSubscription $true -EaSubscriptionKind 'Modern'

                @($Result.Consumption).Count | Should -Be 1
                $Result.Consumption.InstanceId | Should -Be '/subscriptions/xxxx/resourceGroups/RGA/providers/Microsoft.Storage/storageAccounts/A'
            }
        }
    }
}
