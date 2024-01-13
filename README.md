# PowerShell-AzCostTools

[![Build Status](https://dev.azure.com/markwragg/GitHub/_apis/build/status/markwragg.PowerShell-AzCostTools?branchName=main)](https://dev.azure.com/markwragg/GitHub/_build/latest?definitionId=11&branchName=main) ![coverage](https://img.shields.io/badge/coverage-93%25-brightgreen.svg)

A PowerShell module for cmdlets related to Azure cost analysis.

## Installation

The module is published in the PSGallery, so if you have PowerShell 5 or newer can be installed by running:

```powershell
Install-Module AzCostTools
```

## Usage

This module requires the AZ module be installed (Az.Billing in particular):

```powershell
Install-Module Az
```

I also recommend you install the PSparklines module by @endowdly. While the AzCostTools module will function without it,  PSparklines enables the generation of simplistic but fun cost charts.

```powershell
Install-Module PSparklines
```

Ensure you have logged in to AZ PowerShell via `Login-AzAccount` and to the tenant that has the Subscription/s you wish to query.

To return cost data for the current billing month for all Subscriptions in your current Azure Context, simple execute:

```powershell
Get-SubscriptionCost
```

To view some interesting analysis of the cost data returned by that command, execute the following:

```powershell
Get-SubscriptionCost | Show-CostAnalysis
```

