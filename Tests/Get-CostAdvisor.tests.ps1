Describe Get-CostAdvisor {

    Import-Module (Join-Path $PSScriptRoot "/../AzCostTools")
    
    InModuleScope AzCostTools {

        BeforeAll {

            function Get-AzContext {}
            function Get-AzSubscription {}
            function Set-AzContext {}
            function Get-AzAdvisorRecommendation {}
            
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

            Mock Get-AzAdvisorRecommendation {
                @(
                    [pscustomobject]@{
                        Action                     = $null
                        Category                   = 'Cost'
                        Description                = $null
                        ExposedMetadataProperty    = @{}
                        ExtendedProperty           = @{}
                        Id                         = '/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/providers/Microsoft.Billing/billingPeriods/20240101/providers/Microsoft.Advisor/recommendations/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
                        Impact                     = 'High'
                        ImpactedField              = 'Microsoft.Subscriptions/subscriptions'
                        ImpactedValue              = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
                        Label                      = $null
                        LastUpdated                = '02/06/2024 08:21:43'
                        LearnMoreLink              = $null
                        Metadata                   = @{}
                        Name                       = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
                        PotentialBenefit           = $null
                        RecommendationTypeId       = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
                        Remediation                = @{}
                        ResourceGroupName          = $null
                        ResourceMetadataAction     = @{}
                        ResourceMetadataPlural     = $null
                        ResourceMetadataResourceId = '/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
                        ResourceMetadataSingular   = $null
                        ResourceMetadataSource     = $null
                        Risk                       = $null
                        ShortDescriptionProblem    = 'Consider virtual machine reserved instance to save over your on-demand costs'
                        ShortDescriptionSolution   = 'Consider virtual machine reserved instance to save over your on-demand costs'
                        SuppressionId              = $null
                        Type                       = 'Microsoft.Advisor/recommendations'
                    }
                    [pscustomobject]@{
                        Action   = $null
                        Category = 'Security'
                        Id       = '/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/providers/Microsoft.Billing/billingPeriods/20240101/providers/Microsoft.Advisor/recommendations/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
                        Impact   = 'High'
                        Type     = 'Microsoft.Advisor/recommendations'
                    }
                    [pscustomobject]@{
                        Action   = $null
                        Category = 'HighAvailability'
                        Id       = '/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/providers/Microsoft.Billing/billingPeriods/20240101/providers/Microsoft.Advisor/recommendations/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
                        Impact   = 'High'
                        Type     = 'Microsoft.Advisor/recommendations'
                    }
                )
            }
        }

        It 'Should return recommendations for the specified subscription' {
            $Result = Get-CostAdvisor -SubscriptionName 'SomeSubscription'
            @($Result).count | Should -Be 1
        }

        It 'Should return recommendations for all current subscriptions' {
            $Result = Get-CostAdvisor
            @($Result).count | Should -Be 1
        }

        It 'Should exclude non-cost recommendations' {
            $Result = Get-CostAdvisor
            @($Result).count | Should -Be 1
        }

        It 'Should return recommendations for a specified subscription and include the raw consumption data' {
            $Result = Get-CostAdvisor -SubscriptionName 'SomeSubscription' -Raw
            $Result.Recommendation_Raw | Should -Not -BeNullOrEmpty
        }

        It 'Should return recommendations of a specified impact level' {
            $Result = Get-CostAdvisor -Impact Low,Medium
            @($Result).count | Should -Be 0
        }
    }
}