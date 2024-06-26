# Change Log

## [0.0.3] - 2024-06-02

* Implemented `Get-CostAdvisor` to return Azure advisor cost recommendations for one or more subscriptions ([#5](https://github.com/markwragg/PowerShell-AzCostTools/issues/5)).

## [0.0.2] - 2024-03-02

* Implemented `Get-StorageCost` to retrieve Azure Storage account cost data and compare to the previous month.
* Added `-ComparePreviousOffset` parameter to `Get-SubscriptionCost` configure how many months previous to compare cost data for.
* Added `-ComparePrevious` parameter to `Show-CostAnalysis` to output sparkline charts and analysis for the comparison costs.
* Various fixes and documentation improvements.

## [0.0.1] - 2024-01-14

* Implemented `Get-SubscriptionCost` to retrieve Azure subscription cost data and optionally compare to the previous month, while also returning additional insight.
* Implemented `Show-CostAnalysis` to further visually analyse the data returned by `Get-SubscriptionCost`.

## [0.0.0] - 2024-01-09

* Initial commit
