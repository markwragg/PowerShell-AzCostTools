function Set-SubscriptionBudget {
    <#
    .SYNOPSIS
        Updates the amount of one or more Azure subscription budgets based on recent actual spend.

    .DESCRIPTION
        Calculates the average cost for a number of previous billing months (via Get-SubscriptionCost) and updates
        the amount of the subscription's existing consumption budget to match, optionally adding a percentage buffer.
        This allows a budget to be kept in step with genuinely changing costs, rather than remaining a fixed figure
        that is manually maintained.

        By default the first budget found for the subscription is updated. Use -BudgetName if a subscription has
        multiple budgets and you want to target a specific one. If no budget exists and -CreateIfMissing is
        specified, a new monthly budget is created instead.

    .PARAMETER SubscriptionName
        The name or name/s of the Subscriptions to update the budget for. If not specified all subscriptions available
        in the current context will be used.

    .PARAMETER BudgetName
        The name of a specific budget to update (or create, when used with -CreateIfMissing). If not specified, the
        first budget found for the subscription is used.

    .PARAMETER BillingMonth
        The most recent billing month to include in the spend average, specified as a [datetime] object. Defaults to
        the previous calendar month, since the current month's spend is typically incomplete.

    .PARAMETER Months
        The number of billing months (ending with -BillingMonth) to average when calculating the new budget amount.
        Default: 3.

    .PARAMETER BufferPercent
        A percentage to add on top of the calculated average spend, e.g. specify 10 to set the budget 10% higher than
        average spend. Can be negative to set the budget below average spend. Default: 0.

    .PARAMETER MinimumAmount
        If specified, the new budget amount will never be set lower than this value, regardless of the calculated
        average spend.

    .PARAMETER CreateIfMissing
        Switch: If no existing budget is found for a subscription, create a new one using -BudgetName (or a generated
        name if not specified) and -TimeGrain, instead of skipping that subscription.

    .PARAMETER TimeGrain
        The time grain to use when creating a new budget with -CreateIfMissing. Default: Monthly.

    .PARAMETER PassThru
        Switch: Return an object describing the budget change made (or that would be made, with -WhatIf) for each subscription.

    .EXAMPLE
        Set-SubscriptionBudget

        Description
        -----------
        Updates the budget for every subscription in the current Azure context to match its average spend over the previous 3 billing months.

    .EXAMPLE
        Set-SubscriptionBudget -SubscriptionName 'MySubscriptionA' -Months 6 -BufferPercent 10 -WhatIf

        Description
        -----------
        Shows what the budget for 'MySubscriptionA' would be updated to, based on its average spend over the previous 6 billing months plus a 10% buffer, without making any change.

    .EXAMPLE
        Set-SubscriptionBudget -SubscriptionName 'MySubscriptionA' -Months 1 -PassThru

        Description
        -----------
        Updates the budget for 'MySubscriptionA' to match its spend for the previous billing month alone, and returns an object describing the change.

    .EXAMPLE
        Set-SubscriptionBudget -SubscriptionName 'MySubscriptionA' -CreateIfMissing -BudgetName 'MySubscriptionA-Budget'

        Description
        -----------
        Updates the existing budget named 'MySubscriptionA-Budget' for 'MySubscriptionA', or creates it (as a Monthly budget) if it does not already exist.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param(
        [Alias('Name', 'Subscription')]
        [string[]]
        $SubscriptionName,

        [Alias('Budget')]
        [string]
        $BudgetName,

        [Alias('Month')]
        [datetime]
        $BillingMonth = (Get-Date).AddMonths(-1),

        [Alias('PrevMonths')]
        [ValidateRange(1, 24)]
        [int]
        $Months = 3,

        [Alias('Buffer')]
        [double]
        $BufferPercent = 0,

        [double]
        $MinimumAmount,

        [switch]
        $CreateIfMissing,

        [ValidateSet('Monthly', 'Quarterly', 'Annually')]
        [string]
        $TimeGrain = 'Monthly',

        [switch]
        $PassThru
    )
    begin {
        # Store the users current AZ context before we start
        $PreAzContext = Get-AzContext
    }
    process {
        try {
            if (-not $SubscriptionName) {
                $SubscriptionName = (Get-AzSubscription -ErrorAction Stop).Name
            }

            foreach ($Name in $SubscriptionName) {

                try {
                    if ((Get-AzContext).Subscription.Name -ne $Name) {
                        Set-AzContext -Subscription $Name -ErrorAction Stop | Out-Null
                    }

                    $History = Get-SubscriptionCost -SubscriptionName $Name -BillingMonth $BillingMonth -PreviousMonths ($Months - 1) -ErrorAction Stop

                    $AverageCost = ($History.Cost | Measure-Object -Average).Average

                    if (-not $AverageCost) {
                        Write-Warning "No cost history found for subscription '$Name'. Skipping."
                        continue
                    }

                    $NewAmount = [math]::Round($AverageCost * (1 + ($BufferPercent / 100)), 2)

                    if ($MinimumAmount -and $NewAmount -lt $MinimumAmount) {
                        $NewAmount = $MinimumAmount
                    }

                    $ExistingBudgets = Get-AzConsumptionBudget -ErrorAction SilentlyContinue

                    $Budget = if ($BudgetName) {
                        $ExistingBudgets | Where-Object Name -EQ $BudgetName
                    }
                    else {
                        $ExistingBudgets | Select-Object -First 1
                    }

                    if (-not $Budget) {

                        if (-not $CreateIfMissing) {
                            Write-Warning "No existing budget found for subscription '$Name'. Use -CreateIfMissing to create one."
                            continue
                        }

                        $NewBudgetName = if ($BudgetName) { $BudgetName } else { "$Name-Budget" }
                        $StartDate = Get-Date -Day 1 -Hour 0 -Minute 0 -Second 0 -Millisecond 0

                        if ($PSCmdlet.ShouldProcess($Name, "Create budget '$NewBudgetName' with amount $NewAmount")) {
                            $Budget = New-AzConsumptionBudget -Name $NewBudgetName -Amount $NewAmount -Category 'Cost' -TimeGrain $TimeGrain -StartDate $StartDate
                        }

                        if ($PassThru) {
                            [pscustomobject]@{
                                SubscriptionName = $Name
                                BudgetName       = $NewBudgetName
                                PreviousAmount   = $null
                                NewAmount        = $NewAmount
                                AverageCost      = [math]::Round($AverageCost, 2)
                                Months           = $Months
                                BufferPercent    = $BufferPercent
                                Created          = $true
                            }
                        }

                        continue
                    }

                    $PreviousAmount = $Budget.Amount

                    if ($PSCmdlet.ShouldProcess($Name, "Update budget '$($Budget.Name)' amount from $PreviousAmount to $NewAmount")) {
                        Set-AzConsumptionBudget -InputObject $Budget -Amount $NewAmount -ErrorAction Stop | Out-Null
                    }

                    if ($PassThru) {
                        [pscustomobject]@{
                            SubscriptionName = $Name
                            BudgetName       = $Budget.Name
                            PreviousAmount   = $PreviousAmount
                            NewAmount        = $NewAmount
                            AverageCost      = [math]::Round($AverageCost, 2)
                            Months           = $Months
                            BufferPercent    = $BufferPercent
                            Created          = $false
                        }
                    }
                }
                catch {
                    Write-Error $_
                }
            }
        }
        catch {
            throw $_
        }
        finally {
            # Return the user to their previous AZ context (in case it has changed).
            $PreAzContext | Set-AzContext | Out-Null
        }
    }
}
