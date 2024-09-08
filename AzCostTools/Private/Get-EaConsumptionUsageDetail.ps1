function Get-EaConsumptionUsageDetail {
    <#
    .SYNOPSIS
        Fall back script to get consumption usage detail for Enterprise Agreement subscriptions

    .NOTES
        Credit to Brian Stringfellow who wrote the original here: https://github.com/Azure/azure-powershell/issues/12561#issuecomment-808630391
    #>
    [CmdletBinding()]
    param (
        [string]
        $SubscriptionId = (Get-AzContext).Subscription.Id,
  
        [ValidateSet('Legacy', 'Modern')]
        [string]
        $SubscriptionKind = 'Modern',

        [Parameter(Mandatory)]
        [string]
        $BillingPeriodName
    )
  
    $StartDate = [datetime]::parseexact($BillingPeriodName, 'yyyyMM', $null)
    $EndDate = $StartDate.AddMonths(1).AddDays(-1)
    
    $isLegacy = $SubscriptionKind -eq 'Legacy'
  
    $resource = 'https://management.azure.com'
    $context = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile.DefaultContext
    $accessToken = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $context.Tenant.Id.ToString(), $null, [Microsoft.Azure.Commands.Common.Authentication.ShowDialog]::Never, $null, $resource).AccessToken

    
    $Date = $StartDate.AddDays($Day)
    
    $dateFilter = $Date.Date.ToString('yyyy-MM-dd')
    $endDateFilter = $EndDate.Date.ToString('yyyy-MM-dd')
    $uriPath = "https://management.azure.com/subscriptions/$($SubscriptionId)/providers/Microsoft.Consumption/usageDetails"
  
    # https://docs.microsoft.com/en-us/azure/cost-management-billing/costs/manage-automation#get-usage-details-for-a-scope-during-specific-date-range
    if ($isLegacy) {
        $uriQuery = '?$expand=properties/meterDetails&$filter=properties/usageStart ge ''' + $dateFilter + ''' and properties/usageEnd le ''' + $endDateFilter + '''&$top=1000&api-version=2019-10-01'
    }
    else {
        $uriQuery = '?startDate=' + $dateFilter + '&endDate=' + $endDateFilter + '&$top=1000&api-version=2019-10-01'
    }
    $uri = $uriPath + $uriQuery

    $consumptionRaw = @()
    $nextLink = $null

    $consumptionRaw += do {

        $consumptionDetailsRaw = if ($nextLink) {
            Invoke-RestMethod -Method 'Get' -Uri $nextLink -Headers @{ Authorization = "Bearer " + $accessToken }
        }
        else {
            Invoke-RestMethod -Method 'Get' -Uri $uri -Headers @{ Authorization = "Bearer " + $accessToken }
        }

        $nextLink = $consumptionDetailsRaw.nextLink
        $consumptionDetailsRaw

    } until (-not $nextLink)
    
    $consumptionDetails = @()

    foreach ($detail in $consumptionRaw.value) {

        $convertedDetail = [pscustomobject]@{
            SubscriptionGuid  = if ($isLegacy) { $detail.properties.subscriptionId } else { $detail.properties.subscriptionGuid }
            InstanceName      = if ($isLegacy) { $detail.properties.resourceName } else { ($detail.properties.instanceName -split '/')[-1] }
            AccountName       = if ($isLegacy) { $detail.properties.accountName } else { $detail.properties.billingAccountName }
            DepartmentName    = if ($isLegacy) { $detail.properties.invoiceSection } else { $detail.properties.billingProfileName }
            CostCenter        = $detail.properties.costCenter
            BillingPeriodName = $detail.properties.billingPeriodStartDate
            UsageStart        = $detail.properties.date
            UsageEnd          = $detail.properties.date
            ConsumedService   = $detail.properties.consumedService
            Product           = $detail.properties.product
            Currency          = if ($isLegacy) { $detail.properties.billingCurrency } else { $detail.properties.billingCurrencyCode }
            MeterDetails      = @{
                MeterName        = $detail.properties.meterDetails.meterName
                MeterCategory    = $detail.properties.meterDetails.meterCategory
                MeterSubCategory = $detail.properties.meterDetails.meterSubCategory
                Unit             = $detail.properties.meterDetails.unitOfMeasure
                MeterLocation    = $detail.properties.resourceLocation
            }
            UsageQuantity     = $detail.properties.quantity
            PreTaxCost        = if ($isLegacy) { $detail.properties.cost } else { $detail.properties.costInUSD }
        }
  
        $consumptionDetails += $convertedDetail
    }
  
    $consumptionDetails
}