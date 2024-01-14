# PowerShell-AzCostTools

[![Build Status](https://dev.azure.com/markwragg/GitHub/_apis/build/status/markwragg.PowerShell-AzCostTools?branchName=main)](https://dev.azure.com/markwragg/GitHub/_build/latest?definitionId=11&branchName=main) ![coverage](https://img.shields.io/badge/coverage-93%25-brightgreen.svg)

A PowerShell module for cmdlets related to Azure cost analysis.

## Installation

The module is published in the PSGallery, so if you have PowerShell 5 or newer can be installed by running:

```powershell
Install-Module AzCostTools
```

## Prerequisites

This module requires the AZ module be installed (Az.Billing in particular):

```powershell
Install-Module Az
```

I also recommend you install the [PSparklines](https://github.com/endowdly/PSparklines) module by [@endowdly](https://github.com/endowdly). While the AzCostTools module will function without it,  PSparklines enables the generation of simplistic cost charts.

```powershell
Install-Module PSparklines
```

## Usage

### Retrieving costs

Ensure you have logged in to AZ PowerShell via `Login-AzAccount` and to the tenant that has the Subscription/s you wish to query.

> Depending on the number of subscriptions and/or previous months of data you wish to query the `Get-SubscriptionCost` cmdlet can take a few minutes to run.
> I recommend you return the results to a variable. If you want to see the output while also saving to a variable, use the `-OutVariable` parameter.
> E.g: `Get-SubscriptionCost -OutVariable Cost` will return the results to `$Cost` while also showing them on screen.

To return cost data for the current billing month for all Subscriptions in your current Azure Context, execute:

```powershell
Get-SubscriptionCost
```

> Errors may be returned for any subscriptions where the cost data is inaccessible, e.g you are not authorised to access costs of the subscription is of a type where costs are managed elsewhere.

Pipe the result to `Format-List` to see all of the properties that are returned.

![Get-SubscriptionCost](https://github.com/markwragg/PowerShell-AzCostTools/blob/main/Media/Get-SubscriptionCost.png)

To return cost data for the current billing month for a specified subscription, and compare those costs to the previous billing month, execute:

```powershell
Get-SubscriptionCost -Name 'SusbscriptionName' -ComparePrev -SparkLineSize 3
```
> In the above example we also increased the size of the charts by specifying `-SparkLineSize`.

Pipe the result to `Format-List` to see all of the properties that are returned.

![Get-SubscriptionCost](https://github.com/markwragg/PowerShell-AzCostTools/blob/main/Media/Get-SubscriptionCost-ComparePrev.png)

To return a number of previous months, you can use the `-PreviousMonths` parameter. For example:

```powershell
Get-SubscriptionCost -PreviousMonths 5 -ComparePrevious
```

> In the above example we've also used `-ComparePrevious` so that for each month calculations are made comparing it to the previous month. This is optional.

![Get-SubscriptionCost](https://github.com/markwragg/PowerShell-AzCostTools/blob/main/Media/Cost-MultipleSubscription-PrevMonths-ComparePrev.png)

Other parameters available for `Get-SubscriptionCost` include:

`-BillingMonth` — Use to specify a specific month to retrieve costs (or to start from when also retrieving previous months costs).
`-Raw` — Adds properties to the resultant object that include the raw cost data returned by `Get-AzConsumptionUsageDetail` in case you want to do further direct analysis/manipulation.

### Cost Analysis

Having retrieved a set of cost data for one or more subscriptions, you can pipe that data to `Show-CostAnalysis` to generate charts and tables analysing the costs:

```powershell
$Cost | Show-CostAnalysis
```

If `PSparklines` is installed, a daily cost chart will be generated. If the subscription has a budget this will show red for days over budget, and green for under (based on a daily budget calculation).
If there is no budget for the subscription the chart will be white.

A chart and table is also generated of the top 15 service costs, with each service name mapped to an individual colour.

If more than on subscription is in the cost data, the cmdlet will end with a total of cost for all subscriptions and a chart showing most to least expensive.

![Show-CostAnalysis](https://github.com/markwragg/PowerShell-AzCostTools/blob/main/Media/Show-CostAnalysis.gif)

With `Show-CostAnalysis` you can also customise the size of the charts returned by specifying `-SparkLineSize`. The default is 3.
You can also specify `-ConvertToCurrency` with a 3 letter currency code if you'd like the cost values returned to be converted to a different currency. 
Sometimes Azure costs are billed in a currency that is not your own and it may be more informative to view them in your local currency. For example:

```powershell
$Cost | Show-CostAnalysis -ConvertToCurrency GBP
```

> Note that this uses a free/open API for currency conversion that only refreshes the exchange rates once a day.