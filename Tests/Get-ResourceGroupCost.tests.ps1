Describe Get-ResourceGroupCost {

    Import-Module (Join-Path $PSScriptRoot "/../AzCostTools")

    InModuleScope AzCostTools {

        BeforeAll {
            function Get-AzContext {}
            function Get-AzConsumptionUsageDetail ($BillingPeriodName, $ResourceGroup) {}
            function Get-Sparkline {}
            function Write-Sparkline {}

            Mock Get-AzContext {
                @{ Subscription = @{ Name = 'SomeSubscription'; Id = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx' } }
            }
            Mock Write-Progress {}

            Mock Get-AzConsumptionUsageDetail {
                @(
                    [pscustomobject]@{
                        InstanceName     = 'SomeAccount'
                        InstanceId       = '/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/SomeResourceGroup/providers/Microsoft.Storage/storageAccounts/SomeAccount'
                        ConsumedService  = 'Microsoft.Storage'
                        Currency         = 'EUR'
                        SubscriptionName = 'SomeSubscription'
                        PretaxCost       = 10
                        UsageStart       = (Get-Date '02/01/2024 00:00:00')
                    },
                    [pscustomobject]@{
                        InstanceName     = 'SomeVM'
                        InstanceId       = '/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/SomeResourceGroup/providers/Microsoft.Compute/virtualMachines/SomeVM'
                        ConsumedService  = 'Microsoft.Compute'
                        Currency         = 'EUR'
                        SubscriptionName = 'SomeSubscription'
                        PretaxCost       = 10
                        UsageStart       = (Get-Date '02/01/2024 00:00:00')
                    },
                    [pscustomobject]@{
                        InstanceName     = 'SomeVM'
                        InstanceId       = '/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/SomeResourceGroup/providers/Microsoft.Compute/virtualMachines/SomeVM'
                        ConsumedService  = 'Microsoft.Compute'
                        Currency         = 'EUR'
                        SubscriptionName = 'SomeSubscription'
                        PretaxCost       = 10
                        UsageStart       = (Get-Date '02/01/2024 00:00:00')
                    }
                )
            }

            Mock Get-Sparkline
            Mock Write-SparkLine
        }

        It 'Should return costs for the a specified resource group' {
            $Result = Get-ResourceGroupCost -ResourceGroupName 'SomeResourceGroup'
            $Result.Cost | Should -Be 30
        }

        It 'Should return costs for the a specified resource group and compare to previous' {
            $Result = Get-ResourceGroupCost -ResourceGroupName 'SomeResourceGroup' -ComparePrevious
            $Result.Cost | Should -Be 30
        }

        It 'Should return costs for all resource groups found in the billing data' {
            $Result = Get-ResourceGroupCost
            $Result.Cost | Should -Be 30
        }

        It 'Should return a cost breakdown per service' {
            $Result = Get-ResourceGroupCost -ResourceGroupName 'SomeResourceGroup'
            ($Result.CostPerService | Where-Object Service -EQ 'Microsoft.Storage').Cost | Should -Be 10
            ($Result.CostPerService | Where-Object Service -EQ 'Microsoft.Compute').Cost | Should -Be 20
        }

        It 'Should return costs for the a specified resource group and include the raw consumption data' {
            $Result = Get-ResourceGroupCost -ResourceGroupName 'SomeResourceGroup' -Raw
            $Result.Cost | Should -Be 30
        }

        It 'Should return costs for the a specified resource group and size the Sparklines at a height of 3' {
            $Result = Get-ResourceGroupCost -ResourceGroupName 'SomeResourceGroup' -SparkLineSize 3
            $Result.Cost | Should -Be 30
        }

        It 'Should return costs for the a specified resource group and the previous 2 months' {
            $Result = Get-ResourceGroupCost -ResourceGroupName 'SomeResourceGroup' -PreviousMonths 2
            ($Result.Cost | Measure-Object -Sum).Sum | Should -Be 90
        }

        It 'Should return costs for the a specified resource group and the previous 2 months and compare to previous' {
            $Result = Get-ResourceGroupCost -ResourceGroupName 'SomeResourceGroup' -PreviousMonths 2 -ComparePrevious
            ($Result.Cost | Measure-Object -Sum).Sum | Should -Be 90
        }

        It 'Should return costs for the a specified resource group and compare to previous and return the raw consumption data' {
            $Result = Get-ResourceGroupCost -ResourceGroupName 'SomeResourceGroup' -ComparePrevious -Raw
            $Result.Cost | Should -Be 30
        }

        It 'Should return an object per resource group when comparing multiple resource groups' {
            $Result = Get-ResourceGroupCost -ResourceGroupName 'SomeResourceGroup', 'AnotherResourceGroup'
            $Result.Count | Should -Be 2
            ($Result | Where-Object ResourceGroupName -EQ 'AnotherResourceGroup').Cost | Should -Be 0
        }

        It 'Filters server-side with -ResourceGroup when one or more resource group names are specified' {
            Get-ResourceGroupCost -ResourceGroupName 'SomeResourceGroup', 'AnotherResourceGroup' | Out-Null

            Should -Invoke Get-AzConsumptionUsageDetail -Times 1 -Exactly -ParameterFilter { $ResourceGroup -eq 'SomeResourceGroup' }
            Should -Invoke Get-AzConsumptionUsageDetail -Times 1 -Exactly -ParameterFilter { $ResourceGroup -eq 'AnotherResourceGroup' }
        }

        It 'Makes a single unfiltered call when no resource group name is specified' {
            Get-ResourceGroupCost | Out-Null

            Should -Invoke Get-AzConsumptionUsageDetail -Times 1 -Exactly -ParameterFilter { -not $ResourceGroup }
        }
    }

    InModuleScope AzCostTools {

        Context 'Multi-day consumption spanning both the current and previous billing period' {

            BeforeAll {
                function Get-AzContext {}
                function Get-AzConsumptionUsageDetail {}
                function Get-Sparkline {}
                function Write-Sparkline {}

                Mock Get-AzContext {
                    @{ Subscription = @{ Name = 'SomeSubscription'; Id = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx' } }
                }
                Mock Write-Progress {}
                Mock Get-Sparkline
                Mock Write-SparkLine

                # Pin this rather than relying on the real PSparklines module being installed on the
                # agent -- the Sparkline assertion below needs the generation branch to be deterministic.
                Mock Test-PSparklinesModule { $true }

                Mock Get-AzConsumptionUsageDetail {
                    @(
                        [pscustomobject]@{
                            InstanceName     = 'SomeAccount'
                            InstanceId       = '/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/SomeResourceGroup/providers/Microsoft.Storage/storageAccounts/SomeAccount'
                            ConsumedService  = 'Microsoft.Storage'
                            Currency         = 'EUR'
                            SubscriptionName = 'SomeSubscription'
                            PretaxCost       = 10
                            UsageStart       = (Get-Date '02/01/2024 00:00:00')
                        },
                        [pscustomobject]@{
                            InstanceName     = 'SomeAccount'
                            InstanceId       = '/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/SomeResourceGroup/providers/Microsoft.Storage/storageAccounts/SomeAccount'
                            ConsumedService  = 'Microsoft.Storage'
                            Currency         = 'EUR'
                            SubscriptionName = 'SomeSubscription'
                            PretaxCost       = 20
                            UsageStart       = (Get-Date '03/01/2024 00:00:00')
                        }
                    )
                }
            }

            It 'Derives the ResourceGroupName from the InstanceId and generates Sparklines for the current and previous period' {
                $Result = Get-ResourceGroupCost -ResourceGroupName 'SomeResourceGroup' -ComparePrevious
                $Result.ResourceGroupName | Should -Be 'SomeResourceGroup'
                $Result.Cost | Should -Be 30

                Should -Invoke Get-Sparkline -Times 2 -Exactly
            }

            It 'Excludes the Sparkline property and uses the NoSparkLines type when -ExcludeSparklines is used' {
                $Result = Get-ResourceGroupCost -ResourceGroupName 'SomeResourceGroup' -ExcludeSparklines
                $Result.PSObject.Properties.Name | Should -Not -Contain 'DailyCost_SparkLine'
                $Result.PSTypeNames | Should -Contain 'ResourceGroup.CostNoSparkLines'
            }

            It 'Excludes the previous Sparkline property and uses the ComparePrevNoSparklines type when -ExcludeSparklines and -ComparePrevious are used together' {
                $Result = Get-ResourceGroupCost -ResourceGroupName 'SomeResourceGroup' -ExcludeSparklines -ComparePrevious
                $Result.PSObject.Properties.Name | Should -Not -Contain 'PrevDailyCost_SparkLine'
                $Result.PSTypeNames | Should -Contain 'ResourceGroup.Cost.ComparePrevNoSparklines'
            }
        }

        Context 'InstanceId does not contain a resolvable resource group segment' {

            BeforeAll {
                function Get-AzContext {}
                function Get-AzConsumptionUsageDetail {}
                function Get-Sparkline {}
                function Write-Sparkline {}

                Mock Get-AzContext {
                    @{ Subscription = @{ Name = 'SomeSubscription'; Id = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx' } }
                }
                Mock Write-Progress {}
                Mock Get-Sparkline
                Mock Write-SparkLine

                Mock Get-AzConsumptionUsageDetail {
                    @(
                        [pscustomobject]@{
                            InstanceName     = 'SomeAccount'
                            InstanceId       = '/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
                            ConsumedService  = 'Microsoft.Storage'
                            Currency         = 'EUR'
                            SubscriptionName = 'SomeSubscription'
                            PretaxCost       = 10
                            UsageStart       = (Get-Date -Year 2024 -Month 1 -Day 15)
                        }
                    )
                }
            }

            It 'Does not include the record when auto-discovering resource group names' {
                $Result = Get-ResourceGroupCost
                $Result | Should -BeNullOrEmpty
            }
        }

        Context 'No consumption data for the previous billing period' {

            BeforeAll {
                function Get-AzContext {}
                function Get-AzConsumptionUsageDetail ($BillingPeriodName, $ResourceGroup) {}
                function Get-Sparkline {}
                function Write-Sparkline {}

                Mock Get-AzContext {
                    @{ Subscription = @{ Name = 'SomeSubscription'; Id = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx' } }
                }
                Mock Write-Progress {}
                Mock Get-Sparkline
                Mock Write-SparkLine

                Mock Get-AzConsumptionUsageDetail {
                    if ($BillingPeriodName -eq '202401') {
                        @(
                            [pscustomobject]@{
                                InstanceName     = 'SomeAccount'
                                InstanceId       = '/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/SomeResourceGroup/providers/Microsoft.Storage/storageAccounts/SomeAccount'
                                ConsumedService  = 'Microsoft.Storage'
                                Currency         = 'EUR'
                                SubscriptionName = 'SomeSubscription'
                                PretaxCost       = 10
                                UsageStart       = (Get-Date -Year 2024 -Month 1 -Day 15)
                            }
                        )
                    }
                    else {
                        @()
                    }
                }
            }

            It 'Sets PrevCost and CostChange_Pct to null when the resource group has no consumption in the previous period' {
                $Result = Get-ResourceGroupCost -ResourceGroupName 'SomeResourceGroup' -BillingMonth '01/2024' -ComparePrevious
                $Result.PrevCost | Should -Be 0
                $Result.CostChange_Pct | Should -Be ''
            }
        }

        Context 'When retrieving cost data throws an error' {

            BeforeAll {
                function Get-AzContext {}
                function Get-AzConsumptionUsageDetail {}

                Mock Get-AzContext {
                    @{ Subscription = @{ Name = 'SomeSubscription'; Id = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx' } }
                }
                Mock Write-Progress {}
                Mock Write-Error {}

                Mock Get-AzConsumptionUsageDetail {
                    @(
                        [pscustomobject]@{
                            InstanceName     = 'SomeAccount'
                            InstanceId       = '/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/SomeResourceGroup/providers/Microsoft.Storage/storageAccounts/SomeAccount'
                            ConsumedService  = 'Microsoft.Storage'
                            Currency         = 'EUR'
                            SubscriptionName = 'SomeSubscription'
                            PretaxCost       = 10
                            UsageStart       = (Get-Date -Year 2024 -Month 1 -Day 15)
                        }
                    )
                }

                Mock Get-DailyCost { throw 'Simulated failure' }
            }

            It 'Writes a non-terminating error and does not propagate the exception' {
                { Get-ResourceGroupCost -ResourceGroupName 'SomeResourceGroup' } | Should -Not -Throw
                Should -Invoke Write-Error -Times 1 -Exactly
            }
        }

        Context 'When the Az consumption cmdlet fails with a BadRequest for an Enterprise Agreement subscription' {

            BeforeAll {
                function Get-AzContext {}
                function Get-AzConsumptionUsageDetail {}
                function Get-EaConsumptionUsageDetail {}
                function Get-Sparkline {}
                function Write-Sparkline {}

                Mock Get-AzContext {
                    @{ Subscription = @{ Name = 'SomeSubscription'; Id = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx' } }
                }
                Mock Write-Progress {}
                Mock Get-Sparkline
                Mock Write-SparkLine

                Mock Get-EaConsumptionUsageDetail {
                    @(
                        [pscustomobject]@{
                            InstanceName     = 'SomeAccount'
                            InstanceId       = '/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/SomeResourceGroup/providers/Microsoft.Storage/storageAccounts/SomeAccount'
                            ConsumedService  = 'Microsoft.Storage'
                            Currency         = 'EUR'
                            SubscriptionName = 'SomeSubscription'
                            PretaxCost       = 15
                            UsageStart       = (Get-Date '02/01/2024 00:00:00')
                        }
                    )
                }
            }

            It 'Falls back to Get-EaConsumptionUsageDetail for the current billing period' {
                Mock Get-AzConsumptionUsageDetail { throw [System.Exception]::new('Response status code does not indicate success: 400 (BadRequest).') }

                $Result = Get-ResourceGroupCost -ResourceGroupName 'SomeResourceGroup'

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
                                InstanceName     = 'SomeAccount'
                                InstanceId       = '/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/SomeResourceGroup/providers/Microsoft.Storage/storageAccounts/SomeAccount'
                                ConsumedService  = 'Microsoft.Storage'
                                Currency         = 'EUR'
                                SubscriptionName = 'SomeSubscription'
                                PretaxCost       = 10
                                UsageStart       = (Get-Date '02/01/2024 00:00:00')
                            }
                        )
                    }
                    else {
                        throw [System.Exception]::new('Response status code does not indicate success: 400 (BadRequest).')
                    }
                }

                $Result = Get-ResourceGroupCost -ResourceGroupName 'SomeResourceGroup' -ComparePrevious

                $Result.Cost | Should -Be 10
                $Result.PrevCost | Should -Be 15
                Should -Invoke Get-EaConsumptionUsageDetail -Times 1 -Exactly
            }

            It 'Auto-discovers resource group names from the InstanceId returned by the EA fallback when -ResourceGroupName is not specified' {
                Mock Get-AzConsumptionUsageDetail { throw [System.Exception]::new('Response status code does not indicate success: 400 (BadRequest).') }

                $Result = Get-ResourceGroupCost

                $Result | Should -Not -BeNullOrEmpty
                $Result.ResourceGroupName | Should -Be 'SomeResourceGroup'
                $Result.Cost | Should -Be 15
            }
        }

        Context 'One or more subscriptions specified via -SubscriptionName' {

            BeforeAll {
                function Get-AzContext {}
                function Set-AzContext ($Subscription) {}
                function Get-AzConsumptionUsageDetail ($ResourceGroup) {}

                Mock Get-AzContext {
                    @{ Subscription = @{ Name = 'OriginalSubscription'; Id = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx' } }
                }
                Mock Set-AzContext {}
                Mock Write-Progress {}

                Mock Get-AzConsumptionUsageDetail {
                    @(
                        [pscustomobject]@{
                            InstanceId = '/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/SomeResourceGroup/providers/Microsoft.Storage/storageAccounts/SomeAccount'
                            Currency   = 'EUR'
                            PretaxCost = 10
                            UsageStart = (Get-Date '02/01/2024 00:00:00')
                        }
                    )
                }
            }

            It 'Switches the Az context to each specified subscription and returns an object per subscription' {
                $Result = Get-ResourceGroupCost -ResourceGroupName 'SomeResourceGroup' -SubscriptionName 'SubA', 'SubB'

                $Result.Count | Should -Be 2
                ($Result | Sort-Object SubscriptionName).SubscriptionName | Should -Be @('SubA', 'SubB')
                Should -Invoke Set-AzContext -Times 1 -Exactly -ParameterFilter { $Subscription -eq 'SubA' }
                Should -Invoke Set-AzContext -Times 1 -Exactly -ParameterFilter { $Subscription -eq 'SubB' }
            }

            It 'Restores the original Az context after querying every specified subscription' {
                Get-ResourceGroupCost -ResourceGroupName 'SomeResourceGroup' -SubscriptionName 'SubA', 'SubB' | Out-Null

                # One Set-AzContext call per requested subscription, plus one more to restore the original context.
                Should -Invoke Set-AzContext -Times 3 -Exactly
            }

            It 'Does not switch the Az context when -SubscriptionName is not specified' {
                Get-ResourceGroupCost -ResourceGroupName 'SomeResourceGroup' | Out-Null

                Should -Invoke Set-AzContext -Times 0 -Exactly
            }
        }
    }
}
