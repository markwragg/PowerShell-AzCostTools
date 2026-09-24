function Get-ResourceGroupConsumption {
    <#
    .SYNOPSIS
        Retrieves consumption usage details for a billing period, used by Get-ResourceGroupCost.

    .DESCRIPTION
        When one or more resource group names are supplied, each is queried separately using
        Get-AzConsumptionUsageDetail's -ResourceGroup filter so the results are scoped server-side
        instead of pulling every resource in the subscription and filtering client-side. Falls back
        to Get-EaConsumptionUsageDetail (a single unfiltered pull, then filtered client-side by
        InstanceId) for Enterprise Agreement subscriptions where the direct cmdlet returns BadRequest.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $BillingPeriod,

        [string[]]
        $ResourceGroupName,

        [bool]
        $IsEaSubscription,

        [ValidateSet('Legacy', 'Modern')]
        [string]
        $EaSubscriptionKind = 'Modern'
    )

    if (-not $IsEaSubscription -and $ResourceGroupName) {
        $Consumption = foreach ($RG in $ResourceGroupName) {
            try {
                Get-AzConsumptionUsageDetail -BillingPeriodName $BillingPeriod -ResourceGroup $RG -ErrorAction Stop
            }
            catch {
                if ($_.Exception.Message -match 'BadRequest') {
                    $IsEaSubscription = $true
                    break
                }
                else {
                    throw
                }
            }
        }
    }
    elseif (-not $IsEaSubscription) {
        try {
            $Consumption = Get-AzConsumptionUsageDetail -BillingPeriodName $BillingPeriod -ErrorAction Stop
        }
        catch {
            if ($_.Exception.Message -match 'BadRequest') {
                $IsEaSubscription = $true
            }
            else {
                throw
            }
        }
    }

    if ($IsEaSubscription) {
        # A single unfiltered pull -- the EA REST fallback isn't known to support server-side
        # resource group filtering, so any requested names are applied client-side instead.
        $RawConsumption = Get-EaConsumptionUsageDetail -BillingPeriodName $BillingPeriod -SubscriptionKind $EaSubscriptionKind -ErrorAction Stop

        $Consumption = if ($ResourceGroupName) {
            $RawConsumption | Where-Object { $ResourceGroupName -contains (Get-ResourceGroupNameFromInstanceId $_.InstanceId) }
        }
        else {
            $RawConsumption
        }
    }

    [pscustomobject]@{
        Consumption      = $Consumption
        IsEaSubscription = $IsEaSubscription
    }
}
