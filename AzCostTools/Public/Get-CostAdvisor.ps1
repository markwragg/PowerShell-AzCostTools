function Get-CostAdvisor {
    <#
    .SYNOPSIS
        Retrieves Azure cost advisor recommendations for one or more subscriptions.

    .DESCRIPTION
        Invokes the Get-AzAdvisorRecommendation cmdlet against one or more subscriptions and returns recommendations categorised as "Cost".
    
    .PARAMETER SubscriptionName
        The name or name/s of the Subscriptions to query. If not specified all subscriptions available in the current context will be used.

    .PARAMETER Impact
        Use to filter the results to one or more impact categories: High, Medium or Low.

    .PARAMETER Raw
        Switch: Include the raw advisor recommendation data as a property on the returned object.

    .EXAMPLE
        Get-CostAdvisor

        Description
        -----------
        Returns the current cost advisor recommendations for all subscriptions in the current Azure context.

    .EXAMPLE
        Get-CostAdvisor -SubscriptionName 'MySubscriptionA','MySubscriptionB'

        Description
        -----------
        Returns the current cost advisor recommendations for the specified subscription names.

    .EXAMPLE
        Get-CostAdvisor -Impact Medium,High

        Description
        -----------
        Returns the current cost advisor recommendations that match the specified impact levels.
    #>
    [cmdletbinding()]
    param(
        [string[]]
        $SubscriptionName,

        [ValidateSet('High','Medium','Low')]
        [string[]]
        $Impact,

        [switch]
        $Raw
    )
    begin {
        # Store the users current AZ context before we start
        $PreAzContext = Get-AzContext
    }
    process {

        if (-not $SubscriptionName) {
            $SubscriptionName = (Get-AzSubscription -ErrorAction Stop).Name
        }

        foreach ($Subscription in $SubscriptionName) {

            $AdvisorRecommendations = $null
            
            if ($PreAzContext.Subscription.Name -ne $Name) {
                Set-AzContext -Subscription $Subscription -ErrorAction Stop | Out-Null
            }

            $AdvisorRecommendations = Get-AzAdvisorRecommendation | Where-Object { $_.Category -eq 'Cost' }

            if ($Impact) { 
                $AdvisorRecommendations = $AdvisorRecommendations | Where-Object { $_.Impact -in $Impact }
            }

            foreach ($AdvisorRecommendation in $AdvisorRecommendations) {

                $RecommendationObject = [ordered]@{
                    PSTypeName       = 'CostAdvisor.Recommendation'
                    Resource         = $AdvisorRecommendation.ImpactedValue
                    ResourceType     = $AdvisorRecommendation.ImpactedField
                    SubscriptionName = $Subscription
                    Impact           = $AdvisorRecommendation.Impact
                    Recommendation   = $AdvisorRecommendation.ShortDescriptionProblem 
                    AnnualSavings    = $AdvisorRecommendation.ExtendedProperty.AdditionalProperties.annualSavingsAmount
                    Savings          = $AdvisorRecommendation.ExtendedProperty.AdditionalProperties.savingsAmount
                    Currency         = $AdvisorRecommendation.ExtendedProperty.AdditionalProperties.savingsCurrency
                    LookbackPeriod   = $AdvisorRecommendation.ExtendedProperty.AdditionalProperties.lookbackPeriod
                    Region           = $AdvisorRecommendation.ExtendedProperty.AdditionalProperties.region
                }

                if ($Raw) {
                    $RawRecommendationObject = [ordered]@{
                        Recommendation_Raw = $AdvisorRecommendation
                    }

                    $RecommendationObject += $RawRecommendationObject
                }

                [PSCustomObject]$RecommendationObject
            }
        }
    }
}