# PowerShell-AzCostTools

[![Build Status](https://dev.azure.com/markwragg/GitHub/_apis/build/status/markwragg.PowerShell-AzCostTools?branchName=main)](https://dev.azure.com/markwragg/GitHub/_build/latest?definitionId=11&branchName=main) ![coverage](https://img.shields.io/badge/coverage-95%25-brightgreen.svg)

A PowerShell module for cmdlets related to Azure cost analysis.

## Installation

The module is published in the PSGallery, so if you have PowerShell 5 or newer can be installed by running:

```powershell
Install-Module AzCostTools
```

## Prerequisites

This module requires the [AZ module](https://learn.microsoft.com/en-us/powershell/azure/install-azps-windows) be installed:

```powershell
Install-Module Az
```

I also recommend you install the [PSparklines module](https://github.com/endowdly/PSparklines) by [@endowdly](https://github.com/endowdly). While AzCostTools will function without it, PSparklines enables the additional generation of simplistic text based cost charts.

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

> Errors may be returned for any subscriptions where the cost data is inaccessible, e.g you are not authorised to access costs or the subscription is of a type where costs are managed externally (such as a CSP).

There is a default table view. Pipe the result to `Format-List` to see all of the properties that are returned.

![Get-SubscriptionCost returns current costs for all subscriptions in the current context](https://github.com/markwragg/PowerShell-AzCostTools/blob/main/Media/Get-SubscriptionCost.png)

To return cost data for the current billing month for a specified subscription, and compare those costs to the previous billing month, execute:

```powershell
Get-SubscriptionCost -SubscriptionName 'AdventureWorks Cycles' -ComparePrevious -SparkLineSize 3
```
> In the above example we also increased the size of the charts by specifying `-SparkLineSize`.

![Get-SubscriptionCost returns costs for a specified subscription and compares them to the previous month with sparkline charts that are 3 rows in height](https://github.com/markwragg/PowerShell-AzCostTools/blob/main/Media/Get-SubscriptionCost-ComparePrev.png)

To return a number of previous months, you can use the `-PreviousMonths` parameter. For example:

```powershell
Get-SubscriptionCost -PreviousMonths 5 -ComparePrevious
```

> In the above example we've also used `-ComparePrevious` so that for each month calculations are made comparing it to the previous month. This is optional.

![Get-SubscriptionCost returns current costs for all subscriptions in the current context and the previous 5 months of costs](https://github.com/markwragg/PowerShell-AzCostTools/blob/main/Media/Cost-MultipleSubscription-PrevMonths-ComparePrev.png)

When using `-ComparePrevious` you can also specify `-ComparePreviousOffset`. This will compare each month of cost data returned to X month/s prior as specified.
For example, if you wanted to compare costs for the last 6 months against the same 6 months from the year prior, you could execute:

```powershell
Get-SubscriptionCost -PreviousMonths 6 -ComparePrevious -ComparePreviousOffset 12
```
![Get-SubscriptionCost returns current costs for all subscriptions in the current context and the previous 6 months of cost, comparing each to the equivalent month 12 months prior](https://github.com/markwragg/PowerShell-AzCostTools/blob/main/Media/Cost-MultipleSubscription-PrevMonths-ComparePrev-Offset12.png)

Other parameters available for `Get-SubscriptionCost` include:

* `-BillingMonth` — Use to specify a specific month to retrieve costs (or as a starting point from when also retrieving previous months costs).
* `-Raw` — Adds properties to the resultant object that include the raw cost data returned by `Get-AzConsumptionUsageDetail` in case you want to do further direct analysis/manipulation.

### Cost Analysis

Having retrieved a set of cost data for one or more subscriptions, you can pipe that data to `Show-CostAnalysis` to generate charts and tables analysing the costs:

```powershell
$Cost | Show-CostAnalysis
```

If `PSparklines` is installed, a daily cost chart will be generated. If the subscription has a budget this will show red for days over budget, and green for under (based on a daily budget calculation).
If there is no budget for the subscription the chart will be white.

A chart and table is also generated of the top 15 service costs, with each service name mapped to an individual colour.

If more than one subscription is in the cost data, the cmdlet will end with a total of cost for all subscriptions and a chart showing most to least expensive.

![Show-CostAnalysis generates charts and tables for a set of returned cost data](https://github.com/markwragg/PowerShell-AzCostTools/blob/main/Media/Show-CostAnalysis.gif)

With `Show-CostAnalysis` you can also customise the size of the charts returned by specifying `-SparkLineSize`. The default is 3.
You can also specify `-ConvertToCurrency` with a 3 letter currency code if you'd like the cost values returned to be converted to a different currency. 
Sometimes Azure costs are billed in a currency that is not your own and it may be more informative to view them in your local currency. For example:

```powershell
$Cost | Show-CostAnalysis -ConvertToCurrency GBP
```

> Note that this uses a free/open API for currency conversion that only refreshes the exchange rates once a day.

If you used `-ComparePrevious` when executing `Get-SubscriptionCost` you can also specify `-ComparePrevious` for `Show-CostAnalysis` to generate further tables and charts for the previous cost data. This might be most useful when using `-ComparePreviousOffset` so that you can see the charts side by side of the current and previous costs. For example:

```powershell
$Cost | Show-CostAnalysis -ComparePrevious
```
![Show-CostAnalysis generates charts and tables for a set of returned cost data and shows charts for the previous cost data](https://github.com/markwragg/PowerShell-AzCostTools/blob/main/Media/Show-CostAnalysis-ComparePrev.png)

### Saving and reloading cost data

Retrieving cost data from Azure can take a few minutes to run, especially across multiple subscriptions or months. Rather than re-querying Azure every time you want to analyse the same data, you can save it to disk with `Export-CostData` and reload it later with `Import-CostData`:

```powershell
Get-SubscriptionCost -ComparePrevious -PreviousMonths 5 -OutVariable Cost
$Cost | Export-CostData -Path C:\Cost\SubscriptionCost.json
```

> If `-Path` is a directory rather than a file, a timestamped file (`CostData_<timestamp>.json`) is created within it.

The saved data can then be reloaded at any time, without needing to be connected to Azure, and piped directly into `Show-CostAnalysis` or anything else that expects the output of `Get-SubscriptionCost`/`Get-StorageCost`/`Get-CostAdvisor`:

```powershell
Import-CostData -Path C:\Cost\SubscriptionCost.json | Show-CostAnalysis -ComparePrevious
```

> `-Path` can also point to a directory, in which case every `.json` file within it is imported and returned together — useful if you've saved separate exports over time and want to combine them for a longer-running comparison.

### Loading cost data from a Storage Account export

Azure Cost Management can be configured to routinely write "Actual Cost" CSV exports to a Storage Account. This is done in the Azure Portal under **Cost Management + Billing > Cost Management > Exports**, where you can create a scheduled export and select a Storage Account and container for it to write to.

Once configured, `Import-CostExport` can read the exported cost data for a given billing month directly from that container -- avoiding the Consumption API being queried live at all:

```powershell
Import-CostExport -StorageAccountName 'mycostexports' -ResourceGroupName 'rg-cost' -ContainerName 'costexports' -BillingMonth 01/2024 -PreviousMonths 3
```

This requires the `Az.Storage` module to be installed:

```powershell
Install-Module Az.Storage
```

The result is returned in the same shape as `Get-SubscriptionCost`, so it can be piped to `Show-CostAnalysis` or `Export-CostData` in exactly the same way.

> The CSV column mapping is based on the standard "Actual Cost" export schema. If your export uses a Microsoft Customer Agreement/Enterprise Agreement schema variant with different column names, please raise an issue with a sample of the column headers so the mapping can be extended.

### Managing Budgets

Rather than a fixed budget figure that you have to remember to update manually, `Set-SubscriptionBudget` lets you keep a subscription's budget in step with its actual recent spend, by recalculating it from cost history via `Get-SubscriptionCost`.

To update the budget for every subscription in your current context to the average of its previous 3 billing months' cost (the default), execute:

```powershell
Set-SubscriptionBudget
```

> As with other cmdlets in this module, `-WhatIf` is supported so you can preview the change before it's made, e.g `Set-SubscriptionBudget -WhatIf`.

To base the new budget on a different number of months, and add a percentage buffer on top of the calculated average (e.g. to leave some headroom), execute:

```powershell
Set-SubscriptionBudget -SubscriptionName 'AdventureWorks Cycles' -Months 6 -BufferPercent 10
```

Other parameters available for `Set-SubscriptionBudget` include:

* `-BudgetName` — Target a specific budget, for subscriptions that have more than one.
* `-MinimumAmount` — Prevents the calculated budget from ever being set below this value.
* `-CreateIfMissing` — Creates a new Monthly budget if the subscription doesn't already have one, instead of skipping it.
* `-PassThru` — Returns an object describing the budget change made (or that would be made, with `-WhatIf`) for each subscription.
